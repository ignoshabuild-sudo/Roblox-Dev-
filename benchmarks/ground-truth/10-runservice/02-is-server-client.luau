-- context: shared
-- apis: RunService, IsServer, IsClient, Stepped, GetService
local RunService = game:GetService("RunService")

if RunService:IsServer() then
-- Server-side logic
print("Running on server")
RunService.Stepped:Connect(function(_time: number, deltaTime: number)
-- Physics-bound update
end)
elseif RunService:IsClient() then
-- Client-side logic
print("Running on client")
RunService.RenderStepped:Connect(function(deltaTime: number)
-- Render-bound update (before each frame render)
end)
end
</EOF>

cat > "$T/10-runservice/02-is-server-client.yaml" << 'EOF'
id: "10-runservice-02-is-server-client"
category: "runservice"
context_type: "shared"
prompt: "Create a shared script that uses RunService:IsServer() and IsClient() to branch logic. On server, connect to Stepped for physics updates. On client, connect to RenderStepped for render updates."
ground_truth: "02-is-server-client.luau"
expected_apis:
  - "GetService"
  - "RunService"
  - "IsServer"
  - "IsClient"
  - "Stepped"
  - "RenderStepped"
expected_patterns:
  - "get-service"
  - "server-client-guard"
