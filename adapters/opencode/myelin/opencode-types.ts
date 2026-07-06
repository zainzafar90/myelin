/* Event and context shapes the adapter relies on. */

export type HookResult = { code: number; stdout: string; stderr: string }
export type Session = { file: string; cwd: string; banner?: string; nudged: boolean }
export type Json = Record<string, unknown>
export type ContextEvent = { sessionID: string; system: Array<{ type: "text"; text: string }> }
export type ToolEvent = { tool: unknown; sessionID?: string; input?: Json }
export type BusEvent = { type?: unknown; data?: { sessionID?: string; text?: unknown } }

export type PluginContext = {
  location?: { directory?: string }
  session: {
    hook(name: "context", fn: (e: ContextEvent) => void): void
    prompt(args: { sessionID: string; text: string }): Promise<unknown>
  }
  tool: { hook(name: "execute.before", fn: (e: ToolEvent) => void): void }
  event: { subscribe(opts: { signal: AbortSignal }): AsyncIterable<BusEvent> }
}
