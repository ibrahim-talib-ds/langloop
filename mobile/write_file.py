#!/usr/bin/env python3
"""
LangLoop file writer.
Usage:   python write_file.py <path/to/file>
Then paste content and press Ctrl+D on a new line.
"""
import sys
import os
from pathlib import Path

if len(sys.argv) != 2:
    print("Usage: python write_file.py <path>")
    sys.exit(1)

target = Path(sys.argv[1])
target.parent.mkdir(parents=True, exist_ok=True)

print(f"→ Writing to: {target}")
print("→ Paste file content below. Press Ctrl+D when done:\n")

content = sys.stdin.read()

target.write_text(content)
size = target.stat().st_size
print(f"\n✓ Saved {target} ({size} bytes, {content.count(chr(10))} lines)")
