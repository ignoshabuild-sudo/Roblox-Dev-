# 15 — HttpService

External HTTP requests for calling third-party APIs, webhooks, and services.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-get-request.luau` | server | Make a GET request to an external API |
| 02 | `02-post-json.luau` | server | POST JSON data to a webhook |
| 03 | `03-encode-decode.luau` | module | Encode and decode JSON with error handling |

## Key APIs

- `HttpService:GetAsync(url)`
- `HttpService:PostAsync(url, data)`
- `HttpService:JSONEncode(table)`
- `HttpService:JSONDecode(string)`
- `HttpService:RequestAsync(options)` (advanced)

## Common Pitfalls
- HttpService must be enabled in Game Settings (disabled by default)
- External URLs must be allow-listed in Game Settings
- Always wrap HTTP calls in `pcall` — network failures are common
- JSONEncode/JSONDecode can error on malformed data
- GetAsync/PostAsync are server-only; use RequestAsync for broader use
