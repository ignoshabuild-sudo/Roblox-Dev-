-- context: client
-- apis: UserInputService, InputEnded, GetService, KeyCode
local UserInputService = game:GetService("UserInputService")

local keysHeld: {[Enum.KeyCode]: boolean} = {}

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
if not gameProcessed then
keysHeld[input.KeyCode] = true
print("Key down: " .. tostring(input.KeyCode))
end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
keysHeld[input.KeyCode] = nil
print("Key up: " .. tostring(input.KeyCode))
end)

local function isKeyDown(key: Enum.KeyCode): boolean
return keysHeld[key] == true
end
</EOF>

cat > "$T/09-userinputservice/02-input-ended.yaml" << 'EOF'
id: "09-userinputservice-02-input-ended"
category: "userinputservice"
context_type: "client"
prompt: "Create a client LocalScript that tracks held keys using InputBegan and InputEnded. Maintain a dictionary of currently held keys and expose an isKeyDown helper function."
ground_truth: "02-input-ended.luau"
expected_apis:
  - "GetService"
  - "UserInputService"
  - "InputBegan"
  - "InputEnded"
  - "KeyCode"
expected_patterns:
  - "get-service"
  - "input-detection"
  - "key-tracking"
