# 18 — ProximityPrompts

Interaction prompts that appear when a player is near an object.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-basic-prompt.luau` | client | Create a ProximityPrompt on a part that triggers an action |
| 02 | `02-prompt-with-hold.luau` | client | Configure a prompt that requires holding the key |
| 03 | `03-toggle-prompt.luau` | client | Enable/disable a prompt based on game state |

## Key APIs

- `Instance.new("ProximityPrompt")`
- `ProximityPrompt.Triggered:Connect(callback)`
- `ProximityPrompt.Enabled`
- `ProximityPrompt.HoldDuration`
- `ProximityPrompt.ActionText`, `ProximityPrompt.ObjectText`

## Common Pitfalls
- `Triggered` fires on the client — not the server
- Prompts need `RequiresLineOfSight` disabled for through-wall interaction
- HoldDuration of 0 means instant trigger
- Multiple prompts on the same object can conflict
