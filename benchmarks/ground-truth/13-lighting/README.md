# 13 — Lighting

Environment and atmosphere settings — time of day, fog, ambient color,
post-processing effects.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-set-time-of-day.luau` | server | Set the game's ClockTime and ambient color |
| 02 | `02-configure-fog.luau` | server | Set up atmospheric fog with density and color |
| 03 | `03-bloom-sun-rays.luau` | server | Enable post-processing effects like Bloom and SunRays |

## Key APIs

- `Lighting.ClockTime`, `Lighting.GeographicLatitude`
- `Lighting.Ambient`, `Lighting.OutdoorAmbient`
- `Lighting.FogEnd`, `Lighting.FogStart`, `Lighting.FogColor`
- `Lighting.Bloom`, `Lighting.SunRays`, `Lighting.DepthOfField`
- `Lighting.Atmosphere` (density, glare, haze)

## Common Pitfalls
- Lighting changes affect all players — use client-side overrides for per-player
- `ClockTime` uses 0–24 scale (not 0–1)
- Some post-processing effects require specific graphics levels
