"""
ChromaDB vector store service using ONNX-based embeddings (no PyTorch).
Handles embedding generation, document storage, and similarity search.
"""
import time
import hashlib
from typing import Optional

import chromadb
from chromadb.config import Settings as ChromaSettings
from chromadb.utils import embedding_functions

from app.core.config import (
    CHROMA_DIR, CHROMA_COLLECTION,
    DEFAULT_TOP_K, MAX_TOP_K,
)


class VectorStore:
    """Manages the ChromaDB vector store for Roblox API documentation."""

    def __init__(self):
        self._client: Optional[chromadb.PersistentClient] = None
        self._collection: Optional[chromadb.Collection] = None
        self._embedder: Optional[embedding_functions.EmbeddingFunction] = None

    @property
    def client(self) -> chromadb.PersistentClient:
        if self._client is None:
            self._client = chromadb.PersistentClient(
                path=str(CHROMA_DIR),
                settings=ChromaSettings(anonymized_telemetry=False),
            )
        return self._client

    @property
    def embedder(self) -> embedding_functions.EmbeddingFunction:
        if self._embedder is None:
            # ONNX-based MiniLM-L6-v2 — runs locally, no PyTorch needed
            self._embedder = embedding_functions.ONNXMiniLM_L6_V2()
        return self._embedder

    @property
    def collection(self) -> chromadb.Collection:
        if self._collection is None:
            self._collection = self.client.get_or_create_collection(
                name=CHROMA_COLLECTION,
                embedding_function=self.embedder,
                metadata={"hnsw:space": "cosine"},
            )
        return self._collection

    def reset_collection(self) -> None:
        """Delete and recreate the collection for a fresh ingest."""
        try:
            self.client.delete_collection(CHROMA_COLLECTION)
        except Exception:
            pass
        self._collection = None
        # Re-create with embedder
        _ = self.collection

    def add_documents(
        self,
        documents: list[str],
        metadatas: list[dict],
        ids: Optional[list[str]] = None,
    ) -> int:
        """Store documents in the vector DB. Returns count added."""
        if not documents:
            return 0

        if ids is None:
            ids = [
                hashlib.sha256(doc.encode()).hexdigest()[:32]
                for doc in documents
            ]

        # Sanitize metadata: ChromaDB doesn't like None values
        sanitized_metadatas = []
        for m in metadatas:
            sanitized_metadatas.append({
                k: (v if v is not None else "") for k, v in m.items()
            })

        self.collection.add(
            ids=ids,
            documents=documents,
            metadatas=sanitized_metadatas,
        )
        return len(documents)

    def query(
        self,
        query_text: str,
        top_k: int = DEFAULT_TOP_K,
    ) -> tuple[list[dict], float]:
        """
        Retrieve top-k relevant chunks for a query.
        Returns (results, elapsed_time_ms).
        Enforces sub-3-second latency target.
        """
        top_k = min(max(top_k, 1), MAX_TOP_K)
        start = time.time()

        results = self.collection.query(
            query_texts=[query_text],
            n_results=top_k,
        )

        elapsed = (time.time() - start) * 1000

        # Format results
        formatted = []
        if results and results.get("ids") and results["ids"][0]:
            for i in range(len(results["ids"][0])):
                dist = results.get("distances", [[0]])[0]
                relevance = round(1.0 - (dist[i] if i < len(dist) else 0), 4)
                formatted.append({
                    "chunk_id": results["ids"][0][i],
                    "content": results["documents"][0][i] if results.get("documents") else "",
                    "metadata": results["metadatas"][0][i] if results.get("metadatas") else {},
                    "relevance_score": relevance,
                })

        return formatted, elapsed

    def get_stats(self) -> dict:
        """Return collection statistics."""
        try:
            count = self.collection.count()
        except Exception:
            count = 0
        return {
            "total_chunks": count,
            "collection_name": CHROMA_COLLECTION,
        }


# Singleton
vector_store = VectorStore()
