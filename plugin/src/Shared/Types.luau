--!strict
-- Shared type definitions for the Roblox AI Code Assistant plugin.
-- These types mirror the backend Pydantic schemas exactly.

export type ContextType = "server" | "client" | "module"

-- ── Health ──────────────────────────────────────────────────────────────

export type HealthResponse = {
	status: string,
	version: string,
	indexedClasses: number,
	totalChunks: number,
}

-- ── Query ───────────────────────────────────────────────────────────────

export type QueryRequest = {
	query: string,
	topK: number?,
}

export type DocChunk = {
	chunkId: string,
	content: string,
	metadata: { [string]: any },
	relevanceScore: number,
}

export type QueryResponse = {
	query: string,
	chunks: { DocChunk },
	retrievalTimeMs: number,
	totalIndexedClasses: number,
}

-- ── Generate ────────────────────────────────────────────────────────────

export type GenerateRequest = {
	query: string,
	contextType: ContextType?,
	topK: number?,
	model: string?,
}

export type GenerateResponse = {
	code: string,
	apiReferences: { string },
	retrievalTimeMs: number,
	generationTimeMs: number,
	totalTimeMs: number,
	modelUsed: string,
	isUncertain: boolean,
}

-- ── Auth & Credits ──────────────────────────────────────────────────────

export type ValidateKeyResponse = {
	valid: boolean,
	tier: string?,
	creditsRemaining: number?,
	dailyLimit: number?,
	totalUsed: number?,
}

export type CreditsResponse = {
	creditsRemaining: number,
	dailyLimit: number,
	totalUsed: number,
	tier: string?,
	lastResetDate: string?,
}

-- ── Plugin Internal ─────────────────────────────────────────────────────

export type ApiError = {
	statusCode: number,
	message: string,
}

export type HttpResult<T> = {
	success: boolean,
	data: T?,
	error: ApiError?,
}
