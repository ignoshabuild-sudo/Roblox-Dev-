# 06 — BindableEvents

Script-to-script communication on the same side (server↔server or client↔client).
Unlike RemoteEvents, BindableEvents don't cross the client-server boundary.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-fire-between-scripts.luau` | server | Two server Scripts communicate via BindableEvent |
| 02 | `02-bindable-with-data.luau` | server | Pass data through BindableEvent between scripts |
| 03 | `03-unbind-pattern.luau` | server | Connect and later disconnect a BindableEvent handler |

## Key APIs

- `Instance.new("BindableEvent")`
- `BindableEvent.Event:Connect(callback)`
- `BindableEvent:Fire(...)`

## Common Pitfalls
- BindableEvents don't work across client-server boundary (use RemoteEvents for that)
- Must be in a shared location both scripts can access
