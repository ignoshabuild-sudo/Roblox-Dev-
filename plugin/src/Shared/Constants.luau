--!strict
-- Shared constants for the Roblox AI Code Assistant plugin.

local Constants = {}

-- ── API Configuration ───────────────────────────────────────────────────

-- Default backend URL — override via plugin settings or environment.
Constants.DEFAULT_API_BASE_URL = "http://localhost:8000"

-- API endpoints (appended to BASE_URL).
Constants.ENDPOINT_HEALTH = "/health"
Constants.ENDPOINT_QUERY = "/query"
Constants.ENDPOINT_GENERATE = "/generate"

-- HTTP timeouts in seconds.
Constants.HTTP_TIMEOUT_SECONDS = 10
Constants.HTTP_RETRY_COUNT = 2

-- ── Plugin Metadata ─────────────────────────────────────────────────────

Constants.PLUGIN_NAME = "Roblox AI Code Assistant"
Constants.PLUGIN_VERSION = "0.1.0"
Constants.PLUGIN_TOOLBAR_NAME = "AI Assistant"

-- ── Defaults ────────────────────────────────────────────────────────────

Constants.DEFAULT_TOP_K = 5
Constants.DEFAULT_CONTEXT_TYPE: types.ContextType = "module"
Constants.DEFAULT_MODEL = "gpt-4o-mini"

-- ── UI Constants ────────────────────────────────────────────────────────

Constants.WIDGET_MIN_WIDTH = Vector2.new(320, 240)
Constants.WIDGET_DEFAULT_SIZE = Vector2.new(400, 500)

return Constants
