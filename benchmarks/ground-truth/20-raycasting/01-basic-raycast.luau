-- context: server
-- apis: Workspace, Raycast, RaycastParams, GetService
local function shootRay(origin: Vector3, direction: Vector3, maxDistance: number): RaycastResult?
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {}

local raycastResult = workspace:Raycast(origin, direction * maxDistance, params)

if raycastResult then
local hitPosition = raycastResult.Position
local hitInstance = raycastResult.Instance
local hitNormal = raycastResult.Normal
local hitMaterial = raycastResult.Material

print("Hit: " .. hitInstance.Name .. " at " .. tostring(hitPosition))
print("  Material: " .. tostring(hitMaterial) .. ", Normal: " .. tostring(hitNormal))

return raycastResult
end

return nil
end

shootRay(Vector3.new(0, 10, 0), Vector3.new(0, -1, 0), 100)
</EOF>

cat > "$T/20-raycasting/01-basic-raycast.yaml" << 'EOF'
id: "20-raycasting-01-basic-raycast"
category: "raycasting"
context_type: "server"
prompt: "Create a server Script that performs a raycast using workspace:Raycast with RaycastParams. Shoot a ray downward from (0,10,0), print the hit instance name, position, material, and normal."
ground_truth: "01-basic-raycast.luau"
expected_apis:
  - "workspace"
  - "Raycast"
  - "RaycastParams"
  - "RaycastResult"
  - "RaycastFilterType"
expected_patterns:
  - "raycast-hit"
  - "hit-detection"
