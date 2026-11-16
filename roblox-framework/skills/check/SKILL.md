---
name: check
description: Check a roblox-framework project, or given files, against the framework's style rules and fix what it finds. Use before calling Luau work done, or when the user asks to check, lint or review code style in a project that has a framework.config.json.
argument-hint: "[files or folders, default: the whole project]"
---

# Check against the framework rules

1. Run the checker from the project root: `node tools/check-luau.mjs $ARGUMENTS`
   (if the project has no `tools/check-luau.mjs`: `node "${CLAUDE_PLUGIN_ROOT}/scripts/check-luau.mjs" $ARGUMENTS`).
2. Fix every finding in the file it names, keeping that file's shape. The rule names mean:
   `strict`, `header`, `banners`, `function-comment`, `typed-params`, `typed-returns`, `pascal-case`, `use-const`, `no-pairs`, `no-self`, `reserved-hooks`, `no-top-level-yield`, `remotes-in-network`, `no-new-scripts`, `syntax` (a stray backslash, unbalanced blocks or brackets: fix these first, they cause knock-on findings).
   A clean result means the rules hold, not that the code compiles: say so if you couldn't check in Studio.
   Silence a finding only when the rule truly doesn't apply, with `-- check:ignore <rule>` and the reason on the line above. Never silence one just to make it pass.
3. Run it again until it reports clean.
4. Go through `FRAMEWORK_GUIDE.md` section 11 for what the checker can't judge, and report what you fixed and anything you left with a reason.
