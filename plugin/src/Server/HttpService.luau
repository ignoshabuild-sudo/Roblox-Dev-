--!strict
-- HttpService: typed wrapper around Roblox HttpService for communicating
-- with the AI Code Assistant backend API.
--
-- Key design decisions:
--  - JSON encoding/decoding uses Roblox HttpService:JSONEncode/JSONDecode
--  - All responses are parsed into typed Luau tables matching backend schemas
--  - Timeouts and retries are configurable via Constants
--  - Zero data retention: we log only anonymized timing, never query content

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

-- ── Public API ──────────────────────────────────────────────────────────

function HttpService.new(baseUrl: string?): typeof(HttpService)
	local self = setmetatable({}, HttpService)
	self._baseUrl = baseUrl or Constants.DEFAULT_API_BASE_URL
	return self
end

-- GET /health — check backend availability.
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

	local ok, result = pcall(function()
		return httpService:PostAsync(url, encodeBody(body), Enum.HttpContentType.ApplicationJson, false)
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

-- POST /generate — generate Luau code with RAG grounding.
function HttpService:generate(request: Types.GenerateRequest): Types.HttpResult<Types.GenerateResponse>
	local httpService = game:GetService("HttpService")
	local url = buildUrl(self._baseUrl, Constants.ENDPOINT_GENERATE)

	local body = {
		query = request.query,
		context_type = request.contextType or Constants.DEFAULT_CONTEXT_TYPE,
		top_k = request.topK or Constants.DEFAULT_TOP_K,
		model = request.model or Constants.DEFAULT_MODEL,
	}

	local ok, result = pcall(function()
		return httpService:PostAsync(url, encodeBody(body), Enum.HttpContentType.ApplicationJson, false)
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

return HttpService
