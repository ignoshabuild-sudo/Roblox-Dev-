-- context: server
-- apis: Workspace, Raycast, RaycastParams, GetService, Players
local Players = game:GetService("Players")

local function raycastFromCamera(player: Player, maxDistance: number): RaycastResult?
local character = player.Character
if not character then return nil end

local head = character:FindFirstChild("Head") :: BasePart?
if not head then return nil end

local origin = head.Position
local direction = head.CFrame.LookVector

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {character}
params.IgnoreWater = true

local raycastResult = workspace:Raycast(origin, direction * maxDistance, params)

return raycastResult
end

Players.PlayerAdded:Connect(function(player: Player)
player.CharacterAdded:Connect(function(_character)
task.wait(1)
local hit = raycastFromCamera(player, 50)
if hit then
local target = hit.Instance
if target:FindFirstChild("Humanoid") then
print(player.Name .. " is looking at: " .. target.Name)
end
end
end)
end)
</EOF>

cat > "$T/20-raycasting/02-raycast-params.yaml" << 'EOF'
id: "20-raycasting-02-raycast-params"
category: "raycasting"
context_type: "server"
prompt: "Create a server Script that raycasts from a player's head in their look direction using RaycastParams that exclude the player's own character and ignore water. Check if the hit target has a Humanoid."
ground_truth: "02-raycast-params.luau"
expected_apis:
  - "GetService"
  - "workspace"
  - "Raycast"
  - "RaycastParams"
  - "RaycastFilterType"
  - "Players"
  - "PlayerAdded"
  - "CharacterAdded"
expected_patterns:
  - "get-service"
  - "raycast-hit"
  - "hit-detection"
  - "player-character"
