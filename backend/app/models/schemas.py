"""
Pydantic models for the RAG pipeline.
"""
from pydantic import BaseModel, Field
from typing import Optional


class QueryRequest(BaseModel):
    """Incoming query from the user."""
    query: str = Field(..., min_length=1, max_length=2000, description="Natural language query about Roblox APIs")
    top_k: int = Field(default=5, ge=1, le=20, description="Number of document chunks to retrieve")


class DocChunk(BaseModel):
    """A single retrieved document chunk."""
    chunk_id: str
    content: str
    metadata: dict
    relevance_score: float


class QueryResponse(BaseModel):
    """Response from the /query endpoint."""
    query: str
    chunks: list[DocChunk]
    retrieval_time_ms: float
    total_indexed_classes: int


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    version: str
    indexed_classes: int
    total_chunks: int
