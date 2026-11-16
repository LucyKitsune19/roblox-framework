# Roblox Framework: standalone starter pack (v1.0.0)

One file holding a whole Roblox Luau framework and the rules for writing code in it. An agent with nothing but this file can set the framework up and follow it. Generated from the roblox-framework plugin; don't edit it by hand: rebuild it with `node scripts/build-standalone.mjs`.

## How to use this file (for agents)

- **Writing code in a project that already has the framework** (there is a `FRAMEWORK_GUIDE.md` or `framework.config.json` at its root): follow Part 1 always, and the project's own `FRAMEWORK_GUIDE.md` over Part 2 where they differ, since the project may have newer decisions in its section 10.
- **Setting the framework up in a project**: create every file in Part 3 at the path in its heading, with exactly the content of its code block (keep the tabs; the content starts on the line after the opening fence and ends before the closing fence). Never overwrite a file that already exists: list those for the user and ask. Write Part 2 to `FRAMEWORK_GUIDE.md`, and Part 1 to `CLAUDE.md` and `AGENTS.md` (append it if the file exists). Then run `node tools/check-luau.mjs`: it must report every file clean. Then ask the user for the values in the guide's "Fill in per game" table.
- **Before calling any work done**: run `node tools/check-luau.mjs` (needs Node.js) and fix every finding, then go through the guide's checklist (section 11).
- **The place also needs packages** this file can't contain: ProfileStore, ReplicaClient and ReplicaShared in `ReplicatedStorage/SharedPackages`, and ReplicaServer in `ServerScriptService/ServerPackages` (see Part 2, section 2).

## Contents

1. [Part 1: The rules](#part-1-the-rules)
2. [Part 2: The framework guide](#part-2-the-framework-guide)
3. [Part 3: The files](#part-3-the-files)
   - `default.project.json`
   - `framework.config.json`
   - `src/ReplicatedStorage/Controllers/DataController.luau`
   - `src/ReplicatedStorage/Controllers/DataController.meta.json`
   - `src/ReplicatedStorage/Controllers/ExampleController/Ui.luau`
   - `src/ReplicatedStorage/Controllers/ExampleController/init.luau`
   - `src/ReplicatedStorage/SharedModules/DataConfig.luau`
   - `src/ReplicatedStorage/SharedModules/DataPath.luau`
   - `src/ReplicatedStorage/SharedModules/DataTemplate.luau`
   - `src/ReplicatedStorage/SharedModules/ExampleConfig.luau`
   - `src/ReplicatedStorage/SharedModules/Loader.luau`
   - `src/ReplicatedStorage/SharedModules/Network.luau`
   - `src/ReplicatedStorage/SharedModules/SessionTemplate.luau`
   - `src/ServerScriptService/ServerLoader.server.luau`
   - `src/ServerScriptService/Services/DataService.luau`
   - `src/ServerScriptService/Services/ExampleService/ExampleChild.luau`
   - `src/ServerScriptService/Services/ExampleService/init.luau`
   - `src/ServerStorage/Tests/DataController.spec.luau`
   - `src/ServerStorage/Tests/DataPath.spec.luau`
   - `src/ServerStorage/Tests/DataService.spec.luau`
   - `src/ServerStorage/Tests/TestRunner.luau`
   - `src/StarterPlayer/StarterPlayerScripts/ClientLoader.client.luau`
   - `tools/check-luau.mjs`

---

## Part 1: The rules

### Roblox framework rules

This project uses the roblox-framework starter pack. These rules are not optional, and only the lead scripter named in `FRAMEWORK_GUIDE.md` can change them.

**Before writing any code, read `FRAMEWORK_GUIDE.md`.** It has the full style, every rule with an example, and the project's dated decisions (section 10).

#### Hard rules

1. `--!strict` on line 1 of every Luau file, then a header comment saying what the file is for.
2. Server code goes in `src/ServerScriptService/Services/`, client code in `src/ReplicatedStorage/Controllers/`, and code both sides read in `src/ReplicatedStorage/SharedModules/`. Never add a Script or LocalScript: `ServerLoader` and `ClientLoader` are the only two.
3. A big system gets a service *and* a controller with the same name. A sub-system is a child module of its parent system. Interface code is a `Ui` child of its controller.
4. Write in the style of the existing files: the banners in order, `PascalCase`, `UPPER_SNAKE` constants, `_Private`, `const` for anything never reassigned, `for _, X in T do` (never `pairs`/`ipairs`), the module's name instead of `self`, and a comment above every function.
5. Type every parameter and every return value. Use `any` only for network input and for requiring untyped modules.
6. `Initialize`, `Start`, `OnPlayerAdded`, `OnPlayerRemoving`, `OnCharacterAdded` and `OnCharacterRemoving` are loader hooks. Never use these names for anything else.
7. Nothing may wait at the top of a module, and a module must work straight after `require`.
8. Every remote is named in `SharedModules/Network.luau`. Check everything a client sends.
9. Write player data only through `DataService`'s setters. The client only reads it and watches it, through `DataController`.
10. A module with rules or decisions gets a test in `src/ServerStorage/Tests/`.
11. Leave existing code outside these folders where it is, in its own style, unless the lead scripter names it.

#### Before calling work done

- Run `node tools/check-luau.mjs` and fix every finding. With the plugin installed it also runs after every edit. Clean means the rules hold, not that the file compiles. Silence a finding only when it is truly an exception, with `-- check:ignore <rule>` and the reason on the line above.
- Run the unit tests in Studio from the command bar: `require(game.ServerStorage.Tests.TestRunner:Clone()):Run()`.
- Go through the checklist in `FRAMEWORK_GUIDE.md` section 11.
- Report what you could not verify (Script Analysis, a play-test) instead of claiming it.

---

## Part 2: The framework guide

This is the content of `FRAMEWORK_GUIDE.md`, with its headings moved down two levels to fit inside this file. When you write it to `FRAMEWORK_GUIDE.md`, move them back up two levels (`### 1. The rules` becomes `## 1. The rules`).

### Framework guide: how code is written and where it goes

A Roblox (Luau) framework for any game: two loader scripts, one ModuleScript per system, strict types, one style. Drop it into a new project, fill in the box below, and hand this file to anyone (person or agent) who writes code in it. Read it before writing any code.

| Fill in per game | |
|---|---|
| Game | `<name>` |
| Lead scripter (owns these rules, settles every question) | `<name>` |
| Sync tool | Rojo (`default.project.json` is included) or `<other>` |
| Network layer | the included `Network` module, or `<packet library>` (section 6) |
| Unit test runner | the included `ServerStorage/Tests/TestRunner` (section 8), or `<other>` |
| Data store name | `STORE_NAME` in `DataService.luau` (section 7) |
| Style checker | `node tools/check-luau.mjs` (section 8). With the roblox-framework plugin it runs after every edit |

If this file and the lead scripter disagree, the lead scripter wins. Decisions they make go in section 10 with a date.

#### 1. The rules

1. **Write in the style of section 3.** Copy the shape of the example files; don't invent a new one.
2. **Strict typing, always.** `--!strict` is the first line of every file.
3. **All client code goes in Controllers:** `ReplicatedStorage/Controllers/`.
4. **All server code goes in Services:** `ServerScriptService/Services/`.
5. **Code both sides read goes in SharedModules:** `ReplicatedStorage/SharedModules/`.
6. **A big or important system gets a service and a controller with the same name.** A sub-system is a child module of the system it belongs to, never a system of its own.
7. **Two scripts only.** `ServerLoader` and `ClientLoader` are the only Scripts. Everything else is a ModuleScript they load.
8. **Every remote is defined in one shared file.** No `RemoteEvent` is created anywhere else.

#### 2. What's in the box

```
default.project.json                      Rojo project (maps src/ into the place)
src/
  ServerScriptService/
    ServerLoader.server.luau              the only server Script
    Services/
      DataService.luau                    every player's saved and session data (section 7)
      ExampleService/
        init.luau                         a service with children, loaded lazily by name
        ExampleChild.luau                 one child (server half)
  StarterPlayer/StarterPlayerScripts/
    ClientLoader.client.luau              the only client script
  ReplicatedStorage/
    Controllers/
      DataController.luau                 the local player's data, read-only, with change watchers
      DataController.meta.json            LoadOrder = 1, DoesYield = true
      ExampleController/
        init.luau                         the matching controller
        Ui.luau                           its interface, a Ui child
    SharedModules/
      Loader.luau                         what both loaders use to require, sort and call modules
      Network.luau                        every remote, defined once
      DataTemplate.luau                   the saved data's shape and starting values
      SessionTemplate.luau                the session data's shape and starting values
      DataConfig.luau                     the replica names both sides use
      DataPath.luau                       reading and comparing paths into data
      ExampleConfig.luau                  what the Example pair must agree on
  ServerStorage/
    Tests/
      TestRunner.luau                     runs every *.spec module in the folder
      DataPath.spec.luau, DataService.spec.luau, DataController.spec.luau
```

Third-party packages are not in `src/`; they live in the place (or come from Wally), and the Rojo project keeps them (`$ignoreUnknownInstances`):

| Package | Where |
|---|---|
| ProfileStore | `ReplicatedStorage/SharedPackages/ProfileStore` (server-only: `ServerScriptService/ServerPackages` is also fine) |
| ReplicaClient, ReplicaShared | `ReplicatedStorage/SharedPackages/` |
| ReplicaServer | `ServerScriptService/ServerPackages/ReplicaServer` |

Replica's modules look for `ReplicatedStorage.ReplicaShared` by default. With ReplicaShared inside SharedPackages, the line that finds it is changed in each: ReplicaClient reads `script.Parent.ReplicaShared`, ReplicaServer reads `game.ReplicatedStorage.SharedPackages.ReplicaShared`. Redo that after updating Replica.

To start a system: copy `ExampleService` / `ExampleController`, rename the folders, the module tables and the children, add its remotes to `Network`, and delete what it doesn't use. Delete the Example files once the game has a real system to copy from.

The Ui example needs a `ScreenGui` named `ExampleUi` in `ReplicatedStorage/UiTemplates`, holding a `TextButton` named `RunButton` and a `TextLabel` named `Status`. Without it, it warns and does nothing.

#### 3. The style

A complete file in the style:

```lua
--!strict
-- what this module is for, in a few plain lines: what it owns, who calls it, and anything a reader
-- would otherwise have to work out from the code

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // CONTAINERS
const SharedModules = ReplicatedStorage.SharedModules

-- // MODULES
const Network = require(SharedModules.Network)

-- // TYPES
export type Entry = {
	Name:string,
	Weight:number,
}

-- // VARIABLES
const MAX_ENTRIES = 16 -- entries the list holds at most

-- // MODULE
local Example = {
	_Entries = {} :: {Entry},
}

-- the entry with that name, nil if there is none
local function FindEntry(Name:string) : Entry?
	for _, Entry in Example._Entries do
		if Entry.Name == Name then
			return Entry
		end
	end

	return nil
end

-- // METHODS
-- adds an entry. false when the list is full or the name is taken
function Example:Add(Name:string, Weight:number) : boolean
	if #Example._Entries >= MAX_ENTRIES then
		return false
	end

	if FindEntry(Name) then
		return false
	end

	table.insert(Example._Entries, { Name = Name, Weight = Weight })

	return true
end

return Example
```

##### Layout

| Rule | Example |
|---|---|
| Banners in this order: `-- // SERVICES`, `-- // CONTAINERS`, `-- // MODULES`, `-- // TYPES`, `-- // VARIABLES`, `-- // MODULE` (a controller and its Ui write `-- // CONTROLLER`), `-- // METHODS`. Leave out a banner whose block is empty. The two loader scripts have no banners | see above |
| Services through `game:GetService`, one per line. Then folders. Then one `require` per line | `const RunService = game:GetService("RunService")` |
| Tabs. One statement per line. A blank line between logical blocks and after every guard | |
| `PascalCase` for locals, parameters, functions, table fields and the module table | `StartedAt`, `GetLivingRoot` |
| `UPPER_SNAKE` for constants | `MAX_ENTRIES` |
| A leading underscore for private fields and helpers | `_Entries`, `_Connections` |
| `const` for every binding that is never reassigned: services, folders, requires, constants, most locals | `const Root = Character:FindFirstChild("HumanoidRootPart")` |
| `local` for what is reassigned, for functions, and for the module table | `local Rate = Service._Rates[Player]` |
| The module is one table that holds its state. Public functions are colon methods on it, called on the module's name, never on `self` | `function ExampleService:Run(...)`, `ExampleService._Children[Id] = Child` |
| Private helpers are `local function`, above `-- // METHODS` | |
| The file ends with `return ModuleName` | |
| Guard clauses return early, on three lines. `continue` to skip inside a loop | `if not Child then` / `return false` / `end` |
| `for _, Value in Table do`. Never `pairs` or `ipairs` | |
| More than three arguments, or optional ones: one table with named fields and its own `type` | `HitboxService:CreateHitbox(Params:HitboxParams)` |
| Keep every connection so it can be disconnected | `table.insert(Module._Connections, Signal:Connect(...))` |
| Backtick strings to build text. A backtick string can't span lines: use `[[ ]]` for multi-line text | `` `[ExampleService] the child "{Id}" failed to load` `` |

`const` needs a Luau version that has it. If your Studio rejects it, write `local` everywhere and keep the rest.

##### Comments

- A header at the top of every file, after `--!strict`: what the module is for and how it fits.
- A comment above **every** function: what it does and what it returns. Plain lowercase words, no full stop at the end. That means every named function: `function`, `local function`, methods, and methods on test fakes. An anonymous callback passed straight into a call (`Signal:Connect(function() ... end)`) needs a comment only when what it does isn't obvious from the call.
- A comment above a line that needs one, saying **why**, not what.
- A comment beside every constant: what the number means, with its unit.

```lua
-- true for a body that can act. AllowRagdoll: a ragdolled body still counts
local function IsValid(Character:Model?, AllowRagdoll:boolean) : boolean

const REACH_TIME = 0.65 -- seconds the attacker has to close in
```

#### 4. Strict typing

| Rule | Example |
|---|---|
| Every parameter is annotated, `Name:Type`, no space | `function ExampleService:Run(Owner:Player, ChildId:string) : boolean` |
| A function that returns something says what, `) : Type` | `) : ServerChild?`, `) : (number, string?)` |
| A table shape gets a named `type`. One another module needs is `export type`, used as `Module.TypeName` | `ExampleService.ServerChild` |
| A fixed set of names is a string union (or `keyof<typeof(Table)>`), not `string` | `export type ReplyKind = "Done" \| "Refused"` |
| Optional values carry `?`. A field that starts as nil is `nil :: Type?` | `_Gui = nil :: ScreenGui?` |
| A lookup is cast to what it is | `Gui:FindFirstChild("Status", true) :: TextLabel?` |
| Callbacks are typed with named arguments | `(ChildId:string, Reply:ReplyKind) -> ()` |
| A loop variable is annotated when the checker can't tell | `for _, Part:BasePart in Parts do` |
| `any` only where the value really can be anything: what arrives over the network, a dynamic `require` | `local function HandleRequest(Owner:Player, ChildId:any)` |

Never use `any` to quiet the checker on a value whose type you know. When a strict file requires an old untyped module, cast the require and say nothing more: `const Old = require(Path.OldModule) :: any`.

#### 5. Where code goes

| Code | Where | Loaded by |
|---|---|---|
| Server code | `ServerScriptService/Services/`, one ModuleScript (or folder with `init.luau`) per system | `ServerLoader` |
| Client code | `ReplicatedStorage/Controllers/`, one per system | `ClientLoader` |
| Code both sides read: configs both must agree on, shared types, pure helpers | `ReplicatedStorage/SharedModules/` | whoever requires it |

Shared modules hold data and pure functions: no state, no hooks, no connections.

##### A big system: one service and one controller

```
ServerScriptService/Services/InventoryService      the server half
ReplicatedStorage/Controllers/InventoryController  the client half
```

A system with code on one side only gets only that side's module. Don't create an empty shell for the other half; add it the day it has something to do. A small system follows the same rule: a feature with server logic and an interface still gets a service and a controller, because that is where server and client code go.

**A file or a folder?** A module with no children is one file (`DataService.luau`). As soon as it has a child, a `Ui` included, it becomes a folder named after the module, holding `init.luau` (the module) and the children (`ExampleController/init.luau`, `ExampleController/Ui.luau`).

**Using another system.** Require it by its place, from the top of the file:

| From | To | Write |
|---|---|---|
| a service | another service | `require(script.Parent.DataService)` |
| a service's child (inside its folder) | another service | `require(script.Parent.Parent.DataService)` |
| a controller | another controller | `require(script.Parent.DataController)` |
| a controller's `Ui` child | its own controller | `require(script.Parent)` |
| anything | a shared module | `require(ReplicatedStorage.SharedModules.Name)` |

A server module never requires a client one, or the other way round. What both need goes in SharedModules. If a test needs to replace the other system, put it in `_Dependencies` (section 8).

##### Interface code: a `Ui` child

A system's interface (HUD, menu, panel) is a child module named `Ui` under its controller. The loader runs it right after its parent and calls the same hooks on it. It requires its parent (`require(script.Parent)`); the parent never requires it. Its banner for the module table is `-- // CONTROLLER`, like its parent's. See `ExampleController/Ui.luau`.

- Build from templates kept in ReplicatedStorage (`ReplicatedStorage/UiTemplates/<Name>`) and clone them. Never build instances in code.
- A template is made in Studio, not in code. To keep it in `src/` as well, save it from Studio as a model file (right-click → Save to File → `.rbxm`) into `src/ReplicatedStorage/UiTemplates/<Name>.rbxm`; Rojo syncs model files. When an agent writes a `Ui` it can't make the template itself: it names the instances it needs in the header comment and tells the user to build them.
- Anchor at 0.5, 0.5. Scale only, never Offset (UIStroke thickness included). Keep the designed aspect ratio.
- Never name a module `Ui` unless it is one: the loader treats it as an interface.

##### A sub-system: a child of the system it belongs to

Ask "what is this a kind of?". If the answer is an existing system, it's a child of that system, on each side it has code for. A dash is a kind of ability, so it is `AbilityService/Dash.luau` and `AbilityController/Dash.luau`, not a `DashService`.

How the parent handles its children (copy `ExampleService`):

- It finds a child **by name**, so the child module is named after the thing's id. No lookup table.
- **The parent decides when children load.** Many children that a player uses few of: required on first use. Two or three it always needs: required in `Initialize`, which is simpler and shows a broken child at boot.
- The `require` is guarded (`pcall`). A child that fails is warned about by name, treated as missing, remembered so it isn't retried, and stops no other child.
- The parent declares the shape every child has as an exported type (`ExampleService.ServerChild`) and checks the required function is there before keeping it.
- A child may `require(script.Parent)`: safe, because the parent only requires the child later, from inside a function.
- A child that must also run for a player who never triggered it (the target of an ability, say) is woken by the parent, for example when an attribute appears on that player's character.

##### The loaders

| Fact | What it means for you |
|---|---|
| A loader requires only the ModuleScripts **directly inside** its folder (plus each one's `Ui`) | other children are loaded by their parent, never by the loader |
| It calls `Initialize()` on every module, then `Start()`, then the player and character hooks | event connections and loops go in these, not at the top of the file |
| Server hooks: `OnPlayerAdded(Player)`, `OnCharacterAdded(Player, Character)`, `OnCharacterRemoving(Player, Character)`, `OnPlayerRemoving(Player)`. Client hooks: `OnCharacterAdded(Character)`, `OnCharacterRemoving(Character)` | the client waits for the Humanoid and HumanoidRootPart before `OnCharacterAdded` |
| **These names are reserved** | never name a method `Initialize`, `Start` or `On…` for anything else: the loader will call it with its own arguments. Name it `StartRound`, `HandleHit`… |
| Each hook runs in its own thread; an error is caught and reported with the module's name | one broken module doesn't stop the others. Don't rely on another module's `Initialize` having finished |
| Attribute `LoadOrder` (number) on a ModuleScript: lower loads first; modules without it load after, by name | use it only when a module truly must go first |
| Attribute `DoesYield = true`: the module's hooks run inline and the next module waits | for a module others really need ready (data loading). Keep it rare |
| A module may be required by another before its `Initialize` ran | **a module must work straight after `require`.** `Initialize` and `Start` are for what the module does on its own, never for state a caller depends on |
| The top of a module must not wait | no `WaitForChild` or other yield at the top level. Fetch late things inside a function, on first use |

#### 6. Remotes

Every remote is named in `SharedModules/Network.luau`, in `REMOTES`. `ServerLoader` creates them all before any service loads.

```lua
-- server, in Initialize
table.insert(Service._Connections, Network:Listen("ExampleRequest", HandleRequest))

-- client
Network:FireServer("ExampleRequest", ChildId)
```

| Rule | Why |
|---|---|
| Add a remote to `REMOTES` in `Network.luau`, nowhere else | one list both sides read; the name type comes from it, so a typo doesn't compile |
| Never call `Network` at the top of a controller: listen in `Initialize` | the client waits for the remote the first time it is used, and the top of a module must not wait |
| On the server, check every argument a client sent: type, length, range, rate | the types guarantee nothing over the network. See `HandleRequest` and `TakeRequest` in `ExampleService` |
| Don't rename or remove a remote a live server still uses | old servers and new clients would disagree |

**Using a packet library instead** (smaller, batched sends): put every packet definition in one SharedModule both sides require, never require the library directly elsewhere, and wrap it so nothing touches it outside a running game (most packet libraries wait for their RemoteEvent forever, which hangs unit tests run in Edit). Note what your library can't carry (nil, long strings, precise numbers) in section 10.

#### 7. Player data

`DataService` keeps two kinds of data for each player, and `DataController` mirrors both to that player, read-only:

| Data | Shape and defaults | Saved | Use for |
|---|---|---|---|
| Profile (saved) | `SharedModules/DataTemplate.luau` | yes, ProfileStore, session-locked | currency, inventory, settings, progress |
| Session | `SharedModules/SessionTemplate.luau` | no, starts fresh each join | round score, streaks, anything the client should see but not keep |

**How a player loads.** On join, DataService starts the session data and loads the profile (fills in new template keys with `Reconcile`). When the client's `DataController` asks for its data, both replicas are created and sent. `DataController` is loaded first and the loader waits for it, so **every other controller can read data in its own `Initialize`**. After all controllers have started, `ClientLoader` fires `ClientReady`; the player now counts as *loaded*. With `Players.CharacterAutoLoads` off, DataService spawns the character at that moment, so nobody spawns before their client is ready.

**Server: read and write.** Read with the getters. Write **only** through the setters: they change the data and tell the client in one step. Writing `Profile.Data` directly saves, but the client never hears about it.

```lua
DataService:GetValue(Player, { "Coins" })
DataService:Increment(Player, { "Coins" }, 25)
DataService:SetValue({ Player = Player, Path = { "Coins" }, Value = 10, MathOperation = "-", MinValue = 0 })
DataService:SetValue({ Player = Player, Path = { "Settings", "MusicEnabled" }, Value = false })
DataService:SetValues({ Player = Player, Path = { "Settings" }, Values = { MusicEnabled = true } })
DataService:InsertInArray({ Player = Player, Path = { "Inventory" }, Value = "Sword" })
DataService:RemoveFromArray({ Player = Player, Path = { "Inventory" }, Value = "Sword" }) -- or Index = 1
DataService:SetValue({ Player = Player, Path = { "Streak" }, Value = 1, MathOperation = "+", Source = "Session" })

-- another service that needs a player's data
if DataService:WaitForLoaded(Player) then ... end
local Stop = DataService:WatchPlayerLoaded(function(Player) ... end)
```

| Server method | Does |
|---|---|
| `GetValue(Player, Path)`, `GetSessionValue(Player, Path)`, `GetData(Player)` | read; nil until loaded |
| `SetValue(Params)` | sets a value, optionally with `MathOperation` (`= + - * /`), `MinValue`, `MaxValue`, `Source`. false when it can't (not loaded, no parent table, a math operation on something that isn't a number, division by zero) |
| `Increment(Player, Path, Amount)` | `SetValue` with `+` |
| `SetValues(Params)` | several keys of one dictionary in one replication |
| `InsertInArray(Params)` / `RemoveFromArray(Params)` | array changes; return the index inserted at / the value removed |
| `ResetData(Player)` | template back in, then a kick so they rejoin with it |
| `IsPlayerLoaded`, `GetLoadedPlayers`, `WaitForLoaded`, `WatchPlayerLoaded` | who is loaded |
| `GetProfile`, `GetReplica`, `GetSession` | the raw objects, for what the setters don't cover |

**Client: read and react.** The client never writes data. It asks a service through a remote, and the service writes.

```lua
DataController:GetValue({ "Coins" })
local Stop = DataController:ObserveValue({ "Coins" }, function(Coins, OldCoins) ... end) -- now and on change
DataController:WatchValue({ "Settings", "MusicEnabled" }, function(Enabled, WasEnabled) ... end) -- changes only
DataController:WatchArrayInsert({ "Inventory" }, function(Item, Index) ... end)
DataController:WatchArrayRemove({ "Inventory" }, function(Item, Index) ... end)
DataController:ObserveSessionValue({ "Streak" }, function(Streak) ... end)
DataController:WatchAnyChange(function(Action, Path, Param1, Param2) ... end)
DataController:Watch({ Kind = "ArrayInsert", Path = { "Party" }, Source = "Session", Callback = ... }) -- any kind, either source
```

- A value watch fires for a change at its path **or inside it**: watching `{"Settings"}` hears `{"Settings", "MusicEnabled"}`. It only fires when a plain value actually changed. For a table, `OldValue` is nil (the table changed in place).
- Watches can be added before the data arrives; they start when it does.
- Every watch returns its stop function. Keep it, and call it when the thing watching goes away.

| Rule | Why |
|---|---|
| A new saved key goes in `DataTemplate` (and its type) | `Reconcile` gives it to every profile on its next load |
| Never rename or remove a saved key a live profile still has; migrate in DataService first | old profiles still hold the old key |
| Saved values are JSON-safe only: strings, numbers, booleans, tables of those | no Instances, Vector3s, or tables that mix array and dictionary keys |
| Changing `STORE_NAME` starts every player from the template | use it only for a deliberate wipe, or for a separate test store |
| In an unpublished place, or with Studio API access off, ProfileStore keeps data in memory and warns that nothing is saved | that's expected while testing |
| Saved and replicated times are `os.time()` seconds, written by the server. The client compares them with `workspace:GetServerTimeNow()`, which uses the same clock and is synced to the server, never with its own `os.time()` | the player's computer clock can be wrong or changed |
| A service that needs a player's data either checks that it's there (the getters return nil, the setters return false) or waits with `DataService:WaitForLoaded(Player)` | the profile loads a moment after `OnPlayerAdded`, and may never load (the player leaves, or the load fails) |

#### 8. Checks and tests

**The style checker** checks every rule a machine can check: `node tools/check-luau.mjs` from the project root, or with files or folders as arguments. `framework.config.json` lists the folders it checks; anything else (legacy code, packages) is left alone. With the roblox-framework Claude Code plugin it runs after every edit and hands its findings back to the agent. Silence a finding only when the rule truly doesn't apply: `-- check:ignore <rule>` on or above the line, or `-- check:ignore-file <rule>`, always with the reason.

The checker also catches basic syntax slips that would otherwise pass as clean: a backslash outside a string, an `end` too many or too few, and brackets that don't match. It is **not a compiler**: clean means the rules hold, not that the file compiles. Only Studio (Script Analysis, a test run) proves that.

**Unit tests.** A module with rules or decisions gets a unit test. Pure wiring or visuals may go without; say so when you hand the work over.

Run them from the command bar in Edit:

```lua
require(game.ServerStorage.Tests.TestRunner:Clone()):Run()
```

- A test file is `ServerStorage/Tests/<Name>.spec.luau`. It returns a table of test functions, each given a `Check` (`Check:Equal`, `Check:True`). See `DataService.spec.luau`.
- `Check:Fresh(Module)` gives a new copy of a module, so no state leaks between tests.
- Studio caches every module it has already required in Edit. After editing a shared module that a spec requires, restart Studio before trusting the results. The runner and `Check:Fresh` always get new copies.
- Give the module a `_Dependencies` table for what it reaches for outside itself (the clock, packages, another module), and let the test swap it. Type a swapped module by the parts you use, so a fake only needs those:

```lua
-- in the service
-- the parts of DataService this service uses, so a test can swap in a fake
type DataAccess = {
	GetValue:(self:any, Player:Player, Path:{any}) -> any,
	Increment:(self:any, Player:Player, Path:{any}, Amount:number) -> boolean,
}

local RewardService = {
	_Dependencies = {
		GetTime = os.time,
		Data = DataService :: DataAccess,
	},
}

-- in RewardService.spec.luau
const Service = Check:Fresh(REWARD_SERVICE)
const Saved = { Coins = 0 }

Service._Dependencies.GetTime = function() : number
	return 1000
end
Service._Dependencies.Data = {
	GetValue = function(_Self:any, _Player:Player, Path:{any}) : any
		return Saved[Path[1]]
	end,
	Increment = function(_Self:any, _Player:Player, Path:{any}, Amount:number) : boolean
		Saved[Path[1]] += Amount
		return true
	end,
}
```
- Where a parent finds children by name, keep the folder it looks in as a field (`ExampleService._Holder`) so a test can point it at test children.
- Never require the network layer or a package that starts work when required (ProfileStore, Replica) at the top of a module under test. DataService and DataController load them on first use.

#### 9. Existing code

When this framework goes into a game that already has scripts:

- **Leave old scripts where they are.** A system moves into Services/Controllers only when the lead scripter names it.
- **An edit of a few lines in an old file keeps that file's style.** A file must never end up half one style and half the other. Add a dated comment saying why.
- **New behaviour goes in a service or controller**, and the old script calls into it with a few lines.
- No version control? Copy every script you're about to change into a dated backup folder first. Better: use git.

#### 10. Project decisions

The lead scripter's rulings for this game, dated. Start empty.

| Date | Question | Decision |
|---|---|---|
| | | |

#### 11. Before you call a file done

- [ ] `--!strict` is line 1, then a header comment.
- [ ] It's under `Services`, `Controllers` or `SharedModules`; a sub-system is a child of its parent; interface code is a `Ui` child.
- [ ] Any new remote is in `Network.luau`, and nothing calls `Network` at the top of a file.
- [ ] A module with rules or decisions has a test.
- [ ] Banners are in order; `PascalCase` names, `UPPER_SNAKE` constants, `_` for private.
- [ ] `const` everywhere a binding isn't reassigned.
- [ ] Every parameter and return is typed; `any` only for network input and untyped requires.
- [ ] Every function has a comment above it; every constant has its unit.
- [ ] No method is named `Initialize`, `Start` or `On…` unless it is that hook.
- [ ] Nothing at the top level waits; the module works straight after `require`.
- [ ] Every connection is kept; per-player state is cleared in `OnPlayerRemoving`.
- [ ] Player data is written only through DataService's setters; the client only reads and watches.
- [ ] `node tools/check-luau.mjs` reports it clean.
- [ ] It compiles, Script Analysis shows no warnings, and the tests pass.

---

## Part 3: The files

23 files. Each heading is the path from the project root.

### `default.project.json`

````json
{
	"name": "Game",
	"tree": {
		"$className": "DataModel",
		"ReplicatedStorage": {
			"$path": "src/ReplicatedStorage",
			"$ignoreUnknownInstances": true
		},
		"ServerScriptService": {
			"$path": "src/ServerScriptService",
			"$ignoreUnknownInstances": true
		},
		"ServerStorage": {
			"$path": "src/ServerStorage",
			"$ignoreUnknownInstances": true
		},
		"StarterPlayer": {
			"StarterPlayerScripts": {
				"$path": "src/StarterPlayer/StarterPlayerScripts"
			}
		}
	}
}
````

### `framework.config.json`

````json
{
	"check": [
		"src/ServerScriptService",
		"src/ReplicatedStorage/Controllers",
		"src/ReplicatedStorage/SharedModules",
		"src/ServerStorage/Tests",
		"src/StarterPlayer"
	],
	"ignore": ["SharedPackages", "ServerPackages", "Packages"]
}
````

### `src/ReplicatedStorage/Controllers/DataController.luau`

````lua
--!strict
-- the local player's data on the client: a read-only mirror of what DataService keeps, through two Replicas (saved
-- data and session data). Read with GetValue, react with the Watch / Observe methods. The client never writes:
-- ask a service through a remote and let DataService change the data.
-- it loads first and the loader waits for it (attributes LoadOrder = 1, DoesYield = true), so every other controller
-- can read data from its own Initialize. Watchers can be added before the data arrives: they start when it does

-- // SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

-- // CONTAINERS
const SharedModules = ReplicatedStorage.SharedModules

-- // MODULES
const DataConfig = require(SharedModules.DataConfig)
const DataPath = require(SharedModules.DataPath)
const DataTemplate = require(SharedModules.DataTemplate)

-- // TYPES
export type Path = DataPath.Path
export type DataSource = DataConfig.DataSource
export type ChangeAction = "Set" | "SetValues" | "TableInsert" | "TableRemove"

-- Value is the value now. OldValue is the one before for plain values, nil for tables (changed in place)
export type ValueWatcher = (Value:any, OldValue:any) -> ()
-- the value inserted or removed, and its index
export type ArrayWatcher = (Value:any, Index:number) -> ()
-- every change: Set (value, old value), SetValues (values), TableInsert (value, index), TableRemove (value, index)
export type ChangeWatcher = (Action:ChangeAction, Path:Path, Param1:any, Param2:any) -> ()

-- what a watch reacts to
export type WatchKind = "Value" | "ArrayInsert" | "ArrayRemove" | "AnyChange"

export type WatchParams = {
	Kind:WatchKind,
	Path:Path?, -- needed by every kind but AnyChange
	Callback:(...any) -> (),
	Source:DataSource?, -- "Profile" when nil
	Immediate:boolean?, -- Value only: also called once with the current value as soon as there is data
}

-- the parts of a client Replica this controller uses
type Connection = {
	Disconnect:(self:any) -> (),
}

type ClientReplica = {
	Data:any,
	Tags:{[any]:any},
	OnChange:(self:any, Listener:(Action:ChangeAction, Path:{any}, Param1:any, Param2:any) -> ()) -> Connection,
}

-- the parts of ReplicaClient this controller uses
type ReplicaClientModule = {
	OnNew:(Token:string, Listener:(Replica:ClientReplica) -> ()) -> Connection,
	RequestData:() -> (),
}

type Watch = {
	Kind:WatchKind,
	Path:Path,
	Callback:(...any) -> (),
	Immediate:boolean,
	Last:any, -- the last plain value a Value watch saw
}

-- one replica and everything watching it
type Source = {
	Replica:ClientReplica?,
	Watches:{Watch},
	Connection:Connection?,
}

-- // VARIABLES
const DATA_TIME_OUT = 30 -- seconds Initialize waits for the data before letting the other controllers start anyway

-- // CONTROLLER
local DataController = {
	_Sources = {
		Profile = { Replica = nil, Watches = {}, Connection = nil },
		Session = { Replica = nil, Watches = {}, Connection = nil },
	} :: {[DataSource]:Source},
	_Waiting = {} :: {thread},
	_Connections = {} :: {Connection},
	-- what the controller reaches for outside itself, so a test can swap it
	_Dependencies = {
		LoadReplicaClient = nil :: (() -> ReplicaClientModule)?, -- nil: the real one in SharedPackages
		UserId = function() : number
			return (Players.LocalPlayer :: Player).UserId
		end,
		IsRunning = function() : boolean
			return RunService:IsRunning()
		end,
	},
}

-- ReplicaClient, required here and not at the top: at require it starts looking for its remotes, which never
-- appear outside a running game
local function LoadReplicaClient() : ReplicaClientModule
	if DataController._Dependencies.LoadReplicaClient then
		return DataController._Dependencies.LoadReplicaClient()
	end

	return require(ReplicatedStorage.SharedPackages.ReplicaClient) :: any
end

-- calls Callback in its own thread, so a watcher that errors or yields stops nothing
local function Call(Callback:(...any) -> (), ...:any)
	task.spawn(Callback, ...)
end

-- a Value watch looks at the data now: calls it when the value changed since it last looked (always for a table),
-- or when Force is set. Remembers plain values for next time
local function CheckValue(Watch:Watch, Data:any, Force:boolean)
	const Value = DataPath:Get(Data, Watch.Path)
	const Old = Watch.Last

	if type(Value) == "table" then
		Watch.Last = nil
	elseif Value == Old and not Force then
		return
	else
		Watch.Last = Value
	end

	Call(Watch.Callback, Value, if type(Value) == "table" then nil else Old)
end

-- hands one change on to every watch of that source it concerns
local function Dispatch(Source:Source, Action:ChangeAction, ChangedPath:Path, Param1:any, Param2:any)
	const Replica = Source.Replica

	if not Replica then
		return
	end

	for _, Watch in table.clone(Source.Watches) do
		if Watch.Kind == "AnyChange" then
			Call(Watch.Callback, Action, ChangedPath, Param1, Param2)
		elseif Watch.Kind == "Value" then
			if DataPath:Overlaps(Watch.Path, ChangedPath) then
				CheckValue(Watch, Replica.Data, false)
			end
		elseif Watch.Kind == "ArrayInsert" then
			if Action == "TableInsert" and DataPath:Equals(Watch.Path, ChangedPath) then
				Call(Watch.Callback, Param1, Param2)
			end
		elseif Watch.Kind == "ArrayRemove" then
			if Action == "TableRemove" and DataPath:Equals(Watch.Path, ChangedPath) then
				Call(Watch.Callback, Param1, Param2)
			end
		end
	end
end

-- a Value watch starting on data that is here: called now when Immediate, else only remembers the value
local function StartValueWatch(Watch:Watch, Data:any)
	if Watch.Immediate then
		CheckValue(Watch, Data, true)
	else
		const Value = DataPath:Get(Data, Watch.Path)
		Watch.Last = if type(Value) == "table" then nil else Value
	end
end

-- wakes every thread waiting for the data with the answer
local function ResumeWaiting(Arrived:boolean)
	const Waiting = DataController._Waiting
	DataController._Waiting = {}

	for _, Thread in Waiting do
		task.spawn(Thread, Arrived)
	end
end

-- the local player's replica of that source has arrived: starts every watch already waiting on it
local function Attach(SourceName:DataSource, Replica:ClientReplica)
	const Source = DataController._Sources[SourceName]

	if Source.Connection then
		Source.Connection:Disconnect()
	end

	Source.Replica = Replica
	Source.Connection = Replica:OnChange(function(Action:ChangeAction, ChangedPath:{any}, Param1:any, Param2:any)
		Dispatch(Source, Action, ChangedPath :: Path, Param1, Param2)
	end)

	for _, Watch in Source.Watches do
		if Watch.Kind == "Value" then
			StartValueWatch(Watch, Replica.Data)
		end
	end

	if SourceName == "Profile" then
		ResumeWaiting(true)
	end
end

-- the data of that source, nil until it arrived
local function GetSourceData(SourceName:DataSource) : any
	const Replica = DataController._Sources[SourceName].Replica

	return if Replica then Replica.Data else nil
end

-- // METHODS
-- true once the saved data has arrived
function DataController:IsLoaded() : boolean
	return DataController._Sources.Profile.Replica ~= nil
end

-- waits until the saved data has arrived. true when it has, false when Initialize gave up waiting
function DataController:WaitForData() : boolean
	if DataController:IsLoaded() then
		return true
	end

	table.insert(DataController._Waiting, coroutine.running())

	return coroutine.yield()
end

-- the whole saved data, nil until it arrived. Read only
function DataController:GetData() : DataTemplate.Data?
	return GetSourceData("Profile")
end

-- the saved value at Path ({"Settings", "MusicEnabled"}), nil when it is not there or not arrived
function DataController:GetValue(Path:Path) : any
	return DataPath:Get(GetSourceData("Profile"), Path)
end

-- the session value at Path, nil when it is not there or not arrived
function DataController:GetSessionValue(Path:Path) : any
	return DataPath:Get(GetSourceData("Session"), Path)
end

-- starts a watch of any kind on either source (see WatchParams). Returns the function that stops it, keep it
function DataController:Watch(Params:WatchParams) : () -> ()
	const SourceName = Params.Source or "Profile"
	const Source = DataController._Sources[SourceName]

	assert(Params.Kind == "AnyChange" or Params.Path ~= nil, `[DataController] a {Params.Kind} watch needs a Path`)

	const NewWatch:Watch = {
		Kind = Params.Kind,
		Path = Params.Path or {},
		Callback = Params.Callback,
		Immediate = Params.Immediate == true,
		Last = nil,
	}

	table.insert(Source.Watches, NewWatch)

	if NewWatch.Kind == "Value" and Source.Replica then
		StartValueWatch(NewWatch, Source.Replica.Data)
	end

	return function()
		const Index = table.find(Source.Watches, NewWatch)

		if Index then
			table.remove(Source.Watches, Index)
		end
	end
end

-- calls Callback(Value, OldValue) now (or as soon as the data arrives) and every time the saved value at Path
-- changes, including changes inside it. Returns the function that stops it
function DataController:ObserveValue(Path:Path, Callback:ValueWatcher) : () -> ()
	return DataController:Watch({ Kind = "Value", Path = Path, Callback = Callback, Immediate = true })
end

-- like ObserveValue, but only for changes from now on, not the current value
function DataController:WatchValue(Path:Path, Callback:ValueWatcher) : () -> ()
	return DataController:Watch({ Kind = "Value", Path = Path, Callback = Callback })
end

-- like ObserveValue, for a session value
function DataController:ObserveSessionValue(Path:Path, Callback:ValueWatcher) : () -> ()
	return DataController:Watch({ Kind = "Value", Path = Path, Callback = Callback, Immediate = true, Source = "Session" })
end

-- calls Callback(Value, Index) each time a value is inserted into the saved array at Path
function DataController:WatchArrayInsert(Path:Path, Callback:ArrayWatcher) : () -> ()
	return DataController:Watch({ Kind = "ArrayInsert", Path = Path, Callback = Callback })
end

-- calls Callback(Value, Index) each time a value is removed from the saved array at Path
function DataController:WatchArrayRemove(Path:Path, Callback:ArrayWatcher) : () -> ()
	return DataController:Watch({ Kind = "ArrayRemove", Path = Path, Callback = Callback })
end

-- calls Callback(Action, Path, Param1, Param2) for every change to the saved data
function DataController:WatchAnyChange(Callback:ChangeWatcher) : () -> ()
	return DataController:Watch({ Kind = "AnyChange", Callback = Callback })
end

-- loader hook: asks for the data and waits for it (DoesYield: the other controllers start after), at most
-- DATA_TIME_OUT seconds. Skipped outside a running game
function DataController:Initialize()
	if not DataController._Dependencies.IsRunning() then
		return
	end

	const ReplicaClient = LoadReplicaClient()
	const UserId = DataController._Dependencies.UserId()

	-- only the local player's replicas: a game may replicate other players' data under the same token
	for SourceName, Token in { Profile = DataConfig.PROFILE_TOKEN, Session = DataConfig.SESSION_TOKEN } :: {[DataSource]:string} do
		table.insert(DataController._Connections, ReplicaClient.OnNew(Token, function(Replica:ClientReplica)
			if Replica.Tags.UserId == UserId then
				Attach(SourceName, Replica)
			end
		end))
	end

	ReplicaClient.RequestData()

	if DataController:IsLoaded() then
		return
	end

	task.delay(DATA_TIME_OUT, function()
		if not DataController:IsLoaded() then
			warn(`[DataController] no data after {DATA_TIME_OUT} seconds, the other controllers start without it`)
			ResumeWaiting(false)
		end
	end)

	DataController:WaitForData()
end

return DataController
````

### `src/ReplicatedStorage/Controllers/DataController.meta.json`

````json
{
	"attributes": {
		"LoadOrder": 1,
		"DoesYield": true
	}
}
````

### `src/ReplicatedStorage/Controllers/ExampleController/Ui.luau`

````lua
--!strict
-- ExampleController's interface. The loader runs it right after its parent with the same hooks, so the parent never
-- requires it. It clones its ScreenGui from ReplicatedStorage.UiTemplates.ExampleUi (a RunButton TextButton and a
-- Status TextLabel) and never builds instances in code

-- // SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const ExampleController = require(script.Parent)

-- // VARIABLES
const TEMPLATE_NAME = "ExampleUi"
const CHILD_ID = "ExampleChild" -- the child the button asks the server to run

-- // CONTROLLER
local ExampleUi = {
	_Gui = nil :: ScreenGui?,
	_Cleanups = {} :: {() -> ()},
}

-- the template ScreenGui, nil (with a warning) when it is missing
local function FindTemplate() : ScreenGui?
	const Templates = ReplicatedStorage:FindFirstChild("UiTemplates")
	const Template = if Templates then Templates:FindFirstChild(TEMPLATE_NAME) else nil

	if not Template or not Template:IsA("ScreenGui") then
		warn(`[ExampleController.Ui] no ScreenGui named "{TEMPLATE_NAME}" in ReplicatedStorage.UiTemplates`)

		return nil
	end

	return Template
end

-- // METHODS
-- loader hook: clones the interface into the player's gui and wires the button and the status line
function ExampleUi:Start()
	const Template = FindTemplate()

	if not Template then
		return
	end

	const Gui = Template:Clone()
	const FoundButton = Gui:FindFirstChild("RunButton", true)
	const FoundStatus = Gui:FindFirstChild("Status", true)

	if not FoundButton or not FoundButton:IsA("TextButton") or not FoundStatus or not FoundStatus:IsA("TextLabel") then
		warn(`[ExampleController.Ui] "{TEMPLATE_NAME}" needs a RunButton TextButton and a Status TextLabel`)
		Gui:Destroy()

		return
	end

	-- typed bindings, so the closures below keep the refined types
	const RunButton:TextButton = FoundButton
	const Status:TextLabel = FoundStatus

	const Clicked = RunButton.Activated:Connect(function()
		ExampleController:Request(CHILD_ID)
	end)

	table.insert(ExampleUi._Cleanups, function()
		Clicked:Disconnect()
	end)

	table.insert(ExampleUi._Cleanups, ExampleController:WatchReplies(function(ChildId:string, Reply:ExampleController.ReplyKind)
		Status.Text = `{ChildId}: {Reply}`
	end))

	Gui.ResetOnSpawn = false
	Gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	ExampleUi._Gui = Gui
end

return ExampleUi
````

### `src/ReplicatedStorage/Controllers/ExampleController/init.luau`

````lua
--!strict
-- template for the client half of a system: copy the folder, rename it, delete what you don't use.
-- it sends the player's requests to ExampleService and tells whoever watches (its Ui child, other controllers) what
-- came back. Its interface lives in the Ui child, which the loader runs right after it

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const ExampleConfig = require(ReplicatedStorage.SharedModules.ExampleConfig)
const Network = require(ReplicatedStorage.SharedModules.Network)

-- // TYPES
export type ReplyKind = ExampleConfig.ReplyKind

export type ReplyWatcher = (ChildId:string, Reply:ReplyKind) -> ()

-- // CONTROLLER
local ExampleController = {
	_Character = nil :: Model?,
	_Watchers = {} :: {ReplyWatcher},
	_Connections = {} :: {RBXScriptConnection},
}

-- tells every watcher about one reply. A watcher that errors stops no other
local function Announce(ChildId:string, Reply:ReplyKind)
	for _, Watcher in table.clone(ExampleController._Watchers) do
		task.spawn(Watcher, ChildId, Reply)
	end
end

-- one reply from the server, checked before use like anything off the network
local function HandleReply(ChildId:any, Reply:any)
	if not ExampleConfig:IsChildId(ChildId) or not ExampleConfig:IsReplyKind(Reply) then
		return
	end

	Announce(ChildId :: string, Reply :: ReplyKind)
end

-- // METHODS
-- asks the server to run the child with that id. false when there is no character to run it with
function ExampleController:Request(ChildId:string) : boolean
	if not ExampleController._Character then
		return false
	end

	Network:FireServer("ExampleRequest", ChildId)

	return true
end

-- calls Watcher with every reply from now on. Returns the function that stops it, keep it
function ExampleController:WatchReplies(Watcher:ReplyWatcher) : () -> ()
	table.insert(ExampleController._Watchers, Watcher)

	return function()
		const Index = table.find(ExampleController._Watchers, Watcher)

		if Index then
			table.remove(ExampleController._Watchers, Index)
		end
	end
end

-- loader hook: listens for replies. Here, not at the top of the file: Network waits for the remote on first use
function ExampleController:Initialize()
	table.insert(ExampleController._Connections, Network:Listen("ExampleReply", HandleReply))
end

-- loader hook: the player's body is ready
function ExampleController:OnCharacterAdded(Character:Model)
	ExampleController._Character = Character
end

-- loader hook: the player's body is going away
function ExampleController:OnCharacterRemoving(Character:Model)
	if ExampleController._Character == Character then
		ExampleController._Character = nil
	end
end

return ExampleController
````

### `src/ReplicatedStorage/SharedModules/DataConfig.luau`

````lua
--!strict
-- what DataService and DataController must agree on: the names the two replicas are created and found under

-- // TYPES
-- which data a call is about: the saved profile, or the session data that is never saved
export type DataSource = "Profile" | "Session"

-- // MODULE
const DataConfig = {
	PROFILE_TOKEN = "PlayerData", -- the replica holding a player's saved data
	SESSION_TOKEN = "PlayerSession", -- the replica holding a player's session data
}

return DataConfig
````

### `src/ReplicatedStorage/SharedModules/DataPath.luau`

````lua
--!strict
-- reading and comparing paths into nested data ({"Inventory", "Swords", 2}). DataService and DataController both walk
-- player data with these, so a path means the same thing on both sides. Pure functions, no state

-- // TYPES
export type Path = {string | number}

-- // MODULE
local DataPath = {}

-- // METHODS
-- the value at Path inside Data, nil as soon as a key is missing or something on the way is not a table.
-- an empty path is Data itself
function DataPath:Get(Data:any, Path:Path) : any
	local Current = Data

	for _, Key in Path do
		if type(Current) ~= "table" then
			return nil
		end

		Current = Current[Key]
	end

	return Current
end

-- true when one path is the start of the other, or they are equal: a change at one can change the value at the other
function DataPath:Overlaps(PathA:Path, PathB:Path) : boolean
	for Index = 1, math.min(#PathA, #PathB) do
		if PathA[Index] ~= PathB[Index] then
			return false
		end
	end

	return true
end

-- true when the two paths name the same place
function DataPath:Equals(PathA:Path, PathB:Path) : boolean
	if #PathA ~= #PathB then
		return false
	end

	return DataPath:Overlaps(PathA, PathB)
end

-- true for a path a caller may use: a non-empty array of strings and whole numbers
function DataPath:IsValid(Path:any) : boolean
	if type(Path) ~= "table" or #Path == 0 then
		return false
	end

	for _, Key in Path do
		if type(Key) == "number" then
			if Key % 1 ~= 0 then
				return false
			end
		elseif type(Key) ~= "string" then
			return false
		end
	end

	return true
end

-- the path as text ("Inventory.Swords.2"), for warnings
function DataPath:ToText(Path:Path) : string
	const Parts = {} :: {string}

	for _, Key in Path do
		table.insert(Parts, tostring(Key))
	end

	return table.concat(Parts, ".")
end

-- a full copy of Value: tables are copied all the way down, everything else is returned as is
function DataPath:DeepCopy<T>(Value:T) : T
	if type(Value) ~= "table" then
		return Value
	end

	const Copy = {}

	for Key, Inner in Value :: any do
		Copy[Key] = DataPath:DeepCopy(Inner)
	end

	return Copy :: any
end

return DataPath
````

### `src/ReplicatedStorage/SharedModules/DataTemplate.luau`

````lua
--!strict
-- the shape of a player's saved data and its starting values. DataService saves it with ProfileStore; DataController
-- reads the type. Add a key here and every profile gets it on its next load (Reconcile). Never rename or remove a key
-- a live profile still has: write a migration in DataService first.
-- only JSON-safe values: strings, numbers, booleans, and tables of those (no Instances, Vector3s or mixed tables)

-- // TYPES
export type TimeTrackers = {
	FirstJoined:number, -- os.time() of the first session, 0 until then
	LastJoined:number, -- os.time() the current or last session started
	TimePlayed:number, -- seconds played over every session
}

export type Data = {
	Coins:number,
	Inventory:{string},
	Settings:{
		MusicEnabled:boolean,
	},
	TimeTrackers:TimeTrackers,
}

-- // MODULE
-- the starting values. ProfileStore copies them: never write to this table
const DataTemplate:Data = {
	Coins = 0,
	Inventory = {},
	Settings = {
		MusicEnabled = true,
	},
	TimeTrackers = {
		FirstJoined = 0,
		LastJoined = 0,
		TimePlayed = 0,
	},
}

return DataTemplate
````

### `src/ReplicatedStorage/SharedModules/ExampleConfig.luau`

````lua
--!strict
-- what ExampleService and ExampleController must agree on: the reply names and the limits on a request.
-- shared modules hold data and pure helpers only, no state and no hooks

-- // TYPES
-- what the server tells the asking client
export type ReplyKind = "Done" | "Refused"

-- // VARIABLES
const MAX_ID_LENGTH = 32 -- characters: a child id longer than this is not one

-- // MODULE
local ExampleConfig = {
	MAX_ID_LENGTH = MAX_ID_LENGTH,
}

-- // METHODS
-- true for a child id a client may send: a string of 1 to MAX_ID_LENGTH characters
function ExampleConfig:IsChildId(Value:any) : boolean
	return type(Value) == "string" and #Value > 0 and #Value <= MAX_ID_LENGTH
end

-- true for one of the ReplyKind names
function ExampleConfig:IsReplyKind(Value:any) : boolean
	return Value == "Done" or Value == "Refused"
end

return ExampleConfig
````

### `src/ReplicatedStorage/SharedModules/Loader.luau`

````lua
--!strict
-- finds, requires, orders and calls the modules a loader script runs: every ModuleScript directly inside a folder,
-- each followed right away by its "Ui" child when it has one. Only ServerLoader and ClientLoader use it.
-- a module that fails to load, or whose hook errors, is warned about by name and stops no other module

-- // TYPES
-- the hooks a loader calls. These names are reserved: a module never uses them for anything else
export type HookName =
	"Initialize"
	| "Start"
	| "OnPlayerAdded"
	| "OnPlayerRemoving"
	| "OnCharacterAdded"
	| "OnCharacterRemoving"

export type LoadedModule = {
	Name:string,
	Content:any, -- the module's table, its shape is its own
	Instance:ModuleScript,
	LoadOrder:number?, -- the "LoadOrder" attribute: lower runs first, modules without one run after, by name
	DoesYield:boolean, -- the "DoesYield" attribute: its hooks run inline and the next module waits for them
}

-- // MODULE
local Loader = {}

-- the module's table, nil (with a warning naming it) when it errors or does not return a table
local function TryRequire(Module:ModuleScript, Name:string) : any
	const Success, Result = pcall(require, Module)

	if not Success then
		warn(`[Loader] "{Name}" failed to load: {Result}`)

		return nil
	end

	if type(Result) ~= "table" then
		warn(`[Loader] "{Name}" does not return a table, it is skipped`)

		return nil
	end

	return Result
end

-- a LoadedModule for Module, nil when it failed to load
local function Load(Module:ModuleScript, Name:string, LoadOrder:number?) : LoadedModule?
	const Content = TryRequire(Module, Name)

	if not Content then
		return nil
	end

	return {
		Name = Name,
		Content = Content,
		Instance = Module,
		LoadOrder = LoadOrder,
		DoesYield = Module:GetAttribute("DoesYield") == true,
	}
end

-- true when A runs before B: by LoadOrder, then by name so the order is the same every boot
local function RunsBefore(A:LoadedModule, B:LoadedModule) : boolean
	if A.LoadOrder ~= B.LoadOrder then
		return (A.LoadOrder :: number) < (B.LoadOrder :: number)
	end

	return A.Name < B.Name
end

-- // METHODS
-- every ModuleScript directly inside Holder, required and sorted, each followed by its "Ui" child.
-- children other than Ui are never loaded here: their parent module loads them
function Loader:Collect(Holder:Instance) : {LoadedModule}
	const WithOrder = {} :: {LoadedModule}
	const WithoutOrder = {} :: {LoadedModule}

	for _, Child in Holder:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		const LoadOrder = Child:GetAttribute("LoadOrder")
		const Loaded = Load(Child, Child.Name, if type(LoadOrder) == "number" then LoadOrder else nil)

		if not Loaded then
			continue
		end

		table.insert(if Loaded.LoadOrder then WithOrder else WithoutOrder, Loaded)
	end

	table.sort(WithOrder, RunsBefore)
	table.sort(WithoutOrder, RunsBefore)

	const Sorted = {} :: {LoadedModule}

	-- the Ui child requires its parent, so it is loaded after it and the parent never requires it
	for _, List in { WithOrder, WithoutOrder } do
		for _, Loaded in List do
			table.insert(Sorted, Loaded)

			const Ui = Loaded.Instance:FindFirstChild("Ui")

			if not Ui or not Ui:IsA("ModuleScript") then
				continue
			end

			const LoadedUi = Load(Ui, `{Loaded.Name}.Ui`, Loaded.LoadOrder)

			if LoadedUi then
				table.insert(Sorted, LoadedUi)
			end
		end
	end

	return Sorted
end

-- calls HookName on every module that has it, with the arguments given. A yielding module runs inline, the others
-- each in their own thread. An error is warned about with the module's name and stops no other module
function Loader:CallAll(Modules:{LoadedModule}, HookName:HookName, ...:any)
	const Arguments = table.pack(...)

	for _, Loaded in Modules do
		const Hook = Loaded.Content[HookName]

		if type(Hook) ~= "function" then
			continue
		end

		-- runs the hook under the module's memory category, warning with its name if it errors
		local function Invoke()
			debug.setmemorycategory(Loaded.Name)

			const Success, Problem = xpcall(Hook, debug.traceback, Loaded.Content, table.unpack(Arguments, 1, Arguments.n))

			if not Success then
				warn(`[Loader] {Loaded.Name}:{HookName} failed: {Problem}`)
			end
		end

		if Loaded.DoesYield then
			Invoke()
		else
			task.spawn(Invoke)
		end
	end
end

return Loader
````

### `src/ReplicatedStorage/SharedModules/Network.luau`

````lua
--!strict
-- every RemoteEvent the game uses, named in one table both sides read, and the only code that creates or finds them.
-- ServerLoader creates them all before any service loads. On the client a remote is waited for the first time it is
-- used, so never call this at the top of a file: listen in Initialize.
-- if the project uses a packet library instead, this file is where its definitions go, and nothing else changes

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

-- // VARIABLES
const FOLDER_NAME = "Network" -- the folder under ReplicatedStorage that holds the remotes

-- every remote, by name. Add one here when a system needs it; never rename or remove one a live server still uses
const REMOTES = {
	ClientReady = true, -- client -> server: ClientLoader ran every controller's Start, the player may spawn
	ExampleRequest = true, -- client -> server: ExampleController asks ExampleService to run a child
	ExampleReply = true, -- server -> client: what came of it
}

-- // TYPES
-- below VARIABLES on purpose: the names are read from REMOTES, so the list is written once
-- check:ignore-file banners
export type RemoteName = keyof<typeof(REMOTES)>

-- // MODULE
local Network = {
	_Remotes = {} :: {[string]:RemoteEvent},
}

-- the remote with that name. Server: from the folder CreateRemotes made. Client: waits for it on first use
local function GetRemote(Name:RemoteName) : RemoteEvent
	const Cached = Network._Remotes[Name]

	if Cached then
		return Cached
	end

	const Folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	const Remote = Folder:WaitForChild(Name) :: RemoteEvent

	Network._Remotes[Name] = Remote

	return Remote
end

-- // METHODS
-- server only, called once by ServerLoader before the services load: makes the folder and every remote in it
function Network:CreateRemotes()
	assert(RunService:IsServer(), "[Network] CreateRemotes runs on the server only")

	if ReplicatedStorage:FindFirstChild(FOLDER_NAME) then
		return
	end

	const Folder = Instance.new("Folder")
	Folder.Name = FOLDER_NAME

	for Name in REMOTES do
		const Remote = Instance.new("RemoteEvent")
		Remote.Name = Name
		Remote.Parent = Folder

		Network._Remotes[Name] = Remote
	end

	-- parented last so a client never sees the folder half filled
	Folder.Parent = ReplicatedStorage
end

-- calls Callback each time the remote fires. On the server the first argument is the Player who sent it, and every
-- other argument is untrusted: check its type and its range before using it. Returns the connection, keep it
function Network:Listen(Name:RemoteName, Callback:(...any) -> ()) : RBXScriptConnection
	const Remote = GetRemote(Name)

	if RunService:IsServer() then
		return Remote.OnServerEvent:Connect(Callback)
	end

	return Remote.OnClientEvent:Connect(Callback)
end

-- client only: sends the arguments to the server
function Network:FireServer(Name:RemoteName, ...:any)
	GetRemote(Name):FireServer(...)
end

-- server only: sends the arguments to one player
function Network:FireClient(Name:RemoteName, Player:Player, ...:any)
	GetRemote(Name):FireClient(Player, ...)
end

-- server only: sends the arguments to every player
function Network:FireAllClients(Name:RemoteName, ...:any)
	GetRemote(Name):FireAllClients(...)
end

return Network
````

### `src/ReplicatedStorage/SharedModules/SessionTemplate.luau`

````lua
--!strict
-- the shape of a player's session data: replicated to the player like saved data, but never saved. It starts fresh
-- each time the player joins (a round score, a streak, a party). DataService fills JoinedAt itself

-- // TYPES
export type Data = {
	JoinedAt:number, -- os.time() this session started
	Streak:number, -- example value: things done in a row this session
}

-- // MODULE
-- the starting values. DataService copies them: never write to this table
const SessionTemplate:Data = {
	JoinedAt = 0,
	Streak = 0,
}

return SessionTemplate
````

### `src/ServerScriptService/ServerLoader.server.luau`

````lua
--!strict
-- the only server Script. Creates the remotes, requires every service in ServerScriptService.Services and calls its
-- hooks: Initialize, then Start, then the player and character hooks. A new system is a ModuleScript in that folder,
-- never a new Script

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const Loader = require(ReplicatedStorage.SharedModules.Loader)
const Network = require(ReplicatedStorage.SharedModules.Network)

-- boots every service and wires the player hooks
local function LoadServer()
	-- before any service loads, so a service can listen in Initialize and a client never waits on a missing remote
	Network:CreateRemotes()

	const Services = Loader:Collect(ServerScriptService.Services)

	Loader:CallAll(Services, "Initialize")
	Loader:CallAll(Services, "Start")

	-- connects before reading Player.Character so a spawn is never missed, and works when characters do not
	-- load on their own (CharacterAutoLoads off, a menu that spawns the player later)
	local function OnPlayerAdded(Player:Player)
		Loader:CallAll(Services, "OnPlayerAdded", Player)

		Player.CharacterAdded:Connect(function(Character:Model)
			Loader:CallAll(Services, "OnCharacterAdded", Player, Character)
		end)

		Player.CharacterRemoving:Connect(function(Character:Model)
			Loader:CallAll(Services, "OnCharacterRemoving", Player, Character)
		end)

		if Player.Character then
			Loader:CallAll(Services, "OnCharacterAdded", Player, Player.Character)
		end
	end

	Players.PlayerAdded:Connect(OnPlayerAdded)

	-- players who joined while the services were loading
	for _, Player in Players:GetPlayers() do
		task.spawn(OnPlayerAdded, Player)
	end

	Players.PlayerRemoving:Connect(function(Player:Player)
		Loader:CallAll(Services, "OnPlayerRemoving", Player)
	end)
end

LoadServer()
````

### `src/ServerScriptService/Services/DataService.luau`

````lua
--!strict
-- every player's data on the server. Saved data (DataTemplate) is a ProfileStore profile, session data
-- (SessionTemplate) lives only while the player is here, and each is mirrored to its player through a Replica.
-- read with GetValue / GetSessionValue, write ONLY through the setters (SetValue, Increment, SetValues, InsertInArray,
-- RemoveFromArray): they change the table and tell the client in one step. Writing Profile.Data directly saves but
-- never reaches the client.
-- a player is "loaded" once their data is on their client and ClientLoader has started every controller. Other
-- services wait for that with WaitForLoaded or WatchPlayerLoaded

-- // SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const ServerScriptService = game:GetService("ServerScriptService")

-- // CONTAINERS
const SharedModules = ReplicatedStorage.SharedModules

-- // MODULES
const DataConfig = require(SharedModules.DataConfig)
const DataPath = require(SharedModules.DataPath)
const DataTemplate = require(SharedModules.DataTemplate)
const Network = require(SharedModules.Network)
const SessionTemplate = require(SharedModules.SessionTemplate)

-- // TYPES
export type Path = DataPath.Path
export type DataSource = DataConfig.DataSource
export type MathOperation = "=" | "+" | "-" | "*" | "/"

-- the parts of a ProfileStore signal this service uses
type Signal = {
	Connect:(self:any, Listener:(...any) -> ()) -> any,
}

-- the parts of a ProfileStore profile this service uses
export type Profile = {
	Data:any,
	Key:string,
	OnSave:Signal,
	OnSessionEnd:Signal,
	IsActive:(self:any) -> boolean,
	Reconcile:(self:any) -> (),
	EndSession:(self:any) -> (),
	AddUserId:(self:any, UserId:number) -> (),
}

-- the parts of a ProfileStore store this service uses
type Store = {
	StartSessionAsync:(self:any, Key:string, Params:{Cancel:(() -> boolean)?}?) -> Profile?,
}

-- the parts of a server Replica this service uses
export type Replica = {
	Data:any,
	Set:(self:any, Path:{any}, Value:any) -> (),
	SetValues:(self:any, Path:{any}, Values:{[string]:any}) -> (),
	TableInsert:(self:any, Path:{any}, Value:any, Index:number?) -> number,
	TableRemove:(self:any, Path:{any}, Index:number) -> any,
	Subscribe:(self:any, Player:Player) -> (),
	Destroy:(self:any) -> (),
}

-- the packages, loaded on first use so requiring this module in Edit (unit tests) starts nothing
type Packages = {
	Store:Store,
	NewReplica:(Params:{Token:any, Tags:{[string]:any}, Data:{[any]:any}}) -> Replica,
	ReadyPlayers:{[Player]:boolean}, -- players whose client asked ReplicaClient for data
	NewReadyPlayer:Signal,
	ProfileToken:any,
	SessionToken:any,
}

-- a player's session: data that is replicated but never saved
export type Session = {
	StartedAt:number, -- os.time() the player joined
	Data:SessionTemplate.Data,
	Replica:Replica?, -- nil until the client asked for data
}

-- where a write goes: the data table, and the replica that mirrors it once there is one
type Target = {
	Data:any,
	Replica:Replica?,
}

export type SetParams = {
	Player:Player,
	Path:Path,
	Value:any,
	MathOperation:MathOperation?, -- "=" when nil. any other needs a number at Path and a number Value
	MinValue:number?, -- a number result is raised to at least this
	MaxValue:number?, -- a number result is lowered to at most this
	Source:DataSource?, -- "Profile" when nil
}

export type SetValuesParams = {
	Player:Player,
	Path:Path, -- a dictionary in the data
	Values:{[string]:any},
	Source:DataSource?,
}

export type InsertParams = {
	Player:Player,
	Path:Path, -- an array in the data
	Value:any,
	Index:number?, -- the end when nil
	Source:DataSource?,
}

export type RemoveParams = {
	Player:Player,
	Path:Path, -- an array in the data
	Index:number?, -- which entry to remove. give this or Value
	Value:any, -- the first entry equal to this is removed, when Index is nil
	Source:DataSource?,
}

export type LoadedWatcher = (Player:Player) -> ()

-- // VARIABLES
const STORE_NAME = "PlayerData_v1" -- the DataStore. A new name starts every player from the template
const KEY_PREFIX = "Player_" -- a profile's key is this and the UserId
const KICK_LOAD_FAILED = "Your data could not be loaded. Please rejoin."
const KICK_SESSION_ENDED = "Your data was opened on another server. Please rejoin."
const KICK_DATA_RESET = "Your data has been reset. Please rejoin."

-- what each MathOperation does to the value already there (Old) with the value given (Given)
const MATH_OPERATIONS = {
	["+"] = function(Old:number, Given:number) : number
		return Old + Given
	end,
	["-"] = function(Old:number, Given:number) : number
		return Old - Given
	end,
	["*"] = function(Old:number, Given:number) : number
		return Old * Given
	end,
	["/"] = function(Old:number, Given:number) : number
		return Old / Given
	end,
}

-- // MODULE
local DataService = {
	_Packages = nil :: Packages?,
	_Profiles = {} :: {[Player]:Profile},
	_Replicas = {} :: {[Player]:Replica},
	_Sessions = {} :: {[Player]:Session},
	_CountedAt = {} :: {[Player]:number}, -- os.time() play time was last added to TimePlayed
	_ClientReady = {} :: {[Player]:boolean},
	_Loaded = {} :: {Player},
	_Waiting = {} :: {[Player]:{thread}},
	_Watchers = {} :: {LoadedWatcher},
	_Connections = {} :: {any}, -- RBXScriptConnections and the packages' own connection objects
	-- what the service reaches for outside itself, so a test can swap them
	_Dependencies = {
		GetTime = os.time,
		IsInGame = function(Player:Player) : boolean
			return Player:IsDescendantOf(Players)
		end,
		IsRunning = function() : boolean
			return RunService:IsRunning()
		end,
		LoadPackages = nil :: (() -> Packages)?, -- nil: the real ProfileStore and ReplicaServer
	},
}

-- the real packages: ProfileStore (ReplicatedStorage.SharedPackages) and ReplicaServer
-- (ServerScriptService.ServerPackages), required here and not at the top so nothing starts in Edit
local function LoadRealPackages() : Packages
	const ProfileStore = require(ReplicatedStorage.SharedPackages.ProfileStore) :: any
	const ReplicaServer = require(ServerScriptService.ServerPackages.ReplicaServer) :: any

	ProfileStore.OnError:Connect(function(Message:string, StoreName:string, Key:string)
		warn(`[DataService] ProfileStore error in {StoreName}/{Key}: {Message}`)
	end)

	return {
		Store = ProfileStore.New(STORE_NAME, DataTemplate),
		NewReplica = ReplicaServer.New,
		ReadyPlayers = ReplicaServer.ReadyPlayers,
		NewReadyPlayer = ReplicaServer.NewReadyPlayer,
		ProfileToken = ReplicaServer.Token(DataConfig.PROFILE_TOKEN),
		SessionToken = ReplicaServer.Token(DataConfig.SESSION_TOKEN),
	}
end

-- the packages, loaded the first time they are needed
local function GetPackages() : Packages
	if DataService._Packages then
		return DataService._Packages
	end

	const Loader = DataService._Dependencies.LoadPackages or LoadRealPackages
	const Packages = Loader()

	DataService._Packages = Packages

	return Packages
end

-- where a write for Player goes, nil when that data is not there (not loaded yet, or the player left)
local function GetTarget(Player:Player, Source:DataSource?) : Target?
	if Source == "Session" then
		const Session = DataService._Sessions[Player]

		return if Session then { Data = Session.Data, Replica = Session.Replica } else nil
	end

	const Profile = DataService._Profiles[Player]

	if not Profile or not Profile:IsActive() then
		return nil
	end

	return { Data = Profile.Data, Replica = DataService._Replicas[Player] }
end

-- the table holding the last key of Path, and that key. nil when Path is not valid or its parent is not a table
local function GetParent(Data:any, Path:Path) : ({[any]:any}?, (string | number)?)
	if not DataPath:IsValid(Path) then
		return nil, nil
	end

	const ParentPath = table.move(Path, 1, #Path - 1, 1, {})
	const Parent = DataPath:Get(Data, ParentPath)

	if type(Parent) ~= "table" then
		return nil, nil
	end

	return Parent, Path[#Path]
end

-- sets Value at Path, through the replica when there is one so the client hears it. false when Path has no parent
local function WriteAt(Target:Target, Path:Path, Value:any) : boolean
	const Parent, Key = GetParent(Target.Data, Path)

	if not Parent or Key == nil then
		return false
	end

	if Target.Replica then
		Target.Replica:Set(Path :: {any}, Value)
	else
		Parent[Key] = Value
	end

	return true
end

-- the array at Path, nil when there is none
local function GetArray(Target:Target, Path:Path) : {any}?
	if not DataPath:IsValid(Path) then
		return nil
	end

	const Array = DataPath:Get(Target.Data, Path)

	return if type(Array) == "table" then Array else nil
end

-- the value SetValue writes: the operation applied, then the bounds. false (and why) when it cannot be worked out
local function ComputeValue(Old:any, Params:SetParams) : (boolean, any)
	const Operation = Params.MathOperation or "="
	local Result = Params.Value

	if Operation ~= "=" then
		const Apply = MATH_OPERATIONS[Operation]

		if not Apply then
			return false, `unknown MathOperation "{Operation}"`
		end

		if type(Old) ~= "number" or type(Params.Value) ~= "number" then
			return false, `"{Operation}" needs a number at the path and a number Value`
		end

		if Operation == "/" and Params.Value == 0 then
			return false, "division by zero"
		end

		Result = Apply(Old, Params.Value)
	end

	if type(Result) == "number" then
		if Result ~= Result then
			return false, "the result is not a number (NaN)"
		end

		if Params.MinValue then
			Result = math.max(Result, Params.MinValue)
		end

		if Params.MaxValue then
			Result = math.min(Result, Params.MaxValue)
		end
	end

	return true, Result
end

-- adds the time since play time was last counted to TimePlayed
local function CountTimePlayed(Player:Player)
	const CountedAt = DataService._CountedAt[Player]
	const Target = GetTarget(Player, "Profile")

	if not CountedAt or not Target then
		return
	end

	const Now = DataService._Dependencies.GetTime()
	const Played = DataPath:Get(Target.Data, { "TimeTrackers", "TimePlayed" })

	DataService._CountedAt[Player] = Now

	if type(Played) == "number" then
		WriteAt(Target, { "TimeTrackers", "TimePlayed" }, Played + (Now - CountedAt))
	end
end

-- stamps the join times when the profile has just loaded
local function StartTimeTracking(Player:Player, Profile:Profile)
	const Now = DataService._Dependencies.GetTime()
	const TimeTrackers = Profile.Data.TimeTrackers

	if TimeTrackers.FirstJoined == 0 then
		TimeTrackers.FirstJoined = Now
	end

	TimeTrackers.LastJoined = Now
	DataService._CountedAt[Player] = Now
end

-- wakes every thread waiting on Player's load with the answer
local function ResumeWaiting(Player:Player, Loaded:boolean)
	const Waiting = DataService._Waiting[Player]

	if not Waiting then
		return
	end

	DataService._Waiting[Player] = nil

	for _, Thread in Waiting do
		task.spawn(Thread, Loaded)
	end
end

-- marks Player loaded once their data is on their client and the client is ready. Spawns the character when the
-- game does not spawn characters on its own (Players.CharacterAutoLoads off)
local function TryFinishLoading(Player:Player)
	if table.find(DataService._Loaded, Player) then
		return
	end

	if not DataService._Replicas[Player] or not DataService._ClientReady[Player] then
		return
	end

	table.insert(DataService._Loaded, Player)

	if not Players.CharacterAutoLoads then
		task.spawn(function()
			const Success, Problem = pcall(Player.LoadCharacterAsync, Player)

			if not Success then
				warn(`[DataService] could not spawn {Player.Name}: {Problem}`)
			end
		end)
	end

	ResumeWaiting(Player, true)

	for _, Watcher in table.clone(DataService._Watchers) do
		task.spawn(Watcher, Player)
	end
end

-- creates Player's two replicas once their profile is loaded and their client has asked for data
local function TryReplicate(Player:Player)
	if DataService._Replicas[Player] then
		return
	end

	const Profile = DataService._Profiles[Player]
	const Session = DataService._Sessions[Player]
	const Packages = GetPackages()

	if not Profile or not Session or not Packages.ReadyPlayers[Player] then
		return
	end

	const Tags = { UserId = Player.UserId }
	const ProfileReplica = Packages.NewReplica({ Token = Packages.ProfileToken, Tags = Tags, Data = Profile.Data })
	const SessionReplica = Packages.NewReplica({ Token = Packages.SessionToken, Tags = Tags, Data = Session.Data })

	ProfileReplica:Subscribe(Player)
	SessionReplica:Subscribe(Player)

	DataService._Replicas[Player] = ProfileReplica
	Session.Replica = SessionReplica

	TryFinishLoading(Player)
end

-- forgets everything about Player and destroys their replicas. Their profile is ended by the caller
local function Forget(Player:Player)
	const Replica = DataService._Replicas[Player]
	const Session = DataService._Sessions[Player]
	const LoadedIndex = table.find(DataService._Loaded, Player)

	if Replica then
		Replica:Destroy()
	end

	if Session and Session.Replica then
		Session.Replica:Destroy()
	end

	if LoadedIndex then
		table.remove(DataService._Loaded, LoadedIndex)
	end

	DataService._Profiles[Player] = nil
	DataService._Replicas[Player] = nil
	DataService._Sessions[Player] = nil
	DataService._CountedAt[Player] = nil
	DataService._ClientReady[Player] = nil

	ResumeWaiting(Player, false)
end

-- // METHODS
-- Player's profile, nil until it has loaded or once they left. For ProfileStore features the setters do not cover
function DataService:GetProfile(Player:Player) : Profile?
	return DataService._Profiles[Player]
end

-- Player's saved-data replica, nil until their client has asked for data
function DataService:GetReplica(Player:Player) : Replica?
	return DataService._Replicas[Player]
end

-- Player's session, nil before they joined or once they left
function DataService:GetSession(Player:Player) : Session?
	return DataService._Sessions[Player]
end

-- Player's whole saved data, nil until it has loaded. Read it, never write to it: use the setters
function DataService:GetData(Player:Player) : DataTemplate.Data?
	const Target = GetTarget(Player, "Profile")

	return if Target then Target.Data :: DataTemplate.Data else nil
end

-- the saved value at Path ({"Settings", "MusicEnabled"}), nil when it is not there or not loaded
function DataService:GetValue(Player:Player, Path:Path) : any
	const Target = GetTarget(Player, "Profile")

	return if Target then DataPath:Get(Target.Data, Path) else nil
end

-- the session value at Path, nil when it is not there
function DataService:GetSessionValue(Player:Player, Path:Path) : any
	const Target = GetTarget(Player, "Session")

	return if Target then DataPath:Get(Target.Data, Path) else nil
end

-- sets the value at Path, optionally through a MathOperation and between MinValue and MaxValue (see SetParams).
-- false when the data is not loaded, the path has no parent, or the operation cannot apply
function DataService:SetValue(Params:SetParams) : boolean
	const Target = GetTarget(Params.Player, Params.Source)

	if not Target then
		return false
	end

	const Success, Result = ComputeValue(DataPath:Get(Target.Data, Params.Path), Params)

	if not Success then
		warn(`[DataService] SetValue {DataPath:ToText(Params.Path)} for {Params.Player.Name}: {Result}`)

		return false
	end

	return WriteAt(Target, Params.Path, Result)
end

-- adds Amount to the number at Path in saved data (negative to take away). false when there is no number there
function DataService:Increment(Player:Player, Path:Path, Amount:number) : boolean
	return DataService:SetValue({ Player = Player, Path = Path, Value = Amount, MathOperation = "+" })
end

-- sets several keys of the dictionary at Path in one replication. false when there is no dictionary there
function DataService:SetValues(Params:SetValuesParams) : boolean
	const Target = GetTarget(Params.Player, Params.Source)
	const Dictionary = if Target and DataPath:IsValid(Params.Path) then DataPath:Get(Target.Data, Params.Path) else nil

	if not Target or type(Dictionary) ~= "table" then
		return false
	end

	if Target.Replica then
		Target.Replica:SetValues(Params.Path :: {any}, Params.Values)
	else
		for Key, Value in Params.Values do
			Dictionary[Key] = Value
		end
	end

	return true
end

-- inserts Value into the array at Path, at Index or at the end. The index it landed at, nil when there is no array
function DataService:InsertInArray(Params:InsertParams) : number?
	const Target = GetTarget(Params.Player, Params.Source)
	const Array = if Target then GetArray(Target, Params.Path) else nil

	if not Target or not Array then
		return nil
	end

	if Params.Index and (Params.Index < 1 or Params.Index > #Array + 1) then
		return nil
	end

	if Target.Replica then
		return Target.Replica:TableInsert(Params.Path :: {any}, Params.Value, Params.Index)
	end

	const Index = Params.Index or #Array + 1
	table.insert(Array, Index, Params.Value)

	return Index
end

-- removes one entry from the array at Path: the one at Index, or the first equal to Value. The removed value, nil
-- when there is no array or no such entry
function DataService:RemoveFromArray(Params:RemoveParams) : any
	const Target = GetTarget(Params.Player, Params.Source)
	const Array = if Target then GetArray(Target, Params.Path) else nil

	if not Target or not Array then
		return nil
	end

	const Index = Params.Index or table.find(Array, Params.Value)

	if not Index or Array[Index] == nil then
		return nil
	end

	if Target.Replica then
		return Target.Replica:TableRemove(Params.Path :: {any}, Index)
	end

	return table.remove(Array, Index)
end

-- puts Player's saved data back to the template and kicks them, so they rejoin with it. false when not loaded
function DataService:ResetData(Player:Player) : boolean
	const Profile = DataService._Profiles[Player]

	if not Profile or not Profile:IsActive() then
		return false
	end

	-- in place: the replica and the profile keep pointing at the same table, and the kick saves it
	table.clear(Profile.Data)

	for Key, Value in DataPath:DeepCopy(DataTemplate) :: any do
		Profile.Data[Key] = Value
	end

	Player:Kick(KICK_DATA_RESET)

	return true
end

-- true once Player's data is on their client and their client is ready
function DataService:IsPlayerLoaded(Player:Player) : boolean
	return table.find(DataService._Loaded, Player) ~= nil
end

-- a copy of the list of loaded players
function DataService:GetLoadedPlayers() : {Player}
	return table.clone(DataService._Loaded)
end

-- waits until Player is loaded. true when they are, false when they left first (or right away, if not in game)
function DataService:WaitForLoaded(Player:Player) : boolean
	if DataService:IsPlayerLoaded(Player) then
		return true
	end

	if not DataService._Dependencies.IsInGame(Player) then
		return false
	end

	const Waiting = DataService._Waiting[Player] or {}
	DataService._Waiting[Player] = Waiting
	table.insert(Waiting, coroutine.running())

	return coroutine.yield()
end

-- calls Watcher for every player who loads from now on, and right away for those already loaded.
-- returns the function that stops it, keep it
function DataService:WatchPlayerLoaded(Watcher:LoadedWatcher) : () -> ()
	table.insert(DataService._Watchers, Watcher)

	for _, Player in table.clone(DataService._Loaded) do
		task.spawn(Watcher, Player)
	end

	return function()
		const Index = table.find(DataService._Watchers, Watcher)

		if Index then
			table.remove(DataService._Watchers, Index)
		end
	end
end

-- the ClientReady remote: Player's client has started every controller. Counted once
function DataService:_MarkClientReady(Player:Player)
	if DataService._ClientReady[Player] then
		return
	end

	DataService._ClientReady[Player] = true
	TryFinishLoading(Player)
end

-- loader hook: listens for clients asking for their data and for ready clients. Outside a running game it does
-- nothing, unless a test gave it fake packages (then it skips only the remote)
function DataService:Initialize()
	const Running = DataService._Dependencies.IsRunning()

	if not Running and not DataService._Dependencies.LoadPackages then
		return
	end

	table.insert(DataService._Connections, GetPackages().NewReadyPlayer:Connect(TryReplicate))

	if not Running then
		return
	end

	table.insert(DataService._Connections, Network:Listen("ClientReady", function(Player:Player)
		DataService:_MarkClientReady(Player)
	end))
end

-- loader hook: starts the session, then loads the profile (this yields until ProfileStore answers)
function DataService:OnPlayerAdded(Player:Player)
	const Now = DataService._Dependencies.GetTime()
	const SessionData = DataPath:DeepCopy(SessionTemplate)
	SessionData.JoinedAt = Now

	DataService._Sessions[Player] = { StartedAt = Now, Data = SessionData, Replica = nil }

	const Profile = GetPackages().Store:StartSessionAsync(`{KEY_PREFIX}{Player.UserId}`, {
		-- stop retrying once the player is gone
		Cancel = function() : boolean
			return not DataService._Dependencies.IsInGame(Player)
		end,
	})

	if not Profile then
		if DataService._Dependencies.IsInGame(Player) then
			Player:Kick(KICK_LOAD_FAILED)
		end

		return
	end

	if not DataService._Dependencies.IsInGame(Player) then
		Profile:EndSession()

		return
	end

	Profile:AddUserId(Player.UserId) -- GDPR: ties the data to the user for erasure requests
	Profile:Reconcile() -- fills in keys added to DataTemplate since this profile last saved

	Profile.OnSave:Connect(function()
		CountTimePlayed(Player)
	end)

	-- another server took the profile, or it ended: the player can't keep playing without saving
	Profile.OnSessionEnd:Connect(function()
		if DataService._Profiles[Player] ~= Profile then
			return
		end

		Forget(Player)

		if DataService._Dependencies.IsInGame(Player) then
			Player:Kick(KICK_SESSION_ENDED)
		end
	end)

	DataService._Profiles[Player] = Profile
	StartTimeTracking(Player, Profile)
	TryReplicate(Player)
end

-- loader hook: counts the last play time, ends the profile (which saves it) and forgets the player
function DataService:OnPlayerRemoving(Player:Player)
	const Profile = DataService._Profiles[Player]

	CountTimePlayed(Player)
	Forget(Player)

	if Profile then
		Profile:EndSession()
	end
end

return DataService
````

### `src/ServerScriptService/Services/ExampleService/ExampleChild.luau`

````lua
--!strict
-- one kind of thing ExampleService runs, server half. Its name is its id: ExampleService finds it by name and
-- requires it the first time it is asked for. It may require its parent (script.Parent) safely, because the parent
-- only requires it later, from inside a function

-- // VARIABLES
const COOLDOWN = 2 -- seconds between two runs for the same player

-- // MODULE
local ExampleChild = {
	_LastRun = {} :: {[Player]:number},
}

-- // METHODS
-- does the work for Owner. false while Owner is still on cooldown
function ExampleChild:Run(Owner:Player) : boolean
	const Now = os.clock()
	const LastRun = ExampleChild._LastRun[Owner]

	if LastRun and Now - LastRun < COOLDOWN then
		return false
	end

	ExampleChild._LastRun[Owner] = Now
	print(`[ExampleChild] ran for {Owner.Name}`)

	return true
end

-- forgets Owner's cooldown (the player left)
function ExampleChild:Forget(Owner:Player)
	ExampleChild._LastRun[Owner] = nil
end

return ExampleChild
````

### `src/ServerScriptService/Services/ExampleService/init.luau`

````lua
--!strict
-- template for the server half of a system: copy the folder, rename it (and its children), delete what you don't use.
-- it owns the system's server rules. Each kind of thing the system runs is a child module named after its id
-- (ExampleChild.luau), required the first time it is asked for, so a game with many kinds only loads the ones used.
-- clients ask through the ExampleRequest remote; other services call ExampleService:Run directly

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const ExampleConfig = require(ReplicatedStorage.SharedModules.ExampleConfig)
const Network = require(ReplicatedStorage.SharedModules.Network)

-- // TYPES
-- the shape every child module must return. Run is required, the rest is optional
export type ServerChild = {
	-- does the child's work for Owner. false when it refuses
	Run:(self:ServerChild, Owner:Player) -> boolean,
	-- forgets anything it keeps for Owner (the player left)
	Forget:((self:ServerChild, Owner:Player) -> ())?,
}

export type ReplyKind = ExampleConfig.ReplyKind

-- how many requests a player sent in one whole second of the clock
type RequestRate = {
	Second:number,
	Count:number,
}

-- // VARIABLES
const REQUESTS_PER_SECOND = 5 -- requests one player may send each second, the rest are dropped

-- // MODULE
local ExampleService = {
	_Holder = script :: Instance, -- where the child modules are. a test puts its own folder here
	_Children = {} :: {[string]:ServerChild},
	_Failed = {} :: {[string]:boolean}, -- ids whose module failed to load: not tried again
	_Requests = {} :: {[Player]:RequestRate},
	_Connections = {} :: {RBXScriptConnection},
	-- what the service reaches for outside itself, so a test can swap them
	_Dependencies = {
		GetTime = os.clock,
	},
}

-- the child with that id, required on first use. nil when there is none, it failed to load, or it has no Run
local function GetChild(ChildId:string) : ServerChild?
	const Loaded = ExampleService._Children[ChildId]

	if Loaded then
		return Loaded
	end

	if ExampleService._Failed[ChildId] then
		return nil
	end

	const Module = ExampleService._Holder:FindFirstChild(ChildId)

	if not Module or not Module:IsA("ModuleScript") then
		return nil
	end

	const Success, Result = pcall(require, Module)

	if not Success or type(Result) ~= "table" or type(Result.Run) ~= "function" then
		ExampleService._Failed[ChildId] = true
		warn(`[ExampleService] the child "{ChildId}" failed to load: {if Success then "it has no Run function" else Result}`)

		return nil
	end

	const Child = Result :: ServerChild
	ExampleService._Children[ChildId] = Child

	return Child
end

-- true while Owner is under the request limit this second, and counts this request
local function TakeRequest(Owner:Player) : boolean
	const Second = math.floor(ExampleService._Dependencies.GetTime())
	local Rate = ExampleService._Requests[Owner]

	if not Rate or Rate.Second ~= Second then
		Rate = { Second = Second, Count = 0 }
		ExampleService._Requests[Owner] = Rate
	end

	Rate.Count += 1

	return Rate.Count <= REQUESTS_PER_SECOND
end

-- one request from a client. Everything it sent is checked before use: the types guarantee nothing over the network
local function HandleRequest(Owner:Player, ChildId:any)
	if not TakeRequest(Owner) then
		return
	end

	if not ExampleConfig:IsChildId(ChildId) then
		return
	end

	const Reply:ReplyKind = if ExampleService:Run(Owner, ChildId) then "Done" else "Refused"

	Network:FireClient("ExampleReply", Owner, ChildId, Reply)
end

-- // METHODS
-- runs the child with that id for Owner. false when there is no such child or it refused
function ExampleService:Run(Owner:Player, ChildId:string) : boolean
	const Child = GetChild(ChildId)

	if not Child then
		return false
	end

	return Child:Run(Owner)
end

-- loader hook: listens for requests
function ExampleService:Initialize()
	table.insert(ExampleService._Connections, Network:Listen("ExampleRequest", HandleRequest))
end

-- loader hook: forgets the player everywhere, children included
function ExampleService:OnPlayerRemoving(Player:Player)
	ExampleService._Requests[Player] = nil

	for _, Child in ExampleService._Children do
		if Child.Forget then
			Child:Forget(Player)
		end
	end
end

return ExampleService
````

### `src/ServerStorage/Tests/DataController.spec.luau`

````lua
--!strict
-- DataController with a fake ReplicaClient: waiting for the data, the getters, and every kind of watch

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const DataPath = require(ReplicatedStorage.SharedModules.DataPath)
const DataTemplate = require(ReplicatedStorage.SharedModules.DataTemplate)
const TestRunner = require(script.Parent.TestRunner)

-- // TYPES
type Check = TestRunner.Check

-- what a test gets back from Setup
type World = {
	Controller:any,
	Profile:any, -- the fake profile replica
	Session:any, -- the fake session replica
	Deliver:() -> (), -- sends both replicas to the controller, as the server does once data is requested
}

-- // VARIABLES
const DATA_CONTROLLER = ReplicatedStorage.Controllers.DataController :: ModuleScript
const USER_ID = 42

-- a client replica: Fire changes nothing by itself, the test changes Data then calls Fire like ReplicaClient does
local function NewReplica(Data:any, UserId:number) : any
	const Replica = { Data = Data, Tags = { UserId = UserId }, Listeners = {} } :: any

	-- adds a change listener. returns its connection
	function Replica:OnChange(Listener:(...any) -> ()) : any
		table.insert(Replica.Listeners, Listener)

		return {
			Disconnect = function()
				table.remove(Replica.Listeners, table.find(Replica.Listeners, Listener))
			end,
		}
	end

	-- tells every listener about one change
	function Replica:Fire(Action:string, Path:{any}, Param1:any, Param2:any)
		for _, Listener in table.clone(Replica.Listeners) do
			Listener(Action, Path, Param1, Param2)
		end
	end

	-- sets Value at Path and fires Set with the old value, like ReplicaClient
	function Replica:DoSet(Path:{any}, Value:any)
		const Parent = DataPath:Get(Replica.Data, table.move(Path, 1, #Path - 1, 1, {}))
		const Old = Parent[Path[#Path]]
		Parent[Path[#Path]] = Value
		Replica:Fire("Set", Path, Value, Old)
	end

	return Replica
end

-- a fresh DataController with a fake ReplicaClient. Data is only sent when the test calls Deliver
local function Setup(Check:Check) : World
	const Controller = Check:Fresh(DATA_CONTROLLER)
	const Profile = NewReplica(DataPath:DeepCopy(DataTemplate), USER_ID)
	const Session = NewReplica({ JoinedAt = 1, Streak = 0 }, USER_ID)
	const Listeners = {} :: {[string]:{(Replica:any) -> ()}}

	const Fake = {
		OnNew = function(Token:string, Listener:(Replica:any) -> ()) : any
			Listeners[Token] = Listeners[Token] or {}
			table.insert(Listeners[Token], Listener)

			return { Disconnect = function() end }
		end,
		RequestData = function() end,
	}

	Controller._Dependencies.LoadReplicaClient = function() : any
		return Fake
	end
	Controller._Dependencies.UserId = function() : number
		return USER_ID
	end
	Controller._Dependencies.IsRunning = function() : boolean
		return true
	end

	-- another player's replica first: the controller must ignore it
	local function Deliver()
		for _, Listener in Listeners.PlayerData or {} do
			Listener(NewReplica({ Coins = 999 }, USER_ID + 1))
			Listener(Profile)
		end

		for _, Listener in Listeners.PlayerSession or {} do
			Listener(Session)
		end
	end

	return { Controller = Controller, Profile = Profile, Session = Session, Deliver = Deliver }
end

-- // MODULE
return {
	-- Initialize waits for the data; WaitForData callers wake when it lands
	InitializeWaitsForData = function(Check:Check)
		const W = Setup(Check)
		local Finished = false
		local WaitResult = nil :: boolean?

		task.spawn(function()
			W.Controller:Initialize()
			Finished = true
		end)
		task.spawn(function()
			WaitResult = W.Controller:WaitForData()
		end)

		Check:True(not Finished, "Initialize still waiting")
		Check:True(not W.Controller:IsLoaded(), "not loaded")
		Check:Equal(W.Controller:GetValue({ "Coins" }), nil, "no value before data")

		W.Deliver()

		Check:True(Finished, "Initialize returned")
		Check:Equal(WaitResult, true, "waiter woke with true")
		Check:Equal(W.Controller:GetValue({ "Coins" }), 0, "own data, not the other player's")
		Check:Equal(W.Controller:GetSessionValue({ "JoinedAt" }), 1, "session value")
		Check:Equal(W.Controller:GetData(), W.Profile.Data, "GetData")
	end,

	-- a watch added before the data arrives starts when it does: Observe is called, Watch only remembers
	WatchesBeforeData = function(Check:Check)
		const W = Setup(Check)
		const Observed = {} :: {any}
		const Watched = {} :: {any}

		W.Controller:ObserveValue({ "Coins" }, function(Value:any)
			table.insert(Observed, Value)
		end)
		W.Controller:WatchValue({ "Coins" }, function(Value:any)
			table.insert(Watched, Value)
		end)

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()
		Check:Equal(Observed[1], 0, "observe called with the arrived value")
		Check:Equal(#Watched, 0, "watch not called on arrival")

		W.Profile:DoSet({ "Coins" }, 5)
		Check:Equal(Observed[2], 5, "observe on change")
		Check:Equal(Watched[1], 5, "watch on change")
	end,

	-- old values for plain values, nil for tables; a change inside a table reaches its watcher; unrelated paths do not
	ValueWatches = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {string}

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		W.Controller:WatchValue({ "Settings", "MusicEnabled" }, function(Value:any, Old:any)
			table.insert(Log, `Music {Value} {Old}`)
		end)
		W.Controller:WatchValue({ "Settings" }, function(Value:any, Old:any)
			table.insert(Log, `Settings {type(Value)} {Old}`)
		end)

		W.Profile:DoSet({ "Settings", "MusicEnabled" }, false)
		W.Profile:DoSet({ "Coins" }, 3)
		-- SetValues on the parent with the same value: the child watch hears nothing new
		W.Profile:Fire("SetValues", { "Settings" }, { MusicEnabled = false })

		Check:Equal(table.concat(Log, ","), "Music false true,Settings table nil,Settings table nil", "log")
	end,

	-- array watches get the value and index, only for their own array
	ArrayWatches = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {string}

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		W.Controller:WatchArrayInsert({ "Inventory" }, function(Value:any, Index:number)
			table.insert(Log, `+{Value}@{Index}`)
		end)
		W.Controller:WatchArrayRemove({ "Inventory" }, function(Value:any, Index:number)
			table.insert(Log, `-{Value}@{Index}`)
		end)

		W.Profile:Fire("TableInsert", { "Inventory" }, "Sword", 1)
		W.Profile:Fire("TableInsert", { "Other" }, "Nope", 1)
		W.Profile:Fire("TableRemove", { "Inventory" }, "Sword", 1)

		Check:Equal(table.concat(Log, ","), "+Sword@1,-Sword@1", "log")
	end,

	-- AnyChange hears everything until stopped; a stopped watch is never called again
	AnyChangeAndStop = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {string}

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		const Stop = W.Controller:WatchAnyChange(function(Action:string, Path:{any})
			table.insert(Log, `{Action} {table.concat(Path, ".")}`)
		end)

		W.Profile:DoSet({ "Coins" }, 1)
		W.Profile:Fire("TableInsert", { "Inventory" }, "A", 1)
		Stop()
		W.Profile:DoSet({ "Coins" }, 2)

		Check:Equal(table.concat(Log, ","), "Set Coins,TableInsert Inventory", "log")
	end,

	-- session watches follow the session replica only
	SessionWatches = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {any}

		W.Controller:ObserveSessionValue({ "Streak" }, function(Value:any)
			table.insert(Log, Value)
		end)

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()
		W.Session:DoSet({ "Streak" }, 4)
		W.Profile:DoSet({ "Coins" }, 9)

		Check:Equal(table.concat(Log, ","), "0,4", "log")
	end,

	-- a watch whose callback errors stops no other watch
	ErroringWatcher = function(Check:Check)
		const W = Setup(Check)
		local Reached = false

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		W.Controller:WatchValue({ "Coins" }, function()
			error("watcher failure, expected by the test")
		end)
		W.Controller:WatchValue({ "Coins" }, function()
			Reached = true
		end)

		W.Profile:DoSet({ "Coins" }, 1)
		Check:True(Reached, "second watcher still called")
	end,
} :: TestRunner.Spec
````

### `src/ServerStorage/Tests/DataPath.spec.luau`

````lua
--!strict
-- DataPath: reading, comparing and checking paths

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const DataPath = require(ReplicatedStorage.SharedModules.DataPath)
const TestRunner = require(script.Parent.TestRunner)

type Check = TestRunner.Check

-- // MODULE
return {
	-- nested reads, missing keys, numbers as keys, a non-table on the way
	Get = function(Check:Check)
		const Data = { A = { B = { 10, 20 } }, Flat = 5 }

		Check:Equal(DataPath:Get(Data, { "A", "B", 2 }), 20, "nested index")
		Check:Equal(DataPath:Get(Data, { "A", "Missing", 1 }), nil, "missing key")
		Check:Equal(DataPath:Get(Data, { "Flat", "Deeper" }), nil, "through a number")
		Check:Equal(DataPath:Get(Data, {}), Data, "empty path is the data")
		Check:Equal(DataPath:Get(nil, { "A" }), nil, "nil data")
	end,

	-- prefixes overlap both ways, siblings do not
	Overlaps = function(Check:Check)
		Check:True(DataPath:Overlaps({ "A" }, { "A", "B" }), "parent and child")
		Check:True(DataPath:Overlaps({ "A", "B" }, { "A" }), "child and parent")
		Check:True(DataPath:Overlaps({ "A", "B" }, { "A", "B" }), "equal")
		Check:True(not DataPath:Overlaps({ "A", "B" }, { "A", "C" }), "siblings")
		Check:True(DataPath:Equals({ "A", 1 }, { "A", 1 }), "equals")
		Check:True(not DataPath:Equals({ "A" }, { "A", 1 }), "prefix is not equal")
	end,

	-- only non-empty arrays of strings and whole numbers
	IsValid = function(Check:Check)
		Check:True(DataPath:IsValid({ "A", 2 }), "strings and integers")
		Check:True(not DataPath:IsValid({}), "empty")
		Check:True(not DataPath:IsValid({ "A", 1.5 }), "fraction")
		Check:True(not DataPath:IsValid({ "A", true }), "boolean")
		Check:True(not DataPath:IsValid("A"), "not a table")
	end,

	-- a deep copy shares no table with the original
	DeepCopy = function(Check:Check)
		const Original = { A = { B = 1 } }
		const Copy = DataPath:DeepCopy(Original)

		Check:True(Copy ~= Original and Copy.A ~= Original.A, "new tables")
		Check:Equal(Copy.A.B, 1, "same values")
	end,
} :: TestRunner.Spec
````

### `src/ServerStorage/Tests/DataService.spec.luau`

````lua
--!strict
-- DataService with a fake ProfileStore, fake replicas and fake players: loading, the setters' rules, replication,
-- play time, and what happens when a session ends or the player leaves

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- // MODULES
const DataPath = require(ReplicatedStorage.SharedModules.DataPath)
const DataTemplate = require(ReplicatedStorage.SharedModules.DataTemplate)
const TestRunner = require(script.Parent.TestRunner)

-- // TYPES
type Check = TestRunner.Check

-- a stand-in for a ProfileStore or Replica signal
type FakeSignal = {
	Listeners:{(...any) -> ()},
	Connect:(self:FakeSignal, Listener:(...any) -> ()) -> {Disconnect:() -> ()},
	Fire:(self:FakeSignal, ...any) -> (),
}

type SetupOptions = {
	ClientReady:boolean?, -- false: the client has not said it is ready yet
	ReplicaReady:boolean?, -- false: the client has not asked for data yet
	LoadFails:boolean?, -- true: ProfileStore gives no profile
}

-- what a test gets back from Setup
type World = {
	Service:any,
	Player:any,
	Profile:any,
	Replicas:{any},
	Packages:any,
	Clock:{Now:number},
	InGame:{[any]:boolean},
	Kicked:{string},
}

-- // VARIABLES
const DATA_SERVICE = ServerScriptService.Services.DataService :: ModuleScript

-- a signal whose Fire calls every listener in order
local function NewSignal() : FakeSignal
	const Signal = { Listeners = {} } :: any

	-- adds a listener. returns its connection
	function Signal:Connect(Listener:(...any) -> ()) : {Disconnect:() -> ()}
		table.insert(Signal.Listeners, Listener)

		return {
			Disconnect = function()
				const Index = table.find(Signal.Listeners, Listener)

				if Index then
					table.remove(Signal.Listeners, Index)
				end
			end,
		}
	end

	-- calls every listener with the arguments
	function Signal:Fire(...:any)
		for _, Listener in table.clone(Signal.Listeners) do
			Listener(...)
		end
	end

	return Signal
end

-- a replica that changes its Data like the real one and remembers every call. Added to Log
local function NewReplica(Params:any, Log:{any}) : any
	const Replica = { Data = Params.Data, Token = Params.Token, Calls = {}, Subscribed = {}, Destroyed = false } :: any

	-- the table holding the last key of Path
	local function Parent(Path:{any}) : any
		return DataPath:Get(Replica.Data, table.move(Path, 1, #Path - 1, 1, {}))
	end

	-- sets the value at Path
	function Replica:Set(Path:{any}, Value:any)
		table.insert(Replica.Calls, "Set")
		Parent(Path)[Path[#Path]] = Value
	end

	-- sets keys of the dictionary at Path
	function Replica:SetValues(Path:{any}, Values:{[string]:any})
		table.insert(Replica.Calls, "SetValues")
		const Target = DataPath:Get(Replica.Data, Path)

		for Key, Value in Values do
			Target[Key] = Value
		end
	end

	-- inserts into the array at Path. returns the index
	function Replica:TableInsert(Path:{any}, Value:any, Index:number?) : number
		table.insert(Replica.Calls, "TableInsert")
		const Array = DataPath:Get(Replica.Data, Path)
		const At = Index or #Array + 1
		table.insert(Array, At, Value)

		return At
	end

	-- removes from the array at Path. returns the removed value
	function Replica:TableRemove(Path:{any}, Index:number) : any
		table.insert(Replica.Calls, "TableRemove")

		return table.remove(DataPath:Get(Replica.Data, Path), Index)
	end

	-- remembers who it was sent to
	function Replica:Subscribe(Player:any)
		table.insert(Replica.Subscribed, Player)
	end

	-- marks it destroyed
	function Replica:Destroy()
		Replica.Destroyed = true
	end

	table.insert(Log, Replica)

	return Replica
end

-- a profile holding a copy of the template. EndSession fires OnSessionEnd like the real one
local function NewProfile() : any
	const Profile = {
		Data = DataPath:DeepCopy(DataTemplate),
		Key = "",
		Active = true,
		Ended = 0,
		OnSave = NewSignal(),
		OnSessionEnd = NewSignal(),
	} :: any

	-- true until the session ended
	function Profile:IsActive() : boolean
		return Profile.Active
	end

	-- nothing to fill in: the data is already the template
	function Profile:Reconcile() end

	-- not needed by the tests
	function Profile:AddUserId(_UserId:number) end

	-- ends the session and tells the listeners
	function Profile:EndSession()
		Profile.Active = false
		Profile.Ended += 1
		Profile.OnSessionEnd:Fire()
	end

	return Profile
end

-- a fresh DataService wired to fakes, initialized
local function Setup(Check:Check, Options:SetupOptions?) : World
	const Opts = Options or {}
	const Service = Check:Fresh(DATA_SERVICE)
	const Kicked = {} :: {string}
	const Player = {
		Name = "Tester",
		UserId = 42,
		Kick = function(_Self:any, Message:string)
			table.insert(Kicked, Message)
		end,
	} :: any
	const Profile = NewProfile()
	const Replicas = {} :: {any}
	const Clock = { Now = 1000 }
	const InGame = { [Player] = true } :: {[any]:boolean}

	const Packages = {
		Store = {
			StartSessionAsync = function(_Self:any, Key:string, _Params:any) : any
				Profile.Key = Key

				return if Opts.LoadFails then nil else Profile
			end,
		},
		NewReplica = function(Params:any) : any
			return NewReplica(Params, Replicas)
		end,
		ReadyPlayers = {} :: {[any]:boolean},
		NewReadyPlayer = NewSignal(),
		ProfileToken = "ProfileToken",
		SessionToken = "SessionToken",
	}

	if Opts.ReplicaReady ~= false then
		Packages.ReadyPlayers[Player] = true
	end

	Service._Dependencies.LoadPackages = function() : any
		return Packages
	end
	Service._Dependencies.GetTime = function() : number
		return Clock.Now
	end
	Service._Dependencies.IsInGame = function(Target:any) : boolean
		return InGame[Target] == true
	end
	Service._Dependencies.IsRunning = function() : boolean
		return false
	end

	Service:Initialize()

	if Opts.ClientReady ~= false then
		Service:_MarkClientReady(Player)
	end

	return {
		Service = Service,
		Player = Player,
		Profile = Profile,
		Replicas = Replicas,
		Packages = Packages,
		Clock = Clock,
		InGame = InGame,
		Kicked = Kicked,
	}
end

-- // MODULE
return {
	-- a ready client gets both replicas, subscribed, and is marked loaded
	LoadsAndReplicates = function(Check:Check)
		const W = Setup(Check)

		W.Service:OnPlayerAdded(W.Player)

		Check:Equal(W.Profile.Key, "Player_42", "profile key")
		Check:Equal(#W.Replicas, 2, "two replicas")
		Check:Equal(W.Replicas[1].Token, "ProfileToken", "first is the profile replica")
		Check:Equal(W.Replicas[1].Data, W.Profile.Data, "profile replica shares the profile's table")
		Check:Equal(W.Replicas[1].Subscribed[1], W.Player, "profile replica subscribed")
		Check:Equal(W.Replicas[2].Subscribed[1], W.Player, "session replica subscribed")
		Check:True(W.Service:IsPlayerLoaded(W.Player), "loaded")
		Check:Equal(W.Profile.Data.TimeTrackers.FirstJoined, 1000, "first joined stamped")
		Check:Equal(W.Profile.Data.TimeTrackers.LastJoined, 1000, "last joined stamped")
		Check:Equal(W.Service:GetSessionValue(W.Player, { "JoinedAt" }), 1000, "session joined at")
	end,

	-- no replica until the client asked for data; both appear the moment it asks
	WaitsForReplicaReady = function(Check:Check)
		const W = Setup(Check, { ReplicaReady = false })

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Replicas, 0, "no replica before the client asked")
		Check:True(not W.Service:IsPlayerLoaded(W.Player), "not loaded before the client asked")

		W.Packages.ReadyPlayers[W.Player] = true
		W.Packages.NewReadyPlayer:Fire(W.Player)
		Check:Equal(#W.Replicas, 2, "replicated once it asked")
		Check:True(W.Service:IsPlayerLoaded(W.Player), "loaded once it asked")

		W.Packages.NewReadyPlayer:Fire(W.Player)
		Check:Equal(#W.Replicas, 2, "a second ready makes no new replicas")
	end,

	-- the client asking for data before the profile loaded: replicated when the profile arrives
	ReplicaReadyBeforeProfile = function(Check:Check)
		const W = Setup(Check, { ReplicaReady = false })

		W.Packages.ReadyPlayers[W.Player] = true
		W.Packages.NewReadyPlayer:Fire(W.Player)
		Check:Equal(#W.Replicas, 0, "nothing to replicate yet")

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Replicas, 2, "replicated when the profile loaded")
	end,

	-- not loaded until the client says it is ready, even with the data replicated
	WaitsForClientReady = function(Check:Check)
		const W = Setup(Check, { ClientReady = false })

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Replicas, 2, "replicated")
		Check:True(not W.Service:IsPlayerLoaded(W.Player), "not loaded before ClientReady")

		W.Service:_MarkClientReady(W.Player)
		Check:True(W.Service:IsPlayerLoaded(W.Player), "loaded after ClientReady")
	end,

	-- a failed load kicks a player still here, and leaves alone one who left
	LoadFailureKicks = function(Check:Check)
		const W = Setup(Check, { LoadFails = true })

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Kicked, 1, "kicked")
		Check:Equal(W.Service:GetData(W.Player), nil, "no data")

		const Gone = Setup(Check, { LoadFails = true })
		Gone.InGame[Gone.Player] = nil
		Gone.Service:OnPlayerAdded(Gone.Player)
		Check:Equal(#Gone.Kicked, 0, "not kicked after leaving")
	end,

	-- a player who left during the load gets their profile ended at once
	LeftDuringLoad = function(Check:Check)
		const W = Setup(Check)

		W.Packages.Store.StartSessionAsync = function(_Self:any, _Key:string, _Params:any) : any
			W.InGame[W.Player] = nil

			return W.Profile
		end

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(W.Profile.Ended, 1, "profile ended")
		Check:Equal(W.Service:GetProfile(W.Player), nil, "not kept")
		Check:Equal(#W.Replicas, 0, "not replicated")
	end,

	-- operations, bounds, a zero old value, and every refusal
	SetValueRules = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		Check:True(S:SetValue({ Player = P, Path = { "Coins" }, Value = 10, MathOperation = "+" }), "+ on 0")
		Check:Equal(S:GetValue(P, { "Coins" }), 10, "0 + 10")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 3, MathOperation = "*" })
		Check:Equal(S:GetValue(P, { "Coins" }), 30, "10 * 3")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 100, MathOperation = "-", MinValue = 0 })
		Check:Equal(S:GetValue(P, { "Coins" }), 0, "raised to MinValue")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 999, MaxValue = 50 })
		Check:Equal(S:GetValue(P, { "Coins" }), 50, "= lowered to MaxValue")
		Check:True(S:Increment(P, { "Coins" }, -20), "increment")
		Check:Equal(S:GetValue(P, { "Coins" }), 30, "50 - 20")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 4, MathOperation = "/" })
		Check:Equal(S:GetValue(P, { "Coins" }), 7.5, "30 / 4")

		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = 0, MathOperation = "/" }), "division by zero")
		Check:True(not S:SetValue({ Player = P, Path = { "Settings" }, Value = 1, MathOperation = "+" }), "+ on a table")
		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = "x", MathOperation = "+" }), "+ with a string")
		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = 1, MathOperation = "^" :: any }), "unknown operation")
		Check:True(not S:SetValue({ Player = P, Path = { "Missing", "Key" }, Value = 1 }), "no parent")
		Check:True(not S:SetValue({ Player = P, Path = {}, Value = 1 }), "empty path")
		Check:Equal(S:GetValue(P, { "Coins" }), 7.5, "refusals changed nothing")
	end,

	-- every setter refuses for a player with no data
	NotLoadedRefuses = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = 1 }), "SetValue")
		Check:True(not S:Increment(P, { "Coins" }, 1), "Increment")
		Check:True(not S:SetValues({ Player = P, Path = { "Settings" }, Values = {} }), "SetValues")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = 1 }), nil, "InsertInArray")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Index = 1 }), nil, "RemoveFromArray")
		Check:Equal(S:GetValue(P, { "Coins" }), nil, "GetValue")
		Check:True(not S:ResetData(P), "ResetData")
	end,

	-- writes go straight to the table before the replica exists, through it after
	WritesUseReplica = function(Check:Check)
		const W = Setup(Check, { ReplicaReady = false })
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 5 })
		Check:Equal(S:GetValue(P, { "Coins" }), 5, "written before replication")

		W.Packages.ReadyPlayers[P] = true
		W.Packages.NewReadyPlayer:Fire(P)
		Check:Equal(W.Replicas[1].Data.Coins, 5, "the replica starts with it")

		S:Increment(P, { "Coins" }, 1)
		Check:Equal(table.concat(W.Replicas[1].Calls, ","), "Set", "later writes go through the replica")
		Check:Equal(S:GetValue(P, { "Coins" }), 6, "and change the data")
	end,

	-- the array and dictionary setters, through the replica
	SettersReplicate = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		const Replica = W.Replicas[1]

		S:SetValue({ Player = P, Path = { "Settings", "MusicEnabled" }, Value = false })
		Check:True(S:SetValues({ Player = P, Path = { "Settings" }, Values = { MusicEnabled = true } }), "SetValues")
		Check:True(not S:SetValues({ Player = P, Path = { "Coins" }, Values = {} }), "SetValues on a number")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = "Sword" }), 1, "insert at end")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = "Bow", Index = 1 }), 1, "insert at index")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = "X", Index = 5 }), nil, "index past the end")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Coins" }, Value = "X" }), nil, "not an array")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Value = "Sword" }), "Sword", "remove by value")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Value = "Nope" }), nil, "missing value")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Index = 1 }), "Bow", "remove by index")
		Check:Equal(S:GetValue(P, { "Settings", "MusicEnabled" }), true, "dictionary written")
		Check:Equal(#S:GetValue(P, { "Inventory" }), 0, "array emptied")
		Check:Equal(table.concat(Replica.Calls, ","), "Set,SetValues,TableInsert,TableInsert,TableRemove,TableRemove", "replica calls")
	end,

	-- session writes go to the session replica and never touch saved data
	SessionSource = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		S:SetValue({ Player = P, Path = { "Streak" }, Value = 2, MathOperation = "+", Source = "Session" })
		Check:Equal(S:GetSessionValue(P, { "Streak" }), 2, "session value")
		Check:Equal(S:GetValue(P, { "Streak" }), nil, "not in saved data")
		Check:Equal(table.concat(W.Replicas[2].Calls, ","), "Set", "through the session replica")
		Check:Equal(#W.Replicas[1].Calls, 0, "profile replica untouched")
	end,

	-- each save adds the seconds since the last count, once
	CountsTimePlayed = function(Check:Check)
		const W = Setup(Check)

		W.Service:OnPlayerAdded(W.Player)
		W.Clock.Now = 1060
		W.Profile.OnSave:Fire()
		Check:Equal(W.Profile.Data.TimeTrackers.TimePlayed, 60, "first save")
		W.Clock.Now = 1090
		W.Profile.OnSave:Fire()
		Check:Equal(W.Profile.Data.TimeTrackers.TimePlayed, 90, "second save adds only 30")
	end,

	-- leaving counts the last stretch, destroys both replicas, ends the profile and releases waiters with false
	LeavingCleansUp = function(Check:Check)
		const W = Setup(Check, { ClientReady = false })
		const S, P = W.Service, W.Player
		local WaitResult = nil :: boolean?

		S:OnPlayerAdded(P)
		task.spawn(function()
			WaitResult = S:WaitForLoaded(P)
		end)

		W.Clock.Now = 1010
		S:OnPlayerRemoving(P)

		Check:Equal(W.Profile.Data.TimeTrackers.TimePlayed, 10, "last stretch counted")
		Check:True(W.Replicas[1].Destroyed and W.Replicas[2].Destroyed, "replicas destroyed")
		Check:Equal(W.Profile.Ended, 1, "profile ended once")
		Check:Equal(#W.Kicked, 0, "leaving does not kick")
		Check:Equal(WaitResult, false, "waiter told the player left")
		Check:Equal(S:GetData(P), nil, "data forgotten")
		Check:Equal(S:GetSession(P), nil, "session forgotten")
	end,

	-- a session ended elsewhere (another server took it) kicks the player and forgets them
	SessionEndedElsewhere = function(Check:Check)
		const W = Setup(Check)

		W.Service:OnPlayerAdded(W.Player)
		W.Profile:EndSession()

		Check:Equal(#W.Kicked, 1, "kicked")
		Check:Equal(W.Service:GetProfile(W.Player), nil, "forgotten")
		Check:True(not W.Service:IsPlayerLoaded(W.Player), "no longer loaded")
		Check:True(W.Replicas[1].Destroyed, "replica destroyed")
	end,

	-- waiters wake with true, watchers hear new loads and players already loaded, and Stop works
	LoadedWatchers = function(Check:Check)
		const W = Setup(Check, { ClientReady = false })
		const S, P = W.Service, W.Player
		const Heard = {} :: {any}
		local WaitResult = nil :: boolean?

		S:OnPlayerAdded(P)
		task.spawn(function()
			WaitResult = S:WaitForLoaded(P)
		end)

		const Stop = S:WatchPlayerLoaded(function(Loaded:any)
			table.insert(Heard, Loaded)
		end)

		S:_MarkClientReady(P)
		S:_MarkClientReady(P)

		Check:Equal(WaitResult, true, "waiter woke with true")
		Check:Equal(#Heard, 1, "watcher heard the load once")
		Check:Equal(S:WaitForLoaded(P), true, "WaitForLoaded on a loaded player returns at once")
		Check:Equal(#S:GetLoadedPlayers(), 1, "listed")

		const Late = {} :: {any}
		S:WatchPlayerLoaded(function(Loaded:any)
			table.insert(Late, Loaded)
		end)
		Check:Equal(Late[1], P, "a late watcher hears players already loaded")

		Stop()
		Check:Equal(#S._Watchers, 1, "stopped watcher removed")
	end,

	-- reset puts the template back in the same table and kicks
	ResetData = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		const Before = W.Profile.Data
		S:Increment(P, { "Coins" }, 77)

		Check:True(S:ResetData(P), "reset")
		Check:Equal(W.Profile.Data, Before, "same table")
		Check:Equal(W.Profile.Data.Coins, 0, "coins back to template")
		Check:Equal(#W.Kicked, 1, "kicked")
	end,
} :: TestRunner.Spec
````

### `src/ServerStorage/Tests/TestRunner.luau`

````lua
--!strict
-- runs the unit tests: every "<Name>.spec" ModuleScript in this folder returns a table of test functions, each given
-- a Check to assert with. Run from the command bar, in Edit:
--     require(game.ServerStorage.Tests.TestRunner:Clone()):Run()
-- (the clone gets past Studio's require cache, so an edited runner is never served stale)
-- a test gets fresh copies of the modules it tests through Check:Fresh, so no state leaks between tests or runs

-- // TYPES
export type Check = {
	Equal:(self:Check, Actual:any, Expected:any, Label:string?) -> (),
	True:(self:Check, Value:any, Label:string?) -> (),
	Fresh:(self:Check, Module:ModuleScript) -> any,
}

export type Spec = {[string]:(Check:Check) -> ()}

export type Result = {
	Run:number,
	Failed:{string},
}

-- // MODULE
local TestRunner = {}

-- a Check that adds every failed assertion to Failures under the test's name
local function NewCheck(TestName:string, Failures:{string}) : Check
	const Check = {}

	-- fails when Actual is not Expected (==)
	function Check:Equal(Actual:any, Expected:any, Label:string?)
		if Actual ~= Expected then
			table.insert(Failures, `{TestName}: {Label or "value"} was {tostring(Actual)}, expected {tostring(Expected)}`)
		end
	end

	-- fails when Value is false or nil
	function Check:True(Value:any, Label:string?)
		if not Value then
			table.insert(Failures, `{TestName}: {Label or "condition"} was {tostring(Value)}`)
		end
	end

	-- a fresh copy of Module, required: its state is new. Its requires of other modules are shared as usual
	function Check:Fresh(Module:ModuleScript) : any
		return require(Module:Clone()) :: any
	end

	return Check :: any
end

-- // METHODS
-- runs every spec in Folder (this folder when nil), prints a summary and every failure, and returns them
function TestRunner:Run(Folder:Instance?) : Result
	const Holder = Folder or script.Parent :: Instance
	const Result:Result = { Run = 0, Failed = {} }

	for _, Module in Holder:GetChildren() do
		if not Module:IsA("ModuleScript") or not string.match(Module.Name, "%.spec$") then
			continue
		end

		-- a clone, so an edited spec is not served from the require cache. Parented beside the original while it
		-- loads, because a spec requires script.Parent.TestRunner
		const Copy = Module:Clone()
		Copy.Name = `{Module.Name}.Running`
		Copy.Parent = Holder

		const Loaded, Spec = pcall(require, Copy)

		Copy:Destroy()

		if not Loaded or type(Spec) ~= "table" then
			table.insert(Result.Failed, `{Module.Name}: failed to load: {Spec}`)

			continue
		end

		for TestName, Test in Spec :: Spec do
			const FullName = `{Module.Name} > {TestName}`
			const Passed, Problem = xpcall(Test, debug.traceback, NewCheck(FullName, Result.Failed))

			Result.Run += 1

			if not Passed then
				table.insert(Result.Failed, `{FullName}: errored: {Problem}`)
			end
		end
	end

	print(`[TestRunner] {Result.Run} run, {#Result.Failed} failed`)

	for _, Failure in Result.Failed do
		warn(`[TestRunner] {Failure}`)
	end

	return Result
end

return TestRunner
````

### `src/StarterPlayer/StarterPlayerScripts/ClientLoader.client.luau`

````lua
--!strict
-- the only client script. Waits for the game, requires every controller in ReplicatedStorage.Controllers (each
-- followed by its Ui child) and calls its hooks: Initialize, then Start, then the character hooks. Then it tells the
-- server the client is ready (DataService spawns the player when characters don't load on their own).
-- a new system is a ModuleScript in that folder, never a new LocalScript

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Player = Players.LocalPlayer :: Player
const CHARACTER_TIME_OUT = 10 -- seconds a new character gets to stream its parts in before the hooks run anyway
-- what a character needs before the controllers' OnCharacterAdded runs (parts can stream in after the model)
const CHARACTER_READY_NAMES = { "Humanoid", "HumanoidRootPart" }

-- waits until every CHARACTER_READY_NAMES child is in Character, or until Deadline (an os.clock time)
local function WaitForBody(Character:Model, Deadline:number)
	for _, Name in CHARACTER_READY_NAMES do
		const Remaining = Deadline - os.clock()

		if Remaining <= 0 then
			return
		end

		Character:WaitForChild(Name, Remaining)
	end
end

-- boots every controller and wires the character hooks
local function LoadClient()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	-- waited for, then required by path so the checker knows each module's type
	ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Loader")
	ReplicatedStorage:WaitForChild("Controllers")

	const Loader = require(ReplicatedStorage.SharedModules.Loader)
	const Network = require(ReplicatedStorage.SharedModules.Network)
	const Controllers = Loader:Collect(ReplicatedStorage.Controllers)

	-- each character gets OnCharacterAdded once (the event and the boot check below can both see it), and
	-- OnCharacterRemoving only if it got OnCharacterAdded
	local HandledCharacter = nil :: Model? -- dispatched or being waited on
	local DispatchedCharacter = nil :: Model?

	-- waits for the body, then dispatches it. Skipped if the character was replaced or removed meanwhile
	local function OnCharacterAdded(Character:Model)
		if HandledCharacter == Character then
			return
		end

		HandledCharacter = Character

		WaitForBody(Character, os.clock() + CHARACTER_TIME_OUT)

		if HandledCharacter ~= Character or Player.Character ~= Character then
			return
		end

		DispatchedCharacter = Character
		Loader:CallAll(Controllers, "OnCharacterAdded", Character)
	end

	-- connected before the hooks run, so a respawn during Initialize or Start is not missed
	Player.CharacterAdded:Connect(OnCharacterAdded)

	Player.CharacterRemoving:Connect(function(Character:Model)
		if HandledCharacter == Character then
			HandledCharacter = nil
		end

		if DispatchedCharacter ~= Character then
			return
		end

		DispatchedCharacter = nil
		Loader:CallAll(Controllers, "OnCharacterRemoving", Character)
	end)

	Loader:CallAll(Controllers, "Initialize")
	Loader:CallAll(Controllers, "Start")

	-- after the hooks above were called: a yielding controller (DataController) has finished, the others have begun
	Network:FireServer("ClientReady")

	-- a character that arrived before the CharacterAdded connection above
	if Player.Character then
		task.spawn(OnCharacterAdded, Player.Character)
	end
end

LoadClient()
````

### `tools/check-luau.mjs`

````js
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
````
