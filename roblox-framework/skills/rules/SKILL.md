---
name: rules
description: The Roblox Luau framework's coding rules (Services/Controllers, strict types, the house style, DataService, Network). Use for ANY Roblox or Luau code work in a project that has a framework.config.json or FRAMEWORK_GUIDE.md at its root - writing, editing, reviewing or planning a service, controller, shared module, UI, remote, player data or test - before writing a line of code.
---

# Working in a roblox-framework project

The project's `FRAMEWORK_GUIDE.md` is the full rulebook. Read it before writing code; the sections you need most are 3 (style), 4 (types), 5 (where code goes), 6 (remotes), 7 (player data) and 11 (the checklist). Its section 10 holds the lead scripter's dated decisions, and those override anything here. If the project has no guide, the rulebook is [FRAMEWORK_GUIDE.md](${CLAUDE_PLUGIN_ROOT}/template/FRAMEWORK_GUIDE.md).

## Non-negotiable

- `--!strict` is line 1, then a header comment.
- Server code goes in `Services/`, client code in `Controllers/`, code both sides read in `SharedModules/`. Never a new Script or LocalScript.
- A sub-system is a child module of its parent system. Interface code is a `Ui` child of its controller.
- Copy the shape of the existing files, never invent one. For a new system start from `ExampleService` / `ExampleController`; for data look at `DataService` / `DataController`.
- Type every parameter and return. Use `any` only for network input and untyped requires.
- The loader hook names (`Initialize`, `Start`, `On...`) are reserved. Nothing waits at the top of a module.
- Every remote is in `Network.luau`, and the server checks every client argument.
- Player data is written only through `DataService` setters; the client reads it and watches it through `DataController`.
- A module with rules or decisions gets a spec in `src/ServerStorage/Tests/`.
- Existing code outside the framework folders stays where it is and keeps its own style.

## When something is unclear

Ask the user rather than guess when the guide doesn't settle it: which system a feature belongs to, whether something is big enough for its own service, or a change to a saved data key. Suggest recording the answer in the guide's section 10.

## Before you say it is done

1. Run the checker and fix every finding: `node tools/check-luau.mjs` from the project root (or `node "${CLAUDE_PLUGIN_ROOT}/scripts/check-luau.mjs"`). With the plugin it also runs after each edit and reports back to you. Only silence a finding that is truly an exception: `-- check:ignore <rule>` with the reason on the line above.
2. The checker can't judge everything. Check the rest yourself against section 11: comments say *why*, every constant has its unit, the sub-system is under the right parent, and connections and per-player state are cleaned up.
3. Tests run in Studio: `require(game.ServerStorage.Tests.TestRunner:Clone()):Run()`. If you can't run them, or can't read Script Analysis or play-test, say so plainly.
