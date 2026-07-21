-- context: client
-- apis: TweenService, TweenInfo, Create, Play, Completed, Instance.new
local TweenService = game:GetService("TweenService")

local part = Instance.new("Part")
part.Position = Vector3.new(0, 0, 0)
part.Parent = workspace

local tweenInfo = TweenInfo.new(
1,
Enum.EasingStyle.Linear,
Enum.EasingDirection.Out,
0,
false,
0
)

local tween1 = TweenService:Create(part, tweenInfo, {
Position = Vector3.new(10, 0, 0),
})

local tween2 = TweenService:Create(part, tweenInfo, {
Position = Vector3.new(10, 10, 0),
})

local tween3 = TweenService:Create(part, tweenInfo, {
Position = Vector3.new(0, 10, 0),
})

tween1:Play()
tween1.Completed:Connect(function()
tween2:Play()
tween2.Completed:Connect(function()
tween3:Play()
end)
end)
</EOF>

cat > "$T/04-tweenservice/02-chained-twens.yaml" << 'EOF'
id: "04-tweenservice-02-chained-twens"
category: "tweenservice"
context_type: "client"
prompt: "Write a client LocalScript that creates three chained tweens on a Part: move right, then up, then left, each over 1 second using the Completed event to chain them."
ground_truth: "02-chained-twens.luau"
expected_apis:
  - "GetService"
  - "TweenService"
  - "TweenInfo"
  - "Create"
  - "Play"
  - "Completed"
  - "Instance.new"
expected_patterns:
  - "tween-play"
  - "chained-tweens"
  - "get-service"
