# 05 — ModuleScripts

Reusable code organization using `ModuleScript` and `require()`.
The backbone of any well-structured Roblox codebase.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-basic-module.luau` | module | A utility module that returns a table of helper functions |
| 02 | `02-require-module.luau` | server | A Script that requires and uses the module from #01 |
| 03 | `03-module-with-init.luau` | module | A module with an `init` or constructor pattern |

## Key APIs

- `require(path)`
- `script.Parent` / `game:GetService("ServerScriptService")`
- Table construction: `local module = {}; return module`

## Structural Patterns

### Module Definition
```luau
local MyModule = {}
MyModule.__index = MyModule

function MyModule.new()
    local self = setmetatable({}, MyModule)
    return self
end

function MyModule:doSomething()
    -- ...
end

return MyModule
```

### Requiring a Module
```luau
local MyModule = require(script.Parent.MyModule)
local instance = MyModule.new()
instance:doSomething()
```

### Simple Utility Module
```luau
local Utils = {}

function Utils.formatCurrency(amount: number): string
    return "$" .. tostring(amount)
end

return Utils
```

## Common Pitfalls
- Forgetting the `return` statement at the end of the ModuleScript
- Using `require()` on the client for modules in `ServerScriptService` (client can't access)
- Module code executes once on first `require`, then cached — not re-executed
- `require()` paths are relative to the requiring script's location
- Circular requires cause nil values
