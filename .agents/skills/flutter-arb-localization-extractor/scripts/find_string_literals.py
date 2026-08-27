#!/usr/bin/env python3
"""
Scan a Flutter/Dart project for string literals that are candidates for
localization extraction.

This is a heuristic *aid*, not a full Dart parser. It gives Claude a
structured list of every string literal in the codebase, with a line of
surrounding context and a best-guess "skip_reason" for strings that are
almost certainly NOT user-facing UI text (asset paths, URLs, map/JSON keys,
log statements, already-localized strings, etc). Claude should still read
each remaining candidate in context before deciding to extract it -- the
skip_reason is a hint to speed up triage, not a verdict.

Usage:
    python3 find_string_literals.py <project_root_or_lib_dir> [--include-tests] [--json out.json]

Output: JSON array of candidates to stdout (or to --json file), each with:
    file, line, col, raw (literal exactly as written, including quotes),
    text (unescaped literal content), is_interpolated, enclosing_class,
    context_line, skip_reason (null if it looks like real UI text)
"""
import argparse
import json
import re
import sys
from pathlib import Path

SKIP_DIR_NAMES = {".dart_tool", "build", ".git", "ios", "android", "web", "windows", "linux", "macos"}
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart", ".config.dart", ".mocks.dart")

URL_RE = re.compile(r"^(https?://|www\.)", re.IGNORECASE)
ASSET_EXT_RE = re.compile(r"\.(png|jpe?g|gif|svg|webp|json|ttf|otf|mp3|mp4|wav|gltf|glb|lottie)$", re.IGNORECASE)
ASSET_PREFIX_RE = re.compile(r"^(assets?|images?|icons?|fonts?|lottie)/", re.IGNORECASE)
HEX_COLOR_RE = re.compile(r"^#?[0-9A-Fa-f]{6,8}$")
IDENTIFIER_RE = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_./\-]*$")
DATE_TOKEN_RE = re.compile(r"^[yMdHhmsaEGzZ\s:./,\-]+$")
LOG_CALL_RE = re.compile(r"\b(debugPrint|print|log|logger\.\w+|Logger\(|assert)\s*\(")
LOCALIZED_ALREADY_RE = re.compile(r"(AppLocalizations|\.l10n\b|S\.of\(context\)|\.tr\(\))")
CLASS_RE = re.compile(r"^\s*(?:abstract\s+)?class\s+(\w+)")


def iter_dart_files(root: Path, include_tests: bool):
    for path in root.rglob("*.dart"):
        if any(part in SKIP_DIR_NAMES for part in path.parts):
            continue
        if path.name.endswith(GENERATED_SUFFIXES):
            continue
        if "/l10n/" in path.as_posix() or "/gen_l10n/" in path.as_posix() or "/gen/" in path.as_posix():
            continue
        if not include_tests and ("/test/" in path.as_posix() or path.name.endswith("_test.dart")):
            continue
        yield path


def classify(text: str, context_line: str) -> str | None:
    stripped = text.strip()
    if stripped == "":
        return "empty string"
    if len(stripped) <= 1 and not stripped.isalpha():
        return "single char / symbol"
    if URL_RE.match(stripped):
        return "url"
    if ASSET_EXT_RE.search(stripped) or ASSET_PREFIX_RE.match(stripped):
        return "asset path"
    if HEX_COLOR_RE.match(stripped) and "Color(" in context_line:
        return "hex color"
    if LOG_CALL_RE.search(context_line):
        return "log/debug/assert statement"
    if "RegExp(" in context_line:
        return "regex pattern"
    if LOCALIZED_ALREADY_RE.search(context_line):
        return "already localized"
    if IDENTIFIER_RE.match(stripped) and " " not in stripped:
        if stripped.startswith("/") or "route" in context_line.lower():
            return "route name / identifier"
        if re.fullmatch(r"[A-Z0-9_]+", stripped):
            return "constant-like identifier (SCREAMING_CASE)"
        if any(k in context_line for k in ("fromJson", "toJson", "json[", "map[", "Map<String", "headers[", "queryParameters")):
            return "likely a data/JSON key, not UI text"
    if DATE_TOKEN_RE.match(stripped) and any(tok in stripped for tok in ("yyyy", "MM", "dd", "HH", "mm", "ss")):
        return "date format pattern"
    if "import '" in context_line or "export '" in context_line or "part '" in context_line:
        return "import/export/part directive"
    return None


def find_enclosing_class(lines, line_no):
    for i in range(line_no - 1, -1, -1):
        m = CLASS_RE.match(lines[i])
        if m:
            return m.group(1)
    return None


def scan_file(path: Path):
    try:
        content = path.read_text(encoding="utf-8")
    except Exception:
        return []
    lines = content.splitlines()
    candidates = []
    i = 0
    n = len(content)
    line_no = 1
    line_start = 0
    in_line_comment = False
    in_block_comment = False

    def current_col(idx):
        return idx - line_start + 1

    while i < n:
        ch = content[i]
        if ch == "\n":
            line_no += 1
            line_start = i + 1
            in_line_comment = False
            i += 1
            continue
        if in_line_comment:
            i += 1
            continue
        if in_block_comment:
            if content[i:i+2] == "*/":
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue
        if content[i:i+2] == "//":
            in_line_comment = True
            i += 2
            continue
        if content[i:i+2] == "/*":
            in_block_comment = True
            i += 2
            continue

        # Detect optional raw-string prefix 'r' immediately before a quote.
        is_raw = False
        quote_start = i
        if ch == "r" and i + 1 < n and content[i+1] in ("'", '"'):
            is_raw = True
            quote_start = i + 1
            ch = content[quote_start]

        if ch in ("'", '"'):
            quote_char = ch
            triple = content[quote_start:quote_start+3] == quote_char * 3
            q_len = 3 if triple else 1
            body_start = quote_start + q_len
            j = body_start
            closed = False
            while j < n:
                if not is_raw and content[j] == "\\":
                    j += 2
                    continue
                if content[j:j+q_len] == quote_char * q_len:
                    closed = True
                    break
                if content[j] == "\n" and not triple:
                    break  # unterminated single-line string; bail out
                j += 1
            if closed:
                raw_text = content[body_start:j]
                full_raw = content[quote_start:j+q_len]
                is_interp = ("$" in raw_text) and not is_raw
                start_line_no = content.count("\n", 0, quote_start) + 1
                candidates.append({
                    "line": start_line_no,
                    "col": current_col(quote_start),
                    "raw": full_raw,
                    "text": raw_text,
                    "is_interpolated": is_interp,
                })
                i = j + q_len
                line_no = content.count("\n", 0, i) + 1
                line_start = content.rfind("\n", 0, i) + 1
                continue
            else:
                i = quote_start + 1
                continue
        i += 1

    results = []
    for c in candidates:
        idx = c["line"] - 1
        context_line = lines[idx] if 0 <= idx < len(lines) else ""
        skip_reason = classify(c["text"], context_line)
        enclosing_class = find_enclosing_class(lines, c["line"])
        results.append({
            "file": str(path),
            "line": c["line"],
            "col": c["col"],
            "raw": c["raw"],
            "text": c["text"],
            "is_interpolated": c["is_interpolated"],
            "enclosing_class": enclosing_class,
            "context_line": context_line.strip(),
            "skip_reason": skip_reason,
        })
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", help="Project root or lib/ directory to scan")
    parser.add_argument("--include-tests", action="store_true", help="Include test/ files and *_test.dart")
    parser.add_argument("--json", help="Write JSON output to this file instead of stdout")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.exists():
        print(f"Path does not exist: {root}", file=sys.stderr)
        sys.exit(1)

    all_results = []
    for f in sorted(iter_dart_files(root, args.include_tests)):
        all_results.extend(scan_file(f))

    keep = [r for r in all_results if r["skip_reason"] is None]
    skipped = [r for r in all_results if r["skip_reason"] is not None]

    output = {
        "summary": {
            "total_literals_found": len(all_results),
            "likely_ui_text_candidates": len(keep),
            "auto_skipped": len(skipped),
        },
        "candidates": keep,
        "skipped": skipped,
    }

    text = json.dumps(output, indent=2, ensure_ascii=False)
    if args.json:
        Path(args.json).write_text(text, encoding="utf-8")
        print(f"Wrote {len(all_results)} literals ({len(keep)} candidates, {len(skipped)} auto-skipped) to {args.json}", file=sys.stderr)
    else:
        print(text)


if __name__ == "__main__":
    main()