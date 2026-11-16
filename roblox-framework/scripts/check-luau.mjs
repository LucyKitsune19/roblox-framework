#!/usr/bin/env node
// Style checker for the Roblox framework. Checks the rules a machine can check (FRAMEWORK_GUIDE.md section 11).
//
//   node check-luau.mjs [file or folder ...]   check those (default: the project's whole "check" scope)
//   node check-luau.mjs --hook                 Claude Code PostToolUse hook: reads the edit from stdin
//
// A project opts in with framework.config.json at its root; files outside its "check" folders are left alone, so
// legacy code keeps its own style. Silence one finding with "-- check:ignore <rule>" on the line or the line above,
// or a whole file with "-- check:ignore-file <rule>". Exit: 0 clean, 1 findings (CLI), 2 findings (hook: Claude sees them).

import fs from "node:fs";
import path from "node:path";

const HOOKS = new Set(["Initialize", "Start", "OnPlayerAdded", "OnPlayerRemoving", "OnCharacterAdded", "OnCharacterRemoving"]);
const BANNERS = ["SERVICES", "CONTAINERS", "MODULES", "TYPES", "VARIABLES", "MODULE", "METHODS"];
const BANNER_ALIASES = { CONTROLLER: "MODULE" };
const ALLOWED_SCRIPTS = new Set(["ServerLoader.server.luau", "ClientLoader.client.luau"]);
const KEYWORDS = new Set(["and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local",
	"nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue", "const", "export", "type", "typeof"]);

// ---------- project ----------

// the folder holding framework.config.json, walking up from start; null when there is none
function findRoot(start) {
	let dir = fs.existsSync(start) && fs.statSync(start).isDirectory() ? start : path.dirname(start);
	for (;;) {
		if (fs.existsSync(path.join(dir, "framework.config.json"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) return null;
		dir = parent;
	}
}

function loadConfig(root) {
	const raw = JSON.parse(fs.readFileSync(path.join(root, "framework.config.json"), "utf8"));
	return {
		check: (raw.check || ["src"]).map((p) => p.replace(/\\/g, "/").replace(/\/$/, "")),
		ignore: raw.ignore || ["SharedPackages", "ServerPackages", "Packages"],
	};
}

// true when the file is in a "check" folder and in no "ignore" folder
function inScope(root, config, file) {
	const rel = path.relative(root, file).replace(/\\/g, "/");
	if (rel.startsWith("..")) return false;
	const parts = rel.split("/");
	if (parts.some((p) => config.ignore.includes(p))) return false;
	return config.check.some((c) => rel === c || rel.startsWith(c + "/"));
}

function listLuau(target) {
	if (!fs.existsSync(target)) return [];
	if (fs.statSync(target).isFile()) return /\.(luau|lua)$/.test(target) ? [target] : [];
	return fs.readdirSync(target).flatMap((name) => listLuau(path.join(target, name)));
}

// ---------- lexing ----------

// the source with every comment and string blanked out (newlines kept, so positions stay valid)
function blank(src) {
	let out = "";
	let i = 0;
	const keep = (s) => s.replace(/[^\n]/g, " ");
	while (i < src.length) {
		const c = src[i];
		const rest = src.slice(i);
		let m;
		if ((m = rest.match(/^--\[(=*)\[/))) {
			const close = "]" + m[1] + "]";
			const end = src.indexOf(close, i + m[0].length);
			const stop = end === -1 ? src.length : end + close.length;
			out += keep(src.slice(i, stop));
			i = stop;
		} else if (rest.startsWith("--")) {
			const end = src.indexOf("\n", i);
			const stop = end === -1 ? src.length : end;
			out += keep(src.slice(i, stop));
			i = stop;
		} else if ((m = rest.match(/^\[(=*)\[/))) {
			const close = "]" + m[1] + "]";
			const end = src.indexOf(close, i + m[0].length);
			const stop = end === -1 ? src.length : end + close.length;
			out += '"' + keep(src.slice(i + 1, stop - 1)) + '"';
			i = stop;
		} else if (c === '"' || c === "'" || c === "`") {
			let j = i + 1;
			while (j < src.length && src[j] !== c && src[j] !== "\n") j += src[j] === "\\" ? 2 : 1;
			out += c + keep(src.slice(i + 1, j)) + c;
			i = j + 1;
		} else {
			out += c;
			i++;
		}
	}
	return out;
}

// tokens with their line numbers: names, numbers, strings (blanked) and punctuation
function tokenize(code) {
	const tokens = [];
	const re = /([A-Za-z_][A-Za-z0-9_]*)|(\d[\d_.xXa-fA-F]*)|("[ \n]*"|'[ \n]*'|`[ \n]*`)|(\.\.\.|\.\.=|\.\.|->|::|==|~=|<=|>=|\+=|-=|\*=|\/=|%=|\^=|\/\/)|(\S)/g;
	let line = 1;
	let last = 0;
	let m;
	while ((m = re.exec(code))) {
		for (let k = last; k < m.index; k++) if (code[k] === "\n") line++;
		last = m.index;
		tokens.push({ t: m[0], line, kind: m[1] ? "name" : m[3] ? "string" : "punct" });
	}
	return tokens;
}

// ---------- structure ----------

// every function (header, params, return annotation, body range) and the depth of every token.
// Depth counts function / do / repeat / statement-if blocks; Luau's if-expressions have no "end" and are skipped
function analyse(tokens, lines) {
	const functions = [];
	const stack = [];
	let depth = 0;
	for (let i = 0; i < tokens.length; i++) {
		const tok = tokens[i];
		tok.depth = depth;
		if (tok.kind !== "name") continue;
		const w = tok.t;
		if (w === "function") {
			const fn = parseHeader(tokens, i);
			fn.depth = depth;
			fn.line = tok.line;
			functions.push(fn);
			stack.push({ fn });
			depth++;
		} else if (w === "do" || w === "repeat") {
			stack.push({});
			depth++;
		} else if (w === "if" && isStatementIf(tokens, i)) {
			stack.push({});
			depth++;
		} else if (w === "end" || w === "until") {
			const top = stack.pop();
			if (!top) functions.extraEnds = (functions.extraEnds || []).concat(tok.line);
			depth = Math.max(0, depth - 1);
			tok.depth = depth;
			if (top && top.fn) top.fn.endIndex = i;
		}
	}
	functions.unclosed = stack.length;
	for (const fn of functions) {
		fn.returnsValue = false;
		const bodyDepth = fn.depth + 1;
		for (let i = fn.bodyStart; i < (fn.endIndex ?? tokens.length); i++) {
			const tok = tokens[i];
			if (tok.t === "return" && tok.depth === bodyDepth) {
				const next = tokens[i + 1];
				if (next && next.line === tok.line && !["end", ";", "else", "elseif", "until"].includes(next.t)) fn.returnsValue = true;
			}
		}
	}
	return functions;
}

// an "if" that opens a block: first on its line, or right after then / else / do / ; / end.
// an if-expression follows =, return, (, a comma or an operator and has no "end"
function isStatementIf(tokens, i) {
	const prev = tokens[i - 1];
	if (!prev || prev.line !== tokens[i].line) return true;
	return ["then", "else", "do", ";", "end"].includes(prev.t);
}

// name, params and return annotation of the function whose keyword is at index i
function parseHeader(tokens, i) {
	const fn = { name: null, isMethod: false, params: [], hasReturnType: false, bodyStart: i + 1, isLocal: false };
	let j = i + 1;
	if (tokens[i - 1] && tokens[i - 1].t === "local") fn.isLocal = true;
	// name: a, a.b, a:b
	if (tokens[j] && tokens[j].kind === "name") {
		fn.name = tokens[j].t;
		j++;
		while (tokens[j] && (tokens[j].t === "." || tokens[j].t === ":") && tokens[j + 1] && tokens[j + 1].kind === "name") {
			if (tokens[j].t === ":") fn.isMethod = true;
			fn.owner = fn.name;
			fn.name = tokens[j + 1].t;
			j += 2;
		}
	}
	// generics <T>
	if (tokens[j] && tokens[j].t === "<") {
		let d = 0;
		for (; j < tokens.length; j++) {
			if (tokens[j].t === "<") d++;
			if (tokens[j].t === ">") { d--; if (d === 0) { j++; break; } }
		}
	}
	if (!tokens[j] || tokens[j].t !== "(") return fn;
	// params, split on commas at nesting depth 1
	let d = 0;
	let current = [];
	for (; j < tokens.length; j++) {
		const t = tokens[j].t;
		if (t === "(" || t === "{" || t === "[" || t === "<") d++;
		if (t === ")" || t === "}" || t === "]" || t === ">") d--;
		if (d === 0) break;
		if (d === 1 && t === ",") { fn.params.push(current); current = []; continue; }
		if (!(d === 1 && t === "(" && current.length === 0 && fn.params.length === 0 && tokens[j - 1].t !== "(")) current.push(tokens[j]);
	}
	current = current.filter((x) => x.t !== "(");
	if (current.length) fn.params.push(current);
	fn.params = fn.params.map((p) => p.filter((x, k) => !(k === 0 && x.t === "(")));
	fn.closeIndex = j;
	fn.bodyStart = j + 1;
	const after = tokens[j + 1];
	if (after && after.t === ":") fn.hasReturnType = true;
	return fn;
}

// ---------- rules ----------

function check(file, src, relPath) {
	const findings = [];
	const lines = src.split(/\r?\n/);
	const code = blank(src);
	const codeLines = code.split(/\r?\n/);
	const tokens = tokenize(code);
	const base = path.basename(file);
	const isScript = /\.(server|client|legacy|local)\.luau$/.test(base);
	const isTest = /\.spec\.luau$/.test(base) || /(^|\/)Tests\//.test(relPath);
	const fileIgnores = new Set([...src.matchAll(/--\s*check:ignore-file\s+([\w-]+)/g)].map((m) => m[1]));

	function report(rule, line, message) {
		if (fileIgnores.has(rule)) return;
		const here = lines[line - 1] || "";
		const above = lines[line - 2] || "";
		const re = new RegExp(`--\\s*check:ignore\\s+${rule}\\b`);
		if (re.test(here) || re.test(above)) return;
		findings.push({ rule, line, message });
	}

	// strict
	if ((lines[0] || "").trim() !== "--!strict") report("strict", 1, "line 1 must be --!strict");

	// header comment
	const second = (lines[1] || "").trim();
	if (!second.startsWith("--") || /^--\s*\/\//.test(second)) report("header", 2, "line 2 must start the header comment: what this file is for");

	// extra scripts
	if (/\.(server|client|legacy|local)\.luau$/.test(base) && !ALLOWED_SCRIPTS.has(base))
		report("no-new-scripts", 1, "only ServerLoader and ClientLoader are scripts: make this a ModuleScript in Services or Controllers");

	// banners in order
	let lastBanner = -1;
	lines.forEach((text, k) => {
		const m = text.match(/^--\s*\/\/\s*([A-Z]+)\s*$/);
		if (!m) return;
		const name = BANNER_ALIASES[m[1]] || m[1];
		const index = BANNERS.indexOf(name);
		if (index === -1) report("banners", k + 1, `unknown banner "${m[1]}": use ${BANNERS.join(", ")} (CONTROLLER for MODULE in a controller)`);
		else if (index <= lastBanner) report("banners", k + 1, `banner ${m[1]} is out of order: ${BANNERS.join(" > ")}`);
		else lastBanner = index;
	});

	// pairs / ipairs, self
	codeLines.forEach((text, k) => {
		if (/\b(i?pairs)\s*\(/.test(text)) report("no-pairs", k + 1, "iterate with `for _, Value in Table do`, never pairs or ipairs");
		if (/\bself\s*[.\[]/.test(text) || /\bself\s*:\s*[A-Za-z_]\w*\s*\(/.test(text))
			report("no-self", k + 1, "call methods and read state on the module's name, never on self");
	});

	// remotes outside Network
	if (base !== "Network.luau") {
		lines.forEach((text, k) => {
			if (/^\s*--/.test(text)) return;
			if (/Instance\.new\(\s*["'`](Unreliable)?Remote(Event|Function)["'`]/.test(text))
				report("remotes-in-network", k + 1, "remotes are created only by SharedModules/Network.luau: add the name to its REMOTES");
		});
	}

	const functions = analyse(tokens, codeLines);

	// basic syntax: the checker is no compiler, but these mistakes would otherwise pass as "clean"
	codeLines.forEach((text, k) => {
		if (text.includes("\\")) report("syntax", k + 1, "a backslash outside a string is not valid Luau (a literal \\t or \\n left by an edit?)");
	});
	for (const line of functions.extraEnds || []) report("syntax", line, "this end/until closes nothing: a block above is missing its opener, or there is one end too many");
	if (functions.unclosed > 0) report("syntax", lines.length, `${functions.unclosed} block(s) never closed: a function, if, do or repeat is missing its end`);
	const pairsOf = { ")": "(", "}": "{", "]": "[" };
	const open = [];
	for (const tok of tokens) {
		if (tok.t === "(" || tok.t === "{" || tok.t === "[") open.push(tok);
		else if (pairsOf[tok.t]) {
			const top = open.pop();
			if (!top || top.t !== pairsOf[tok.t]) { report("syntax", tok.line, `"${tok.t}" does not match ${top ? `the "${top.t}" on line ${top.line}` : "any opening bracket"}`); break; }
		}
	}
	if (open.length) report("syntax", open[open.length - 1].line, `"${open[open.length - 1].t}" is never closed`);

	for (const fn of functions) {
		// comment above every named function
		if (fn.name) {
			const above = (lines[fn.line - 2] || "").trim();
			if (!above.startsWith("--") || /^--\s*\/\//.test(above))
				report("function-comment", fn.line, `function ${fn.name} needs a comment right above it: what it does and what it returns`);
		}
		// typed params
		for (const param of fn.params) {
			if (!param.length) continue;
			const name = param[0].t;
			const typed = param[1] && param[1].t === ":";
			if (!typed) report("typed-params", param[0].line, `parameter ${name} needs a type: ${name === "..." ? "...:Type" : name + ":Type"}`);
			if (name !== "..." && name !== "_" && !/^_?[A-Z]/.test(name))
				report("pascal-case", param[0].line, `parameter ${name} must be PascalCase`);
		}
		// return type
		if (fn.returnsValue && !fn.hasReturnType)
			report("typed-returns", fn.line, `function ${fn.name || "(anonymous)"} returns a value: declare it with ") : Type"`);
		// names
		if (fn.name && !/^_?[A-Z]/.test(fn.name)) report("pascal-case", fn.line, `function ${fn.name} must be PascalCase`);
		// reserved hooks
		if (!isTest && fn.isMethod && fn.depth === 0 && /^(Initialize|Start|On[A-Z]\w*)$/.test(fn.name) && !HOOKS.has(fn.name))
			report("reserved-hooks", fn.line, `${fn.name} is a loader hook name (Initialize, Start, On...): pick another name, e.g. Handle${fn.name.replace(/^On/, "")}`);
		// the loader calls Initialize and Start with no arguments
		if (!isTest && fn.isMethod && fn.depth === 0 && (fn.name === "Initialize" || fn.name === "Start") && fn.params.some((p) => p.length))
			report("reserved-hooks", fn.line, `the loader calls ${fn.name} with no arguments: this one takes some, so it is not the hook. Rename it (e.g. ${fn.name}Round)`);
	}

	// locals: PascalCase, and top-level never-reassigned ones as const
	const returned = (() => {
		for (let i = tokens.length - 1; i > 0; i--) if (tokens[i].t === "return" && tokens[i].depth === 0) return tokens[i + 1] && tokens[i + 1].t;
		return null;
	})();
	for (let i = 0; i < tokens.length; i++) {
		const tok = tokens[i];
		if ((tok.t === "local" || tok.t === "const") && tokens[i + 1] && tokens[i + 1].t !== "function") {
			let j = i + 1;
			const names = [];
			while (tokens[j] && tokens[j].kind === "name") {
				names.push(tokens[j]);
				j++;
				if (tokens[j] && tokens[j].t === ":") { // skip a type annotation up to , or =
					let d = 0;
					for (j++; j < tokens.length; j++) {
						const t = tokens[j].t;
						if (t === "(" || t === "{" || t === "[" || t === "<") d++;
						if (t === ")" || t === "}" || t === "]" || t === ">") d--;
						if (d === 0 && (t === "," || t === "=" || tokens[j].line !== tok.line)) break;
					}
				}
				if (tokens[j] && tokens[j].t === ",") j++; else break;
			}
			for (const n of names) {
				if (n.t !== "_" && !/^_?[A-Z]/.test(n.t)) report("pascal-case", n.line, `${n.t} must be PascalCase (UPPER_SNAKE for a constant)`);
			}
			if (tok.t === "local" && tok.depth === 0 && tokens[j] && tokens[j].t === "=") {
				for (const n of names) {
					if (n.t === returned) continue;
					const reassigned = tokens.some((x, k) => k !== tokens.indexOf(n) && x.t === n.t && tokens[k + 1]
						&& ["=", "+=", "-=", "*=", "/=", "..=", "%=", "^=", "//="].includes(tokens[k + 1].t)
						&& !["local", "const", ".", ":"].includes(tokens[k - 1] && tokens[k - 1].t)
						&& !(tokens[k - 1] && ["{", ","].includes(tokens[k - 1].t) && x.depth === 0 && tokens[k + 1].t === "="));
					if (!reassigned) report("use-const", n.line, `${n.t} is never reassigned: declare it with const`);
				}
			}
		}
		// loop variables
		if (tok.t === "for") {
			for (let j = i + 1; tokens[j] && tokens[j].t !== "in" && tokens[j].t !== "=" && tokens[j].t !== "do"; j++) {
				const n = tokens[j];
				if (n.kind === "name" && tokens[j - 1] && (tokens[j - 1].t === "for" || tokens[j - 1].t === ",") && n.t !== "_" && !/^_?[A-Z]/.test(n.t))
					report("pascal-case", n.line, `loop variable ${n.t} must be PascalCase`);
			}
		}
	}

	// no waiting at the top level of a module
	if (!isScript) {
		for (let i = 0; i < tokens.length; i++) {
			const tok = tokens[i];
			if (tok.depth !== 0) continue;
			const prev = tokens[i - 1] ? tokens[i - 1].t : "";
			const next = tokens[i + 1] ? tokens[i + 1].t : "";
			const isYield = tok.t === "WaitForChild"
				|| (tok.t === "Wait" && prev === ":")
				|| (tok.t === "wait" && next === "(");
			// depth 0 is outside every block, so outside every function body too
			if (isYield) report("no-top-level-yield", tok.line, "nothing may wait at the top of a module: fetch it inside a function, on first use");
		}
	}

	findings.sort((a, b) => a.line - b.line);
	return findings;
}

// ---------- entry ----------

function readStdin() {
	try { return fs.readFileSync(0, "utf8"); } catch { return ""; }
}

function run() {
	const args = process.argv.slice(2);
	const hook = args.includes("--hook");
	let targets = args.filter((a) => !a.startsWith("--"));

	if (hook) {
		let input = {};
		// a byte-order mark (PowerShell pipes add one) would make JSON.parse fail
		try { input = JSON.parse(readStdin().replace(/^﻿/, "") || "{}"); } catch { process.exit(0); }
		const ti = input.tool_input || {};
		const file = ti.file_path || ti.path || ti.notebook_path;
		if (!file || !/\.(luau|lua)$/.test(file)) process.exit(0);
		targets = [path.isAbsolute(file) ? file : path.join(input.cwd || process.cwd(), file)];
	}

	let files = [];
	if (!targets.length) {
		const root = findRoot(process.cwd());
		if (!root) { console.error("no framework.config.json found here or above"); process.exit(1); }
		const config = loadConfig(root);
		files = config.check.flatMap((c) => listLuau(path.join(root, c)));
	} else {
		files = targets.flatMap(listLuau);
	}

	const report = [];
	let count = 0;
	for (const file of files) {
		const root = findRoot(file);
		if (!root) continue;
		const config = loadConfig(root);
		if (!inScope(root, config, file)) continue;
		const rel = path.relative(root, file).replace(/\\/g, "/");
		// editors may save a byte-order mark, which would hide --!strict on line 1
		const findings = check(file, fs.readFileSync(file, "utf8").replace(/^﻿/, ""), rel);
		count += findings.length;
		for (const f of findings) report.push(`${rel}:${f.line} [${f.rule}] ${f.message}`);
	}

	if (!count) {
		if (!hook) console.log(`framework check: ${files.length} file(s) clean`);
		process.exit(0);
	}

	const text = report.join("\n");
	if (hook) {
		console.error(`Framework style check failed (${count}). Fix these before moving on; the rules are in FRAMEWORK_GUIDE.md. A finding that is truly an exception can be silenced with "-- check:ignore <rule>" and a reason.\n${text}`);
		process.exit(2);
	}
	console.log(text);
	console.log(`framework check: ${count} finding(s)`);
	process.exit(1);
}

run();
