-- context: server
-- apis: RunService, Heartbeat, GetService
local RunService = game:GetService("RunService")

local totalElapsed = 0

local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
totalElapsed += deltaTime

-- Perform server-authoritative work each frame, e.g. physics updates
if totalElapsed >= 10 then
print("10 seconds elapsed, disconnecting heartbeat")
connection:Disconnect()
end
end)
</EOF>

cat > "$T/10-runservice/01-heartbeat-loop.yaml" << 'EOF'
id: "10-runservice-01-heartbeat-loop"
category: "runservice"
context_type: "server"
prompt: "Create a server Script that connects to RunService.Heartbeat to track elapsed time and disconnects after 10 seconds."
ground_truth: "01-heartbeat-loop.luau"
expected_apis:
  - "GetService"
  - "RunService"
  - "Heartbeat"
  - "Connect"
  - "Disconnect"
expected_patterns:
  - "get-service"
  - "heartbeat-loop"
