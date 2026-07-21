-- context: client
-- apis: SoundService, Sound, Instance.new, Play, GetService, pcall
local SoundService = game:GetService("SoundService")

local function loadAndPlaySound(assetId: string): Sound?
local success, sound = pcall(function()
local s = Instance.new("Sound")
s.SoundId = "rbxassetid://" .. assetId
s.Parent = SoundService
return s
end)

if not success then
warn("Failed to create Sound: " .. tostring(sound))
return nil
end

local castedSound = sound :: Sound

local loadedSuccess, loaded = pcall(function()
castedSound.Loaded:Wait()
return true
end)

if not loadedSuccess then
warn("Sound failed to load: " .. tostring(loaded))
castedSound:Destroy()
return nil
end

castedSound:Play()
return castedSound
end

local sfx = loadAndPlaySound("9120384567")
if sfx then
print("Sound effect playing")
end
</EOF>

cat > "$T/12-soundservice/02-error-handling.yaml" << 'EOF'
id: "12-soundservice-02-error-handling"
category: "soundservice"
context_type: "client"
prompt: "Create a client LocalScript with a function that safely loads and plays a Sound using pcall. Wait for the sound to load, handle creation and loading errors, and clean up on failure."
ground_truth: "02-error-handling.luau"
expected_apis:
  - "GetService"
  - "SoundService"
  - "Instance.new"
  - "Sound"
  - "Play"
  - "pcall"
  - "Loaded"
  - "Destroy"
expected_patterns:
  - "get-service"
  - "sound-playback"
  - "error-handling"
