# 16 — Pathfinding

NPC movement and obstacle navigation using `PathfindingService`.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-simple-path.luau` | server | Create a path from start to goal and move an NPC along it |
| 02 | `02-path-with-waypoints.luau` | server | Move through path waypoints with humanoid |
| 03 | `03-path-blocked-retry.luau` | server | Handle path blockage and recompute |

## Key APIs

- `PathfindingService:CreatePath(agentParams)`
- `Path:ComputeAsync(start, finish)`
- `Path:GetWaypoints()`
- `Path.Blocked:Connect(callback)`
- `Humanoid:MoveTo(position)`

## Common Pitfalls
- `ComputeAsync` can yield and may fail — always wrap in `pcall`
- Paths become invalid if the environment changes; use `Blocked` event
- Waypoints include Enum.PathWaypointAction.Jump for gaps
- AgentParams (radius, height, maxSlope) affect path generation
