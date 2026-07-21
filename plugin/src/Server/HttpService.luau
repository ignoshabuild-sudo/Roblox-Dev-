--!strict
-- HttpService: typed wrapper around Roblox HttpService for communicating
-- with the AI Code Assistant backend API.
--
-- Key design decisions:
--  - JSON encoding/decoding uses Roblox HttpService:JSONEncode/JSONDecode
--  - All responses are parsed into typed Luau tables matching backend schemas
--  - Timeouts and retries are configurable via Constants
--  - Zero data retention: we log only anonymized timing, never query content
--  - API key is sent via X-API-Key header on every authenticated request

local HttpService = {}
HttpService.__index = HttpService

local Constants = require(script.Parent.Parent.Shared.Constants)
local Types = require(script.Parent.Parent.Shared.Types)

-- ── Private helpers ─────────────────────────────────────────────────────

local function buildUrl(baseUrl: string, endpoint: string): string
	-- Strip trailing slash from base, ensure leading slash on endpoint.
	local base = if baseUrl:sub(-1) == "/" then baseUrl:sub(1, -2) else baseUrl
	return base .. endpoint
end

local function encodeBody(body: { [string]: any }): string
	local httpService = game:GetService("HttpService")
	return httpService:JSONEncode(body)
end

local function decodeResponse(json: string): { [string]: any }
	local httpService = game:GetService("HttpService")
	return httpService:JSONDecode(json)
end

local function buildHeaders(self: typeof(HttpService)): { [string]: string }
	local headers = {
		["Content-Type"] = "application/json",
	}
	if self._apiKey and self._apiKey ~= "" then
		headers["X-API-Key"] = self._apiKey
	end
	return headers
end

-- ── Public API ──────────────────────────────────────────────────────────

function HttpService.new(baseUrl: string?): typeof(HttpService)
	local self = setmetatable({}, HttpService)
	self._baseUrl = baseUrl or Constants.DEFAULT_API_BASE_URL
	self._apiKey = ""
	return self
end

-- Set the API key used for authenticated endpoints.
function HttpService:setApiKey(key: string)
	self._apiKey = key
end

-- GET /health — check backend availability (no auth required).
function HttpService:health(): Types.HttpResult<Types.HealthResponse>
	local httpService = game:GetService("HttpService")
	local url = buildUrl(self._baseUrl, Constants.ENDPOINT_HEALTH)

	local ok, result = pcall(function()
		return httpService:GetAsync(url, false)
	end)

	if not ok then
		return {
			success = false,
			error = {
				statusCode = 0,
				message = "Connection failed: " .. tostring(result),
			},
		}
	end

	local data = decodeResponse(result)
	return {
		success = true,
		data = {
			status = data.status :: string,
			version = data.version :: string,
			indexedClasses = data.indexed_classes :: number,
			totalChunks = data.total_chunks :: number,
		},
	}
end

-- POST /query — retrieve relevant Roblox API doc chunks.
function HttpService:query(request: Types.QueryRequest): Types.HttpResult<Types.QueryResponse>
	local httpService = game:GetService("HttpService")
	local url = buildUrl(self._baseUrl, Constants.ENDPOINT_QUERY)

	local body = {
		query = request.query,
		top_k = request.topK or Constants.DEFAULT_TOP_K,
	}

	local headers = buildHeaders(self)

	local ok, result = pcall(function()
		return httpService:PostAsync(url, encodeBody(body), Enum.HttpContentType.ApplicationJson, false, headers)
	end)

	if not ok then
		return {
			success = false,
			error = {
				statusCode = 0,
				message = "Query request failed: " .. tostring(result),
			},
		}
	end

	local data = decodeResponse(result)
	local chunks: { Types.DocChunk } = {}

	for _, chunk in ipairs(data.chunks :: { any }) do
		table.insert(chunks, {
			chunkId = chunk.chunk_id :: string,
			content = chunk.content :: string,
			metadata = chunk.metadata :: { [string]: any },
			relevanceScore = chunk.relevance_score :: number,
		})
	end

	return {
		success = true,
		data = {
			query = data.query :: string,
			chunks = chunks,
			retrievalTimeMs = data.retrieval_time_ms :: number,
			totalIndexedClasses = data.total_indexed_classes :: number,
		},
	}
end

-- POST /generate — generate Luau code with RAG grounding (requires API key).
function HttpService:generate(request: Types.GenerateRequest): Types.HttpResult<Types.GenerateResponse>
	local httpService = game:GetService("HttpService")
	local url = buildUrl(self._baseUrl, Constants.ENDPOINT_GENERATE)

	local body = {
		query = request.query,
		context_type = request.contextType or Constants.DEFAULT_CONTEXT_TYPE,
		top_k = request.topK or Constants.DEFAULT_TOP_K,
		model = request.model or Constants.DEFAULT_MODEL,
	}

	local headers = buildHeaders(self)

	local ok, result = pcall(function()
		return httpService:PostAsync(url, encodeBody(body), Enum.HttpContentType.ApplicationJson, false, headers)
	end)

	if not ok then
		return {
			success = false,
			error = {
				statusCode = 0,
				message = "Generate request failed: " .. tostring(result),
			},
		}
	end

	local data = decodeResponse(result)

	return {
		success = true,
		data = {
			code = data.code :: string,
			apiReferences = data.api_references :: { string },
			retrievalTimeMs = data.retrieval_time_ms :: number,
			generationTimeMs = data.generation_time_ms :: number,
			totalTimeMs = data.total_time_ms :: number,
			modelUsed = data.model_used :: string,
			isUncertain = data.is_uncertain :: boolean,
		},
	}
end

-- GET /validate-key — validate an API key and return tier + credit info.
function HttpService:validateKey(key: string): Types.HttpResult<Types.ValidateKeyResponse>
	local httpService = game:GetService("HttpService")
	local url = buildUrl(self._baseUrl, Constants.ENDPOINT_VALIDATE_KEY)

	local headers = {
		["X-API-Key"] = key,
	}

	local ok, result = pcall(function()
		return httpService:GetAsync(url, false, headers)
	end)

	if not ok then
		return {
			success = false,
			error = {
				statusCode = 0,
				message = "Validate-key request failed: " .. tostring(result),
			},
		}
	end

	local data = decodeResponse(result)
	return {
		success = true,
		data = {
			valid = data.valid :: boolean,
			tier = data.tier :: string?,
			creditsRemaining = data.credits_remaining :: number?,
			dailyLimit = data.daily_limit :: number?,
			totalUsed = data.total_used :: number?,
		},
	}
end

-- GET /credits — retrieve credit balance for the current API key.
function HttpService:getCredits(): Types.HttpResult<Types.CreditsResponse>
	local httpService = game:GetService("HttpService")
	local url = buildUrl(self._baseUrl, Constants.ENDPOINT_CREDITS)

	if not self._apiKey or self._apiKey == "" then
		return {
			success = false,
			error = {
				statusCode = 401,
				message = "No API key set — authenticate first",
			},
		}
	end

	local headers = buildHeaders(self)

	local ok, result = pcall(function()
		return httpService:GetAsync(url, false, headers)
	end)

	if not ok then
		return {
			success = false,
			error = {
				statusCode = 0,
				message = "Credits request failed: " .. tostring(result),
			},
		}
	end

	local data = decodeResponse(result)

	-- Handle 401 error response from backend
	if data.detail then
		return {
			success = false,
			error = {
				statusCode = 401,
				message = data.detail :: string,
			},
		}
	end

	return {
		success = true,
		data = {
			creditsRemaining = data.credits_remaining :: number,
			dailyLimit = data.daily_limit :: number,
			totalUsed = data.total_used :: number,
			tier = data.tier :: string?,
			lastResetDate = data.last_reset_date :: string?,
		},
	}
end

return HttpService
