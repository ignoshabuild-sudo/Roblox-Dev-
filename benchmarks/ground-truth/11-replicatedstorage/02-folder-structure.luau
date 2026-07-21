-- context: server
-- apis: ReplicatedStorage, Instance.new, Folder, GetService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function setupAssetStructure()
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local events = Instance.new("Folder")
events.Name = "Events"
events.Parent = remotes

local functions = Instance.new("Folder")
functions.Name = "Functions"
functions.Parent = remotes

local modules = Instance.new("Folder")
modules.Name = "Modules"
modules.Parent = ReplicatedStorage

local assets = Instance.new("Folder")
assets.Name = "Assets"
assets.Parent = ReplicatedStorage

return remotes, modules, assets
end

local remotes, modules, assets = setupAssetStructure()
print("Created folders: " .. remotes.Name .. ", " .. modules.Name .. ", " .. assets.Name)
</EOF>

cat > "$T/11-replicatedstorage/02-folder-structure.yaml" << 'EOF'
id: "11-replicatedstorage-02-folder-structure"
category: "replicatedstorage"
context_type: "server"
prompt: "Create a server Script that organizes ReplicatedStorage with a hierarchy of Folders: Remotes/Events, Remotes/Functions, Modules, and Assets using Instance.new('Folder')."
ground_truth: "02-folder-structure.luau"
expected_apis:
  - "GetService"
  - "ReplicatedStorage"
  - "Instance.new"
  - "Folder"
expected_patterns:
  - "get-service"
  - "asset-organization"
