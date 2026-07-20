"""
FastAPI application for the Roblox AI Code Assistant RAG pipeline.
Provides a /query endpoint for retrieving relevant Roblox API documentation.
"""
import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import DEFAULT_TOP_K
from app.models.schemas import QueryRequest, QueryResponse, DocChunk, HealthResponse
from app.services.vector_store import vector_store


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown lifecycle."""
    # Verify ChromaDB is populated on startup
    stats = vector_store.get_stats()
    if stats["total_chunks"] == 0:
        print("⚠ WARNING: ChromaDB is empty. Run ingest_docs.py first.")
    else:
        print(f"✓ ChromaDB ready: {stats['total_chunks']} chunks indexed")
    yield


app = FastAPI(
    title="Roblox AI Code Assistant — RAG API",
    description="Retrieval-Augmented Generation pipeline for Roblox Luau API documentation.",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS: allow Studio plugin and CLI clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    stats = vector_store.get_stats()
    return HealthResponse(
        status="ok",
        version="0.1.0",
        indexed_classes=0,  # populated from stats file if available
        total_chunks=stats["total_chunks"],
    )


@app.post("/query", response_model=QueryResponse)
async def query_docs(request: QueryRequest):
    """
    Query the Roblox API documentation.

    Accepts a natural language query and returns the top-k most relevant
    documentation chunks from the Roblox Engine API reference.

    Constraints:
    - Sub-3-second retrieval latency
    - Zero query logging (no data retention)
    - Results grounded in official Roblox API docs
    """
    start = time.time()

    try:
        chunks, retrieval_ms = vector_store.query(
            query_text=request.query,
            top_k=request.top_k or DEFAULT_TOP_K,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retrieval error: {str(e)}")

    total_ms = (time.time() - start) * 1000

    doc_chunks = [
        DocChunk(
            chunk_id=c["chunk_id"],
            content=c["content"],
            metadata=c["metadata"],
            relevance_score=c["relevance_score"],
        )
        for c in chunks
    ]

    stats = vector_store.get_stats()

    # NOTE: Zero data retention — we NEVER log or store the user's query.
    # The query variable is discarded after this response is returned.

    return QueryResponse(
        query=request.query,
        chunks=doc_chunks,
        retrieval_time_ms=round(retrieval_ms, 2),
        total_indexed_classes=0,  # placeholder; populated from stats
    )
