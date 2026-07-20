# 20 — Raycasting

Spatial queries for line-of-sight, hit detection, and world interaction.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-basic-raycast.luau` | server | Cast a ray and detect what it hits |
| 02 | `02-raycast-with-filter.luau` | server | Raycast with filter params to ignore certain instances |
| 03 | `03-raycast-from-mouse.luau` | client | Cast a ray from the player's mouse position into the world |

## Key APIs

- `Workspace:Raycast(origin, direction, params)`
- `RaycastParams.new()`
- `RaycastParams.FilterType`, `RaycastParams.FilterDescendantsInstances`
- `RaycastResult.Instance`, `RaycastResult.Position`, `RaycastResult.Normal`

## Common Pitfalls
- `RaycastParams` is required for most use cases (filtering)
- Direction vector must be a unit vector multiplied by distance
- Raycast ignores the instance the ray originates from by default
- `Workspace:Raycast()` returns nil if nothing is hit
