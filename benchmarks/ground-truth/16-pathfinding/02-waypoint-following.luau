-- context: server
-- apis: PathfindingService, CreatePath, ComputeAsync, GetWaypoints, RunService
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local function followPath(npc: Model, target: Vector3)
local humanoid = npc:FindFirstChild("Humanoid") :: Humanoid?
if not humanoid then return end

local path = PathfindingService:CreatePath()
path:ComputeAsync(npc.PrimaryPart.Position, target)

if path.Status ~= Enum.PathStatus.Success then
warn("No path found for " .. npc.Name)
return
end

local waypoints = path:GetWaypoints()
for _, waypoint in ipairs(waypoints) do
if waypoint.Action == Enum.PathWaypointAction.Jump then
humanoid.Jump = true
end
humanoid:MoveTo(waypoint.Position)
humanoid.MoveToFinished:Wait()
end

print(npc.Name .. " reached destination")
end
</EOF>

cat > "$T/16-pathfinding/02-waypoint-following.yaml" << 'EOF'
id: "16-pathfinding-02-waypoint-following"
category: "pathfinding"
context_type: "server"
prompt: "Create a server Script that makes an NPC Model follow a computed path to a target. Iterate waypoints, handle Jump actions, use Humanoid:MoveTo and MoveToFinished:Wait() to move through each waypoint."
ground_truth: "02-waypoint-following.luau"
expected_apis:
  - "GetService"
  - "PathfindingService"
  - "CreatePath"
  - "ComputeAsync"
  - "GetWaypoints"
  - "Humanoid"
  - "MoveTo"
  - "MoveToFinished"
expected_patterns:
  - "get-service"
  - "pathfinding"
  - "waypoint-tracking"
