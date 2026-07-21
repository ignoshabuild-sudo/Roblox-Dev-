-- context: server
-- apis: Debris, AddItem, Instance.new, GetService, RunService
local Debris = game:GetService("Debris")

local function createExplosion(center: Vector3)
local debrisCount = 12

for i = 1, debrisCount do
local part = Instance.new("Part")
part.Size = Vector3.new(1, 1, 1)
part.Color = Color3.fromRGB(math.random(200, 255), math.random(100, 200), 0)
part.Anchored = false
part.Position = center + Vector3.new(
math.random(-3, 3),
math.random(-3, 3),
math.random(-3, 3)
)

-- Apply random velocity
part.Velocity = Vector3.new(
math.random(-20, 20),
math.random(20, 40),
math.random(-20, 20)
)
part.Parent = workspace

-- Auto-cleanup after 4 seconds
Debris:AddItem(part, 4)
end
end

createExplosion(Vector3.new(0, 10, 0))
print("Explosion debris created, will cleanup in 4 seconds")
</EOF>

cat > "$T/19-debris-service/02-cleanup-patterns.yaml" << 'EOF'
id: "19-debris-service-02-cleanup-patterns"
category: "debris-service"
context_type: "server"
prompt: "Create a server Script that simulates an explosion by spawning 12 debris parts with random colors and velocities from a center point, then adds all parts to Debris with a 4-second lifetime."
ground_truth: "02-cleanup-patterns.luau"
expected_apis:
  - "GetService"
  - "Debris"
  - "AddItem"
  - "Instance.new"
  - "Color3.fromRGB"
  - "math.random"
expected_patterns:
  - "get-service"
  - "debris-cleanup"
  - "particle-burst"
