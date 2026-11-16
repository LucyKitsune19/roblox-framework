#!/usr/bin/env node
// Sets up the framework in a project folder:  node scaffold.mjs <project folder>
// Copies template/ in without ever overwriting a file that exists, copies the checker to tools/, and adds the
// framework rules to CLAUDE.md and AGENTS.md (appended between markers when those files already exist).
// Prints what it created, what it skipped, and what it appended.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.join(here, "..");
const template = path.join(pluginRoot, "template");
const rulesFile = path.join(pluginRoot, "project-files", "RULES.md");
const START = "<!-- roblox-framework:start -->";
const END = "<!-- roblox-framework:end -->";

const target = path.resolve(process.argv[2] || process.cwd());
const created = [];
const skipped = [];
const appended = [];

// every file under dir, as paths relative to it
function walk(dir, base = dir) {
	return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
		const full = path.join(dir, entry.name);
		return entry.isDirectory() ? walk(full, base) : [path.relative(base, full)];
	});
}

// copies one file unless the destination exists
function copyNew(from, to, label) {
	if (fs.existsSync(to)) {
		skipped.push(label);
		return;
	}
	fs.mkdirSync(path.dirname(to), { recursive: true });
	fs.copyFileSync(from, to);
	created.push(label);
}

// writes the rules block into an agent instructions file: new file, appended block, or left alone if present
function writeRules(name) {
	const file = path.join(target, name);
	const block = `${START}\n${fs.readFileSync(rulesFile, "utf8").trim()}\n${END}\n`;
	if (!fs.existsSync(file)) {
		fs.writeFileSync(file, block);
		created.push(name);
	} else if (fs.readFileSync(file, "utf8").includes(START)) {
		skipped.push(`${name} (already has the framework rules)`);
	} else {
		fs.appendFileSync(file, `\n${block}`);
		appended.push(name);
	}
}

fs.mkdirSync(target, { recursive: true });

for (const rel of walk(template)) copyNew(path.join(template, rel), path.join(target, rel), rel.replace(/\\/g, "/"));
copyNew(path.join(here, "check-luau.mjs"), path.join(target, "tools", "check-luau.mjs"), "tools/check-luau.mjs");
writeRules("CLAUDE.md");
writeRules("AGENTS.md");

console.log(`Framework set up in ${target}`);
console.log(`created  (${created.length}): ${created.join(", ") || "-"}`);
if (appended.length) console.log(`appended rules to: ${appended.join(", ")}`);
if (skipped.length) console.log(`skipped, already there (${skipped.length}): ${skipped.join(", ")}`);
