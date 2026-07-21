-- context: server
-- apis: Instance.new, RemoteFunction, OnServerInvoke, ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "GetServerTime"
remoteFunction.Parent = ReplicatedStorage

remoteFunction.OnServerInvoke = function(player)
	return os.time()
end
