# Phase 0 Baseline — 2026-11-11

This is the preservation boundary for the Core Semantic Harness migration. Existing dirty entries are pre-existing work unless explicitly claimed by a later phase. Do not use broad staging or cleanup commands.

| Repository | HEAD | Branch | Dirty entries | Tracked/staged | Untracked | Worktrees |
|---|---|---:|---:|---:|---:|---:|
| ProjectHoomans | `dbc55f0a034c721c77ac20d4b18501fd993dcdec` | `main` | 73 | 61 | 12 | 3 |
| psychopatzCore | `67631fa1d4c6d011986c3cd0cbdb9ee1cbb83fc7` | `main` | 30 | 11 | 19 | 1 |
| DynamicTrading | `f12910ba64387e252cc885dba83d9adfec79a453` | `main` | 8 | 7 | 1 | 2 |

## Harness inventory

Counts exclude `.venv` and Python cache files.

| Repository | Harness files | CodeBuilder files | Lua files |
|---|---:|---:|---:|
| ProjectHoomans | 679 | 152 | 96 |
| psychopatzCore | 68 | 13 | 12 |
| DynamicTrading | 5 | 0 | 3 |

## Current ownership facts

- Project Hoomans still contains the executable Semantic Lab, its package metadata, launcher, UI, CodeBuilder, tests, fixtures, and PNC-specific worker modules.
- Core contains the partial provider-neutral worker/protocol/profile foundation and a partial CodeBuilder foundation, but no complete package/entrypoint.
- Dynamic Trading contains DT provider descriptors and Lua adapters under the harness namespace.
- The target is a single Core harness plus explicit provider packages outside that namespace.

## Baseline evidence

This baseline was collected from exact Git and filesystem reads at the start of the active goal. Existing focused test results from the preceding audit remain recorded in the conversation summary; the post-cutover matrix is not yet verified.
