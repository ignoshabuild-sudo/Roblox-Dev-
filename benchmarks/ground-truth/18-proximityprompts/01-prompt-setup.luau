-- context: client
-- apis: ProximityPrompt, Instance.new, Triggered, GetService
local function createPrompt(parent: Instance, actionText: string, holdDuration: number): ProximityPrompt
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = actionText
prompt.HoldDuration = holdDuration
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = true
prompt.Parent = parent
return prompt
end

local door = workspace:FindFirstChild("Door")
if door then
local prompt = createPrompt(door, "Open Door", 1.5)
prompt.Triggered:Connect(function(player: Player)
print(player.Name .. " opened the door")
door.Transparency = 0.5
end)
end
</EOF>

cat > "$T/18-proximityprompts/01-prompt-setup.yaml" << 'EOF'
id: "18-proximityprompts-01-prompt-setup"
category: "proximityprompts"
context_type: "client"
prompt: "Create a client LocalScript that creates a ProximityPrompt on a Door part with ActionText 'Open Door', HoldDuration 1.5, MaxActivationDistance 10, and line-of-sight required. Connect Triggered to handle interaction."
ground_truth: "01-prompt-setup.luau"
expected_apis:
  - "Instance.new"
  - "ProximityPrompt"
  - "Triggered"
  - "Connect"
expected_patterns:
  - "prompt-setup"
  - "triggered-event"
