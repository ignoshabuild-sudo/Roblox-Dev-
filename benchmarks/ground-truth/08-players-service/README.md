# 08 — Players Service

Player lifecycle management — handling players joining, leaving, and accessing
their character and properties.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-player-added.luau` | server | Handle PlayerAdded to set up leaderstats on join |
| 02 | `02-player-removing.luau` | server | Clean up player data on PlayerRemoving |
| 03 | `03-get-player-by-name.luau` | server | Find a player by username using Players:FindFirstChild |

## Key APIs

- `Players.PlayerAdded:Connect(callback)`
- `Players.PlayerRemoving:Connect(callback)`
- `Players:GetPlayers()`
- `Player.Character`, `Player.UserId`, `Player.Name`
- `Player:WaitForChild("leaderstats")`

## Common Pitfalls
- PlayerAdded fires BEFORE the character is loaded — use `Player.CharacterAdded` for character access
- Never trust the client for player data; always use UserId from the server
- `GetPlayers()` returns a table, not something you can iterate with pairs
