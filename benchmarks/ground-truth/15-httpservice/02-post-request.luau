-- context: server
-- apis: HttpService, PostAsync, JSONEncode, JSONDecode, pcall, GetService
local HttpService = game:GetService("HttpService")

local function postPlayerStats(userId: number, stats: {[string]: any}): boolean
local url = "https://api.example.com/stats"
local body = HttpService:JSONEncode({
userId = userId,
stats = stats,
timestamp = os.time(),
})

local success, result = pcall(function()
return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
end)

if not success then
warn("HTTP POST failed: " .. tostring(result))
return false
end

local decodeSuccess, response = pcall(function()
return HttpService:JSONDecode(result)
end)

if not decodeSuccess then
warn("Response decode failed: " .. tostring(response))
return false
end

local data = response :: {[string]: any}
return data.success == true
end

postPlayerStats(156, {score = 5000, level = 10})
</EOF>

cat > "$T/15-httpservice/02-post-request.yaml" << 'EOF'
id: "15-httpservice-02-post-request"
category: "httpservice"
context_type: "server"
prompt: "Create a server Script with a function that posts player stats via HttpService:PostAsync with JSON-encoded body and ApplicationJson content type. Handle errors with pcall and decode the response."
ground_truth: "02-post-request.luau"
expected_apis:
  - "GetService"
  - "HttpService"
  - "PostAsync"
  - "JSONEncode"
  - "JSONDecode"
  - "pcall"
  - "ApplicationJson"
expected_patterns:
  - "get-service"
  - "http-request"
  - "error-handling"
  - "json-encode"
