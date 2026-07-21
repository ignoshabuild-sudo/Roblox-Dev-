-- context: server
-- apis: HttpService, GetAsync, JSONDecode, pcall, GetService
local HttpService = game:GetService("HttpService")

local function fetchPlayerData(userId: number): {[string]: any}?
local url = "https://api.example.com/players/" .. tostring(userId)

local success, result = pcall(function()
return HttpService:GetAsync(url)
end)

if not success then
warn("HTTP GET failed: " .. tostring(result))
return nil
end

local decodeSuccess, data = pcall(function()
return HttpService:JSONDecode(result)
end)

if not decodeSuccess then
warn("JSON decode failed: " .. tostring(data))
return nil
end

return data :: {[string]: any}
end

local playerData = fetchPlayerData(156)
if playerData then
print("Fetched player: " .. tostring(playerData.username))
end
</EOF>

cat > "$T/15-httpservice/01-get-request.yaml" << 'EOF'
id: "15-httpservice-01-get-request"
category: "httpservice"
context_type: "server"
prompt: "Create a server Script with a function that makes an HTTP GET request using HttpService:GetAsync, then decodes the JSON response. Wrap both the request and decode in pcall for error handling."
ground_truth: "01-get-request.luau"
expected_apis:
  - "GetService"
  - "HttpService"
  - "GetAsync"
  - "JSONDecode"
  - "pcall"
expected_patterns:
  - "get-service"
  - "http-request"
  - "error-handling"
  - "json-decode"
