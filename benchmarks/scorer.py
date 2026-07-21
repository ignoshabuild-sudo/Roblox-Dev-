#!/usr/bin/env python3
"""
Benchmark Scorer — Roblox AI Code Assistant

Evaluates AI-generated Luau code against ground-truth scripts across
three dimensions: syntax accuracy, semantic accuracy, and structural accuracy.

Usage:
    python scorer.py --all                          # Run all categories
    python scorer.py --category remoteevents        # Run one category
    python scorer.py --endpoint http://host:8000 --all
    python scorer.py --all --output results/report.csv
"""

import argparse
import csv
import json
import os
import re
import sys
import time
import yaml
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

import requests


# ── Data Classes ──────────────────────────────────────────────────────────────

@dataclass
class TestCase:
    """A single benchmark test case loaded from YAML."""
    id: str
    category: str
    context_type: str          # "server" | "client" | "module"
    prompt: str
    ground_truth_path: str     # relative filename of the .luau ground truth
    expected_apis: list[str] = field(default_factory=list)
    expected_patterns: list[str] = field(default_factory=list)

    @classmethod
    def from_yaml(cls, path: Path) -> "TestCase":
        with open(path, "r") as f:
            data = yaml.safe_load(f)
        return cls(
            id=data["id"],
            category=data["category"],
            context_type=data.get("context_type", "module"),
            prompt=data["prompt"],
            ground_truth_path=data["ground_truth"],
            expected_apis=data.get("expected_apis", []),
            expected_patterns=data.get("expected_patterns", []),
        )


@dataclass
class ScoreResult:
    """Result of scoring one generated script against ground truth."""
    test_id: str
    category: str
    syntax_score: float        # 0.0 or 1.0 (binary)
    semantic_score: float      # 0.0–1.0
    structural_score: float    # 0.0–1.0
    composite_score: float     # weighted composite
    passed: bool               # composite >= threshold
    is_uncertain: bool         # model returned "I don't know"
    generation_time_ms: float
    retrieval_time_ms: float
    generated_code: str
    errors: list[str] = field(default_factory=list)


@dataclass
class SuiteReport:
    """Aggregate report for the full benchmark suite."""
    timestamp: str
    total_tests: int
    passed: int
    failed: int
    syntax_pass_rate: float
    avg_composite: float
    avg_generation_ms: float
    avg_retrieval_ms: float
    uncertain_count: int
    uncertain_rate: float
    results: list[ScoreResult] = field(default_factory=list)
    suite_passed: bool = False


# ── Configuration ─────────────────────────────────────────────────────────────

def load_config(config_path: Path = None) -> dict:
    """Load benchmark configuration from config.yaml."""
    if config_path is None:
        config_path = Path(__file__).parent / "config.yaml"
    with open(config_path, "r") as f:
        return yaml.safe_load(f)


# ── Syntax Scoring ────────────────────────────────────────────────────────────

# Patterns that indicate syntax errors in Luau
SYNTAX_ERROR_PATTERNS = [
    (r'=\s*=\s*=', "double equals assignment"),           # a == b outside condition
    (r'[\w\]]\s*=\s*[\w\[]', None),                       # valid assignment (not an error)
]

SANDBOX_BLACKLIST = re.compile(
    r'\b(loadstring|getfenv|setfenv|getsenv|newcclosure|hookfunction|'
    r'checkcaller|__namecall|__index)\b'
)

# Basic structural balance checks
BALANCE_CHECKS = [
    (r'\bfunction\b', r'\bend\b', "function/end"),
    (r'\bdo\b', r'\bend\b', "do/end"),  # approximate (end shared)
    (r'\(', r'\)', "parentheses"),
    (r'\[', r'\]', "brackets"),
    (r'\{', r'\}', "braces"),
]


def score_syntax(code: str, blacklist: re.Pattern = SANDBOX_BLACKLIST) -> tuple[float, list[str]]:
    """
    Evaluate syntax accuracy of generated Luau code.

    Returns (score, errors) where score is 1.0 (pass) or 0.0 (fail).
    A fail means the code contains sandbox-escaping patterns or obvious
    structural imbalance.
    """
    errors = []

    # 1. Blacklist check: no sandbox-escaping functions
    blacklist_matches = blacklist.findall(code)
    if blacklist_matches:
        errors.append(f"sandbox-escaping patterns found: {blacklist_matches}")
        return 0.0, errors

    # 2. String termination: no unterminated strings
    # Count unescaped quotes roughly
    single_quotes = len(re.findall(r"(?<!\\)'", code))
    double_quotes = len(re.findall(r'(?<!\\)"', code))
    if single_quotes % 2 != 0:
        errors.append("unterminated single-quoted string")
    if double_quotes % 2 != 0:
        errors.append("unterminated double-quoted string")

    # 3. Multi-line comment balance --[[ and ]]
    open_comments = len(re.findall(r'--\[\[', code))
    close_comments = len(re.findall(r'\]\]', code))
    if open_comments != close_comments:
        errors.append("unbalanced multi-line comments")

    # 4. Parentheses balance
    parens = code.count('(') - code.count(')')
    if parens != 0:
        errors.append(f"unbalanced parentheses (diff: {parens})")

    # 5. Basic structure: must have at least some code
    stripped = code.strip()
    if len(stripped) < 10:
        errors.append("code too short (likely empty or error response)")
        return 0.0, errors

    # 6. Check for "I don't know" / uncertain responses
    if re.search(r'(?i)(I don\'?t know|I am unsure|cannot generate|uncertain)', stripped[:200]):
        errors.append("model expressed uncertainty")
        return 0.0, errors  # Not a syntax error per se, but treated as failure at this level

    if errors:
        return 0.0, errors

    return 1.0, []


# ── Semantic Scoring ──────────────────────────────────────────────────────────

def score_semantic(code: str, expected_apis: list[str]) -> tuple[float, list[str]]:
    """
    Evaluate semantic accuracy: does the generated code use the correct APIs?

    Returns (score, errors) where score is the fraction of expected APIs found.
    """
    if not expected_apis:
        return 1.0, []  # No expected APIs to check against — skip

    found = []
    missing = []
    code_lower = code.lower()

    for api in expected_apis:
        # Check for the API token as a word boundary match
        pattern = re.compile(r'\b' + re.escape(api) + r'\b', re.IGNORECASE)
        if pattern.search(code):
            found.append(api)
        else:
            missing.append(api)

    score = len(found) / len(expected_apis) if expected_apis else 1.0
    errors = [f"missing API: {m}" for m in missing]

    return score, errors


# ── Structural Scoring ────────────────────────────────────────────────────────

# Structural patterns associated with each expected_pattern key
# Each pattern is a regex that should appear in well-formed code
STRUCTURAL_PATTERNS = {
    "fire-to-server": [
        (r'OnServerEvent|FireServer', "fire-to-server pattern (OnServerEvent or FireServer)"),
        (r':Connect\s*\(', "Connect callback"),
    ],
    "fire-to-client": [
        (r':FireClient\s*\(|OnClientEvent', "fire-to-client pattern (FireClient or OnClientEvent)"),
    ],
    "fire-all-clients": [
        (r':FireAllClients\s*\(', "FireAllClients call"),
    ],
    "invoke-server": [
        (r'OnServerInvoke', "server invoke handler"),
    ],
    "invoke-client": [
        (r':InvokeClient\s*\(', "InvokeClient call"),
    ],
    "datastore-get": [
        (r':GetAsync\s*\(', "GetAsync call"),
        (r'pcall\s*\(', "pcall wrapper"),
    ],
    "datastore-set": [
        (r':SetAsync\s*\(', "SetAsync call"),
        (r'pcall\s*\(', "pcall wrapper"),
    ],
    "tween-create": [
        (r'TweenInfo\.new\s*\(', "TweenInfo.new call"),
        (r':Create\s*\(', "TweenService:Create"),
        (r':Play\s*\(', "Play call"),
    ],
    "module-return": [
        (r'\breturn\b', "return statement"),
    ],
    "module-require": [
        (r'\brequire\s*\(', "require call"),
    ],
    "player-added": [
        (r'PlayerAdded', "PlayerAdded event"),
        (r':Connect\s*\(', "Connect callback"),
    ],
    "player-removing": [
        (r'PlayerRemoving', "PlayerRemoving event"),
    ],
    "input-began": [
        (r'InputBegan', "InputBegan event"),
        (r':Connect\s*\(', "Connect callback"),
    ],
    "heartbeat": [
        (r'Heartbeat', "Heartbeat event"),
        (r':Connect\s*\(', "Connect callback"),
    ],
    "render-stepped": [
        (r'RenderStepped', "RenderStepped event"),
        (r':Connect\s*\(', "Connect callback"),
    ],
    "get-service": [
        (r':GetService\s*\(', "GetService call"),
    ],
    "process-receipt": [
        (r'ProcessReceipt', "ProcessReceipt callback"),
    ],
    "http-get": [
        (r':GetAsync\s*\(', "HttpService GetAsync"),
    ],
    "http-post": [
        (r':PostAsync\s*\(', "HttpService PostAsync"),
    ],
    "path-create": [
        (r'CreatePath\s*\(', "CreatePath call"),
        (r':ComputeAsync\s*\(', "ComputeAsync call"),
    ],
    "bind-action": [
        (r'BindAction\s*\(', "BindAction call"),
    ],
    "unbind-action": [
        (r'UnbindAction\s*\(', "UnbindAction call"),
    ],
    "proximity-triggered": [
        (r'ProximityPrompt', "ProximityPrompt reference"),
        (r'Triggered', "Triggered event"),
    ],
    "debris-add": [
        (r':AddItem\s*\(', "Debris AddItem"),
    ],
    "raycast": [
        (r':Raycast\s*\(', "Raycast call"),
    ],
}


def score_structural(code: str, expected_patterns: list[str]) -> tuple[float, list[str]]:
    """
    Evaluate structural accuracy: does the code follow expected patterns?

    Returns (score, errors) where score is the fraction of expected pattern
    sub-patterns that are found.
    """
    if not expected_patterns:
        return 1.0, []

    total_checks = 0
    passed_checks = 0
    errors = []

    for pattern_key in expected_patterns:
        sub_patterns = STRUCTURAL_PATTERNS.get(pattern_key, [])
        if not sub_patterns:
            continue  # Unknown pattern key — skip

        for regex, description in sub_patterns:
            total_checks += 1
            if re.search(regex, code, re.IGNORECASE):
                passed_checks += 1
            else:
                errors.append(f"structural: missing '{description}' ({pattern_key})")

    if total_checks == 0:
        return 1.0, []

    score = passed_checks / total_checks
    return score, errors


# ── API Integration ──────────────────────────────────────────────────────────

def call_generate(
    prompt: str,
    context_type: str,
    base_url: str,
    generate_path: str = "/generate",
    timeout: int = 15,
    top_k: int = 5,
) -> dict:
    """
    Call the /generate endpoint and return the response JSON.

    Raises requests.RequestException on failure.
    """
    url = f"{base_url.rstrip('/')}{generate_path}"

    payload = {
        "query": prompt,
        "context_type": context_type,
        "top_k": top_k,
    }

    response = requests.post(
        url,
        json=payload,
        timeout=timeout,
        headers={"Content-Type": "application/json"},
    )
    response.raise_for_status()
    return response.json()


# ── Runner ────────────────────────────────────────────────────────────────────

def load_test_cases(benchmarks_dir: Path, category: Optional[str] = None) -> list[tuple[TestCase, Path, str]]:
    """
    Discover and load all test cases from test-cases/ directories.

    Returns list of (TestCase, ground_truth_path, category_dir_name) tuples.
    """
    test_cases_dir = benchmarks_dir / "test-cases"
    ground_truth_dir = benchmarks_dir / "ground-truth"
    cases = []

    for cat_dir in sorted(test_cases_dir.iterdir()):
        if not cat_dir.is_dir():
            continue
        if category and cat_dir.name != f"{category}":
            # Match against the numbered name (e.g., "01-remoteevents")
            if not cat_dir.name.endswith(f"-{category}"):
                continue

        yaml_files = sorted(cat_dir.glob("*.yaml"))
        for yf in yaml_files:
            tc = TestCase.from_yaml(yf)
            gt_path = ground_truth_dir / cat_dir.name / tc.ground_truth_path
            cases.append((tc, gt_path, cat_dir.name))

    return cases


def run_benchmark(
    benchmarks_dir: Path,
    config: dict,
    category: Optional[str] = None,
    dry_run: bool = False,
) -> SuiteReport:
    """
    Run the full benchmark suite.

    Args:
        benchmarks_dir: Path to the benchmarks/ directory
        config: Configuration dict from config.yaml
        category: Optional category filter (e.g., "remoteevents")
        dry_run: If True, skip API calls and score ground-truth against itself

    Returns:
        SuiteReport with aggregate results
    """
    api_cfg = config["api"]
    scoring_cfg = config["scoring"]
    thresholds = config["thresholds"]
    blacklist = re.compile(r'\b(' + '|'.join(config.get("sandbox_blacklist", [])) + r')\b')

    cases = load_test_cases(benchmarks_dir, category)

    if not cases:
        print(f"No test cases found. Category filter: {category or 'none'}")
        return SuiteReport(
            timestamp=datetime.now().isoformat(),
            total_tests=0, passed=0, failed=0,
            syntax_pass_rate=0.0, avg_composite=0.0,
            avg_generation_ms=0.0, avg_retrieval_ms=0.0,
            uncertain_count=0, uncertain_rate=0.0,
        )

    results: list[ScoreResult] = []
    syntax_weight = scoring_cfg["syntax_weight"]
    semantic_weight = scoring_cfg["semantic_weight"]
    structural_weight = scoring_cfg["structural_weight"]
    composite_threshold = thresholds["composite_pass"]

    for tc, gt_path, cat_name in cases:
        print(f"  [{tc.id}] ", end="", flush=True)

        errors_all = []

        # Generate code via API (or dry-run: use ground truth directly)
        if dry_run:
            # For dry run, read ground truth and score it — should be 1.0
            if gt_path.exists():
                generated_code = gt_path.read_text(encoding="utf-8")
            else:
                generated_code = "-- placeholder: ground truth not yet written"
            gen_time_ms = 0.0
            ret_time_ms = 0.0
            is_uncertain = False
        else:
            try:
                resp = call_generate(
                    prompt=tc.prompt,
                    context_type=tc.context_type,
                    base_url=api_cfg["base_url"],
                    generate_path=api_cfg["generate_path"],
                    timeout=api_cfg["timeout_seconds"],
                )
                generated_code = resp.get("code", "")
                gen_time_ms = resp.get("generation_time_ms", 0.0)
                ret_time_ms = resp.get("retrieval_time_ms", 0.0)
                is_uncertain = resp.get("is_uncertain", False)
            except requests.RequestException as e:
                generated_code = ""
                gen_time_ms = 0.0
                ret_time_ms = 0.0
                is_uncertain = False
                errors_all.append(f"API error: {e}")

        # Score
        syntax, syn_errs = score_syntax(generated_code, blacklist)
        errors_all.extend(syn_errs)

        semantic, sem_errs = score_semantic(generated_code, tc.expected_apis)
        errors_all.extend(sem_errs)

        structural, struct_errs = score_structural(generated_code, tc.expected_patterns)
        errors_all.extend(struct_errs)

        composite = (syntax * syntax_weight
                     + semantic * semantic_weight
                     + structural * structural_weight)
        composite = round(composite, 4)
        passed = composite >= composite_threshold and not is_uncertain

        result = ScoreResult(
            test_id=tc.id,
            category=cat_name,
            syntax_score=syntax,
            semantic_score=round(semantic, 4),
            structural_score=round(structural, 4),
            composite_score=composite,
            passed=passed,
            is_uncertain=is_uncertain,
            generation_time_ms=gen_time_ms,
            retrieval_time_ms=ret_time_ms,
            generated_code=generated_code,
            errors=errors_all,
        )
        results.append(result)

        status = "✓" if passed else "✗"
        print(f"{status} composite={composite:.2f} syn={syntax:.0f} sem={semantic:.2f} struct={structural:.2f}")

    # Build report
    total = len(results)
    passed_count = sum(1 for r in results if r.passed)
    failed_count = total - passed_count
    syntax_pass = sum(r.syntax_score for r in results) / total if total else 0
    avg_comp = sum(r.composite_score for r in results) / total if total else 0
    avg_gen = sum(r.generation_time_ms for r in results) / total if total else 0
    avg_ret = sum(r.retrieval_time_ms for r in results) / total if total else 0
    uncertain = sum(1 for r in results if r.is_uncertain)
    unc_rate = uncertain / total if total else 0
    suite_passed = (passed_count / total >= thresholds["suite_pass_rate"]) if total else False

    return SuiteReport(
        timestamp=datetime.now().isoformat(),
        total_tests=total,
        passed=passed_count,
        failed=failed_count,
        syntax_pass_rate=round(syntax_pass, 4),
        avg_composite=round(avg_comp, 4),
        avg_generation_ms=round(avg_gen, 2),
        avg_retrieval_ms=round(avg_ret, 2),
        uncertain_count=uncertain,
        uncertain_rate=round(unc_rate, 4),
        results=results,
        suite_passed=suite_passed,
    )


# ── CLI ───────────────────────────────────────────────────────────────────────

def print_report(report: SuiteReport):
    """Print a human-readable benchmark report."""
    print()
    print("=" * 65)
    print("  BENCHMARK SUITE REPORT")
    print("=" * 65)
    print(f"  Timestamp:         {report.timestamp}")
    print(f"  Tests run:         {report.total_tests}")
    print(f"  Passed:            {report.passed}")
    print(f"  Failed:            {report.failed}")
    print(f"  Suite passed:      {'✓ YES' if report.suite_passed else '✗ NO'}")
    print("-" * 65)
    print(f"  Syntax pass rate:  {report.syntax_pass_rate:.2%}")
    print(f"  Avg composite:     {report.avg_composite:.4f}")
    print(f"  Avg generation:    {report.avg_generation_ms:.0f}ms")
    print(f"  Avg retrieval:     {report.avg_retrieval_ms:.0f}ms")
    print(f"  Uncertain rate:    {report.uncertain_rate:.2%} ({report.uncertain_count}/{report.total_tests})")
    print("=" * 65)

    if report.failed > 0:
        print("\n  FAILURES:")
        for r in report.results:
            if not r.passed:
                print(f"    [{r.test_id}] composite={r.composite_score:.2f}")
                for err in r.errors:
                    print(f"      - {err}")
    print()


def save_csv(report: SuiteReport, output_path: Path):
    """Save benchmark results to CSV."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "test_id", "category", "passed", "composite",
            "syntax", "semantic", "structural",
            "generation_ms", "retrieval_ms", "is_uncertain", "errors"
        ])
        for r in report.results:
            writer.writerow([
                r.test_id, r.category, r.passed, r.composite_score,
                r.syntax_score, r.semantic_score, r.structural_score,
                r.generation_time_ms, r.retrieval_time_ms,
                r.is_uncertain, "; ".join(r.errors),
            ])


def save_json_report(report: SuiteReport, output_path: Path):
    """Save full report as JSON including generated code."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "timestamp": report.timestamp,
        "suite_passed": report.suite_passed,
        "total": report.total_tests,
        "passed": report.passed,
        "failed": report.failed,
        "syntax_pass_rate": report.syntax_pass_rate,
        "avg_composite": report.avg_composite,
        "avg_generation_ms": report.avg_generation_ms,
        "avg_retrieval_ms": report.avg_retrieval_ms,
        "uncertain_count": report.uncertain_count,
        "uncertain_rate": report.uncertain_rate,
        "results": [
            {
                "test_id": r.test_id,
                "category": r.category,
                "passed": r.passed,
                "composite": r.composite_score,
                "syntax": r.syntax_score,
                "semantic": r.semantic_score,
                "structural": r.structural_score,
                "generation_ms": r.generation_time_ms,
                "retrieval_ms": r.retrieval_time_ms,
                "is_uncertain": r.is_uncertain,
                "errors": r.errors,
                "generated_code": r.generated_code,
            }
            for r in report.results
        ],
    }
    with open(output_path, "w") as f:
        json.dump(data, f, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description="Roblox AI Code Assistant — Benchmark Scorer"
    )
    parser.add_argument(
        "--all", action="store_true",
        help="Run all test categories"
    )
    parser.add_argument(
        "--category", type=str, default=None,
        help="Run a specific category (e.g., 'remoteevents')"
    )
    parser.add_argument(
        "--endpoint", type=str, default=None,
        help="Override API base URL (default: from config.yaml)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Score ground-truth scripts against themselves (no API calls)"
    )
    parser.add_argument(
        "--output", type=str, default=None,
        help="Save CSV report to path (relative to benchmarks/)"
    )
    parser.add_argument(
        "--json", type=str, default=None,
        help="Save full JSON report to path"
    )
    args = parser.parse_args()

    if not args.all and not args.category:
        parser.error("Must specify --all or --category <name>")

    benchmarks_dir = Path(__file__).parent.resolve()
    config = load_config()

    # Override API endpoint if provided
    if args.endpoint:
        config["api"]["base_url"] = args.endpoint

    print(f"API endpoint: {config['api']['base_url']}")
    print(f"Mode: {'dry-run (no API)' if args.dry_run else 'live'}")
    print()

    report = run_benchmark(
        benchmarks_dir=benchmarks_dir,
        config=config,
        category=args.category,
        dry_run=args.dry_run,
    )

    print_report(report)

    # Save outputs
    if args.output:
        out_path = benchmarks_dir / args.output
        save_csv(report, out_path)
        print(f"CSV saved to {out_path}")

    if args.json or config.get("output", {}).get("save_json"):
        json_path = args.json or (benchmarks_dir / "results" / f"report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json")
        json_path = Path(json_path)
        if not json_path.is_absolute():
            json_path = benchmarks_dir / json_path
        save_json_report(report, json_path)
        print(f"JSON saved to {json_path}")

    # Exit code
    sys.exit(0 if report.suite_passed else 1)


if __name__ == "__main__":
    main()
