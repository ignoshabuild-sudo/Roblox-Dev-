-- context: client
-- apis: UserInputService, InputBegan, GetService, KeyCode
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
if gameProcessedEvent then
return
end

if input.KeyCode == Enum.KeyCode.E then
print("Player pressed E - Interact!")
elseif input.KeyCode == Enum.KeyCode.Space then
print("Player pressed Space - Jump!")
elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
print("Player clicked MouseButton1")
end
end)
</EOF>

cat > "$T/09-userinputservice/01-input-began.yaml" << 'EOF'
id: "09-userinputservice-01-input-began"
category: "userinputservice"
context_type: "client"
prompt: "Create a client LocalScript that listens for InputBegan on UserInputService. Detect E key for interaction, Space for jumping, and MouseButton1 click. Skip game-processed events."
ground_truth: "01-input-began.luau"
expected_apis:
  - "GetService"
  - "UserInputService"
  - "InputBegan"
  - "Connect"
  - "InputObject"
expected_patterns:
  - "get-service"
  - "input-detection"
  - "keycode-check"
