-- context: server
-- apis: MarketplaceService, ProcessReceipt, GetService, pcall, Players
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PRODUCT_MAP: {[number]: (player: Player) -> ()} = {
[12345678] = function(player: Player)
-- Grant 100 coins
local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
local coins = leaderstats:FindFirstChild("Coins") :: IntValue?
if coins then
coins.Value += 100
end
end
end,
}

MarketplaceService.ProcessReceipt = function(receiptInfo)
local success, result = pcall(function()
local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
if not player then
return Enum.ProductPurchaseDecision.NotProcessedYet
end

local handler = PRODUCT_MAP[receiptInfo.ProductId]
if handler then
handler(player)
return Enum.ProductPurchaseDecision.PurchaseGranted
end

return Enum.ProductPurchaseDecision.NotProcessedYet
end)

if not success then
warn("ProcessReceipt error: " .. tostring(result))
return Enum.ProductPurchaseDecision.NotProcessedYet
end

return result
end
</EOF>

cat > "$T/14-marketplaceservice/01-process-receipt.yaml" << 'EOF'
id: "14-marketplaceservice-01-process-receipt"
category: "marketplaceservice"
context_type: "server"
prompt: "Create a server Script that sets MarketplaceService.ProcessReceipt. Use pcall, look up the player with GetPlayerByUserId, and grant 100 coins for product ID 12345678. Return appropriate ProductPurchaseDecision enums."
ground_truth: "01-process-receipt.luau"
expected_apis:
  - "GetService"
  - "MarketplaceService"
  - "ProcessReceipt"
  - "Players"
  - "GetPlayerByUserId"
  - "pcall"
  - "ProductPurchaseDecision"
expected_patterns:
  - "get-service"
  - "purchase-handling"
  - "error-handling"
