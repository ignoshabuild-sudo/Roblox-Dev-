-- context: server
-- apis: DataStoreService, GetDataStore, UpdateAsync, pcall, Players
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local dataStore = DataStoreService:GetDataStore("CoinStore")

local MAX_RETRIES = 3

local function addCoins(player: Player, amount: number): boolean
	local success, errorMessage = pcall(function()
		dataStore:UpdateAsync(player.UserId, function(oldValue: number?)
			local current = oldValue or 0
			return current + amount
		end)
	end)

	if not success then
		-- Retry logic with exponential backoff
		for attempt = 1, MAX_RETRIES do
			task.wait(2 ^ attempt)
			local retrySuccess, retryError = pcall(function()
				dataStore:UpdateAsync(player.UserId, function(oldValue: number?)
					local current = oldValue or 0
					return current + amount
				end)
			end)
			if retrySuccess then
				print("Retry succeeded on attempt " .. attempt)
				return true
			else
				warn("Retry " .. attempt .. " failed: " .. tostring(retryError))
			end
		end
		warn("All retries exhausted for " .. player.Name)
		return false
	end

	return true
end
