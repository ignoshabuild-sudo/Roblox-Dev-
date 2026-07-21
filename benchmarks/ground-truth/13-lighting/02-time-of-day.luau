-- context: server
-- apis: Lighting, GetService, RunService, ClockTime
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local DAY_LENGTH = 300  -- seconds for a full day cycle
local timeOfDay = 0

RunService.Heartbeat:Connect(function(deltaTime: number)
timeOfDay = (timeOfDay + deltaTime / DAY_LENGTH * 24) % 24
Lighting.ClockTime = timeOfDay

-- Adjust fog based on time (dense at night, clear at day)
local isNighttime = timeOfDay < 6 or timeOfDay > 20
Lighting.FogEnd = if isNighttime then 200 else 2000
Lighting.FogStart = if isNighttime then 20 else 500
end)
</EOF>

cat > "$T/13-lighting/02-time-of-day.yaml" << 'EOF'
id: "13-lighting-02-time-of-day"
category: "lighting"
context_type: "server"
prompt: "Create a server Script that drives a day-night cycle by updating Lighting.ClockTime each Heartbeat frame. Reduce fog distance at night and increase it during daytime over a configurable DAY_LENGTH."
ground_truth: "02-time-of-day.luau"
expected_apis:
  - "GetService"
  - "Lighting"
  - "RunService"
  - "Heartbeat"
  - "ClockTime"
  - "FogEnd"
  - "FogStart"
expected_patterns:
  - "get-service"
  - "day-night-cycle"
  - "heartbeat-loop"
