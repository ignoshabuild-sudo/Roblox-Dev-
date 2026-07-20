-- context: server
-- apis: Instance.new, RemoteEvent, OnServerEvent, Connect, ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "Ping"
remoteEvent.Parent = ReplicatedStorage

remoteEvent.OnServerEvent:Connect(function(player, message)
	print(player.Name .. " sent: " .. message)
end)
