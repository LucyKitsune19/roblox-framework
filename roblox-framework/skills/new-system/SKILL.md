---
name: new-system
description: Add a new system (a service, a controller, or both, optionally with a Ui child and children) to a roblox-framework project, following its rules. Use when the user asks to add a feature or system to a project that has a framework.config.json.
argument-hint: "<SystemName> [what it does]"
---

# Add a system

Request: `$ARGUMENTS`

1. Load the rules: read `FRAMEWORK_GUIDE.md` sections 3 to 7 and 11 in the project.
   If `plans/<SystemName>.md` exists, read it. If its status is `Approved`, build exactly what it says: its pieces, remotes, data keys, config and tests. If its status is `Draft`, ask the user whether to approve it first. Skip step 2 for anything the plan already decides. When building, mark the plan `Built` and note anything you had to change from it.
2. Decide where it goes, and say it in one or two lines before writing:
   - "What is this a kind of?" If it's a kind of an existing system, it's a **child module** of that system (on each side it has code for), not a new system.
   - Server only, client only, or both? Make only the halves that have something to do now; never an empty shell.
   - An interface? It's a `Ui` child of the controller.
   - Does it talk across the network? Name each remote in `SharedModules/Network.luau`. Does it keep player data? Add keys to `DataTemplate` (or `SessionTemplate`) and write through `DataService`.
   If one of these isn't clear from the request and the code, ask the user before writing.
3. Copy the shape of `ExampleService` / `ExampleController` (and its `Ui`), not a new one: banners, header, `_Dependencies` for anything a test needs to swap, connections kept, per-player state cleared in `OnPlayerRemoving`, client input checked on the server. Name the module tables `<Name>Service` and `<Name>Controller`.
4. Write a spec in `src/ServerStorage/Tests/<Name>Service.spec.luau` (or the controller's) for every rule or decision. Pure wiring or visuals may skip it; say so.
5. Run `node tools/check-luau.mjs` and fix every finding.
6. Report: the files added, where each piece went and why, the remotes and data keys added, and what you couldn't verify (Studio tests, Script Analysis, a play-test).
