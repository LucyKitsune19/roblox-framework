#!/usr/bin/env node
// Checks the standalone file can be turned back into the framework exactly: extracts every Part 3 file the way the
// file tells an agent to, and the guide from Part 2 with its headings moved back up, then compares each with its
// source byte for byte (line endings aside).   node test-standalone.mjs [standalone file]

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.join(here, "..");
const standalone = path.resolve(process.argv[2] || path.join(pluginRoot, "..", "ROBLOX_FRAMEWORK.md"));
const text = fs.readFileSync(standalone, "utf8");
const normalize = (s) => s.replace(/\r\n/g, "\n").replace(/\n$/, "");
let problems = 0;

// Part 3: "### `path`", a blank line, an opening fence, the content, the closing fence
const extracted = new Map();
const re = /^### `([^`]+)`\n\n````[a-z]*\n([\s\S]*?)\n````$/gm;
for (const m of text.matchAll(re)) extracted.set(m[1], m[2]);

// the sources each extracted file must match
const sources = new Map();
(function walk(dir) {
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) walk(full);
		else sources.set(path.relative(path.join(pluginRoot, "template"), full).replace(/\\/g, "/"), full);
	}
})(path.join(pluginRoot, "template"));
sources.delete("FRAMEWORK_GUIDE.md");
sources.set("tools/check-luau.mjs", path.join(here, "check-luau.mjs"));

for (const [rel, full] of sources) {
	if (!extracted.has(rel)) { console.log(`MISSING   ${rel}`); problems++; continue; }
	if (extracted.get(rel) !== normalize(fs.readFileSync(full, "utf8"))) { console.log(`DIFFERENT ${rel}`); problems++; }
}
for (const rel of extracted.keys()) if (!sources.has(rel)) { console.log(`EXTRA     ${rel}`); problems++; }

// Part 2: the guide, headings moved back up two levels outside code blocks
const part2 = text.split("\n## Part 2: The framework guide\n")[1].split("\n---\n\n## Part 3: The files")[0];
const guideBody = part2.replace(/^\n[^\n]*\n\n/, "");
let inFence = false;
const guide = guideBody.split("\n").map((line) => {
	if (/^\s*(```|~~~)/.test(line)) inFence = !inFence;
	return !inFence && /^#{3,8} /.test(line) ? line.slice(2) : line;
}).join("\n").trim();
const realGuide = normalize(fs.readFileSync(path.join(pluginRoot, "template", "FRAMEWORK_GUIDE.md"), "utf8")).trim();
if (guide !== realGuide) { console.log("DIFFERENT FRAMEWORK_GUIDE.md (Part 2)"); problems++; }

console.log(problems ? `standalone test: ${problems} problem(s)` : `standalone test: ok (${extracted.size} files and the guide match their sources)`);
process.exit(problems ? 1 : 0);
