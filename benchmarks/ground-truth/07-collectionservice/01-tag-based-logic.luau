-- context: server
-- apis: CollectionService, GetTagged, AddTag, RemoveTag, HasTag
local CollectionService = game:GetService("CollectionService")

local TAG_NAME = "Enemy"

local function tagAllEnemies()
local enemies = workspace:GetDescendants()
for _, obj in ipairs(enemies) do
if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
CollectionService:AddTag(obj, TAG_NAME)
end
end
end

local function getTaggedEnemies(): {Instance}
return CollectionService:GetTagged(TAG_NAME)
end

local function isEnemy(instance: Instance): boolean
return CollectionService:HasTag(instance, TAG_NAME)
end

tagAllEnemies()
for _, enemy in ipairs(getTaggedEnemies()) do
print("Found enemy: " .. enemy.Name)
end
</EOF>

cat > "$T/07-collectionservice/01-tag-based-logic.yaml" << 'EOF'
id: "07-collectionservice-01-tag-based-logic"
category: "collectionservice"
context_type: "server"
prompt: "Create a server Script that uses CollectionService to tag all Models with a Humanoid as 'Enemy', then gets all tagged instances. Include helper functions for tagging, getting tagged, and checking tags."
ground_truth: "01-tag-based-logic.luau"
expected_apis:
  - "GetService"
  - "CollectionService"
  - "AddTag"
  - "GetTagged"
  - "HasTag"
  - "GetDescendants"
expected_patterns:
  - "get-service"
  - "tag-based-logic"
