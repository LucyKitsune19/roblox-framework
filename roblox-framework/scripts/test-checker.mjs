#!/usr/bin/env node
// Regression test for check-luau.mjs: Bad.luau must give exactly these findings, Good.luau none, and the framework
// template none. Run after changing the checker:  node scripts/test-checker.mjs

import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const checker = path.join(here, "check-luau.mjs");

const EXPECTED = [
	"src/Bad.luau:1 strict", "src/Bad.luau:2 header", "src/Bad.luau:2 use-const", "src/Bad.luau:5 no-top-level-yield",
	"src/Bad.luau:7 banners", "src/Bad.luau:8 pascal-case", "src/Bad.luau:10 banners", "src/Bad.luau:13 function-comment",
	"src/Bad.luau:13 typed-params", "src/Bad.luau:13 typed-returns", "src/Bad.luau:18 typed-returns", "src/Bad.luau:27 no-pairs",
	"src/Bad.luau:27 pascal-case", "src/Bad.luau:30 no-pairs", "src/Bad.luau:37 no-self", "src/Bad.luau:38 no-self",
	"src/Bad.luau:42 reserved-hooks", "src/Bad.luau:47 reserved-hooks", "src/Bad.luau:53 remotes-in-network",
	"src/Bad.luau:57 typed-params", "src/Extra.server.luau:1 no-new-scripts",
	// Broken.luau: the three syntax mistakes, plus two knock-on findings of the missing end
	"src/Broken.luau:5 use-const", "src/Broken.luau:6 syntax", "src/Broken.luau:10 typed-returns",
	"src/Broken.luau:12 syntax", "src/Broken.luau:16 syntax",
];

// the findings the checker prints for a folder, as "file:line rule"
function findings(cwd) {
	let out = "";
	try {
		out = execFileSync(process.execPath, [checker], { cwd, encoding: "utf8" });
	} catch (error) {
		out = error.stdout || "";
	}
	return out.split("\n").map((l) => l.match(/^(\S+:\d+) \[([\w-]+)\]/)).filter(Boolean).map((m) => `${m[1]} ${m[2]}`);
}

let failed = 0;

const got = findings(path.join(here, "fixtures"));
for (const want of EXPECTED) if (!got.includes(want)) { console.log(`MISSING  ${want}`); failed++; }
for (const have of got) if (!EXPECTED.includes(have)) { console.log(`EXTRA    ${have}`); failed++; }

const template = findings(path.join(here, "..", "template"));
for (const have of template) { console.log(`TEMPLATE ${have}`); failed++; }

console.log(failed ? `checker test: ${failed} problem(s)` : `checker test: ok (${EXPECTED.length} expected findings, Good.luau and template clean)`);
process.exit(failed ? 1 : 0);
