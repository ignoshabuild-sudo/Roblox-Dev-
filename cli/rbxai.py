#!/usr/bin/env python3
"""
rbxai — Roblox AI Code Assistant CLI

Generate production-ready Luau code from your terminal.
Grounded in official Roblox API docs. Zero data retention.

Usage:
    python rbxai.py "Create a RemoteEvent for player data sync"
    python rbxai.py --context server "DataStore with retry logic"
    python rbxai.py --project "Create a tycoon game with money system"
    python rbxai.py --project "Simple clicker game" --output-dir ./my-game
    python rbxai.py --credits
    python rbxai.py --key YOUR_KEY "Part welding system"
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

try:
    import httpx
except ImportError:
    print("Error: httpx is required. Install with: pip install httpx")
    sys.exit(1)

try:
    from rich.console import Console
    from rich.syntax import Syntax
    from rich.panel import Panel
    from rich.table import Table
    from rich.tree import Tree
    from rich import box
    HAS_RICH = True
except ImportError:
    HAS_RICH = False

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# ── Configuration ───────────────────────────────────────────────
DEFAULT_API_URL = "http://127.0.0.1:8000"
API_URL = os.environ.get("RBXAI_API_URL", DEFAULT_API_URL)


def get_api_key(args) -> str:
    """Resolve API key from flag, env var, or prompt."""
    key = args.key or os.environ.get("RBXAI_API_KEY")
    if not key:
        print("Error: No API key provided. Set RBXAI_API_KEY or use --key.")
        print("Get a key at: https://23caccdb19d616fd54ecba6af9408adc.ctonew.app/dashboard")
        sys.exit(1)
    return key


def print_rich_result(result: dict, credits_info: dict | None, args):
    """Pretty-print generation results using Rich."""
    console = Console()

    # Code panel
    code = result.get("code", "")
    if code:
        syntax = Syntax(code, "lua", theme="monokai", line_numbers=True,
                        word_wrap=True, background_color="#1a1a2e")
        title = "Generated Luau Code"
        if result.get("is_uncertain"):
            title += " ⚠️ (Uncertain — verify before use)"
        console.print(Panel(syntax, title=title, border_style="blue"))

    # API references
    refs = result.get("api_references", [])
    if refs and refs != ["No grounding references extracted"]:
        ref_table = Table(box=box.SIMPLE, show_header=True, border_style="dim blue")
        ref_table.add_column("#", style="dim", width=4)
        ref_table.add_column("API Reference", style="cyan")
        for i, ref in enumerate(refs, 1):
            ref_table.add_row(str(i), ref)
        console.print(Panel(ref_table, title="Grounding References", border_style="dim blue"))

    # Timing
    timing = []
    if result.get("retrieval_time_ms"):
        timing.append(f"🔍 Retrieval: {result['retrieval_time_ms']:.0f}ms")
    if result.get("generation_time_ms"):
        timing.append(f"🧠 Generation: {result['generation_time_ms']:.0f}ms")
    if result.get("total_time_ms"):
        timing.append(f"⏱️  Total: {result['total_time_ms']:.0f}ms")
    if result.get("model_used"):
        timing.append(f"🤖 Model: {result['model_used']}")

    if timing:
        console.print("  " + " · ".join(timing), style="dim")

    # Credits
    if credits_info:
        remaining = credits_info.get("credits_remaining", "?")
        tier = credits_info.get("tier", "unknown").upper()
        total_used = credits_info.get("total_used", 0)
        daily = credits_info.get("daily_limit", "∞")

        if daily == 999999:
            credits_str = f"[green]Unlimited[/green] ({tier})"
        else:
            color = "green" if remaining > 3 else "yellow" if remaining > 0 else "red"
            credits_str = f"[{color}]{remaining}/{daily} remaining[/{color}] ({tier})"

        console.print(f"  💳 Credits: {credits_str} · {total_used} used today", style="dim")


def print_plain_result(result: dict, credits_info: dict | None, args):
    """Fallback plain-text output when rich is not available."""
    code = result.get("code", "")
    print("\n" + "=" * 60)
    print("  GENERATED LUAU CODE")
    print("=" * 60)
    print(code)
    print("=" * 60)

    refs = result.get("api_references", [])
    if refs and refs != ["No grounding references extracted"]:
        print("\nGrounding References:")
        for ref in refs:
            print(f"  • {ref}")

    timing = []
    if result.get("retrieval_time_ms"):
        timing.append(f"Retrieval: {result['retrieval_time_ms']:.0f}ms")
    if result.get("generation_time_ms"):
        timing.append(f"Generation: {result['generation_time_ms']:.0f}ms")
    if result.get("total_time_ms"):
        timing.append(f"Total: {result['total_time_ms']:.0f}ms")
    if timing:
        print("  " + " · ".join(timing))

    if credits_info:
        print(f"  Credits: {credits_info.get('credits_remaining')}/{credits_info.get('daily_limit')} "
              f"({credits_info.get('tier', 'unknown')})")


def check_credits(api_key: str):
    """Check remaining credits for an API key."""
    try:
        resp = httpx.get(
            f"{API_URL}/credits",
            headers={"X-API-Key": api_key},
            timeout=10,
        )
        if resp.status_code != 200:
            detail = resp.json().get("detail", resp.text)
            print(f"Error checking credits: {resp.status_code} — {detail}")
            sys.exit(1)

        data = resp.json()
        if HAS_RICH:
            console = Console()
            table = Table(title="Credit Balance", box=box.SIMPLE, border_style="blue")
            table.add_column("Metric", style="dim")
            table.add_column("Value", style="bold cyan")
            table.add_row("Tier", data.get("tier", "unknown").upper())
            remaining = data.get("credits_remaining", 0)
            daily = data.get("daily_limit", 10)
            if daily >= 999999:
                table.add_row("Credits", "Unlimited")
            else:
                table.add_row("Credits", f"{remaining}/{daily} remaining")
            table.add_row("Used Today", str(data.get("total_used", 0)))
            table.add_row("Daily Reset", data.get("last_reset_date", "N/A"))
            console.print(table)
        else:
            print(f"Tier: {data.get('tier', 'unknown').upper()}")
            remaining = data.get("credits_remaining")
            daily = data.get("daily_limit")
            if daily >= 999999:
                print("Credits: Unlimited")
            else:
                print(f"Credits: {remaining}/{daily} remaining")
            print(f"Used Today: {data.get('total_used', 0)}")
            print(f"Daily Reset: {data.get('last_reset_date', 'N/A')}")

    except httpx.ConnectError:
        print(f"Error: Cannot connect to {API_URL}. Is the server running?")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


def generate_code(api_key: str, query: str, context_type: str):
    """Call the /generate endpoint and display results."""
    try:
        resp = httpx.post(
            f"{API_URL}/generate",
            headers={"X-API-Key": api_key, "Content-Type": "application/json"},
            json={"query": query, "context_type": context_type},
            timeout=30,
        )
        if resp.status_code == 401:
            print("Error: Invalid API key. Check your key or get one at the dashboard.")
            sys.exit(1)
        if resp.status_code == 402:
            detail = resp.json().get("detail", "No credits remaining")
            print(f"Error: {detail}")
            sys.exit(1)
        if resp.status_code != 200:
            detail = resp.json().get("detail", resp.text)
            print(f"Error: {resp.status_code} — {detail}")
            sys.exit(1)

        result = resp.json()

        # Also fetch credits
        credits_info = None
        try:
            cred_resp = httpx.get(
                f"{API_URL}/credits",
                headers={"X-API-Key": api_key},
                timeout=5,
            )
            if cred_resp.status_code == 200:
                credits_info = cred_resp.json()
        except Exception:
            pass

        if HAS_RICH:
            print_rich_result(result, credits_info, None)
        else:
            print_plain_result(result, credits_info, None)

    except httpx.ConnectError:
        print(f"Error: Cannot connect to {API_URL}. Is the server running?")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


# ── Rojo project manifest template ───────────────────────────────

ROJO_MANIFEST_TEMPLATE = """{
  "name": "{project_name}",
  "tree": {{
    "$className": "DataModel",
    "ServerScriptService": {{
      "$path": "src/Server"
    }},
    "StarterPlayer": {{
      "StarterPlayerScripts": {{
        "$path": "src/Client"
      }}
    }},
    "ReplicatedStorage": {{
      "$path": "src/Shared"
    }}
  }}
}}"""


def sanitize_project_name(query: str) -> str:
    """Derive a safe folder name from the query string."""
    # Take first 3-4 words, lowercase, replace non-alphanumeric with hyphens
    words = query.strip().lower().split()[:4]
    name = "-".join(words)
    name = re.sub(r"[^a-z0-9-]", "", name)
    name = re.sub(r"-+", "-", name).strip("-")
    return name or "generated-game"


def generate_project(api_key: str, query: str, game_type: str, output_dir: str):
    """Call the /generate-project endpoint and save files to disk."""
    console = Console() if HAS_RICH else None

    try:
        resp = httpx.post(
            f"{API_URL}/generate-project",
            headers={"X-API-Key": api_key, "Content-Type": "application/json"},
            json={"query": query, "game_type": game_type},
            timeout=60,
        )
        if resp.status_code == 401:
            print("Error: Invalid API key. Check your key or get one at the dashboard.")
            sys.exit(1)
        if resp.status_code == 402:
            detail = resp.json().get("detail", "No credits remaining")
            print(f"Error: {detail}")
            sys.exit(1)
        if resp.status_code != 200:
            detail = resp.json().get("detail", resp.text)
            print(f"Error: {resp.status_code} — {detail}")
            sys.exit(1)

        data = resp.json()

    except httpx.ConnectError:
        print(f"Error: Cannot connect to {API_URL}. Is the server running?")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

    # Show header
    if console:
        console.print()
        console.print(Panel(
            f"[bold]Game Type:[/bold] {data['manifest']['game_type']}\n"
            f"[bold]Description:[/bold] {data['manifest']['description']}\n"
            f"[bold]Files:[/bold] {len(data['files'])} generated\n"
            f"[dim]Retrieval: {data.get('retrieval_time_ms', 0):.0f}ms · "
            f"Generation: {data.get('generation_time_ms', 0):.0f}ms · "
            f"Total: {data.get('total_time_ms', 0):.0f}ms · "
            f"Model: {data.get('model_used', '?')}[/dim]",
            title=f"🎮 {data['project_name']}",
            border_style="green",
        ))

    # Write files to disk
    project_dir = Path(output_dir)
    project_dir.mkdir(parents=True, exist_ok=True)

    # Build file tree for display
    file_tree: dict[str, list[dict]] = {}
    for f in data["files"]:
        path = f["path"]
        if path.endswith(".luau"):
            dir_key = str(Path(path).parent)
        else:
            dir_key = str(Path(path))
        if dir_key not in file_tree:
            file_tree[dir_key] = []
        file_tree[dir_key].append(f)

    # Write each file
    for f in data["files"]:
        file_path = project_dir / f["path"]
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(f["content"], encoding="utf-8")

    # Write default.project.json (Rojo manifest)
    rojo_path = project_dir / "default.project.json"
    if not rojo_path.exists():
        rojo_content = ROJO_MANIFEST_TEMPLATE.replace("{project_name}", data["project_name"])
        rojo_path.write_text(rojo_content, encoding="utf-8")

    # Write README.md
    readme_path = project_dir / "README.md"
    readme_path.write_text(
        f"# {data['project_name']}\n\n"
        f"{data['manifest']['description']}\n\n"
        f"## Open in Roblox Studio\n\n"
        f"1. Install [Rojo](https://rojo.space/)\n"
        f"2. Run `rojo serve` in this directory\n"
        f"3. Open Roblox Studio and connect the Rojo plugin\n\n"
        f"Generated by [Roblox AI Code Assistant](https://23caccdb19d616fd54ecba6af9408adc.ctonew.app)\n",
        encoding="utf-8",
    )

    # Display file tree
    if console:
        tree = Tree(f"📁 {project_dir.name}", guide_style="dim blue")
        dir_nodes: dict[str, Tree] = {}

        sorted_dirs = sorted(file_tree.keys())
        for dir_key in sorted_dirs:
            files = file_tree[dir_key]
            display = dir_key if dir_key != "." else ""
            parent = tree
            if display:
                parts = Path(display).parts
                for part in parts:
                    if part not in dir_nodes:
                        dir_nodes[part] = parent.add(f"📁 {part}")
                    parent = dir_nodes[part]
            for f in files:
                fname = Path(f["path"]).name
                parent.add(f"📄 {fname}", style="green")

        # Add Rojo manifest and README
        if rojo_path.exists():
            tree.add("📄 default.project.json", style="yellow")
        if readme_path.exists():
            tree.add("📄 README.md", style="dim")

        console.print(tree)
        console.print()

    # Success message
    print(f"\n✅ Game generated in {project_dir.absolute()}/")
    print(f"   Open with: rojo serve")
    print(f"   Then connect the Rojo plugin in Roblox Studio.\n")


def main():
    parser = argparse.ArgumentParser(
        description="Roblox AI Code Assistant — Generate Luau from your terminal",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python rbxai.py "Create a RemoteEvent for player data sync"
  python rbxai.py --context server "DataStore with retry logic"
  python rbxai.py --project "Create a tycoon game with money system"
  python rbxai.py --project "Simple clicker game" --output-dir ./my-game
  python rbxai.py --credits
  python rbxai.py --key dev-key-2026 "Part welding system"

Tiers:
  Free — 10 generations/day with watermark
  Hobbyist ($9/mo) — Unlimited, no watermark
  Pro ($29/mo) — 16K context, Refactor tool
  Studio ($99/mo) — 5 seats, Project Memory, fine-tuning
        """,
    )
    parser.add_argument(
        "query", nargs="?", default=None,
        help="Natural language description of the code to generate"
    )
    parser.add_argument(
        "--key", "-k", default=None,
        help="API key (or set RBXAI_API_KEY env var)"
    )
    parser.add_argument(
        "--context", "-c", choices=["server", "client", "module"],
        default="module",
        help="Execution context for generated code (default: module)"
    )
    parser.add_argument(
        "--project", "-p", default=None,
        help="Generate a complete multi-file game project instead of a single script"
    )
    parser.add_argument(
        "--game-type", "-g",
        choices=["tycoon", "obby", "simulator", "rpg", "generic"],
        default="generic",
        help="Game genre for project generation (default: generic)"
    )
    parser.add_argument(
        "--output-dir", "-o", default="./generated-game",
        help="Output directory for project generation (default: ./generated-game)"
    )
    parser.add_argument(
        "--credits", action="store_true",
        help="Check remaining credits and exit"
    )
    parser.add_argument(
        "--version", action="version", version="rbxai v0.1.0"
    )

    args = parser.parse_args()

    # --credits mode: just check balance
    if args.credits:
        api_key = get_api_key(args)
        check_credits(api_key)
        return

    # --project mode: generate complete game project
    if args.project:
        api_key = get_api_key(args)
        generate_project(api_key, args.project, args.game_type, args.output_dir)
        return

    # Generate mode: need a query
    if not args.query:
        parser.print_help()
        sys.exit(1)

    api_key = get_api_key(args)
    generate_code(api_key, args.query, args.context)


if __name__ == "__main__":
    main()
