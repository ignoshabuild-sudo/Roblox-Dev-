"""
API Key Authentication Module

Provides a simple API key system to gate paid-tier endpoints.
Keys are validated against a hardcoded list (backed by env var or DB in production).
Zero data retention: keys are never logged to disk.
"""

from fastapi import Header, HTTPException, status

# ── Valid API keys ──────────────────────────────────────────────
# In production, these would be loaded from environment variables
# or a database. For now, we keep dev keys for testing.

VALID_API_KEYS: dict[str, dict[str, str | int]] = {
    "free-key-2026": {"tier": "free", "credits": 10},
    "hobbyist-key-2026": {"tier": "hobbyist", "credits": 999_999},
    "dev-key-2026": {"tier": "pro", "credits": 999_999},
    "studio-key-2026": {"tier": "studio", "credits": 999_999},
}

# Credit cost per generation by tier
CREDIT_COST: dict[str, int] = {
    "free": 1,
    "hobbyist": 0,
    "pro": 0,
    "studio": 0,
}

# Daily credit limits by tier
DAILY_LIMITS: dict[str, int] = {
    "free": 10,
    "hobbyist": 999_999,
    "pro": 999_999,
    "studio": 999_999,
}

# ── Dependency ───────────────────────────────────────────────────

async def require_api_key(x_api_key: str = Header(..., alias="X-API-Key")) -> dict:
    """
    FastAPI dependency that validates the X-API-Key header.

    Returns the key's metadata dict on success (including the raw key as '_raw_key').
    Raises 401 if the key is missing or invalid.
    """
    if not x_api_key or x_api_key not in VALID_API_KEYS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key. Request one at https://buy.stripe.com/bJeaEX6rQ86w6wp9Lvg3606",
        )
    result = dict(VALID_API_KEYS[x_api_key])
    result["_raw_key"] = x_api_key
    return result


def validate_key(key: str) -> dict | None:
    """Non-dependency helper: returns key metadata or None."""
    entry = VALID_API_KEYS.get(key)
    if entry is not None:
        return dict(entry)
    return None


def get_key_credits(key: str) -> int:
    """Return the credits field for a key (static config value)."""
    entry = VALID_API_KEYS.get(key, {})
    return entry.get("credits", 0)
