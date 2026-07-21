-- context: server
-- apis: PathfindingService, CreatePath, ComputeAsync, GetService
local PathfindingService = game:GetService("PathfindingService")

local function createPathToTarget(start: Vector3, finish: Vector3): Path
local path = PathfindingService:CreatePath({
AgentRadius = 2,
AgentHeight = 5,
AgentMaxSlope = 45,
AgentCanJump = true,
Costs = {
Water = 10,
},
})

local success, errorMessage = pcall(function()
path:ComputeAsync(start, finish)
end)

if not success then
warn("Path computation failed: " .. tostring(errorMessage))
end

return path
end

local path = createPathToTarget(Vector3.new(0, 0, 0), Vector3.new(100, 0, 50))
if path.Status == Enum.PathStatus.Success then
print("Path computed with " .. #path:GetWaypoints() .. " waypoints")
end
</EOF>

cat > "$T/16-pathfinding/01-create-compute-path.yaml" << 'EOF'
id: "16-pathfinding-01-create-compute-path"
category: "pathfinding"
context_type: "server"
prompt: "Create a server Script that uses PathfindingService:CreatePath with agent parameters (radius, height, slope, water cost) and computes a path between two Vector3 positions. Check PathStatus.Success and print waypoint count."
ground_truth: "01-create-compute-path.luau"
expected_apis:
  - "GetService"
  - "PathfindingService"
  - "CreatePath"
  - "ComputeAsync"
  - "GetWaypoints"
  - "PathStatus"
expected_patterns:
  - "get-service"
  - "pathfinding"
  - "error-handling"
