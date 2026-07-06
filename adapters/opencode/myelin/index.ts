/* OpenCode adapter: thin shim over hooks/*.sh. Fail-open everywhere. */
import { appendFileSync, mkdirSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { BLOCK_EXIT, DEBUG, errMsg, log, runHook } from "./hook-runner.ts"
import type { BusEvent, Json, PluginContext, Session, ToolEvent } from "./opencode-types.ts"

const DIR = join(tmpdir(), "myelin-opencode")

const sessions = new Map<string, Session>()

function sessionFor(id: string, cwd: string): Session {
  let s = sessions.get(id)

  if (!s) {
    mkdirSync(DIR, { recursive: true })
    s = { file: join(DIR, `${id.replace(/[^\w-]/g, "_")}.jsonl`), cwd, nudged: false }
    sessions.set(id, s)
  }

  return s
}

function record(s: Session, entry: Json): void {
  try {
    appendFileSync(s.file, JSON.stringify(entry) + "\n")
  } catch (e) {
    log(`transcript write failed: ${errMsg(e)}`)
  }
}

function skillName(input: Json | undefined): string | undefined {
  const v = input?.id ?? input?.name

  return typeof v === "string" ? v : undefined
}

function bannerFor(s: Session): string {
  if (s.banner === undefined) {
    const r = runHook("session-start.sh", { cwd: s.cwd })

    s.banner = r && r.code === 0 ? r.stdout.trim() : ""
  }

  return s.banner
}

function recordSkillCall(s: Session, e: ToolEvent): void {
  if (!/skill/i.test(String(e.tool))) return

  const skill = skillName(e.input)

  if (skill) record(s, { type: "tool_use", name: "Skill", input: { skill } })
}

function gateShell(s: Session, command: string): string | undefined {
  record(s, { type: "tool_use", name: "Bash", input: { command } })

  const r = runHook("pre-git-gate.sh", {
    tool_name: "Bash",
    tool_input: { command },
    cwd: s.cwd,
    transcript_path: s.file,
  })

  if (r?.code !== BLOCK_EXIT) return undefined

  return r.stderr.trim() || "myelin git-gate blocked this command"
}

function blockReason(e: ToolEvent, cwd: string): string | undefined {
  if (DEBUG) log(`execute.before tool=${e.tool} keys=${Object.keys(e)} input=${JSON.stringify(e.input).slice(0, 200)}`)

  const s = sessionFor(e.sessionID ?? "unknown", cwd)

  if (typeof e.input?.workdir === "string") s.cwd = e.input.workdir

  recordSkillCall(s, e)

  const command = e.input?.command

  if (e.tool !== "shell" || typeof command !== "string") return undefined

  return gateShell(s, command)
}

async function nudgeIfUnverified(ctx: PluginContext, s: Session, id: string): Promise<void> {
  const r = runHook("stop-verify.sh", { transcript_path: s.file, stop_hook_active: s.nudged })
  const wasNudged = s.nudged

  s.nudged = false

  if (wasNudged || r?.code !== BLOCK_EXIT) return

  s.nudged = true
  await ctx.session.prompt({ sessionID: id, text: r.stderr.trim() })
  log(`nudged session ${id}`)
}

async function onEvent(ctx: PluginContext, ev: BusEvent, cwd: string): Promise<void> {
  const id = ev.data?.sessionID

  if (!id) return

  const s = sessionFor(id, cwd)

  if (DEBUG && String(ev.type).startsWith("session.execution")) log(`${ev.type} ${id}`)

  if (ev.type === "session.text.ended" && typeof ev.data?.text === "string") {
    record(s, { type: "text", text: ev.data.text })

    return
  }

  if (ev.type === "session.execution.succeeded") await nudgeIfUnverified(ctx, s, id)
}

async function pumpEvents(ctx: PluginContext, signal: AbortSignal, cwdOf: () => string): Promise<void> {
  try {
    for await (const ev of ctx.event.subscribe({ signal })) {
      try {
        await onEvent(ctx, ev, cwdOf())
      } catch (err) {
        log(`event ${ev?.type} error (allowing): ${errMsg(err)}`)
      }
    }
  } catch (err) {
    if (!signal.aborted) log(`event loop ended: ${errMsg(err)}`)
  }
}

export default {
  id: "myelin",
  async setup(ctx: PluginContext) {
    const abort = new AbortController()
    const cwdOf = () => ctx.location?.directory ?? process.cwd()

    ctx.session.hook("context", (e) => {
      try {
        const banner = bannerFor(sessionFor(e.sessionID, cwdOf()))

        if (banner) e.system.push({ type: "text", text: banner })
      } catch (err) {
        log(`context hook error (allowing): ${errMsg(err)}`)
      }
    })

    ctx.tool.hook("execute.before", (e) => {
      let block: string | undefined

      try {
        block = blockReason(e, cwdOf())
      } catch (err) {
        log(`execute.before error (allowing): ${errMsg(err)}`)
      }

      if (block) throw new Error(block)
    })

    void pumpEvents(ctx, abort.signal, cwdOf)

    return () => abort.abort()
  },
}
