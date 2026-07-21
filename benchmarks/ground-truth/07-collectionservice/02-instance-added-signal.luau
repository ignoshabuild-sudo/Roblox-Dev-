-- context: server
-- apis: CollectionService, GetInstanceAddedSignal, GetInstanceRemovedSignal, AddTag
local CollectionService = game:GetService("CollectionService")

local TAG_NAME = "Collectible"

CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(function(instance: Instance)
if instance:IsA("BasePart") then
instance.BrickColor = BrickColor.new("Bright yellow")
print("Collectible added: " .. instance:GetFullName())
end
end)

CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(instance: Instance)
print("Collectible removed: " .. instance:GetFullName())
end)

-- Tag all existing parts with the name "Coin"
for _, part in ipairs(workspace:GetDescendants()) do
if part.Name == "Coin" then
CollectionService:AddTag(part, TAG_NAME)
end
end
</EOF>

cat > "$T/07-collectionservice/02-instance-added-signal.yaml" << 'EOF'
id: "07-collectionservice-02-instance-added-signal"
category: "collectionservice"
context_type: "server"
prompt: "Create a server Script that uses CollectionService:GetInstanceAddedSignal and GetInstanceRemovedSignal to detect when 'Collectible' tagged instances are added or removed. Tag any existing parts named 'Coin'."
ground_truth: "02-instance-added-signal.luau"
expected_apis:
  - "GetService"
  - "CollectionService"
  - "GetInstanceAddedSignal"
  - "GetInstanceRemovedSignal"
  - "AddTag"
  - "GetDescendants"
expected_patterns:
  - "get-service"
  - "tag-based-logic"
  - "signal-connect"
