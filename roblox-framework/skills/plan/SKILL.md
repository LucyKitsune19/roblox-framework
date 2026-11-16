---
name: plan
description: Plan a feature or system in a roblox-framework project before any code is written - where each piece goes, the remotes, the player data keys, the config, the flow and the tests - and save the plan for new-system to build from.
argument-hint: "<SystemName>: <what it should do>"
disable-model-invocation: true
---

# Plan a system

Request: `$ARGUMENTS`

This command writes **no code**. It ends with a plan the user approves, saved where `/roblox-framework:new-system` will find it.

1. Load the rules: read `FRAMEWORK_GUIDE.md` in the project, all of it, the first time this session. Section 10 holds the project's own decisions.
2. Look at what exists:
   - the systems in `src/ServerScriptService/Services/` and `src/ReplicatedStorage/Controllers/`
   - `SharedModules/Network.luau`, `DataTemplate.luau` and `SessionTemplate.luau`
   - any plan already in `plans/`
   
   Read only what this feature touches.
3. Decide each piece the way the guide does:
   - **Kind:** "What is this a kind of?" If it's a kind of an existing system, it's a child module of that system, not a new one.
   - **Sides:** server, client or both. Plan only the halves that have work to do.
   - **Interface:** any UI is a `Ui` child of the controller, and its template is an `.rbxm`.
   - **Code both sides read:** a shared module or a config.
4. If something the plan depends on isn't clear from the request and the code, ask the user. Ask all of it at once, then wait for the answers. Typical gaps:
   - numbers: costs, cooldowns, limits
   - saved or session-only
   - who can trigger it
   - what happens on leave or rejoin
5. Write the plan to `plans/<SystemName>.md`, using the shape below. Show the user the same plan, and ask whether to build it as written or change it.
6. When the user wants changes, update the file and show it again. When they approve it, set its `Status` to `Approved` and tell them to run `/roblox-framework:new-system <SystemName>`.

## Plan shape

```markdown
# <SystemName> plan

Status: Draft
Date: <YYYY-MM-DD>

## What it does
<two or three sentences, in the player's terms>

## Pieces
| File | Kind | Does |
|---|---|---|
| src/ServerScriptService/Services/<Name>Service.luau | service | ... |
| src/ReplicatedStorage/Controllers/<Name>Controller/init.luau | controller | ... |
| src/ReplicatedStorage/Controllers/<Name>Controller/Ui.luau | Ui | ... |
| (existing) <path> | changed | what changes, and why it belongs there |

## Remotes (SharedModules/Network.luau)
| Name | Direction | Sends | Server checks |
|---|---|---|---|

## Player data
| Key | Template | Type | Default | Written by |
|---|---|---|---|---|
(DataTemplate keys are saved. SessionTemplate keys last for the visit only.)

## Config
| Value | Where | Default |
|---|---|---|

## Flow
1. <step by step: what the player does, what each side does, what saves>

## Tests (src/ServerStorage/Tests/)
| Spec | Checks |
|---|---|

## Edge cases
- <leaving mid-action, spamming the remote, data not loaded yet, two players at once...>

## Not in this plan
- <what was left out on purpose>

## Open questions
- <none, or what still needs an answer>
```

Leave out a section that has nothing in it, except Pieces, Flow and Tests. If no test is needed, write "none" in Tests and say why.
