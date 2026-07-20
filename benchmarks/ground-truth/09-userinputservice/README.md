# 09 — UserInputService

Client-side input detection for keyboard, mouse, gamepad, and touch.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-detect-key-press.luau` | client | Detect when a specific key is pressed |
| 02 | `02-mouse-click-world.luau` | client | Handle mouse clicks and get world position |
| 03 | `03-input-began-ended.luau` | client | Track input state (began vs ended) for held keys |

## Key APIs

- `UserInputService.InputBegan:Connect(callback)`
- `UserInputService.InputEnded:Connect(callback)`
- `UserInputService:IsKeyDown(keyCode)`
- `UserInputService:GetMouseLocation()`
- `Enum.KeyCode`, `Enum.UserInputType`

## Common Pitfalls
- UserInputService is client-only
- ContextActionService may be preferred for gameplay actions (supports mobile buttons)
- InputBegan fires for every input device — filter by `input.UserInputType`
