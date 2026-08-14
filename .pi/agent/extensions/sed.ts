/**
 * sed Tool - stream editor exposed as a first-class tool.
 *
 * Runs GNU sed with a structured script argument. Supports both file input
 * and stdin input (via `content`), so the model can pipe text directly
 * without writing temp files.
 *
 * Safety: in-place editing (`-i`) is opt-in and flagged as destructive;
 * a `backup` suffix can be provided to keep a .bak file.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const MAX_BYTES = 50 * 1024;

const SedParams = Type.Object({
	script: Type.String({ description: "sed expression, e.g. 's/foo/bar/g' or '/pattern/d'" }),
	file: Type.Optional(Type.String({ description: "File to process (default: read from content/stdin)" })),
	content: Type.Optional(Type.String({ description: "Input text to pipe to sed via stdin (used when file is not set)" })),
	extended: Type.Optional(Type.Boolean({ description: "Use extended regex syntax (-E)" })),
	quiet: Type.Optional(Type.Boolean({ description: "Suppress automatic printing of pattern space (-n)" })),
	inPlace: Type.Optional(Type.Boolean({ description: "Edit file in place (-i). DESTRUCTIVE - modifies the file directly; use backup for safety" })),
	backup: Type.Optional(Type.String({ description: "Backup suffix for in-place edits, e.g. 'bak' keeps file.bak (-i.bak)" })),
});

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "sed",
		label: "sed",
		description: "Stream editor (GNU sed). Apply a sed expression to a file or stdin text. In-place edits are opt-in.",
		promptSnippet: "Transform text with sed (stream editor)",
		promptGuidelines: [
			"Use sed for line-based text transformations (substitute, delete, print ranges) when the change is expressible as one sed expression; prefer the edit tool for precise multi-line edits.",
		],
		parameters: SedParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			return runSed(params, signal, ctx);
		},
	});
}

async function runSed(
	params: {
		script: string;
		file?: string;
		content?: string;
		extended?: boolean;
		quiet?: boolean;
		inPlace?: boolean;
		backup?: string;
	},
	signal: AbortSignal | undefined,
	ctx: ExtensionContext,
): Promise<{ content: Array<{ type: "text"; text: string }>; details?: unknown }> {
	const args: string[] = [];
	if (params.extended) args.push("-E");
	if (params.quiet) args.push("-n");
	if (params.inPlace) args.push(params.backup ? `-i.${params.backup}` : "-i");
	args.push("--", params.script);
	if (params.file) args.push(params.file);

	const useStdin = !params.file;
	return new Promise((resolve, reject) => {
		const child = spawn("sed", args, { cwd: ctx.cwd });
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

		if (useStdin) {
			child.stdin.write(params.content ?? "");
			child.stdin.end();
		}
		child.stdout.on("data", (d: Buffer) => {
			stdout += d.toString();
		});
		child.stderr.on("data", (d: Buffer) => {
			stderr += d.toString();
		});
		child.on("error", (err: NodeJS.ErrnoException) => {
			settle(() =>
				reject(
					new Error(
						err.code === "ENOENT"
							? "sed is not installed on this system"
							: `Failed to run sed: ${err.message}`,
					),
				),
			);
		});
		child.on("close", (code) => {
			settle(() => {
				if (code !== 0) {
					reject(new Error(`sed exited with code ${code}: ${stderr.trim() || "unknown error"}`));
					return;
				}
				if (params.inPlace) {
					resolve({ content: [{ type: "text", text: `Applied in-place edit to ${params.file}` }], details: {} });
					return;
				}
				const lines = stdout.split("\n").filter((l) => l.length > 0);
				let text = stdout;
				if (Buffer.byteLength(text, "utf8") > MAX_BYTES) {
					let kept: string[] = [];
					let bytes = 0;
					for (const line of lines) {
						const size = Buffer.byteLength(line, "utf8") + 1;
						if (bytes + size > MAX_BYTES) break;
						kept.push(line);
						bytes += size;
					}
					text = kept.join("\n") + `\n\n[Truncated: ${lines.length - kept.length} more lines omitted]`;
				}
				resolve({ content: [{ type: "text", text }], details: { lines: lines.length } });
			});
		});
	});
}
