# 17 — ContextActionService

Input binding for gameplay actions — supports keyboard, gamepad, and mobile buttons.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-bind-action.luau` | client | Bind a key to a named action |
| 02 | `02-unbind-action.luau` | client | Unbind and rebind an action dynamically |
| 03 | `03-action-with-touch.luau` | client | Bind an action that also creates a mobile button |

## Key APIs

- `ContextActionService:BindAction(name, callback, createTouchButton, ...keys)`
- `ContextActionService:UnbindAction(name)`
- `ContextActionService:GetBoundActionInfo(name)`
- `Enum.KeyCode`, `Enum.UserInputState`

## Common Pitfalls
- `BindAction` returns void but the callback receives `(actionName, inputState, inputObject)`
- Creating a touch button (`createTouchButton = true`) requires a valid action name
- Binding the same name twice replaces the old binding
- Actions are client-only
