/**
 * Subagent tool — delegate a task to an isolated `pi` process.
 *
 * Skills are injected as `/skill:x` messages and expanded by the child
 * process itself (no template handling in the parent). The child runs in
 * JSON mode and is terminated by the parent on `agent_end`, so there is
 * no completion tool to call and no lingering pane/widget.
 */

import { Type } from "typebox";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { runSubagent, type RunResult, type Usage } from "./runner.js";

function formatUsage(u: Usage): string {
  const parts: string[] = [];
  if (u.turns) parts.push(`${u.turns} turn${u.turns > 1 ? "s" : ""}`);
  if (u.input) parts.push(`\u2191${u.input}`);
  if (u.output) parts.push(`\u2193${u.output}`);
  if (u.cacheRead) parts.push(`R${u.cacheRead}`);
  if (u.cacheWrite) parts.push(`W${u.cacheWrite}`);
  if (u.cost) parts.push(`$${u.cost.toFixed(4)}`);
  return parts.join(" ");
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Delegate a task to an isolated pi process with its own context window.",
      "The subagent runs headless (no pane, no interactive session) and exits automatically when done.",
      "Optional skills are loaded by the subagent itself as /skill:x — use them to inject reusable workflows (e.g. simplify, code-review).",
      "Spawns as a separate process, so context is isolated: the subagent sees only its task (and the loaded skills).",
    ].join(" "),
    promptSnippet: "Delegate tasks to an isolated headless subagent, optionally with skills",
    promptGuidelines: [
      "Use subagent when a task benefits from an isolated context (research, review, parallel exploration) without polluting the main session.",
      "Pass skills to inject reusable workflows (e.g. skills: [\"simplify\"]) that the subagent loads itself. Without skills the subagent sees only the task text.",
      "Skills define the workflow (how); the task defines the target (what). When they conflict, the task's explicit target wins — state the target in the task and explicitly note any deviation from the skill's default scope (e.g. a skill that diffs the current repo when the target is a specific file).",
      "Choose skills by scope: skills like simplify are bound to the current repo's diff — use them when the target is the repo's recent changes. For a specific file, directory, or external target, inline the review/simplification requirements in the task instead of passing such a skill.",
      "Keep the task self-contained: the subagent has no access to this session's conversation, only to the task text (and loaded skills).",
    ],
    parameters: Type.Object({
      task: Type.String({ description: "Self-contained task description for the subagent" }),
      skills: Type.Optional(
        Type.Array(Type.String(), {
          description: "Skill names to load in the subagent, e.g. [\"simplify\"]",
        }),
      ),
      cwd: Type.Optional(
        Type.String({ description: "Working directory for the subagent process (default: current directory)" }),
      ),
    }),

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const cwd = params.cwd ?? ctx.cwd;

      const result: RunResult = await runSubagent({
        cwd,
        task: params.task,
        skills: params.skills,
        signal,
        onUpdate: (partial) => {
          onUpdate?.({
            content: [{ type: "text", text: partial.text }],
            details: {},
          });
        },
      });

      const isError = result.exitCode !== 0 || result.finalOutput.startsWith("Subagent error:");
      const usageText = formatUsage(result.usage);

      return {
        content: [
          {
            type: "text",
            text: `${isError ? "Subagent failed" : "Subagent done"}${result.model ? ` (${result.model})` : ""}${
              usageText ? ` [${usageText}]` : ""
            }:\n\n${result.finalOutput}`,
          },
        ],
        details: {
          exitCode: result.exitCode,
          usage: result.usage,
          model: result.model,
          stderr: result.stderr,
        },
        ...(isError ? { isError: true } : {}),
      };
    },
  });
}
