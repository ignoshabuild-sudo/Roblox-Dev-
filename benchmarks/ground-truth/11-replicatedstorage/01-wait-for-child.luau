-- context: client
-- apis: ReplicatedStorage, WaitForChild, GetService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getRemotesFolder(): Folder
return ReplicatedStorage:WaitForChild("Remotes", 5) :: Folder
end

local function getRemoteEvent(name: string): RemoteEvent
local remotes = getRemotesFolder()
return remotes:WaitForChild(name) :: RemoteEvent
end

local function getModuleScript(name: string): ModuleScript
return ReplicatedStorage:WaitForChild("Modules"):WaitForChild(name) :: ModuleScript
end

local pingEvent = getRemoteEvent("Ping")
print("Loaded Ping event: " .. pingEvent.Name)
</EOF>

cat > "$T/11-replicatedstorage/01-wait-for-child.yaml" << 'EOF'
id: "11-replicatedstorage-01-wait-for-child"
category: "replicatedstorage"
context_type: "client"
prompt: "Create a client LocalScript that uses ReplicatedStorage:WaitForChild to access a 'Remotes' folder, then retrieves a RemoteEvent named 'Ping'. Include a helper to load ModuleScripts from a 'Modules' folder."
ground_truth: "01-wait-for-child.luau"
expected_apis:
  - "GetService"
  - "ReplicatedStorage"
  - "WaitForChild"
expected_patterns:
  - "get-service"
  - "wait-for-child"
  - "asset-organization"
