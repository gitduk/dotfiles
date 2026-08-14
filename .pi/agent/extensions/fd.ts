/**
 * fd Tool - fast file search powered by the `fd` binary.
 *
 * A custom tool exposing `fd` (https://github.com/sharkdp/fd) to the model as
 * a first-class function, similar to the built-in `find` tool but faster.
 *
 * Requires `fd` on PATH (installed here at ~/.local/bin/fd). If missing, the
 * tool returns a clear install hint instead of failing silently.
 */

import { spawn } from "node:child_process";
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DEFAULT_LIMIT = 1000;
const MAX_BYTES = 50 * 1024; // keep aligned with built-in tool output budgets

const FdParams = Type.Object({
	pattern: Type.Optional(
		Type.String({ description: "Glob pattern, e.g. '*.ts', 'src/**/*.json'. Omit to list all entries" }),
	),
	path: Type.Optional(Type.String({ description: "Directory to search in (default: current directory)" })),
	limit: Type.Optional(Type.Number({ description: "Maximum number of results (default: 1000)" })),
	type: Type.Optional(
		StringEnum(["f", "d", "l"] as const, {
			description: "Match only files (f), directories (d), or symlinks (l)",
		}),
	),
	extension: Type.Optional(Type.String({ description: "Filter by file extension without the dot, e.g. 'ts' (same as -e)" })),
	hidden: Type.Optional(Type.Boolean({ description: "Include hidden files and directories (default: false)" })),
});

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "fd",
		label: "fd",
		description:
			"Find files fast with fd. Accepts glob patterns and respects .gitignore. Returns relative paths, truncated to 1000 results or 50KB.",
		promptSnippet: "Find files fast with fd (glob patterns, respects .gitignore)",
		promptGuidelines: [
			"Use fd when the user asks to find files by name or glob — faster than the built-in find tool.",
		],
		parameters: FdParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			return runFd(params, signal, ctx);
		},
	});
}

async function runFd(
	params: {
		pattern?: string;
		path?: string;
		limit?: number;
		type?: "f" | "d" | "l";
		extension?: string;
		hidden?: boolean;
	},
	signal: AbortSignal | undefined,
	ctx: ExtensionContext,
): Promise<{ content: Array<{ type: "text"; text: string }>; details?: unknown }> {
	const args: string[] = ["--color=never", "--glob", "--max-results", String(params.limit ?? DEFAULT_LIMIT)];
	if (params.type) args.push("--type", params.type);
	if (params.extension) args.push("-e", params.extension);
	if (params.hidden) args.push("--hidden");

	// fd --glob matches against the basename unless --full-path is set; in --full-path
	// mode it matches against the absolute candidate path, so a path-containing
	// pattern like 'src/**/*.spec.ts' needs a leading '**/' to match anything.
	// (Same handling as pi's built-in find tool.)
	let effectivePattern = params.pattern;
	if (effectivePattern && effectivePattern.includes("/")) {
		args.push("--full-path");
		if (!effectivePattern.startsWith("/") && !effectivePattern.startsWith("**/") && effectivePattern !== "**") {
			effectivePattern = `**/${effectivePattern}`;
		}
	}

	// Positional args: fd requires the first positional arg to be the PATTERN, so when no
	// pattern is given, pass the path via the official --search-path option instead of
	// relying on a match-all pattern. (See fd.1: "use the --search-path option to specify
	// the path(s) instead of the positional parameter.")
	if (effectivePattern) {
		args.push("--", effectivePattern);
		if (params.path) args.push(params.path);
	} else if (params.path) {
		args.push("--search-path", params.path);
	}
	// No pattern and no path: fd lists the current directory by default.

	return new Promise((resolve, reject) => {
		const child = spawn("fd", args, { cwd: ctx.cwd });
		let stdout = "";
		let stderr = "";
		let settled = false;

		const settle = (fn: () => void) => {
			if (settled) return;
			settled = true;
			signal?.removeEventListener("abort", onAbort);
			fn();
		};
		const onAbort = () => {
			child.kill();
			settle(() => reject(new Error("Operation aborted")));
		};
		signal?.addEventListener("abort", onAbort, { once: true });

		child.stdout.on("data", (d: Buffer) => {
			stdout += d.toString();
			if (stdout.length > MAX_BYTES * 2) child.kill(); // runaway output guard
		});
		child.stderr.on("data", (d: Buffer) => {
			stderr += d.toString();
		});
		child.on("error", (err: NodeJS.ErrnoException) => {
			settle(() =>
				reject(
					new Error(
						err.code === "ENOENT"
							? "fd is not installed. Install it via your package manager (apt install fd-find, brew install fd, cargo install fd-find) or download from https://github.com/sharkdp/fd"
							: `Failed to run fd: ${err.message}`,
					),
				),
			);
		});
		child.on("close", (code) => {
			settle(() => {
				if (code !== 0) {
					reject(new Error(`fd exited with code ${code}: ${stderr.trim() || "unknown error"}`));
					return;
				}
				const lines = stdout.split("\n").filter((l) => l.length > 0);
				if (lines.length === 0) {
					resolve({ content: [{ type: "text", text: "No files found matching pattern" }] });
					return;
				}
				let text = lines.join("\n");
				const truncated = Buffer.byteLength(text, "utf8") > MAX_BYTES;
				if (truncated) {
					// Trim to whole lines that fit within MAX_BYTES
					let kept: string[] = [];
					let bytes = 0;
					for (const line of lines) {
						const size = Buffer.byteLength(line, "utf8") + 1;
						if (bytes + size > MAX_BYTES) break;
						kept.push(line);
						bytes += size;
					}
					text = kept.join("\n") + `\n\n[Truncated: ${lines.length - kept.length} more results omitted]`;
				}
				resolve({ content: [{ type: "text", text }], details: { count: lines.length } });
			});
		});
	});
}
