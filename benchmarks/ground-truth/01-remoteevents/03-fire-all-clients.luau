-- context: server
-- apis: Instance.new, RemoteEvent, FireAllClients, ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "Broadcast"
remoteEvent.Parent = ReplicatedStorage

-- Broadcast a message to all connected players
local function broadcastMessage(message: string)
	remoteEvent:FireAllClients(message)
end

-- Example: broadcast after a short delay
task.wait(3)
broadcastMessage("Welcome, everyone!")
