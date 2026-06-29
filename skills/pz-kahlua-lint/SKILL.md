---
name: pz-kahlua-lint
description: >
  Project Zomboid Kahlua Lua linter and compatibility checker. Use when
  verifying PZ mod .lua files for Kahlua2 (Lua 5.1) compatibility. Detects
  goto, continue, table.pack, table.unpack, bitwise operators, floor division,
  sandboxed libraries (os, io, coroutine, debug, package, require), and other
  PZ-invalid Lua patterns. Also scans PZ base-game API for future-proofing.
argument-hint: "path to .lua file or mod directory (e.g. Contents/mods/MyMod)"
---

# PZ Kahlua Lint

Validates `.lua` files against Kahlua2 (Lua 5.1 subset, sandboxed stdlib).

## When to Use

- Before pushing mod updates to Workshop
- When a PZ mod silently fails with no error message
- After editing NPC / trading / colony / objective scripts
- To audit all mods at once or compare against a new PZ version

## Quick Start

```bash
TOOL="python3 .github/skills/pz-kahlua-lint/scripts/pz_kahlua_lint.py"

# Lint (errors only, with stats)
$TOOL lint Contents/ --severity=ERROR --stats

# Lint with quality checks disabled (KAHL-Q*)
$TOOL lint Contents/ --no-quality

# List all rules with descriptions
$TOOL lint --list-rules

# Scan PZ base-game Lua and save API manifest
$TOOL api-scan

# Compare mod against manifest (unknown events)
$TOOL api-diff Contents/

# Diff two manifests across PZ updates
$TOOL api-scan --diff-prev
```

For full options: `$TOOL <subcommand> --help`  
For rule details: `.github/skills/pz-kahlua-lint/references/kahlua-rules.md`

## Procedure

1. Run `lint` — pipe output to the user; highlight `ERROR` lines.
2. For unknown-event warnings, run `api-diff` — show unrecognised `Events.*` names.
3. After a PZ update, run `api-scan --diff-prev` — show what changed in the base-game API.
4. Do NOT manually edit generated files in `*/Manuals/*` or `*/WhatsNew/*` — they are excluded by default.
5. Code-quality checks (KAHL-Q*) are enabled by default; use `--no-quality` when you only want compatibility checks.
