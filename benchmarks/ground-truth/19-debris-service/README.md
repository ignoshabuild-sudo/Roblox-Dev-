# 19 — Debris Service

Time-based cleanup and destruction of instances.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-add-debris.luau` | server | Schedule a part for destruction after N seconds |
| 02 | `02-cleanup-effects.luau` | server | Create a particle effect and auto-destroy it |
| 03 | `03-batch-cleanup.luau` | server | Add multiple items to debris with staggered times |

## Key APIs

- `Debris:AddItem(instance, lifetime)`
- `game:GetService("Debris")`
- `instance:Destroy()`

## Common Pitfalls
- `AddItem` parent-locks the instance — you can't re-parent it after
- Lifetime is in seconds, can be fractional
- Debris is server-only; use `task.wait(n); instance:Destroy()` on client
- Debris does NOT fire an event — it silently destroys after the timer
