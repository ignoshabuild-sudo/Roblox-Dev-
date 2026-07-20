"""
Core configuration for the Roblox AI Code Assistant RAG pipeline.
"""
import os
from pathlib import Path

# Base paths
BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "data"
CHROMA_DIR = DATA_DIR / "chroma_db"
RAW_DOCS_DIR = DATA_DIR / "raw_docs"
PROCESSED_DOCS_DIR = DATA_DIR / "processed"

# Ensure directories exist
for d in [DATA_DIR, CHROMA_DIR, RAW_DOCS_DIR, PROCESSED_DOCS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Roblox API docs
ROBLOX_DOCS_BASE = "https://create.roblox.com"
ENGINE_LLMS_URL = f"{ROBLOX_DOCS_BASE}/docs/reference/engine/llms.txt"

# Chunking
CHUNK_SIZE = 800  # target characters per chunk
CHUNK_OVERLAP = 100

# Embeddings: ONNX-based MiniLM-L6-v2 (384-dim, no PyTorch)

# Retrieval
DEFAULT_TOP_K = 5
MAX_TOP_K = 20

# ChromaDB
CHROMA_COLLECTION = "roblox_api_docs"

# Performance
RETRIEVAL_TIMEOUT_MS = 3000  # 3-second target
REQUEST_TIMEOUT = 30  # seconds for doc fetching
