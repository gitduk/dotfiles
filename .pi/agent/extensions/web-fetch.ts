/**
 * web_fetch — fetch a URL over HTTP(S).
 *
 * - Converts HTML pages to readable text (strips scripts/styles/tags)
 * - Enforces a timeout and a response size limit (truncates with a notice)
 * - Follows redirects, reports HTTP status and final URL
 * - Returns errors as readable text instead of throwing
 */

import { Type } from "typebox";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DEFAULT_MAX_BYTES = 150_000;
const DEFAULT_TIMEOUT_MS = 15_000;
const USER_AGENT = "pi-web-fetch/1.0";

/** Rough HTML → readable text: strip script/style/comment, unwrap tags, decode entities, collapse whitespace. */
function htmlToText(html: string): string {
	let s = html;
	s = s.replace(/<script\b[^>]*>[\s\S]*?<\/script\s*>/gi, " ");
	s = s.replace(/<style\b[^>]*>[\s\S]*?<\/style\s*>/gi, " ");
	s = s.replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript\s*>/gi, " ");
	s = s.replace(/<!--[\s\S]*?-->/g, " ");
	s = s.replace(/<\/(p|div|section|article|li|h[1-6]|tr|blockquote|pre|table|ul|ol|header|footer|nav|form|aside|main)>/gi, "\n");
	s = s.replace(/<br\s*\/?\s*>/gi, "\n");
	s = s.replace(/<[^>]+>/g, "");
	// common entities
	s = s.replace(/&nbsp;/gi, " ");
	s = s.replace(/&amp;/gi, "&");
	s = s.replace(/&lt;/gi, "<");
	s = s.replace(/&gt;/gi, ">");
	s = s.replace(/&quot;/gi, '"');
	s = s.replace(/&#39;|&apos;/gi, "'");
	s = s.replace(/&#(\d+);/g, (_m, n: string) => {
		const code = Number(n);
		return Number.isFinite(code) ? String.fromCodePoint(code) : _m;
	});
	s = s.replace(/&#x([0-9a-fA-F]+);/g, (_m, h: string) => {
		const code = parseInt(h, 16);
		return Number.isFinite(code) ? String.fromCodePoint(code) : _m;
	});
	// collapse whitespace
	s = s.replace(/[ \t]+/g, " ");
	s = s.replace(/\n{3,}/g, "\n\n");
	return s.trim();
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch a URL over HTTP(S). Converts HTML pages to readable text, enforces a timeout and a response size limit, follows redirects, and reports HTTP status and final URL.",
		promptSnippet:
			"Fetch remote URLs (web pages, docs, raw files, JSON APIs) over HTTP(S), auto-converting HTML to readable text",
		promptGuidelines: [
			"Use web_fetch to retrieve remote URLs (pi docs on GitHub, web pages, API responses) instead of piping curl through bash.",
		],
		parameters: Type.Object({
			url: Type.String({ description: "The full URL to fetch, e.g. https://example.com/page" }),
			maxBytes: Type.Optional(
				Type.Number({ description: `Maximum response bytes to read (default ${DEFAULT_MAX_BYTES}); larger responses are truncated` }),
			),
			timeoutMs: Type.Optional(
				Type.Number({ description: `Timeout in milliseconds (default ${DEFAULT_TIMEOUT_MS})` }),
			),
			asText: Type.Optional(
				Type.Boolean({ description: "Convert HTML to readable text (default true); set false to return the raw body" }),
			),
			headers: Type.Optional(
				Type.Record(Type.String(), Type.String(), {
					description: "Extra request headers, e.g. User-Agent or Authorization",
				}),
			),
		}),

		async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
			const maxBytes = params.maxBytes ?? DEFAULT_MAX_BYTES;
			const timeoutMs = params.timeoutMs ?? DEFAULT_TIMEOUT_MS;
			const asText = params.asText ?? true;

			const ac = new AbortController();
			const timer = setTimeout(() => ac.abort(new Error(`timeout after ${timeoutMs}ms`)), timeoutMs);
			const onCallerAbort = () => ac.abort();
			signal?.addEventListener("abort", onCallerAbort, { once: true });

			try {
				const res = await fetch(params.url, {
					signal: ac.signal,
					redirect: "follow",
					headers: {
						"User-Agent": USER_AGENT,
						Accept: "text/html,text/plain,application/json,*/*;q=0.8",
						...(params.headers ?? {}),
					},
				});
				const contentType = res.headers.get("content-type") ?? "";
				const finalUrl = res.url;
				const status = res.status;

				if (!res.ok) {
					return {
						content: [
							{
								type: "text",
								text: `web_fetch: HTTP ${status} ${res.statusText ?? ""} for ${params.url}`.trim(),
							},
						],
						details: { status, contentType, finalUrl, ok: false },
					};
				}

				// stream the body with a size limit
				const chunks: Uint8Array[] = [];
				let total = 0;
				let truncated = false;
				const reader = res.body?.getReader();
				if (reader) {
					for (;;) {
						const { done, value } = await reader.read();
						if (done) break;
						if (total + value.byteLength > maxBytes) {
							const remaining = maxBytes - total;
							if (remaining > 0) chunks.push(value.slice(0, remaining));
							total = maxBytes;
							truncated = true;
							await reader.cancel();
							break;
						}
						chunks.push(value);
						total += value.byteLength;
					}
				}

				const buf = new Uint8Array(total);
				let offset = 0;
				for (const c of chunks) {
					buf.set(c, offset);
					offset += c.byteLength;
				}
				let body = new TextDecoder("utf-8", { fatal: false }).decode(buf);

				const mime = contentType.split(";")[0].trim().toLowerCase();
				if (asText && mime.includes("html")) {
					body = htmlToText(body);
				}

				const suffix = truncated ? `\n\n[web_fetch: response truncated at ${maxBytes} bytes]` : "";
				return {
					content: [{ type: "text", text: body + suffix }],
					details: { status, contentType, finalUrl, bytes: total, truncated, ok: true },
				};
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				return {
					content: [{ type: "text", text: `web_fetch: ${msg}` }],
					details: { ok: false, error: msg },
				};
			} finally {
				clearTimeout(timer);
				signal?.removeEventListener("abort", onCallerAbort);
			}
		},
	});
}
