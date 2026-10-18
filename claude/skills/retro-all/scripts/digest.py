#!/usr/bin/env python3
"""Shrink Claude Code session logs into one small text digest per session.

Usage: digest.py OUT_DIR [--days N] [--batch-kb N] [--projects DIR]

Writes OUT_DIR/<session-id>.txt per main session (subagent logs skipped) and
prints one tab-separated line per digest: batch, path, project, date, title, bytes.
Batches fill up to --batch-kb so each one fits a single reader.
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

PROMPT_CHARS = 400
CALL_CHARS = 160
ERROR_CHARS = 200
NOISE = re.compile(r"<(system-reminder|task-notification)>.*?</\1>", re.S)
KEY_INPUTS = ("command", "file_path", "pattern", "path", "url", "query", "skill", "description", "prompt")


def clip(text, n):
    text = " ".join(str(text).split())
    return text if len(text) <= n else text[: n - 1] + "…"


def call_summary(block):
    inp = block.get("input") or {}
    for key in KEY_INPUTS:
        if key in inp:
            return f"{block.get('name')}: {clip(inp[key], CALL_CHARS)}"
    return str(block.get("name"))


def result_text(block):
    content = block.get("content")
    if isinstance(content, list):
        content = " ".join(c.get("text", "") for c in content if isinstance(c, dict))
    return content or ""


def digest(path):
    title, project, first_ts, lines = None, None, None, []
    for raw in path.open(errors="replace"):
        try:
            rec = json.loads(raw)
        except ValueError:
            continue
        kind = rec.get("type")
        if kind == "custom-title":
            title = rec.get("customTitle")
        if kind not in ("user", "assistant"):
            continue
        project = project or rec.get("cwd")
        first_ts = first_ts or rec.get("timestamp")
        content = (rec.get("message") or {}).get("content")
        if kind == "user" and rec.get("isMeta"):
            continue
        if isinstance(content, str):
            content = [{"type": "text", "text": content}]
        for block in content or []:
            if not isinstance(block, dict):
                continue
            btype = block.get("type")
            if kind == "user" and btype == "text":
                text = NOISE.sub("", block.get("text", "")).strip()
                if text:
                    lines.append(f"USER: {clip(text, PROMPT_CHARS)}")
            elif kind == "user" and btype == "tool_result" and block.get("is_error"):
                lines.append(f"  ERROR: {clip(result_text(block), ERROR_CHARS)}")
            elif kind == "assistant" and btype == "tool_use":
                lines.append(f"  CALL {call_summary(block)}")
    if not lines:
        return None
    header = f"SESSION {path.stem}\nPROJECT {project}\nDATE {first_ts}\nTITLE {title}\n"
    return header + "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out_dir")
    ap.add_argument("--days", type=int, default=0, help="only sessions modified in the last N days (0 = all)")
    ap.add_argument("--batch-kb", type=int, default=400)
    ap.add_argument("--projects", default=os.path.expanduser("~/.claude/projects"))
    args = ap.parse_args()

    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    cutoff = time.time() - args.days * 86400 if args.days else 0
    batch, batch_bytes = 1, 0
    for path in sorted(Path(args.projects).glob("*/*.jsonl")):
        if path.stat().st_mtime < cutoff:
            continue
        text = digest(path)
        if text is None:
            continue
        target = out / f"{path.stem}.txt"
        target.write_text(text)
        if batch_bytes and batch_bytes + len(text) > args.batch_kb * 1024:
            batch, batch_bytes = batch + 1, 0
        batch_bytes += len(text)
        head = text.splitlines()
        print(f"{batch}\t{target}\t{head[1][8:]}\t{head[2][5:15]}\t{head[3][6:]}\t{len(text)}")


if __name__ == "__main__":
    sys.exit(main())
