"""
Documentation ingestion pipeline for Roblox Engine API.
Fetches class pages from the official docs, parses them into structured chunks,
and stores them in the ChromaDB vector database.
"""
import asyncio
import hashlib
import json
import re
import sys
import time
from pathlib import Path
from typing import Optional

import httpx

# Add backend to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.config import (
    ENGINE_LLMS_URL, ROBLOX_DOCS_BASE, RAW_DOCS_DIR, PROCESSED_DOCS_DIR,
    REQUEST_TIMEOUT,
)
from app.services.vector_store import vector_store


# ─── URL Extraction ───────────────────────────────────────────────────────────

async def fetch_llms_txt(client: httpx.AsyncClient) -> str:
    """Fetch the engine API llms.txt index."""
    resp = await client.get(ENGINE_LLMS_URL, timeout=REQUEST_TIMEOUT)
    resp.raise_for_status()
    return resp.text


def extract_class_urls(llms_content: str) -> list[tuple[str, str, str]]:
    """
    Extract class names, URLs, and short descriptions from llms.txt.
    Returns list of (class_name, url_path, short_description).
    """
    classes = []
    # Match: - [ClassName](/docs/reference/engine/classes/ClassName.md): Description
    pattern = re.compile(
        r'^-\s+\[([^\]]+)\]\((/docs/reference/engine/classes/[^\)]+\.md)\)(?::\s*(.*))?$',
        re.MULTILINE,
    )
    for match in pattern.finditer(llms_content):
        name = match.group(1)
        url = match.group(2)
        desc = match.group(3) or ""
        classes.append((name, url, desc.strip()))
    return classes


def extract_datatype_urls(llms_content: str) -> list[tuple[str, str, str]]:
    """Extract datatype URLs."""
    datatypes = []
    pattern = re.compile(
        r'^-\s+\[([^\]]+)\]\((/docs/reference/engine/datatypes/[^\)]+\.md)\)(?::\s*(.*))?$',
        re.MULTILINE,
    )
    for match in pattern.finditer(llms_content):
        datatypes.append((match.group(1), match.group(2), (match.group(3) or "").strip()))
    return datatypes


def extract_enum_urls(llms_content: str) -> list[tuple[str, str, str]]:
    """Extract enum URLs."""
    enums = []
    pattern = re.compile(
        r'^-\s+\[([^\]]+)\]\((/docs/reference/engine/enums/[^\)]+\.md)\)(?::\s*(.*))?$',
        re.MULTILINE,
    )
    for match in pattern.finditer(llms_content):
        enums.append((match.group(1), match.group(2), (match.group(3) or "").strip()))
    return enums


# ─── Markdown Fetching ────────────────────────────────────────────────────────

async def fetch_class_page(
    client: httpx.AsyncClient, url_path: str
) -> Optional[str]:
    """Fetch a single class markdown page."""
    url = f"{ROBLOX_DOCS_BASE}{url_path}"
    try:
        resp = await client.get(url, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        return resp.text
    except Exception as e:
        print(f"  [WARN] Failed to fetch {url}: {e}")
        return None


# ─── Markdown Parsing ─────────────────────────────────────────────────────────

def parse_frontmatter(md_content: str) -> dict:
    """Parse YAML frontmatter from markdown. Simple parser for known fields."""
    fm = {}
    if not md_content.startswith("---"):
        return fm

    end = md_content.find("---", 3)
    if end == -1:
        return fm

    fm_text = md_content[3:end].strip()
    current_key = None

    for line in fm_text.split("\n"):
        line = line.strip()
        if not line:
            continue
        if line.startswith("- ") and current_key:
            # List continuation
            fm.setdefault(current_key, []).append(line[2:].strip())
            continue
        if ":" in line:
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            current_key = key
            if val:
                fm[key] = val
            else:
                fm[key] = []
        else:
            # Could be a list item without leading dash
            if current_key:
                fm.setdefault(current_key, []).append(line.strip())

    return fm


def chunk_class_document(md_content: str, class_name: str) -> list[dict]:
    """
    Parse a class markdown document and return structured chunks.
    Each chunk is a dict with: id, content, metadata.

    Produces these chunk types:
    - overview: class description and inheritance
    - method: individual method documentation
    - property: individual property
    - event: individual event
    - callback: individual callback
    """
    frontmatter = parse_frontmatter(md_content)
    summary = frontmatter.get("summary", "")
    inherits = frontmatter.get("inherits", [])
    if isinstance(inherits, str):
        inherits = [inherits]
    memory_category = frontmatter.get("memory_category", "")

    chunks = []

    # ── Overview chunk ──
    # Extract the description (text between ## Description and next ## heading)
    desc_match = re.search(r'## Description\s*\n(.*?)(?=\n##\s|\Z)', md_content, re.DOTALL)
    description = ""
    if desc_match:
        # Clean markdown links: [text](url) -> text
        description = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', desc_match.group(1))
        description = re.sub(r'\n\s*\n', '\n\n', description).strip()
        # Remove bold markers for cleaner text
        description = re.sub(r'\*\*([^*]+)\*\*', r'\1', description)

    overview = f"# {class_name}\n\n"
    if summary:
        overview += f"Summary: {summary}\n\n"
    if inherits:
        overview += f"Inherits from: {' > '.join(inherits)}\n\n"
    if memory_category:
        overview += f"Memory Category: {memory_category}\n\n"
    if description:
        overview += description

    chunks.append({
        "id": f"{class_name}__overview",
        "content": overview,
        "metadata": {
            "class_name": class_name,
            "chunk_type": "overview",
            "inherits": ", ".join(inherits),
            "memory_category": memory_category,
        },
    })

    # ── Method chunks ──
    method_section = extract_section(md_content, "Methods")
    if method_section:
        method_blocks = re.split(r'\n### Method:', method_section)
        for block in method_blocks:
            if not block.strip():
                continue
            block = "### Method:" + block if not block.startswith("###") else block
            method_chunks = parse_method_block(block, class_name)
            chunks.extend(method_chunks)

    # ── Property chunks ──
    prop_section = extract_section(md_content, "Properties")
    if prop_section:
        prop_blocks = re.split(r'\n### Property:', prop_section)
        for block in prop_blocks:
            if not block.strip():
                continue
            block = "### Property:" + block if not block.startswith("###") else block
            prop_chunks = parse_property_block(block, class_name)
            chunks.extend(prop_chunks)

    # ── Event chunks ──
    event_section = extract_section(md_content, "Events")
    if event_section:
        event_blocks = re.split(r'\n### Event:', event_section)
        for block in event_blocks:
            if not block.strip():
                continue
            block = "### Event:" + block if not block.startswith("###") else block
            event_chunks = parse_event_block(block, class_name, "event")
            chunks.extend(event_chunks)

    # ── Callback chunks ──
    callback_section = extract_section(md_content, "Callbacks")
    if callback_section:
        cb_blocks = re.split(r'\n### Callback:', callback_section)
        for block in cb_blocks:
            if not block.strip():
                continue
            block = "### Callback:" + block if not block.startswith("###") else block
            cb_chunks = parse_event_block(block, class_name, "callback")
            chunks.extend(cb_chunks)

    return chunks


def extract_section(md_content: str, section_name: str) -> Optional[str]:
    """Extract a named section from the markdown."""
    pattern = rf'## {section_name}\s*\n(.*?)(?=\n##\s[^#]|\Z)'
    match = re.search(pattern, md_content, re.DOTALL)
    return match.group(1) if match else None


def parse_method_block(block: str, class_name: str) -> list[dict]:
    """Parse a single method block into a chunk."""
    # Extract method name from heading
    name_match = re.search(r'### Method:\s*([^\n]+)', block)
    if not name_match:
        return []
    full_name = name_match.group(1).strip()
    # full_name could be "ClassName:MethodName" or just "MethodName"
    method_name = full_name.split(":")[-1] if ":" in full_name else full_name

    # Extract signature
    sig_match = re.search(r'\*\*Signature:\*\*\s*`([^`]+)`', block)
    signature = sig_match.group(1) if sig_match else ""

    # Clean text
    clean = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', block)
    clean = re.sub(r'\*\*([^*]+)\*\*', r'\1', clean)
    clean = re.sub(r'#{1,4}\s*', '', clean)
    clean = re.sub(r'\n\s*\n', '\n\n', clean).strip()

    content = (
        f"# {class_name}:{method_name} (Method)\n\n"
        f"Signature: `{signature}`\n\n"
        f"{clean}"
    )

    chunk_id = hashlib.sha256(f"{class_name}:{method_name}".encode()).hexdigest()[:32]
    return [{
        "id": chunk_id,
        "content": content,
        "metadata": {
            "class_name": class_name,
            "member_name": method_name,
            "chunk_type": "method",
            "full_signature": signature,
        },
    }]


def parse_property_block(block: str, class_name: str) -> list[dict]:
    """Parse a single property block into a chunk."""
    name_match = re.search(r'### Property:\s*([^\n]+)', block)
    if not name_match:
        return []
    full_name = name_match.group(1).strip()
    prop_name = full_name.split(":")[-1] if ":" in full_name else full_name

    clean = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', block)
    clean = re.sub(r'\*\*([^*]+)\*\*', r'\1', clean)
    clean = re.sub(r'#{1,4}\s*', '', clean)
    clean = re.sub(r'\n\s*\n', '\n\n', clean).strip()

    content = (
        f"# {class_name}.{prop_name} (Property)\n\n"
        f"{clean}"
    )

    chunk_id = hashlib.sha256(f"{class_name}.{prop_name}".encode()).hexdigest()[:32]
    return [{
        "id": chunk_id,
        "content": content,
        "metadata": {
            "class_name": class_name,
            "member_name": prop_name,
            "chunk_type": "property",
        },
    }]


def parse_event_block(block: str, class_name: str, event_type: str) -> list[dict]:
    """Parse an event or callback block."""
    prefix = "Event" if event_type == "event" else "Callback"
    name_match = re.search(rf'### {prefix}:\s*([^\n]+)', block)
    if not name_match:
        return []
    full_name = name_match.group(1).strip()
    event_name = full_name.split(":")[-1] if ":" in full_name else full_name

    clean = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', block)
    clean = re.sub(r'\*\*([^*]+)\*\*', r'\1', clean)
    clean = re.sub(r'#{1,4}\s*', '', clean)
    clean = re.sub(r'\n\s*\n', '\n\n', clean).strip()

    content = (
        f"# {class_name}.{event_name} ({prefix})\n\n"
        f"{clean}"
    )

    chunk_id = hashlib.sha256(f"{class_name}.{event_name}.{event_type}".encode()).hexdigest()[:32]
    return [{
        "id": chunk_id,
        "content": content,
        "metadata": {
            "class_name": class_name,
            "member_name": event_name,
            "chunk_type": event_type,
        },
    }]


# ─── Main Ingestion Pipeline ──────────────────────────────────────────────────

async def ingest_docs(
    max_classes: int = 0,
    target_classes: Optional[list[str]] = None,
    concurrency: int = 5,
) -> dict:
    """
    Full ingestion pipeline:
    1. Fetch llms.txt
    2. Extract class URLs
    3. Fetch and parse each class page
    4. Chunk and store in ChromaDB
    """
    print("=" * 60)
    print("Roblox API Documentation Ingestion Pipeline")
    print("=" * 60)

    async with httpx.AsyncClient(
        timeout=REQUEST_TIMEOUT,
        headers={"User-Agent": "RobloxDev-AI-Assistant/0.1"},
    ) as client:
        # Step 1: Fetch index
        print("\n[1/4] Fetching engine API index...")
        llms_content = await fetch_llms_txt(client)
        print(f"  Got {len(llms_content):,} bytes")

        # Step 2: Extract URLs
        print("\n[2/4] Extracting class URLs...")
        classes = extract_class_urls(llms_content)
        datatypes = extract_datatype_urls(llms_content)
        enums = extract_enum_urls(llms_content)
        print(f"  Found {len(classes)} classes, {len(datatypes)} datatypes, {len(enums)} enums")

        # Filter if target_classes specified
        if target_classes:
            classes = [(n, u, d) for n, u, d in classes if n in target_classes]
            print(f"  Filtered to {len(classes)} target classes")

        # Limit if needed
        if max_classes > 0 and len(classes) > max_classes:
            classes = classes[:max_classes]
            print(f"  Limited to first {max_classes} classes")

        # Step 3: Fetch and parse class pages
        print(f"\n[3/4] Fetching and parsing {len(classes)} class pages...")
        all_chunks = []
        class_count = 0
        semaphore = asyncio.Semaphore(concurrency)

        async def process_class(name: str, url: str, desc: str):
            nonlocal class_count
            async with semaphore:
                md = await fetch_class_page(client, url)
                if md is None:
                    return
                chunks = chunk_class_document(md, name)
                class_count += 1
                chunk_types = set(c["metadata"]["chunk_type"] for c in chunks)
                types_str = ", ".join(sorted(chunk_types))
                print(f"  [{class_count}/{len(classes)}] {name}: {len(chunks)} chunks ({types_str})")
                return chunks

        tasks = [process_class(name, url, desc) for name, url, desc in classes]
        results = await asyncio.gather(*tasks)

        for chunks in results:
            if chunks:
                all_chunks.extend(chunks)

        print(f"\n  Total chunks generated: {len(all_chunks)}")

        # Step 4: Store in ChromaDB
        print(f"\n[4/4] Storing {len(all_chunks)} chunks in ChromaDB...")
        vector_store.reset_collection()

        documents = [c["content"] for c in all_chunks]
        metadatas = [c["metadata"] for c in all_chunks]
        ids = [c["id"] for c in all_chunks]

        # Batch insertion for efficiency
        batch_size = 100
        total_stored = 0
        for i in range(0, len(documents), batch_size):
            batch_docs = documents[i:i + batch_size]
            batch_metas = metadatas[i:i + batch_size]
            batch_ids = ids[i:i + batch_size]
            total_stored += vector_store.add_documents(batch_docs, batch_metas, batch_ids)
            print(f"  Stored batch {i // batch_size + 1}: {total_stored}/{len(documents)}")

        # Save processed metadata
        stats = {
            "total_classes": class_count,
            "total_chunks": total_stored,
            "classes_indexed": [n for n, _, _ in classes],
        }
        PROCESSED_DOCS_DIR.mkdir(parents=True, exist_ok=True)
        with open(PROCESSED_DOCS_DIR / "ingestion_stats.json", "w") as f:
            json.dump(stats, f, indent=2)

        print(f"\n✓ Ingestion complete: {class_count} classes, {total_stored} chunks stored")
        return stats


# ─── CLI Entry Point ──────────────────────────────────────────────────────────

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Ingest Roblox API docs into ChromaDB")
    parser.add_argument("--max-classes", type=int, default=50,
                        help="Maximum number of classes to ingest (default: 50)")
    parser.add_argument("--all", action="store_true",
                        help="Ingest ALL classes (654+)")
    parser.add_argument("--concurrency", type=int, default=5,
                        help="Concurrent fetches (default: 5)")
    parser.add_argument("--classes", type=str, default=None,
                        help="Comma-separated list of specific classes to ingest")
    args = parser.parse_args()

    max_c = 0 if args.all else args.max_classes
    targets = args.classes.split(",") if args.classes else None

    start = time.time()
    stats = asyncio.run(ingest_docs(
        max_classes=max_c,
        target_classes=targets,
        concurrency=args.concurrency,
    ))
    elapsed = time.time() - start
    print(f"\nTotal time: {elapsed:.1f}s")
