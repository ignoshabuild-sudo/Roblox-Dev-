# 11 — ReplicatedStorage

Shared asset container accessible by both server and client.
Used to store RemoteEvents, RemoteFunctions, and shared modules.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-store-and-retrieve.luau` | server | Store an object in ReplicatedStorage and retrieve it |
| 02 | `02-wait-for-child.luau` | client | Client waits for a shared object to exist |
| 03 | `03-clone-from-storage.luau` | server | Clone a template from ReplicatedStorage |

## Key APIs

- `game:GetService("ReplicatedStorage")`
- `ReplicatedStorage:WaitForChild(name)`
- `ReplicatedStorage:FindFirstChild(name)`
- `instance:Clone()`

## Common Pitfalls
- Server-only assets should go in ServerStorage, not ReplicatedStorage
- `WaitForChild` yields indefinitely if the child never appears
- Both server and client can modify ReplicatedStorage contents (security concern)
