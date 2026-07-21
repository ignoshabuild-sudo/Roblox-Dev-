-- context: client
-- apis: ProximityPrompt, Instance.new, Triggered, Enabled, GetService
local collectionService = game:GetService("CollectionService")

local function setupCollectible(item: BasePart, itemName: string, reward: number)
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Collect " .. itemName
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 8
prompt.Parent = item

prompt.Triggered:Connect(function(player: Player)
-- Disable to prevent double-collection
prompt.Enabled = false

print(player.Name .. " collected " .. itemName .. " (+" .. reward .. " coins)")
item:Destroy()
end)
end

-- Tagged collectible items are set up by the server; client handles prompts
local items = collectionService:GetTagged("Collectible")
for _, item in ipairs(items) do
if item:IsA("BasePart") then
setupCollectible(item, item.Name, 10)
end
end
</EOF>

cat > "$T/18-proximityprompts/02-triggered-handling.yaml" << 'EOF'
id: "18-proximityprompts-02-triggered-handling"
category: "proximityprompts"
context_type: "client"
prompt: "Create a client LocalScript that sets up ProximityPrompts on all CollectionService-tagged 'Collectible' parts. On Triggered, disable the prompt and destroy the item to prevent double-collection."
ground_truth: "02-triggered-handling.luau"
expected_apis:
  - "GetService"
  - "Instance.new"
  - "ProximityPrompt"
  - "Triggered"
  - "GetTagged"
  - "Destroy"
expected_patterns:
  - "get-service"
  - "prompt-setup"
  - "triggered-event"
