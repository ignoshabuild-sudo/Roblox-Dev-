-- context: client
-- apis: ContextActionService, BindAction, UnbindAction, GetService, KeyCode
local ContextActionService = game:GetService("ContextActionService")

local ACTION_NAME = "Dash"
local bound = false

local function onDashAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
if inputState == Enum.UserInputState.Begin then
print("Dash activated!")
return Enum.ContextActionResult.Sink
end
return Enum.ContextActionResult.Pass
end

local function enableDash()
if not bound then
ContextActionService:BindAction(
ACTION_NAME,
onDashAction,
false,  -- createTouchButton
Enum.KeyCode.LeftShift,
Enum.KeyCode.ButtonR2
)
bound = true
print("Dash bound")
end
end

local function disableDash()
if bound then
ContextActionService:UnbindAction(ACTION_NAME)
bound = false
print("Dash unbound")
end
end

enableDash()
</EOF>

cat > "$T/17-contextactionservice/01-bind-unbind.yaml" << 'EOF'
id: "17-contextactionservice-01-bind-unbind"
category: "contextactionservice"
context_type: "client"
prompt: "Create a client LocalScript that binds a 'Dash' action to LeftShift and ButtonR2 using ContextActionService:BindAction. Handle input state, return Sink on Begin, and include enableDash/disableDash functions with UnbindAction."
ground_truth: "01-bind-unbind.luau"
expected_apis:
  - "GetService"
  - "ContextActionService"
  - "BindAction"
  - "UnbindAction"
  - "ContextActionResult"
expected_patterns:
  - "get-service"
  - "action-binding"
  - "input-detection"
