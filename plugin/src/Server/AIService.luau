--!strict
-- AIService: Knit Service that orchestrates communication between the
-- Roblox Studio plugin and the AI Code Assistant backend.
--
-- Responsibilities:
--  - Provide a clean, typed API for the plugin UI to call
--  - Manage HttpService lifecycle and API base URL configuration
--  - Handle errors gracefully and surface them to the UI layer
--  - Enforce the sandbox constraint: NEVER execute generated code
--
-- Usage from Client:
--   local AIService = Knit.GetService("AIService")
--   local result = AIService:GenerateCode("spawn a part", "server"):await()

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

-- ── Lifecycle ───────────────────────────────────────────────────────────

function AIService:KnitStart()
	_http = HttpService.new(_apiBaseUrl)
	print("[AIService] Started — API base URL: " .. _apiBaseUrl)
end

-- ── Configuration ───────────────────────────────────────────────────────

function AIService:SetApiBaseUrl(url: string)
	_apiBaseUrl = url
	_http = HttpService.new(_apiBaseUrl)
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

-- ── Client-facing methods (exposed to Knit client via RemoteFunctions) ──

function AIService.Client:GenerateCode(
	player: Player,
	query: string,
	contextType: string?,
	topK: number?,
	model: string?
): Types.HttpResult<Types.GenerateResponse>
	return AIService:GenerateCode(query, contextType :: Types.ContextType?, topK, model)
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
