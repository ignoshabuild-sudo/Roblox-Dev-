-- context: server
-- apis: Debris, AddItem, Instance.new, GetService
local Debris = game:GetService("Debris")

local function spawnTemporaryPart(position: Vector3, color: Color3, lifetime: number)
local part = Instance.new("Part")
part.Size = Vector3.new(2, 2, 2)
part.Position = position
part.Color = color
part.Anchored = true
part.CanCollide = false
part.Parent = workspace

Debris:AddItem(part, lifetime)
print("Spawned temporary part at " .. tostring(position) .. " for " .. lifetime .. "s")
return part
end

-- Spawn 3 temporary parts
spawnTemporaryPart(Vector3.new(0, 5, 0), Color3.fromRGB(255, 0, 0), 3)
spawnTemporaryPart(Vector3.new(5, 5, 0), Color3.fromRGB(0, 255, 0), 5)
spawnTemporaryPart(Vector3.new(-5, 5, 0), Color3.fromRGB(0, 0, 255), 8)
</EOF>

cat > "$T/19-debris-service/01-add-item.yaml" << 'EOF'
id: "19-debris-service-01-add-item"
category: "debris-service"
context_type: "server"
prompt: "Create a server Script with a function that spawns anchored, non-collidable Parts at given positions with colors, then adds them to Debris for automatic cleanup after a specified lifetime."
ground_truth: "01-add-item.luau"
expected_apis:
  - "GetService"
  - "Debris"
  - "AddItem"
  - "Instance.new"
  - "Color3.fromRGB"
expected_patterns:
  - "get-service"
  - "debris-cleanup"
