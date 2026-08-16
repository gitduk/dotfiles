/**
 * Subagent runner — spawns an isolated `pi` process in JSON mode,
 * streams its events, and returns the final assistant output.
 *
 * Auto-exit: waits for the child's `agent_end` event, then kills the
 * process after a short grace period. The child does not need to call
 * any completion tool — it is terminated by the parent.
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const SIGKILL_TIMEOUT_MS = 5000;
const AGENT_END_GRACE_MS = 250;

export interface Usage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  contextTokens: number;
  turns: number;
}

export interface AssistantMessage {
  role: string;
  content: unknown;
  usage?: { input?: number; output?: number; cacheRead?: number; cacheWrite?: number; cost?: { total?: number }; totalTokens?: number };
  model?: string;
  stopReason?: string;
}

export interface RunResult {
  exitCode: number;
  messages: AssistantMessage[];
  stderr: string;
  usage: Usage;
  model?: string;
  finalOutput: string;
}

const emptyUsage = (): Usage => ({
  input: 0,
  output: 0,
  cacheRead: 0,
  cacheWrite: 0,
  cost: 0,
  contextTokens: 0,
  turns: 0,
});

/** Derive the pi invocation so child spawns work without a shell wrapper. */
function resolvePiSpawn(): { command: string; prefixArgs: string[] } {
  const isNode = /[\\/]node(?:\.exe)?$/i.test(process.execPath);
  if (isNode && process.argv[1]) {
    return { command: process.execPath, prefixArgs: [process.argv[1]] };
  }
  return { command: process.execPath, prefixArgs: [] };
}

/** Forward `-e/--extension` flags from the parent so the child has the same custom tools. */
function inheritedExtensionArgs(argv: string[]): string[] {
  const out: string[] = [];
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "-e" || arg === "--extension") {
      const value = argv[i + 1];
      if (value && !value.startsWith("-")) {
        const resolved = value.startsWith("~/")
          ? path.join(os.homedir(), value.slice(2))
          : value;
        out.push(arg, resolved);
        i++;
      }
    } else if (arg.startsWith("--extension=")) {
      out.push("--extension", arg.slice("--extension=".length));
    }
  }
  return out;
}

/** Extract the final assistant text from collected messages. */
export function getFinalOutput(messages: AssistantMessage[]): string {
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role !== "assistant" || !Array.isArray(msg.content)) continue;
    for (const part of msg.content as Array<{ type?: string; text?: string }>) {
      if (part?.type === "text" && part.text) return part.text;
    }
  }
  return "";
}

function recordMessage(result: RunResult, message: any): void {
  if (!message || message.role !== "assistant") return;
  if (!result.model && message.model) result.model = message.model;
  result.messages.push(message as AssistantMessage);
  result.usage.turns++;
  const u = message.usage;
  if (u) {
    result.usage.input += u.input || 0;
    result.usage.output += u.output || 0;
    result.usage.cacheRead += u.cacheRead || 0;
    result.usage.cacheWrite += u.cacheWrite || 0;
    result.usage.cost += u.cost?.total || 0;
    result.usage.contextTokens = u.totalTokens || 0;
  }
}

export interface RunOptions {
  cwd: string;
  task: string;
  skills?: string[];
  signal?: AbortSignal;
  onUpdate?: (partial: { text: string }) => void;
}

/**
 * Run one subagent. Skills are injected as standalone `/skill:x` positional
 * messages (the child pi process expands them itself), followed by the task.
 */
export async function runSubagent(opts: RunOptions): Promise<RunResult> {
  const { cwd, task, skills, signal, onUpdate } = opts;

  const result: RunResult = {
    exitCode: -1,
    messages: [],
    stderr: "",
    usage: emptyUsage(),
  };

  const args: string[] = ["--mode", "json", ...inheritedExtensionArgs(process.argv), "-p", "--no-session"];
  for (const s of skills ?? []) args.push(`/skill:${s}`);
  args.push(`Task: ${task}`);

  let wasAborted = false;

  const exitCode = await new Promise<number>((resolve) => {
    const { command, prefixArgs } = resolvePiSpawn();
    const proc = spawn(command, [...prefixArgs, ...args], {
      cwd,
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env, PI_OFFLINE: "1" },
    });

    // stdin is "ignore" — no pipe to write to, nothing to wire up.

    let buffer = "";
    let didClose = false;
    let settled = false;
    let sawAgentEnd = false;
    let semanticTimer: NodeJS.Timeout | undefined;
    let abortHandler: (() => void) | undefined;

    const clearTimer = () => {
      if (semanticTimer) {
        clearTimeout(semanticTimer);
        semanticTimer = undefined;
      }
    };

    const terminateChild = () => {
      proc.kill("SIGTERM");
      const killer = setTimeout(() => {
        if (!didClose) proc.kill("SIGKILL");
      }, SIGKILL_TIMEOUT_MS);
      killer.unref();
    };

    const finish = (code: number) => {
      if (settled) return;
      settled = true;
      clearTimer();
      if (signal && abortHandler) signal.removeEventListener("abort", abortHandler);
      resolve(code);
    };

    const flushBuffered = (text: string) => {
      for (const line of text.split(/\r?\n/)) {
        if (!line.trim()) continue;
        let event: any;
        try {
          event = JSON.parse(line);
        } catch {
          continue;
        }
        if (event?.type === "agent_end") sawAgentEnd = true;
        if (event?.type === "message_end") {
          recordMessage(result, event.message);
          onUpdate?.({ text: getFinalOutput(result.messages) || "(running...)" });
        }
        if (event?.type === "agent_end" && Array.isArray(event.messages)) {
          for (const m of event.messages) recordMessage(result, m);
          onUpdate?.({ text: getFinalOutput(result.messages) || "(running...)" });
        }
      }
    };

    const armAgentEndTimer = () => {
      clearTimer();
      semanticTimer = setTimeout(() => {
        if (didClose || settled) return;
        if (buffer.trim()) {
          flushBuffered(buffer);
          buffer = "";
        }
        proc.stdout.removeAllListeners("data");
        proc.stderr.removeAllListeners("data");
        finish(0);
        terminateChild();
      }, AGENT_END_GRACE_MS);
      semanticTimer.unref();
    };

    const onStdoutData = (chunk: Buffer) => {
      buffer += chunk.toString();
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() || "";
      for (const line of lines) {
        if (!line.trim()) continue;
        let event: any;
        try {
          event = JSON.parse(line);
        } catch {
          continue;
        }
        if (event?.type === "agent_end") {
          sawAgentEnd = true;
          armAgentEndTimer();
        }
        if (event?.type === "message_end") {
          recordMessage(result, event.message);
          onUpdate?.({ text: getFinalOutput(result.messages) || "(running...)" });
        }
        if (event?.type === "agent_end" && Array.isArray(event.messages)) {
          for (const m of event.messages) recordMessage(result, m);
          onUpdate?.({ text: getFinalOutput(result.messages) || "(running...)" });
        }
      }
    };

    const onStderrData = (chunk: Buffer) => {
      result.stderr += chunk.toString();
    };

    proc.stdout.on("data", onStdoutData);
    proc.stderr.on("data", onStderrData);

    proc.on("close", (code) => {
      didClose = true;
      if (buffer.trim()) flushBuffered(buffer);
      finish(code ?? 0);
    });

    proc.on("error", (err) => {
      if (!result.stderr.trim()) result.stderr = err.message;
      finish(1);
    });

    if (signal) {
      abortHandler = () => {
        if (didClose || settled) return;
        wasAborted = true;
        terminateChild();
      };
      if (signal.aborted) abortHandler();
      else signal.addEventListener("abort", abortHandler, { once: true });
    }
  });

  result.exitCode = exitCode;
  result.finalOutput =
    getFinalOutput(result.messages) ||
    (result.stderr.trim() ? `Subagent error: ${result.stderr.trim()}` : "(no output)");
  return result;
}
