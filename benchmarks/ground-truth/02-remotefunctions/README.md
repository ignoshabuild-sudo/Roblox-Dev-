# 02 — RemoteFunctions

Client-server communication with return values using `RemoteFunction`.
Used when the caller needs a synchronous-style response from the other side.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-invoke-server.luau` | server | Server handles `OnServerInvoke`, processes data, returns result |
| 02 | `02-invoke-client.luau` | client | Client calls `InvokeServer` and uses the returned value |
| 03 | `03-invoke-with-timeout.luau` | client | Client invokes server with a timeout pattern |

## Key APIs

- `Instance.new("RemoteFunction")`
- `RemoteFunction.OnServerInvoke:Connect(callback)`
- `RemoteFunction:InvokeServer(...)`
- `RemoteFunction:InvokeClient(player, ...)`

## Structural Patterns

### Invoke Server (client → server, with return)
```
Client: local result = remoteFunction:InvokeServer(data)
Server: remoteFunction.OnServerInvoke = function(player, data) return processed end
```

### Invoke Client (server → client, with return)
```
Server: local result = remoteFunction:InvokeClient(player, data)
Client: remoteFunction.OnClientInvoke = function(data) return processed end
```

## Common Pitfalls
- `OnServerInvoke` must return a value (unlike `OnServerEvent`)
- `InvokeServer` yields the client thread until the server responds
- Cannot invoke from the same side the function is defined on
- RemoteFunction must be parented to `ReplicatedStorage`
