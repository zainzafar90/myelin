/* Hook process runner and logging for the OpenCode adapter. */
import { spawnSync } from "node:child_process"
import { appendFileSync } from "node:fs"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import type { HookResult, Json } from "./opencode-types.ts"

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../../..")
const HOOKS = join(ROOT, "hooks")
const TIMEOUT_MS = 2000

export const DEBUG = process.env.MYELIN_OC_LOG
export const BLOCK_EXIT = 2

export function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err)
}

export function log(msg: string): void {
  const line = `[myelin-opencode] ${msg}`

  try {
    if (DEBUG) appendFileSync(DEBUG, line + "\n")
    else console.error(line)
  } catch {
    /* logging must never throw */
  }
}

export function runHook(script: string, payload: Json): HookResult | undefined {
  const r = spawnSync("bash", [join(HOOKS, script)], {
    input: JSON.stringify(payload),
    encoding: "utf8",
    timeout: TIMEOUT_MS,
    env: { ...process.env, MYELIN_ROOT: ROOT },
  })

  if (r.error || r.status === null) {
    log(`${script} failed (allowing): ${r.error?.message ?? "signal " + r.signal}`)
    return undefined
  }

  return { code: r.status, stdout: r.stdout ?? "", stderr: r.stderr ?? "" }
}
