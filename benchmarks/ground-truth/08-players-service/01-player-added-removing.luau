-- context: server
-- apis: Players, PlayerAdded, PlayerRemoving, GetService
local Players = game:GetService("Players")

local playerCount = 0

Players.PlayerAdded:Connect(function(player: Player)
playerCount += 1
print(player.Name .. " joined. Players online: " .. playerCount)

local leaderstats = Instance.new("Folder")
leaderstats.Name = "leaderstats"
leaderstats.Parent = player

local coins = Instance.new("IntValue")
coins.Name = "Coins"
coins.Value = 0
coins.Parent = leaderstats
end)

Players.PlayerRemoving:Connect(function(player: Player)
playerCount -= 1
print(player.Name .. " left. Players online: " .. playerCount)
end)
</EOF>

cat > "$T/08-players-service/01-player-added-removing.yaml" << 'EOF'
id: "08-players-service-01-player-added-removing"
category: "players-service"
context_type: "server"
prompt: "Create a server Script that tracks player count using Players.PlayerAdded and PlayerRemoving events. On join, create a leaderstats folder with a Coins IntValue for the player."
ground_truth: "01-player-added-removing.luau"
expected_apis:
  - "GetService"
  - "Players"
  - "PlayerAdded"
  - "PlayerRemoving"
  - "Instance.new"
expected_patterns:
  - "get-service"
  - "player-join-leave"
  - "leaderstats"
