# 03 — DataStores

Persistent player data storage using `DataStoreService`. Critical for saving
player progress, inventory, and stats across sessions.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-save-player-data.luau` | server | Save player data on `PlayerRemoving` with `pcall` error handling |
| 02 | `02-load-player-data.luau` | server | Load player data on `PlayerAdded` with retry logic |
| 03 | `03-update-incremental.luau` | server | Update a numeric value using `UpdateAsync` |

## Key APIs

- `DataStoreService:GetDataStore(name)`
- `DataStore:GetAsync(key)`
- `DataStore:SetAsync(key, value)`
- `DataStore:UpdateAsync(key, callback)`
- `pcall(function)`
- `Players.PlayerAdded` / `Players.PlayerRemoving`

## Structural Patterns

### Save with pcall
```luau
local success, err = pcall(function()
    dataStore:SetAsync(key, data)
end)
if not success then warn("Save failed:", err) end
```

### Load with retry
```luau
local function loadWithRetry(key, attempts)
    for i = 1, attempts do
        local success, result = pcall(function()
            return dataStore:GetAsync(key)
        end)
        if success then return result end
        task.wait(1)
    end
    return nil
end
```

## Common Pitfalls
- Must ALWAYS wrap DataStore calls in `pcall` — never raw
- DataStores are server-only (`Script`, not `LocalScript`)
- Keys must be strings
- Budget limits: avoid writing in tight loops
- `SetAsync` vs `UpdateAsync`: use `UpdateAsync` for incremental updates to avoid race conditions
