-- context: client
-- apis: SoundService, Sound, Instance.new, Play, GetService
local SoundService = game:GetService("SoundService")

local function playSound(soundId: string, volume: number?)
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://" .. soundId
sound.Volume = volume or 1
sound.Parent = SoundService
sound:Play()

sound.Ended:Connect(function()
sound:Destroy()
end)

return sound
end

local bgMusic = playSound("1837854234", 0.5)
print("Playing background music...")
</EOF>

cat > "$T/12-soundservice/01-sound-playback.yaml" << 'EOF'
id: "12-soundservice-01-sound-playback"
category: "soundservice"
context_type: "client"
prompt: "Create a client LocalScript that creates a Sound instance parented to SoundService, sets its SoundId from an asset ID, plays it, and cleans up on End. Include volume control."
ground_truth: "01-sound-playback.luau"
expected_apis:
  - "GetService"
  - "SoundService"
  - "Instance.new"
  - "Sound"
  - "Play"
  - "Ended"
  - "Destroy"
expected_patterns:
  - "get-service"
  - "sound-playback"
