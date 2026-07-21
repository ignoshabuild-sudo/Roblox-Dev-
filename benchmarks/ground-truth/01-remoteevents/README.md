# 01 — RemoteEvents

Client-server communication using `RemoteEvent`. One of the most common patterns
in Roblox development.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-basic-fire-server.luau` | server | Server listens for `OnServerEvent` from any player, prints the message |
| 02 | `02-basic-fire-client.luau` | client | Client fires a `RemoteEvent` to the server with a message argument |
| 03 | `03-fire-all-clients.luau` | server | Server fires `:FireAllClients()` to broadcast a message to all players |

## Key APIs

- `Instance.new("RemoteEvent")`
- `RemoteEvent.OnServerEvent:Connect(callback)`
- `RemoteEvent:FireServer(...)`
- `RemoteEvent:FireClient(player, ...)`
- `RemoteEvent:FireAllClients(...)`
- `game:GetService("ReplicatedStorage")`

## Structural Patterns

### Fire to Server (client → server)
```
Client: remoteEvent:FireServer(data)
Server: remoteEvent.OnServerEvent:Connect(function(player, data) ... end)
```

### Fire to Client (server → specific player)
```
Server: remoteEvent:FireClient(player, data)
Client: remoteEvent.OnClientEvent:Connect(function(data) ... end)
```

### Fire All Clients (server → all)
```
Server: remoteEvent:FireAllClients(data)
Client: remoteEvent.OnClientEvent:Connect(function(data) ... end)
```

## Common Pitfalls the AI Must Avoid
- Placing `RemoteEvent` in a client-only location (must be in `ReplicatedStorage`)
- Forgetting the `player` argument in `OnServerEvent` callback
- Using `FireServer` on the server or `FireClient` on the client
- Missing the `Parent` assignment for newly created instances
