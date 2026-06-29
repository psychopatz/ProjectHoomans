---
name: file-token-bloat-detector
description: >
  Detect bloated source files that exceed a token threshold using a local
  ChatGPT 5.4-compatible tokenizer (no API calls). Use this before refactoring
  to identify files that should be split/decoupled.
argument-hint: "path to file or directory (e.g. Contents/mods/DynamicTradingV2)"
---

# File Token Bloat Detector

Finds files exceeding token budgets to identify decoupling candidates.

## Tokenizer

- Target: ChatGPT 5.4 tokenizer
- Implementation: local `tiktoken` with `o200k_base`
- API usage: none

## Quick Start

```bash
TOOL="python3 .github/skills/file-token-bloat-detector/scripts/file_token_bloat_scan.py"

# Scan a mod and flag files over 2000 tokens
$TOOL Contents/mods/DynamicTradingV2 --threshold 2000

# JSON output for automation
$TOOL Contents/ --threshold 2000 --json

# Include all file extensions and show all results
$TOOL Contents/ --all-files --top 0
```

## Usage Notes

1. Exit code `1` means one or more files exceeded threshold.
2. Exit code `0` means no file exceeded threshold.
3. Exit code `2` means setup/input error.
4. Defaults exclude generated/irrelevant paths (`Manuals`, `WhatsNew`, `.git`, `node_modules`, etc.).
