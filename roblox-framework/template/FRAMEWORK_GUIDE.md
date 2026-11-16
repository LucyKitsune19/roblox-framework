# Framework guide: how code is written and where it goes

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

## 1. The rules

1. **Write in the style of section 3.** Copy the shape of the example files; don't invent a new one.
2. **Strict typing, always.** `--!strict` is the first line of every file.
3. **All client code goes in Controllers:** `ReplicatedStorage/Controllers/`.
4. **All server code goes in Services:** `ServerScriptService/Services/`.
5. **Code both sides read goes in SharedModules:** `ReplicatedStorage/SharedModules/`.
6. **A big or important system gets a service and a controller with the same name.** A sub-system is a child module of the system it belongs to, never a system of its own.
7. **Two scripts only.** `ServerLoader` and `ClientLoader` are the only Scripts. Everything else is a ModuleScript they load.
8. **Every remote is defined in one shared file.** No `RemoteEvent` is created anywhere else.

## 2. What's in the box

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

## 3. The style

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

### Layout

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

### Comments

- A header at the top of every file, after `--!strict`: what the module is for and how it fits.
- A comment above **every** function: what it does and what it returns. Plain lowercase words, no full stop at the end. That means every named function: `function`, `local function`, methods, and methods on test fakes. An anonymous callback passed straight into a call (`Signal:Connect(function() ... end)`) needs a comment only when what it does isn't obvious from the call.
- A comment above a line that needs one, saying **why**, not what.
- A comment beside every constant: what the number means, with its unit.

```lua
-- true for a body that can act. AllowRagdoll: a ragdolled body still counts
local function IsValid(Character:Model?, AllowRagdoll:boolean) : boolean

const REACH_TIME = 0.65 -- seconds the attacker has to close in
```

## 4. Strict typing

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

## 5. Where code goes

| Code | Where | Loaded by |
|---|---|---|
| Server code | `ServerScriptService/Services/`, one ModuleScript (or folder with `init.luau`) per system | `ServerLoader` |
| Client code | `ReplicatedStorage/Controllers/`, one per system | `ClientLoader` |
| Code both sides read: configs both must agree on, shared types, pure helpers | `ReplicatedStorage/SharedModules/` | whoever requires it |

Shared modules hold data and pure functions: no state, no hooks, no connections.

### A big system: one service and one controller

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

### Interface code: a `Ui` child

A system's interface (HUD, menu, panel) is a child module named `Ui` under its controller. The loader runs it right after its parent and calls the same hooks on it. It requires its parent (`require(script.Parent)`); the parent never requires it. Its banner for the module table is `-- // CONTROLLER`, like its parent's. See `ExampleController/Ui.luau`.

- Build from templates kept in ReplicatedStorage (`ReplicatedStorage/UiTemplates/<Name>`) and clone them. Never build instances in code.
- A template is made in Studio, not in code. To keep it in `src/` as well, save it from Studio as a model file (right-click → Save to File → `.rbxm`) into `src/ReplicatedStorage/UiTemplates/<Name>.rbxm`; Rojo syncs model files. When an agent writes a `Ui` it can't make the template itself: it names the instances it needs in the header comment and tells the user to build them.
- Anchor at 0.5, 0.5. Scale only, never Offset (UIStroke thickness included). Keep the designed aspect ratio.
- Never name a module `Ui` unless it is one: the loader treats it as an interface.

### A sub-system: a child of the system it belongs to

Ask "what is this a kind of?". If the answer is an existing system, it's a child of that system, on each side it has code for. A dash is a kind of ability, so it is `AbilityService/Dash.luau` and `AbilityController/Dash.luau`, not a `DashService`.

How the parent handles its children (copy `ExampleService`):

- It finds a child **by name**, so the child module is named after the thing's id. No lookup table.
- **The parent decides when children load.** Many children that a player uses few of: required on first use. Two or three it always needs: required in `Initialize`, which is simpler and shows a broken child at boot.
- The `require` is guarded (`pcall`). A child that fails is warned about by name, treated as missing, remembered so it isn't retried, and stops no other child.
- The parent declares the shape every child has as an exported type (`ExampleService.ServerChild`) and checks the required function is there before keeping it.
- A child may `require(script.Parent)`: safe, because the parent only requires the child later, from inside a function.
- A child that must also run for a player who never triggered it (the target of an ability, say) is woken by the parent, for example when an attribute appears on that player's character.

### The loaders

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

## 6. Remotes

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

## 7. Player data

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

## 8. Checks and tests

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

## 9. Existing code

When this framework goes into a game that already has scripts:

- **Leave old scripts where they are.** A system moves into Services/Controllers only when the lead scripter names it.
- **An edit of a few lines in an old file keeps that file's style.** A file must never end up half one style and half the other. Add a dated comment saying why.
- **New behaviour goes in a service or controller**, and the old script calls into it with a few lines.
- No version control? Copy every script you're about to change into a dated backup folder first. Better: use git.

## 10. Project decisions

The lead scripter's rulings for this game, dated. Start empty.

| Date | Question | Decision |
|---|---|---|
| | | |

## 11. Before you call a file done

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
