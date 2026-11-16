# Roblox framework rules

This project uses the roblox-framework starter pack. These rules are not optional, and only the lead scripter named in `FRAMEWORK_GUIDE.md` can change them.

**Before writing any code, read `FRAMEWORK_GUIDE.md`.** It has the full style, every rule with an example, and the project's dated decisions (section 10).

## Hard rules

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

## Before calling work done

- Run `node tools/check-luau.mjs` and fix every finding. With the plugin installed it also runs after every edit. Clean means the rules hold, not that the file compiles. Silence a finding only when it is truly an exception, with `-- check:ignore <rule>` and the reason on the line above.
- Run the unit tests in Studio from the command bar: `require(game.ServerStorage.Tests.TestRunner:Clone()):Run()`.
- Go through the checklist in `FRAMEWORK_GUIDE.md` section 11.
- Report what you could not verify (Script Analysis, a play-test) instead of claiming it.
