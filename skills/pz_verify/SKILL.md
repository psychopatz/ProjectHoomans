---
name: pz_verify
description: >
  Swiss-army-knife debugger for Project Zomboid mod Lua files.
  Detects: hardcoded UI strings (i18n), Kahlua2/Lua-5.1 incompatibilities,
  and files exceeding a token threshold (default 2000).
  Supports whole-mod, sub-directory, or single-file scan modes.
  Mod-agnostic: works on DynamicTrading, DynamicColonies, ZedColonies, or any PZ mod.
  Use in place of pz-kahlua-lint (more robust, customizable, atomic).
argument-hint: "--mod-dir <path>  OR  --dir <sub-path>  OR  --file <file.lua>"
---

# pz_verify

Unified PZ mod verifier: i18n + Kahlua + token-bloat, all configurable.

## Entry Point

```
.agent/skills/pz_verify/scripts/pz_verify.py
```

## Usage

```bash
TOOL="python3 .agent/skills/pz_verify/scripts/pz_verify.py"

# Full wide scan (all checks, default settings)
$TOOL --mod-dir <mod-root>

# Narrow: specific sub-directory
$TOOL --dir <mod-root>/42.16/media/lua/client/DT/UI

# Single file
$TOOL --file path/to/MyFile.lua

# Kahlua only, errors only, no snippets
$TOOL --mod-dir <mod-root> --kahlua --severity ERROR --no-snippets

# Token check with custom threshold
$TOOL --mod-dir <mod-root> --tokens --token-threshold 1500

# Save to file
$TOOL --mod-dir <mod-root> --output /tmp/report.txt
```

## All Flags

| Flag | Default | Description |
|---|---|---|
| `--mod-dir PATH` | — | Wide scan (mod root) |
| `--dir PATH` | — | Narrow scan (sub-directory) |
| `--file PATH` | — | Single-file scan |
| `--i18n` | *(all)* | Run only i18n check |
| `--kahlua` | *(all)* | Run only Kahlua check |
| `--tokens` | *(all)* | Run only token-bloat check |
| `--token-threshold N` | `2000` | Token limit before flagging |
| `--chars-per-token N` | `4` | Chars-per-token approximation |
| `--severity LEVEL` | `WARNING` | Min severity: ERROR/WARNING/INFO |
| `--top N` | `10` | Rows in TOP FILES tables |
| `--no-snippets` | off | Omit code snippets (saves tokens) |
| `--snippet-max N` | `80` | Max chars per snippet |
| `--exclude FOLDERS` | `Manuals,Debug` | Comma-separated folders to skip |
| `--output FILE` | stdout | Write report to file |

## Module Structure

```
scripts/
  pz_verify.py              ← CLI only (arg parse + dispatch)
  checker/
    config.py               ← RunOpts dataclass + ALL constants
    token_counter.py        ← Zero-dep token estimator
    path_filter.py          ← File discovery + exclusion
    runner.py               ← Orchestrator (register new checks here)
    reporting.py            ← Assembles section output
    checks/                 ← One plugin per check type
      i18n_check.py
      kahlua_check.py
      token_check.py
    i18n/
      key_collector.py      ← Harvest translation keys
      string_scanner.py     ← Detect hardcoded UI strings
    kahlua/
      rules.py              ← All KAHL-E*/KAHL-W* rules
      kahlua_scanner.py     ← Apply rules per-line
    sections/               ← One formatter per report section
      summary_section.py
      i18n_section.py
      kahlua_section.py
      token_section.py
```

> **Add a new check**: create `checks/my_check.py` + `sections/my_section.py`, register in `runner.py`.  
> **Add a new Kahlua rule**: append to `KAHLUA_RULES` in `kahlua/rules.py`.  
> **Change any trigger/pattern**: edit `config.py` only.

## Auto-Excluded (default)

| Excluded | Reason |
|---|---|
| `Manuals/` folders | In-game docs, not UI code |
| `Debug/` folders | Debug-only scripts |
| `print(`, `Log(`, `error(` lines | Not user-facing |
| `require "…"`, `getTexture(…)` | Technical identifiers |
| PascalCase / camelCase / snake_case identifiers | Internal keys |
| Lines using `getText(` / `T("KEY"` | Already translated |
