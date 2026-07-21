-- context: server
-- apis: Players, GetPlayerByUserId, GetService
local Players = game:GetService("Players")

local function getPlayerNameFromId(userId: number): string
local player: Player? = Players:GetPlayerByUserId(userId)
if player then
return player.Name
else
return "Unknown Player"
end
end

local function isPlayerOnline(userId: number): boolean
return Players:GetPlayerByUserId(userId) ~= nil
end

print(getPlayerNameFromId(156))  -- Example: ROBLOX user
</EOF>

cat > "$T/08-players-service/02-get-player-by-userid.yaml" << 'EOF'
id: "08-players-service-02-get-player-by-userid"
category: "players-service"
context_type: "server"
prompt: "Create a server Script with a helper function that uses Players:GetPlayerByUserId to look up an online player by their userId. Include a function that returns the player's name or 'Unknown Player' if offline."
ground_truth: "02-get-player-by-userid.luau"
expected_apis:
  - "GetService"
  - "Players"
  - "GetPlayerByUserId"
expected_patterns:
  - "get-service"
  - "player-lookup"
