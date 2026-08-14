/**
 * Protected Paths Extension
 *
 * Blocks write and edit operations to protected paths.
 * Useful for preventing accidental modifications to sensitive files.
 *
 * Coverage:
 * - write / edit: the target `path`
 * - sed: only when `inPlace` is set (plain sed only writes to stdout)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const protectedPaths = [".env", ".git/", "node_modules/"];

	/** Collect the file paths a tool call may write to. */
	function getWriteTargets(event: { toolName: string; input: Record<string, unknown> }): string[] {
		switch (event.toolName) {
			case "write":
			case "edit":
				return [event.input.path as string];
			case "sed":
				// Only in-place edits modify files; plain sed reads input and writes stdout.
				return event.input.inPlace ? [event.input.file as string] : [];
			default:
				return [];
		}
	}

	pi.on("tool_call", async (event, ctx) => {
		const targets = getWriteTargets(event);
		const blocked = targets.find((path) => path && protectedPaths.some((p) => path.includes(p)));

		if (blocked) {
			if (ctx.hasUI) {
				ctx.ui.notify(`Blocked write to protected path: ${blocked}`, "warning");
			}
			return { block: true, reason: `Path "${blocked}" is protected` };
		}

		return undefined;
	});
}
