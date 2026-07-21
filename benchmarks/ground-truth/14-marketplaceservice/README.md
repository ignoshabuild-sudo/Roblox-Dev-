# 14 — MarketplaceService

In-game purchases and developer product processing.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-process-receipt.luau` | server | Handle a purchase receipt from a game pass |
| 02 | `02-check-ownership.luau` | server | Check if a player owns a specific game pass |
| 03 | `03-prompt-purchase.luau` | client | Prompt a player to purchase a developer product |

## Key APIs

- `MarketplaceService.ProcessReceipt`
- `MarketplaceService:UserOwnsGamePassAsync(userId, passId)`
- `MarketplaceService:PromptProductPurchase(player, productId)`
- `MarketplaceService:PromptGamePassPurchase(player, passId)`

## Common Pitfalls
- `ProcessReceipt` must be assigned as a callback BEFORE any purchases can happen
- Always return `Enum.ProductPurchaseDecision.PurchaseGranted` after granting
- `UserOwnsGamePassAsync` is server-only
- Purchase prompts must originate client-side
