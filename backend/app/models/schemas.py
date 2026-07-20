"""
Pydantic models for the RAG pipeline and code generation API.
"""
from pydantic import BaseModel, Field
from typing import Optional, Literal


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


# ── Code Generation Models ──────────────────────────────────────────────

class GenerateRequest(BaseModel):
    """Request to generate Luau code from a natural language description."""
    query: str = Field(
        ..., min_length=1, max_length=4000,
        description="Natural language description of what code to generate"
    )
    context_type: Literal["server", "client", "module"] = Field(
        default="module",
        description="Execution context: server (Script), client (LocalScript), or module (ModuleScript)"
    )
    top_k: int = Field(default=5, ge=1, le=20, description="Number of doc chunks to retrieve for RAG grounding")
    model: Optional[Literal["gpt-4o-mini", "gpt-4o"]] = Field(
        default=None,
        description="OpenAI model to use (default: gpt-4o-mini for speed)"
    )


class GenerateResponse(BaseModel):
    """Response from the /generate endpoint."""
    code: str = Field(description="Generated Luau code")
    api_references: list[str] = Field(description="List of API docs used for grounding")
    retrieval_time_ms: float = Field(description="Time spent on RAG retrieval (ms)")
    generation_time_ms: float = Field(description="Time spent on LLM generation (ms)")
    total_time_ms: float = Field(description="Total wall-clock time (ms)")
    model_used: str = Field(description="Which OpenAI model was used")
    is_uncertain: bool = Field(
        default=False,
        description="True if model responded with 'I don't know' due to missing API context"
    )
    # Query discarded after response — zero retention policy
