# Roblox AI Code Assistant — Benchmark Suite

Evaluates AI-generated Luau code against a curated set of **50 ground-truth scripts**
across **20 common use-case categories**. The benchmark measures syntax accuracy,
API correctness, and structural pattern adherence.

## Quick Start

```bash
# Install dependencies
pip install -r ../backend/requirements.txt pyyaml requests

# Run full benchmark suite
cd benchmarks
python scorer.py --all

# Run a single category
python scorer.py --category remoteevents

# Run with custom API endpoint
python scorer.py --endpoint http://localhost:8000 --all

# Generate a CSV report
python scorer.py --all --output results/report.csv
```

## Directory Structure

```
benchmarks/
├── README.md                  # This file
├── config.yaml               # Scoring weights, API URL, thresholds
├── scorer.py                 # Main evaluation runner
├── ground-truth/             # 50 reference Luau scripts (the "answers")
│   ├── 01-remoteevents/      # 2–3 .luau files per category
│   ├── 02-remotefunctions/
│   ├── ...
│   └── 20-raycasting/
├── test-cases/               # Natural-language prompts per script
│   ├── 01-remoteevents/      # 2–3 .yaml files per category
│   ├── 02-remotefunctions/
│   └── ...
└── results/                  # Generated reports (gitignored except .gitkeep)
    ├── .gitkeep
    └── report-*.csv
```

## Scoring Methodology

Each generated script is evaluated on three dimensions, then combined into
a weighted composite score:

### 1. Syntax Accuracy (weight: 0.30) — Binary pass/fail
Did the generated code parse without errors?

- Balanced parentheses, brackets, and `end` keywords
- No `loadstring`, `getfenv`, or other sandbox-escaping patterns
- Valid Luau lexical structure (no unterminated strings, etc.)

### 2. Semantic Accuracy (weight: 0.45) — API correctness
Does the generated code use the correct Roblox APIs?

- Expected API surface present (e.g., `RemoteEvent:FireServer`)
- No hallucinated APIs or methods
- Correct parameter types and counts for key API calls
- Checks against a whitelist derived from ground-truth API usage

### 3. Structural Accuracy (weight: 0.25) — Pattern adherence
Does the code follow the correct structural pattern for its context?

- **RemoteEvent**: proper `OnServerEvent:Connect()` / `:FireClient()` pairing
- **ModuleScript**: returns a table, uses `require()` on the client
- **DataStore**: wraps in `pcall`, handles retry, uses `SetAsync`/`GetAsync`
- **TweenService**: creates + plays tween, proper property table
- General: correct Script vs LocalScript vs ModuleScript boundaries

### Composite Score

```
composite = (syntax × 0.30) + (semantic × 0.45) + (structural × 0.25)
```

Target: **≥ 85% composite** across all 50 tests.

## Authoring Conventions

### Ground-Truth Scripts (`ground-truth/<category>/<NN>-<name>.luau`)

Each script is the **reference implementation** — the ideal output the AI should generate.
Conventions:
- File naming: `NN-name.luau` where NN is 01–03 (up to 3 scripts per category)
- First line must be a `-- context: server|client|module` comment
- Use canonical Roblox API patterns (follow DevHub docs)
- Include the minimal complete pattern, not a full game system
- Comment expected API tokens at the top: `-- apis: Instance.new, RemoteEvent, OnServerEvent`

Example:
```luau
-- context: server
-- apis: Instance.new, RemoteEvent, OnServerEvent, Connect
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "Ping"
remoteEvent.Parent = ReplicatedStorage

remoteEvent.OnServerEvent:Connect(function(player, message)
    print(player.Name .. " sent: " .. message)
end)
```

### Test Cases (`test-cases/<category>/<NN>-<name>.yaml`)

Each test case is the natural-language prompt paired with expected metadata.
File naming must match the corresponding ground-truth script.

```yaml
id: "01-remoteevents-01-basic-fire-server"
category: "remoteevents"
context_type: "server"
prompt: "Create a RemoteEvent named Ping that prints a message from any player when fired to the server."
ground_truth: "01-basic-fire-server.luau"
expected_apis:
  - "Instance.new"
  - "RemoteEvent"
  - "OnServerEvent"
  - "Connect"
expected_patterns:
  - "fire-to-server"
```

## Category Reference

| # | Category | Context | Key APIs |
|---|----------|---------|----------|
| 01 | RemoteEvents | server/client | `RemoteEvent`, `OnServerEvent`, `FireServer`, `FireClient` |
| 02 | RemoteFunctions | server/client | `RemoteFunction`, `OnServerInvoke`, `InvokeServer` |
| 03 | DataStores | server | `DataStoreService`, `GetAsync`, `SetAsync`, `pcall` |
| 04 | TweenService | client | `TweenService`, `TweenInfo`, `Create`, `Play` |
| 05 | ModuleScripts | shared | `require`, `ModuleScript`, table return |
| 06 | BindableEvents | shared | `BindableEvent`, `Event`, `Fire` |
| 07 | CollectionService | shared | `CollectionService`, `GetTagged`, `AddTag` |
| 08 | Players Service | server | `Players`, `PlayerAdded`, `PlayerRemoving` |
| 09 | UserInputService | client | `UserInputService`, `InputBegan`, `InputEnded` |
| 10 | RunService | shared | `RunService`, `Heartbeat`, `RenderStepped` |
| 11 | ReplicatedStorage | shared | `ReplicatedStorage`, asset sharing |
| 12 | SoundService | client | `Sound`, `SoundService`, `Play`, `Volume` |
| 13 | Lighting | server | `Lighting`, `ClockTime`, `FogEnd`, `Atmosphere` |
| 14 | MarketplaceService | server | `MarketplaceService`, `ProcessReceipt` |
| 15 | HttpService | server | `HttpService`, `GetAsync`, `JSONEncode` |
| 16 | Pathfinding | server | `PathfindingService`, `CreatePath`, `ComputeAsync` |
| 17 | ContextActionService | client | `ContextActionService`, `BindAction` |
| 18 | ProximityPrompts | client | `ProximityPrompt`, `Triggered`, `Enabled` |
| 19 | Debris Service | server | `Debris`, `AddItem` |
| 20 | Raycasting | server | `Workspace`, `Raycast`, `RaycastParams` |

## KPI Targets

| Metric | Target |
|--------|--------|
| First-try syntax accuracy | ≥ 85% |
| Benchmark pass rate (composite ≥ 0.70) | ≥ 90% (45/50 scripts) |
| "I don't know" rate | ≤ 5% |
