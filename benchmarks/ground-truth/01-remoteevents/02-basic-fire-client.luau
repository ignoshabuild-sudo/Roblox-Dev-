-- context: client
-- apis: ReplicatedStorage, RemoteEvent, FireServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvent = ReplicatedStorage:WaitForChild("Ping")

remoteEvent:FireServer("Hello from client!")
