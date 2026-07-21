# 10 — RunService

Game loop events for frame-by-frame logic and physics updates.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-heartbeat-loop.luau` | server | Run logic every physics frame on the server |
| 02 | `02-renderstepped-camera.luau` | client | Update camera every render frame |
| 03 | `03-is-running-check.luau` | shared | Check if running in Studio vs live game |

## Key APIs

- `RunService.Heartbeat:Connect(callback)`
- `RunService.RenderStepped:Connect(callback)`
- `RunService.Stepped:Connect(callback)`
- `RunService:IsRunning()`
- `RunService:IsStudio()`

## Common Pitfalls
- RenderStepped is client-only and fires before each frame is rendered
- Heartbeat fires after physics simulation — not at a fixed rate
- Don't run heavy logic in RenderStepped (causes frame drops)
- Heartbeat vs Stepped: Stepped fires BEFORE physics, Heartbeat AFTER
