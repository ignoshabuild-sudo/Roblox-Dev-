--!strict
-- AIService: Knit Service that orchestrates communication between the
-- Roblox Studio plugin and the AI Code Assistant backend.
--
-- Responsibilities:
--  - Provide a clean, typed API for the plugin UI to call
--  - Manage HttpService lifecycle and API base URL configuration
--  - Handle API key authentication and credit tracking
--  - Handle errors gracefully and surface them to the UI layer
--  - Enforce the sandbox constraint: NEVER execute generated code
--
-- Usage from Client:
--   local AIService = Knit.GetService("AIService")
--   local authResult = AIService:Authenticate("player", "api-key-here"):await()
--   local result = AIService:GenerateCode("player", "spawn a part", "server"):await()
--
-- Usage from plugin (direct):
--   local AIService = require(script.Parent.AIService)
--   local authResult = AIService:Authenticate(nil, "api-key-here")
--   local result = AIService:GenerateCode(nil, "spawn a part", "server")

local Knit = require(script.Parent.Parent.Packages.Knit)
local Types = require(script.Parent.Parent.Shared.Types)
local HttpService = require(script.HttpService)

local AIService = Knit.CreateService({
	Name = "AIService",
	Client = {},
})

-- ── Internal state ──────────────────────────────────────────────────────

local _http: typeof(HttpService) = nil
local _apiBaseUrl: string = require(script.Parent.Parent.Shared.Constants).DEFAULT_API_BASE_URL
local _apiKey: string = ""
local _tier: string = "free"

-- ── Lifecycle ───────────────────────────────────────────────────────────

function AIService:KnitStart()
	_http = HttpService.new(_apiBaseUrl)
	print("[AIService] Started — API base URL: " .. _apiBaseUrl)
end

-- ── Configuration ───────────────────────────────────────────────────────

function AIService:SetApiBaseUrl(url: string)
	_apiBaseUrl = url
	_http = HttpService.new(_apiBaseUrl)
	if _apiKey ~= "" then
		_http:setApiKey(_apiKey)
	end
end

-- ── Authentication ──────────────────────────────────────────────────────

-- Validate an API key with the backend and store the tier.
-- The `player` parameter is required by Knit for Client methods;
-- pass `nil` when calling directly from a plugin script.
function AIService:Authenticate(player: Player?, apiKey: string): Types.HttpResult<Types.ValidateKeyResponse>
	if not _http then
		_http = HttpService.new(_apiBaseUrl)
	end

	local result = _http:validateKey(apiKey)

	if result.success and result.data then
		if result.data.valid then
			_apiKey = apiKey
			_tier = result.data.tier or "free"
			_http:setApiKey(apiKey)
			print("[AIService] Authenticated — tier: " .. _tier)
		else
			_apiKey = ""
			_tier = "free"
			_http:setApiKey("")
		end
	end

	return result
end

-- ── Backend health check ────────────────────────────────────────────────

function AIService:CheckHealth(): Types.HttpResult<Types.HealthResponse>
	if not _http then
		return {
			success = false,
			error = { statusCode = 503, message = "Service not started" },
		}
	end
	return _http:health()
end

-- ── Documentation query ─────────────────────────────────────────────────

function AIService:QueryDocs(query: string, topK: number?): Types.HttpResult<Types.QueryResponse>
	if not _http then
		return {
			success = false,
			error = { statusCode = 503, message = "Service not started" },
		}
	end

	local req: Types.QueryRequest = {
		query = query,
		topK = topK,
	}

	return _http:query(req)
end

-- ── Code generation ─────────────────────────────────────────────────────
-- NON-NEGOTIABLE: The returned code is NEVER executed.
-- Plugin UI must only display and offer copy-to-clipboard.

function AIService:GenerateCode(
	player: Player?,
	query: string,
	contextType: Types.ContextType?,
	topK: number?,
	model: string?
): Types.HttpResult<Types.GenerateResponse>
	if not _http then
		return {
			success = false,
			error = { statusCode = 503, message = "Service not started" },
		}
	end

	if _apiKey == "" then
		return {
			success = false,
			error = { statusCode = 401, message = "Not authenticated — connect with an API key first" },
		}
	end

	-- Quick credit check before sending (best-effort, backend also enforces).
	local creditResult = _http:getCredits()
	if creditResult.success and creditResult.data then
		if creditResult.data.creditsRemaining <= 0 then
			return {
				success = false,
				error = {
					statusCode = 402,
					message = "No credits remaining. Upgrade your tier or wait for daily reset.",
				},
			}
		end
	end

	local req: Types.GenerateRequest = {
		query = query,
		contextType = contextType,
		topK = topK,
		model = model,
	}

	local result = _http:generate(req)

	-- Safety assertion: generated code is returned as a display-only string.
	-- Under no circumstances do we loadstring() or execute this code.
	if result.success and result.data then
		print(string.format(
			"[AIService] Code generated — %d chars, model: %s, uncertain: %s, %.0fms",
			#result.data.code,
			result.data.modelUsed,
			tostring(result.data.isUncertain),
			result.data.totalTimeMs
		))
	end

	return result
end

-- ── Credit management ───────────────────────────────────────────────────

function AIService:GetCredits(player: Player?): Types.HttpResult<Types.CreditsResponse>
	if not _http then
		return {
			success = false,
			error = { statusCode = 503, message = "Service not started" },
		}
	end

	if _apiKey == "" then
		return {
			success = false,
			error = { statusCode = 401, message = "Not authenticated — connect with an API key first" },
		}
	end

	return _http:getCredits()
end

-- ── Tier accessor ───────────────────────────────────────────────────────

function AIService:GetTier(): string
	return _tier
end

function AIService:IsAuthenticated(): boolean
	return _apiKey ~= ""
end

-- ── Client-facing methods (exposed to Knit client via RemoteFunctions) ──

function AIService.Client:Authenticate(player: Player, apiKey: string): Types.HttpResult<Types.ValidateKeyResponse>
	return AIService:Authenticate(player, apiKey)
end

function AIService.Client:GenerateCode(
	player: Player,
	query: string,
	contextType: string?,
	topK: number?,
	model: string?
): Types.HttpResult<Types.GenerateResponse>
	return AIService:GenerateCode(player, query, contextType :: Types.ContextType?, topK, model)
end

function AIService.Client:GetCredits(player: Player): Types.HttpResult<Types.CreditsResponse>
	return AIService:GetCredits(player)
end

function AIService.Client:QueryDocs(
	player: Player,
	query: string,
	topK: number?
): Types.HttpResult<Types.QueryResponse>
	return AIService:QueryDocs(query, topK)
end

function AIService.Client:CheckHealth(player: Player): Types.HttpResult<Types.HealthResponse>
	return AIService:CheckHealth()
end

return AIService
