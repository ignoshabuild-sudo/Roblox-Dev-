-- context: server
-- apis: MarketplaceService, PromptProductPurchase, GetService, Players, PromptGamePassPurchaseFinished
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local GAMEPASS_ID = 9876543

local function onPurchaseFinished(player: Player, gamePassId: number, wasPurchased: boolean)
if wasPurchased then
print(player.Name .. " purchased gamepass " .. gamePassId)
else
print(player.Name .. " cancelled or failed purchase of " .. gamePassId)
end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPurchaseFinished)

local function promptGamePass(player: Player)
MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
end

-- Example: prompt purchasing player
Players.PlayerAdded:Connect(function(player: Player)
task.wait(3)
promptGamePass(player)
end)
</EOF>

cat > "$T/14-marketplaceservice/02-prompt-purchase.yaml" << 'EOF'
id: "14-marketplaceservice-02-prompt-purchase"
category: "marketplaceservice"
context_type: "server"
prompt: "Create a server Script that prompts a player to purchase a gamepass when they join. Listen to PromptGamePassPurchaseFinished to handle the result, and use PromptGamePassPurchase to trigger the prompt."
ground_truth: "02-prompt-purchase.luau"
expected_apis:
  - "GetService"
  - "MarketplaceService"
  - "PromptGamePassPurchase"
  - "PromptGamePassPurchaseFinished"
  - "Players"
  - "PlayerAdded"
expected_patterns:
  - "get-service"
  - "purchase-handling"
