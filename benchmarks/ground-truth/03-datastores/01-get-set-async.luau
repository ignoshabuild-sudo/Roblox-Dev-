-- context: server
-- apis: DataStoreService, GetDataStore, SetAsync, GetAsync, pcall, Players
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local dataStore = DataStoreService:GetDataStore("PlayerData")

local function saveData(player: Player, data: {[string]: any}): boolean
	local success, errorMessage = pcall(function()
		dataStore:SetAsync(player.UserId, data)
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(errorMessage))
		return false
	end

	return true
end

local function loadData(player: Player): {[string]: any} | nil
	local success, result = pcall(function()
		return dataStore:GetAsync(player.UserId)
	end)

	if not success then
		warn("Failed to load data for " .. player.Name .. ": " .. tostring(result))
		return nil
	end

	return result or {}
end

Players.PlayerAdded:Connect(function(player: Player)
	local data = loadData(player)
	if data then
		print("Loaded data for " .. player.Name)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local playerData = {
		coins = 0,
		lastPlayed = os.time(),
	}
	saveData(player, playerData)
end)
