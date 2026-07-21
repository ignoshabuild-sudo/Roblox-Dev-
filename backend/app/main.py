"""
FastAPI application for the Roblox AI Code Assistant.
Provides:
  - /query — RAG retrieval of Roblox API documentation
  - /generate — LLM-powered Luau code generation (RAG-grounded)
  - /health — Health check with DB stats
"""
import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import DEFAULT_TOP_K
from app.models.schemas import (
    QueryRequest, QueryResponse, DocChunk, HealthResponse,
    GenerateRequest, GenerateResponse,
)
from app.core.auth import require_api_key, validate_key, VALID_API_KEYS
from app.services.vector_store import vector_store
from app.services.llm_service import llm_service, DEFAULT_MODEL


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


@app.post("/generate", response_model=GenerateResponse)
async def generate_code(request: GenerateRequest, api_key: dict = Depends(require_api_key)):
    """
    Generate production-ready Luau code from a natural language description.

    Flow: user query → RAG retrieval → prompt construction → OpenAI → code

    Non-Negotiables:
      - Sub-3-second total latency target
      - Zero data retention: user queries NEVER logged or stored
      - Hallucination guardrails: model must only use APIs from provided docs
      - "I don't know" fallback when APIs are uncertain
      - No sandbox-escaping functions (loadstring, getfenv, etc.)
    """
    total_start = time.time()

    # 1. RAG retrieval
    try:
        chunks, retrieval_ms = vector_store.query(
            query_text=request.query,
            top_k=request.top_k or DEFAULT_TOP_K,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"RAG retrieval error: {str(e)}")

    # 2. LLM generation with RAG context
    model = request.model or DEFAULT_MODEL
    if model != DEFAULT_MODEL:
        # Override model on the service if a different one is requested
        llm_service._model = model
    else:
        llm_service._model = DEFAULT_MODEL

    try:
        gen_result = llm_service.generate(
            query=request.query,
            context_chunks=chunks,
            context_type=request.context_type,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM generation error: {str(e)}")

    total_ms = (time.time() - total_start) * 1000

    # NOTE: Zero data retention — the user's query is discarded after this response.
    # We only log anonymized timing metrics.
    # Query discarded after response — zero retention policy
    print(
        f"[generate] retrieval={retrieval_ms:.0f}ms "
        f"generation={gen_result['generation_time_ms']:.0f}ms "
        f"total={total_ms:.0f}ms "
        f"model={gen_result['model_used']} "
        f"chunks={len(chunks)} "
        f"uncertain={gen_result['is_uncertain']}"
    )

    return GenerateResponse(
        code=gen_result["code"],
        api_references=gen_result["api_references"],
        retrieval_time_ms=round(retrieval_ms, 2),
        generation_time_ms=gen_result["generation_time_ms"],
        total_time_ms=round(total_ms, 2),
        model_used=gen_result["model_used"],
        is_uncertain=gen_result["is_uncertain"],
    )


@app.get("/validate-key")
async def validate_api_key(x_api_key: str = Header(..., alias="X-API-Key")):
    """
    Validate an API key and return its tier.
    Used by the Studio plugin and CLI to check access before making generate requests.
    """
    key_info = validate_key(x_api_key)
    if key_info is None:
        return {"valid": False, "tier": None}
    return {"valid": True, "tier": key_info.get("tier", "unknown")}
