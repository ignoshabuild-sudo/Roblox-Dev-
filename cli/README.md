# rbxai — Roblox AI Code Assistant CLI

Generate production-ready Luau code from your terminal, grounded in official Roblox API docs.

## Quick Install

```bash
pip install -r requirements.txt
```

Or copy `rbxai.py` anywhere on your PATH — it's a single-file CLI.

## Setup

Set your API key as an environment variable:

```bash
export RBXAI_API_KEY="your-api-key-here"
```

Or pass it with `--key` on every command.

## Usage

### Generate Code

```bash
# Basic generation (defaults to module context)
python rbxai.py "Create a RemoteEvent for player data sync"

# Specify context type
python rbxai.py --context server "DataStore with retry logic"
python rbxai.py --context client "Health bar GUI with TweenService"

# Use explicit API key
python rbxai.py --key dev-key-2026 "Character respawn handler"

# Pass API key via env var
export RBXAI_API_KEY="dev-key-2026"
python rbxai.py "Part welding system"
```

### Check Credits

```bash
python rbxai.py --credits
```

### Context Types

| Flag | Context | Script Type |
|------|---------|-------------|
| `server` | Server | Script (server-side) |
| `client` | Client | LocalScript (client-side) |
| `module` | Module | ModuleScript (shared) |

## Output

The CLI uses `rich` for pretty terminal output with syntax-highlighted Luau code blocks.
After each generation, it displays:
- The generated code with syntax highlighting
- API references used for grounding
- Credit usage and remaining balance
- Generation latency

## API Endpoint

By default, the CLI connects to the production API. Set `RBXAI_API_URL` to override:

```bash
export RBXAI_API_URL="http://localhost:8000"
```

## Upgrade

Free tier includes 10 generations/day. Upgrade for unlimited:

- **Hobbyist** ($9/mo): https://buy.stripe.com/bJe00j8zY73i7At0aVg3607
- **Pro** ($29/mo): https://buy.stripe.com/4gMfZh17w5Ze5slf5Pg3608
- **Studio** ($99/mo): https://buy.stripe.com/9B6eVd2bAafu1c15Hrg3609
