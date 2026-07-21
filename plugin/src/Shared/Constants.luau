--!strict
-- Shared constants for the Roblox AI Code Assistant plugin.

local Constants = {}

-- ── API Configuration ───────────────────────────────────────────────────

-- Live production backend URL.
Constants.API_BASE_URL = "https://23caccdb19d616fd54ecba6af9408adc.ctonew.app"

-- Local development fallback.
Constants.LOCAL_BASE_URL = "http://localhost:8000"

-- Default to local for development; set explicitly when shipping to users.
Constants.DEFAULT_API_BASE_URL = Constants.LOCAL_BASE_URL

-- API endpoints (appended to BASE_URL).
Constants.ENDPOINT_HEALTH = "/health"
Constants.ENDPOINT_QUERY = "/query"
Constants.ENDPOINT_GENERATE = "/generate"
Constants.ENDPOINT_VALIDATE_KEY = "/validate-key"
Constants.ENDPOINT_CREDITS = "/credits"

-- HTTP timeouts in seconds.
Constants.HTTP_TIMEOUT_SECONDS = 10
Constants.HTTP_RETRY_COUNT = 2

-- ── Stripe Payment Links ────────────────────────────────────────────────

Constants.STRIPE_HOBBYIST = "https://23caccdb19d616fd54ecba6af9408adc.ctonew.app/#pricing?upgrade=hobbyist"
Constants.STRIPE_PRO = "https://23caccdb19d616fd54ecba6af9408adc.ctonew.app/#pricing?upgrade=pro"
Constants.STRIPE_STUDIO = "https://23caccdb19d616fd54ecba6af9408adc.ctonew.app/#pricing?upgrade=studio"
Constants.STRIPE_FOUNDER = "https://23caccdb19d616fd54ecba6af9408adc.ctonew.app/#pricing?upgrade=founder"

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
