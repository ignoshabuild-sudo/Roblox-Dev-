"""
Credit System Module

Tracks API key credit balances and handles daily credit resets.
Free tier: 10 credits/day, resets daily.
Paid tiers: unlimited (represented as 999,999).
Zero data retention: credit balances only; no query data stored.
"""

import json
import time
from pathlib import Path
from threading import Lock

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "data"
CREDITS_FILE = DATA_DIR / "credits.json"

# In-memory cache + file sync
_credits_lock = Lock()
_credits_cache: dict[str, dict] | None = None

# ── Tier configuration ──────────────────────────────────────────
TIER_CREDITS = {
    "free": 10,
    "hobbyist": 999_999,
    "pro": 999_999,
    "studio": 999_999,
}

TIER_COST = {
    "free": 1,
    "hobbyist": 0,
    "pro": 0,
    "studio": 0,
}


def _load_credits() -> dict:
    """Load credits from JSON file. Returns empty dict if file missing."""
    if CREDITS_FILE.exists():
        try:
            with open(CREDITS_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def _save_credits(data: dict) -> None:
    """Atomically save credits to JSON file."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    tmp = CREDITS_FILE.with_suffix(".tmp")
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    tmp.replace(CREDITS_FILE)


def _get_cache() -> dict:
    """Return the in-memory credits cache, loading from disk if needed."""
    global _credits_cache
    if _credits_cache is None:
        with _credits_lock:
            if _credits_cache is None:
                _credits_cache = _load_credits()
    return _credits_cache


def _flush_cache() -> None:
    """Persist current cache to disk."""
    global _credits_cache
    if _credits_cache is not None:
        with _credits_lock:
            _save_credits(_credits_cache)


def _ensure_entry(key_hash: str, tier: str) -> dict:
    """Ensure a credits entry exists for this key hash. Creates one if new."""
    cache = _get_cache()
    today = _today_str()

    if key_hash not in cache:
        cache[key_hash] = {
            "tier": tier,
            "credits_remaining": TIER_CREDITS.get(tier, 10),
            "last_reset_date": today,
            "total_used": 0,
            "created_at": time.time(),
        }
        _flush_cache()
    return cache[key_hash]


def _today_str() -> str:
    """Return today's date as 'YYYY-MM-DD' in UTC."""
    return time.strftime("%Y-%m-%d", time.gmtime())


def _maybe_reset(entry: dict) -> dict:
    """Check if daily reset is needed for free tier and apply it."""
    today = _today_str()
    if entry.get("last_reset_date") != today and entry.get("tier") == "free":
        tier = entry.get("tier", "free")
        entry["credits_remaining"] = TIER_CREDITS.get(tier, 10)
        entry["last_reset_date"] = today
        _flush_cache()
    return entry


def get_credits(api_key: str, tier: str = "free") -> dict:
    """
    Get credit info for an API key.
    Returns dict with: credits_remaining, tier, total_used, daily_limit.
    """
    import hashlib

    key_hash = hashlib.sha256(api_key.encode()).hexdigest()[:16]
    entry = _ensure_entry(key_hash, tier)
    entry = _maybe_reset(entry)

    return {
        "credits_remaining": entry.get("credits_remaining", 0),
        "tier": entry.get("tier", tier),
        "total_used": entry.get("total_used", 0),
        "daily_limit": TIER_CREDITS.get(tier, 10),
        "last_reset_date": entry.get("last_reset_date", _today_str()),
    }


def deduct_credit(api_key: str, tier: str = "free") -> dict:
    """
    Deduct one credit from the API key's balance.
    Paid tiers are never actually deducted (cost is 0).
    Returns updated credit info.
    """
    import hashlib

    cost = TIER_COST.get(tier, 1)
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()[:16]
    entry = _ensure_entry(key_hash, tier)
    entry = _maybe_reset(entry)

    if cost > 0:
        if entry.get("credits_remaining", 0) <= 0:
            return {
                "credits_remaining": 0,
                "tier": tier,
                "total_used": entry.get("total_used", 0),
                "daily_limit": TIER_CREDITS.get(tier, 10),
                "last_reset_date": entry.get("last_reset_date", _today_str()),
                "error": "No credits remaining. Upgrade or wait for daily reset.",
            }
        entry["credits_remaining"] = max(0, entry.get("credits_remaining", 0) - cost)
        entry["total_used"] = entry.get("total_used", 0) + cost
        _flush_cache()

    return {
        "credits_remaining": entry.get("credits_remaining", 0),
        "tier": tier,
        "total_used": entry.get("total_used", 0),
        "daily_limit": TIER_CREDITS.get(tier, 10),
        "last_reset_date": entry.get("last_reset_date", _today_str()),
    }


def reset_daily_credits() -> int:
    """
    Reset credits for all free-tier keys whose last_reset_date != today.
    Returns count of keys reset.
    """
    cache = _get_cache()
    today = _today_str()
    reset_count = 0

    for key_hash, entry in cache.items():
        if entry.get("tier") == "free" and entry.get("last_reset_date") != today:
            tier = entry.get("tier", "free")
            entry["credits_remaining"] = TIER_CREDITS.get(tier, 10)
            entry["last_reset_date"] = today
            reset_count += 1

    if reset_count > 0:
        _flush_cache()

    return reset_count
