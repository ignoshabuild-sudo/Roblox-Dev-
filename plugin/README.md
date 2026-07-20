# Roblox AI Code Assistant — Studio Plugin

A Rojo-based Roblox Studio plugin that provides an AI-powered code assistant
inside Roblox Studio, backed by a RAG (Retrieval Augmented Generation) pipeline
and LLM inference.

> **Status:** Scaffold — communication skeleton with placeholder UI.
> Full UI and integration coming in follow-up tasks.

## Architecture

```
plugin/
├── default.project.json      # Rojo 7.x build manifest
├── serve.project.json        # Rojo dev server manifest
├── wally.toml                # Wally package dependencies
├── README.md                 # This file
└── src/
    ├── Shared/
    │   ├── Types.luau        # Typed request/response schemas (mirrors backend Pydantic)
    │   └── Constants.luau    # API URLs, timeouts, defaults, UI sizing
    ├── Server/
    │   ├── AIService.luau    # Knit Service — orchestrates backend communication
    │   └── HttpService.luau  # Typed wrapper around Roblox HttpService
    └── Client/
        └── PluginLoader.luau # Plugin entry point — toolbar + placeholder widget
```

## Prerequisites

- [Rojo 7.x](https://rojo.space/) (`rojo` CLI)
- [Wally](https://wally.run/) (`wally` CLI for package management)
- Roblox Studio (latest)

## Quick Start

### 1. Install dependencies

```bash
cd plugin/
wally install
```

This pulls Knit (and any dev dependencies) into `plugin/Packages/`.

### 2. Start the Rojo dev server

```bash
rojo serve serve.project.json
```

### 3. Connect Roblox Studio

1. Open Roblox Studio
2. Install the [Rojo Studio Plugin](https://rojo.space/docs/v7/guide/studio-plugin/)
3. Connect to the Rojo server (default: `localhost:34872`)

### 4. Build for distribution

```bash
rojo build default.project.json -o "RobloxAICodeAssistant.rbxm"
```

This produces a `.rbxm` (Roblox Model) file you can load as a Studio plugin.

## Backend API Contract

The plugin communicates with the AI Code Assistant backend. The backend must be
running and accessible at the configured `BASE_URL` (default: `http://localhost:8000`).

### Endpoints

| Method | Path        | Request Body              | Response Body        |
|--------|-------------|---------------------------|----------------------|
| GET    | `/health`   | —                         | `HealthResponse`     |
| POST   | `/query`    | `QueryRequest`            | `QueryResponse`      |
| POST   | `/generate` | `GenerateRequest`         | `GenerateResponse`   |

### Request/Response Schemas

#### `HealthResponse`
```json
{
  "status": "ok",
  "version": "0.1.0",
  "indexed_classes": 0,
  "total_chunks": 1234
}
```

#### `QueryRequest` → `QueryResponse`
```json
// Request
{ "query": "How do I tween a part?", "top_k": 5 }

// Response
{
  "query": "How do I tween a part?",
  "chunks": [
    {
      "chunk_id": "abc-123",
      "content": "TweenService:Create(instance, tweenInfo, properties)...",
      "metadata": { "class": "TweenService", "url": "https://..." },
      "relevance_score": 0.92
    }
  ],
  "retrieval_time_ms": 45.2,
  "total_indexed_classes": 0
}
```

#### `GenerateRequest` → `GenerateResponse`
```json
// Request
{
  "query": "Create a script that spawns a red part at the origin",
  "context_type": "server",
  "top_k": 5,
  "model": "gpt-4o-mini"
}

// Response
{
  "code": "local part = Instance.new(\"Part\")\npart.Color = Color3.fromRGB(255, 0, 0)\npart.Parent = workspace",
  "api_references": ["Instance.new", "BasePart.Color"],
  "retrieval_time_ms": 38.1,
  "generation_time_ms": 1200.5,
  "total_time_ms": 1238.6,
  "model_used": "gpt-4o-mini",
  "is_uncertain": false
}
```

### Type Mapping (Python → Luau)

| Python / Pydantic    | Luau                         |
|----------------------|------------------------------|
| `str`                | `string`                     |
| `int`                | `number`                     |
| `float`              | `number`                     |
| `bool`               | `boolean`                    |
| `list[T]`            | `{ T }`                      |
| `Optional[T]`        | `T?`                         |
| `Literal["a","b"]`   | `"a" | "b"` (union)         |
| `snake_case` fields  | `camelCase` fields           |

## Sandbox Constraint

**NON-NEGOTIABLE:** The plugin MUST NOT execute any generated code directly.
Generated code is returned as a display-only string. The plugin UI will offer
copy-to-clipboard functionality only. No `loadstring()`, no `require()` on
generated code, no injection into the DataModel.

This constraint is enforced at every layer:
1. `HttpService` returns raw code strings — never calls any execution API
2. `AIService` logs generation stats but never touches the code string content
3. `PluginLoader` (and future UI) only displays code, never runs it

## Development Notes

- **Rojo partitioning:** `Shared/` maps to a shared Folder accessible from both Server and Client contexts. `Server/` and `Client/` are separate partitions for plugin-side and widget-side code respectively.
- **Knit lifecycle:** `AIService:KnitStart()` initializes the HTTP client. Knit handles the service registry, dependency injection, and RemoteFunction middleware automatically.
- **Strict typing:** All Luau files use `--!strict` mode. Types are defined once in `Shared/Types.luau` and imported everywhere.
- **Configuration:** Base URL can be changed at runtime via `AIService:SetApiBaseUrl(url)`. Future work will add a settings UI.
