# Roblox AI Code Assistant — RAG Pipeline Backbone

Retrieval-Augmented Generation pipeline for the Roblox AI Code Assistant. Ingests official Roblox Engine API documentation into a ChromaDB vector database and provides a FastAPI endpoint for semantic search over Roblox APIs.

## Architecture

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application + /query endpoint
│   ├── api/
│   │   └── __init__.py
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py        # Centralized configuration
│   ├── models/
│   │   ├── __init__.py
│   │   └── schemas.py       # Pydantic models for API
│   └── services/
│       ├── __init__.py
│       └── vector_store.py  # ChromaDB wrapper + embeddings
├── scripts/
│   ├── __init__.py
│   └── ingest_docs.py       # Documentation ingestion pipeline
├── data/
│   ├── chroma_db/           # ChromaDB persistent storage
│   ├── raw_docs/            # Raw fetched documentation
│   └── processed/           # Ingestion statistics
├── requirements.txt
└── README.md
```

## Prerequisites

- Python 3.12+
- 2GB+ free disk space (for embeddings model + vector DB)
- Internet access (for initial documentation fetch)

## Setup

```bash
# Clone the repo
git clone <repo-url>
cd Roblox-Dev-/backend

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Ingest Roblox API Documentation

The ingestion pipeline fetches the official Roblox Engine API reference docs, parses classes/methods/properties/events/callbacks into structured chunks, generates embeddings, and stores them in ChromaDB.

```bash
# Ingest 50 classes (default, recommended for development)
python scripts/ingest_docs.py

# Ingest specific classes
python scripts/ingest_docs.py --classes "RemoteEvent,RemoteFunction,Player,Players,Workspace"

# Ingest ALL 654+ classes
python scripts/ingest_docs.py --all --concurrency 10

# Custom limit
python scripts/ingest_docs.py --max-classes 100 --concurrency 8
```

**What it does:**
1. Fetches the engine API index from `https://create.roblox.com/docs/reference/engine/llms.txt`
2. Discovers all 654 class pages with markdown URLs
3. Downloads each class `.md` file concurrently
4. Parses markdown into structured chunks (overview, methods, properties, events, callbacks)
5. Generates embeddings using `all-MiniLM-L6-v2` (384-dim, runs locally)
6. Stores chunks + embeddings in ChromaDB for fast retrieval

## Run the Query API

```bash
# Start the FastAPI server
cd backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API is available at `http://localhost:8000`.

### Endpoints

#### `GET /health`
Health check. Returns DB statistics.

```json
{
  "status": "ok",
  "version": "0.1.0",
  "indexed_classes": 50,
  "total_chunks": 342
}
```

#### `POST /query`
Query the Roblox API documentation.

**Request:**
```json
{
  "query": "How do I fire a RemoteEvent from the server to a specific client?",
  "top_k": 5
}
```

**Response:**
```json
{
  "query": "How do I fire a RemoteEvent from the server to a specific client?",
  "chunks": [
    {
      "chunk_id": "abc123...",
      "content": "# RemoteEvent:FireClient (Method)\n\nSignature: `RemoteEvent:FireClient(player: Player, arguments: Tuple): ()`\n\nFires the OnClientEvent event for the specified client...",
      "metadata": {
        "class_name": "RemoteEvent",
        "member_name": "FireClient",
        "chunk_type": "method",
        "full_signature": "RemoteEvent:FireClient(player: Player, arguments: Tuple): ()"
      },
      "relevance_score": 0.9234
    }
  ],
  "retrieval_time_ms": 12.45,
  "total_indexed_classes": 50
}
```

### Interactive API docs

Once running, open:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Key Design Decisions

### Zero Data Retention
The `/query` endpoint **never logs or stores user queries**. The query variable is discarded immediately after the response is returned. No telemetry, no analytics, no persistent query logs.

### Sub-3-Second Latency
- `all-MiniLM-L6-v2` embedding model: ~5ms per query on CPU
- ChromaDB with cosine similarity + HNSW indexing: ~2ms for top-5 retrieval
- Total pipeline latency targets <50ms (excluding HTTP overhead)

### Grounded in Official Docs
All chunks are sourced directly from `create.roblox.com/docs/reference/engine/` — the official Roblox API reference. No synthetic data, no web scraping of unofficial sources. Each chunk carries metadata linking back to the source class and member.

### Structured Chunking
Each class is chunked by semantic unit:
- **Overview**: class description, inheritance, memory category
- **Method**: individual method with signature, parameters, description
- **Property**: individual property with type and description
- **Event**: event with parameters and description
- **Callback**: callback with parameters and description

This granular chunking ensures precise retrieval — a query about `FireClient` won't return the entire `RemoteEvent` page.

## Dependencies

| Package | Purpose |
|---------|---------|
| `fastapi` | API framework |
| `uvicorn` | ASGI server |
| `chromadb` | Vector database (runs locally, no external service) |
| `sentence-transformers` | Embedding generation (`all-MiniLM-L6-v2`) |
| `httpx` | Async HTTP client for doc fetching |
| `pydantic` | Request/response validation |

## Next Steps

After this backbone is stable:
1. **CLI integration**: Package as a CLI tool for the Rojo workflow
2. **Studio plugin client**: Connect the Roblox Studio plugin to this endpoint
3. **LLM integration**: Wire retrieval results into an LLM prompt for code generation
4. **Fine-tuning data**: Collect retrieval → generation pairs for future model fine-tuning
5. **Re-indexing scheduler**: Auto-refresh docs when Roblox updates the API
