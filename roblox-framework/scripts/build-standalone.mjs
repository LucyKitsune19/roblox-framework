#!/usr/bin/env node
// Builds the standalone starter pack: one Markdown file holding the rules, the full guide and every framework file,
// so an agent with no plugin can set the framework up and follow it from that file alone.
//   node build-standalone.mjs [output file]    (default: StarterPack/ROBLOX_FRAMEWORK.md)
// Rebuild after any change to template/, project-files/RULES.md or check-luau.mjs.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.join(here, "..");
const template = path.join(pluginRoot, "template");
const output = path.resolve(process.argv[2] || path.join(pluginRoot, "..", "ROBLOX_FRAMEWORK.md"));
const plugin = JSON.parse(fs.readFileSync(path.join(pluginRoot, ".claude-plugin", "plugin.json"), "utf8"));

// every file under dir, relative, with forward slashes, sorted so the output is stable
function walk(dir, base = dir) {
	return fs.readdirSync(dir, { withFileTypes: true })
		.flatMap((entry) => {
			const full = path.join(dir, entry.name);
			return entry.isDirectory() ? walk(full, base) : [path.relative(base, full).replace(/\\/g, "/")];
		})
		.sort();
}

// pushes every Markdown heading down by Levels, leaving code blocks alone
function demote(markdown, levels) {
	let inFence = false;
	return markdown.split("\n").map((line) => {
		if (/^\s*(```|~~~)/.test(line)) inFence = !inFence;
		return !inFence && /^#{1,6} /.test(line) ? "#".repeat(levels) + line : line;
	}).join("\n");
}

const LANG = { ".luau": "lua", ".lua": "lua", ".json": "json", ".mjs": "js", ".md": "markdown" };

// the files the standalone sets up: the template, plus the checker under tools/
const files = walk(template)
	.filter((rel) => rel !== "FRAMEWORK_GUIDE.md")
	.map((rel) => ({ rel, text: fs.readFileSync(path.join(template, rel), "utf8") }));
files.push({ rel: "tools/check-luau.mjs", text: fs.readFileSync(path.join(here, "check-luau.mjs"), "utf8") });

const rules = fs.readFileSync(path.join(pluginRoot, "project-files", "RULES.md"), "utf8").trim();
const guide = fs.readFileSync(path.join(template, "FRAMEWORK_GUIDE.md"), "utf8").trim();

const out = [];
out.push(`# Roblox Framework: standalone starter pack (v${plugin.version})`);
out.push("");
out.push("One file holding a whole Roblox Luau framework and the rules for writing code in it. An agent with nothing but this file can set the framework up and follow it. Generated from the roblox-framework plugin; don't edit it by hand: rebuild it with `node scripts/build-standalone.mjs`.");
out.push("");
out.push("## How to use this file (for agents)");
out.push("");
out.push("- **Writing code in a project that already has the framework** (there is a `FRAMEWORK_GUIDE.md` or `framework.config.json` at its root): follow Part 1 always, and the project's own `FRAMEWORK_GUIDE.md` over Part 2 where they differ, since the project may have newer decisions in its section 10.");
out.push(`- **Setting the framework up in a project**: create every file in Part 3 at the path in its heading, with exactly the content of its code block (keep the tabs; the content starts on the line after the opening fence and ends before the closing fence). Never overwrite a file that already exists: list those for the user and ask. Write Part 2 to \`FRAMEWORK_GUIDE.md\`, and Part 1 to \`CLAUDE.md\` and \`AGENTS.md\` (append it if the file exists). Then run \`node tools/check-luau.mjs\`: it must report every file clean. Then ask the user for the values in the guide's "Fill in per game" table.`);
out.push("- **Before calling any work done**: run `node tools/check-luau.mjs` (needs Node.js) and fix every finding, then go through the guide's checklist (section 11).");
out.push("- **The place also needs packages** this file can't contain: ProfileStore, ReplicaClient and ReplicaShared in `ReplicatedStorage/SharedPackages`, and ReplicaServer in `ServerScriptService/ServerPackages` (see Part 2, section 2).");
out.push("");
out.push("## Contents");
out.push("");
out.push("1. [Part 1: The rules](#part-1-the-rules)");
out.push("2. [Part 2: The framework guide](#part-2-the-framework-guide)");
out.push("3. [Part 3: The files](#part-3-the-files)");
for (const file of files) out.push(`   - \`${file.rel}\``);
out.push("");
out.push("---");
out.push("");
out.push("## Part 1: The rules");
out.push("");
out.push(demote(rules, 2));
out.push("");
out.push("---");
out.push("");
out.push("## Part 2: The framework guide");
out.push("");
out.push("This is the content of `FRAMEWORK_GUIDE.md`, with its headings moved down two levels to fit inside this file. When you write it to `FRAMEWORK_GUIDE.md`, move them back up two levels (`### 1. The rules` becomes `## 1. The rules`).");
out.push("");
out.push(demote(guide, 2));
out.push("");
out.push("---");
out.push("");
out.push("## Part 3: The files");
out.push("");
out.push(`${files.length} files. Each heading is the path from the project root.`);
for (const file of files) {
	const fence = "````";
	const body = file.text.replace(/\r\n/g, "\n").replace(/\n$/, "");
	if (body.includes(fence)) throw new Error(`${file.rel} contains ${fence}: use a longer fence`);
	out.push("");
	out.push(`### \`${file.rel}\``);
	out.push("");
	out.push(`${fence}${LANG[path.extname(file.rel)] || ""}`);
	out.push(body);
	out.push(fence);
}
out.push("");

fs.writeFileSync(output, out.join("\n"));
console.log(`wrote ${output}: ${files.length} files, ${Math.round(fs.statSync(output).size / 1024)} KB`);
