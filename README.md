# Roblox starter pack (Claude Code plugin)

A Roblox Luau framework that an agent can pick up in any project and follow strictly. One install gives you:

| Part | What it does |
|---|---|
| `/roblox-framework:new-game` | sets up the framework in a folder: loaders, Services/Controllers, DataService/DataController (ProfileStore + Replica), Network, unit tests, Rojo project, the guide, CLAUDE.md and AGENTS.md |
| `/roblox-framework:plan <Name>: <what it does>` | plans a system before any code: pieces, remotes, data keys, config, flow and tests. It asks what's unclear, then saves `plans/<Name>.md` for you to approve |
| `/roblox-framework:new-system <Name>` | adds a system the framework's way (service, controller, Ui, children, remotes, data, tests) |
| `/roblox-framework:check` | runs the style checker and fixes what it finds |
| the `rules` skill | loads on its own for any Luau work in a framework project |
| the hook | runs the checker after **every** Luau edit and hands any finding back to the agent to fix |

The hook only acts in projects with a `framework.config.json`, so leaving the plugin on everywhere is harmless.

## Install

You need [Node.js](https://nodejs.org) (the checker and setup script run on it).

**Terminal:**

```bash
claude plugin marketplace add LucyKitsune19/roblox-framework
```

```bash
claude plugin install roblox-framework@roblox-starter
```

**Desktop app (Code tab):** click **+** next to the prompt box → **Plugins** → **Add plugins**, add the marketplace `LucyKitsune19/roblox-framework`, then install **roblox-framework**.

Then, in a session opened on your game's folder: `/roblox-framework:new-game`.

**Updates** arrive when your marketplace refreshes. To get one right away, run `claude plugin marketplace update roblox-starter`.

## Working on the plugin itself

Clone this repository, then add your local copy as the marketplace instead (`claude plugin marketplace add "C:/path/to/roblox-framework"`). Edits take effect at the next session start or `/reload-plugins`. Bump `version` in `roblox-framework/.claude-plugin/plugin.json` when you release, then push.

## Without the plugin: one file

[`ROBLOX_FRAMEWORK.md`](ROBLOX_FRAMEWORK.md) is the whole starter pack in a single Markdown file: the rules, the full guide, and every framework file (the checker included), with instructions at the top telling an agent how to set it up and work in it. Hand it to any agent (Claude without the plugin, Cursor, Codex, ChatGPT…) and say "read this, then…".

It's generated, so never edit it by hand. After changing the template, the rules or the checker, rebuild it and run its test:

```bash
node roblox-framework/scripts/build-standalone.mjs
```

```bash
node roblox-framework/scripts/test-standalone.mjs
```

## Other agents (Cursor, Codex…)

They don't load Claude plugins, but `new-game` also writes `AGENTS.md` and copies the checker to `tools/check-luau.mjs`, so the rules and `node tools/check-luau.mjs` work in any tool, and in CI.

## Changing the rules

| To change | Edit |
|---|---|
| The style and rules | `roblox-framework/template/FRAMEWORK_GUIDE.md` and `roblox-framework/project-files/RULES.md` |
| The starting code | `roblox-framework/template/src/` |
| What the checker enforces | `roblox-framework/scripts/check-luau.mjs`, then run `node roblox-framework/scripts/test-checker.mjs` |
| Any of the above | then rebuild `ROBLOX_FRAMEWORK.md` (see above) |

Projects that are already set up keep their own copy (the guide, `tools/check-luau.mjs`), so a rule change reaches them only when you copy it in. Rules decided for one game go in that game's guide, section 10.
