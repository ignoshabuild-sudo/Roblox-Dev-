-- context: client
-- apis: TweenService, TweenInfo, Create, Play, Instance.new
local TweenService = game:GetService("TweenService")

local part = Instance.new("Part")
part.Position = Vector3.new(0, 0, 0)
part.Parent = workspace

local tweenInfo = TweenInfo.new(
2,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out,
0,
false,
0
)

local tween = TweenService:Create(part, tweenInfo, {
Position = Vector3.new(10, 5, 0),
})

tween:Play()
</EOF>

cat > "$T/04-tweenservice/01-basic-tween.yaml" << 'EOF'
id: "04-tweenservice-01-basic-tween"
category: "tweenservice"
context_type: "client"
prompt: "Create a client LocalScript that uses TweenService to tween a Part from position (0,0,0) to (10,5,0) over 2 seconds using a Quad easing style."
ground_truth: "01-basic-tween.luau"
expected_apis:
  - "GetService"
  - "TweenService"
  - "TweenInfo"
  - "Create"
  - "Play"
  - "Instance.new"
expected_patterns:
  - "tween-play"
  - "get-service"
