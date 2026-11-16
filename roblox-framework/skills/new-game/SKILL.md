---
name: new-game
description: Set up the Roblox framework (loaders, DataService/DataController, Network, tests, style checker, agent rules) in a project folder. Run when the user asks to start a new Roblox game or add the framework to a project.
argument-hint: "[project folder, default: current folder]"
disable-model-invocation: true
---

# Set up the framework

Target folder: `$ARGUMENTS` (the current working folder when empty).

1. Run the setup script. It never overwrites a file that already exists:
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.mjs" "<target folder>"`
   Show the user its summary. If it skipped files that came from an older framework or another project, list them and ask whether to keep them; never replace them on your own.
2. Run `node tools/check-luau.mjs` in the target folder. It must report every file clean.
3. Ask the user, in one question, for the values in the "Fill in per game" table at the top of `FRAMEWORK_GUIDE.md`: the game name and the lead scripter (sync tool, network layer and test runner default to the included ones). Write the answers into the table.
4. Tell the user what the place needs and the code can't create:
   - ProfileStore, ReplicaClient and ReplicaShared in `ReplicatedStorage/SharedPackages`, and ReplicaServer in `ServerScriptService/ServerPackages`, with the ReplicaShared path change described in the guide's section 2.
   - A Rojo sync (`rojo serve` with `default.project.json`), or another way to get `src/` into Studio.
   - The Example files are there to copy from. Delete them once the game has a real system.
5. Finish with: where the framework is, what was skipped, and the next step (usually `/roblox-framework:new-system <Name>`).
