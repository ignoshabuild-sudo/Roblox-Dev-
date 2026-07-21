-- context: client
-- apis: ContextActionService, BindAction, GetService, UserInputState, TouchButton
local ContextActionService = game:GetService("ContextActionService")

local function onJumpAction(actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
if inputState == Enum.UserInputState.Begin then
print("Jump pressed via " .. actionName)
end
return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
"Jump",
onJumpAction,
true,  -- createTouchButton for mobile players
Enum.KeyCode.Space
)

ContextActionService:BindAction(
"Interact",
function(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
if inputState == Enum.UserInputState.Begin then
print("Interact pressed")
end
return Enum.ContextActionResult.Sink
end,
true,  -- mobile-compatible
Enum.KeyCode.E,
Enum.KeyCode.ButtonA
)

print("Mobile-compatible controls bound")
</EOF>

cat > "$T/17-contextactionservice/02-mobile-input.yaml" << 'EOF'
id: "17-contextactionservice-02-mobile-input"
category: "contextactionservice"
context_type: "client"
prompt: "Create a client LocalScript that binds 'Jump' and 'Interact' actions with createTouchButton=true for mobile support. Use Space for Jump and E/ButtonA for Interact. Return Sink for Interact, Pass for Jump."
ground_truth: "02-mobile-input.luau"
expected_apis:
  - "GetService"
  - "ContextActionService"
  - "BindAction"
  - "ContextActionResult"
expected_patterns:
  - "get-service"
  - "action-binding"
  - "mobile-input"
