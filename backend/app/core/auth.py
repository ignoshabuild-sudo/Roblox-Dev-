"""
API Key Authentication Module

Provides a simple API key system to gate paid-tier endpoints.
Keys are validated against a hardcoded list (backed by env var or DB in production).
Zero data retention: keys are never logged to disk.
"""

from fastapi import Header, HTTPException, status

# ── Valid API keys ──────────────────────────────────────────────
# In production, these would be loaded from environment variables
# or a database. For now, we keep one dev key for testing.

VALID_API_KEYS: dict[str, dict[str, str]] = {
    "dev-key-2026": {"tier": "pro"},
}

# ── Dependency ───────────────────────────────────────────────────

async def require_api_key(x_api_key: str = Header(..., alias="X-API-Key")) -> dict:
    """
    FastAPI dependency that validates the X-API-Key header.

    Returns the key's metadata dict on success.
    Raises 401 if the key is missing or invalid.
    """
    if not x_api_key or x_api_key not in VALID_API_KEYS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key. Request one at https://buy.stripe.com/bJeaEX6rQ86w6wp9Lvg3606",
        )
    return VALID_API_KEYS[x_api_key]


def validate_key(key: str) -> dict | None:
    """Non-dependency helper: returns key metadata or None."""
    return VALID_API_KEYS.get(key)
