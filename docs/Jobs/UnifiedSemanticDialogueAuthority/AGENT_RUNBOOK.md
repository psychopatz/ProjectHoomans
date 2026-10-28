# Agent Runbook — Unified Semantic Dialogue Authority

Use this only when actively implementing the current P11 roadmap.

## Read order

Read root `AGENTS.md`, then:

1. `README.md`;
2. `ARCHITECTURE.md`;
3. this runbook;
4. `ROADMAP.md`;
5. `PROGRESS.md` last.

Completed phase/characterization history is not part of the normal bootstrap.
Use Git history only when investigating a specific regression.

## Source and generation discipline

Canonical authoring lives in modular Conversation source shards and CodeBuilder.

Generated Lua, generated translations, manifests, indexes, fingerprints and
snapshots are downstream artifacts.

Always:

1. edit CodeBuilder/canonical source/tests;
2. regenerate;
3. inspect generated diff;
4. run focused validation;
5. prove deterministic second generation;
6. commit the coherent source+generated result.

Never hand-fix generated output as a parallel implementation.

## Locale discipline

EN is the required fallback locale.

All other locales are data-driven. CodeBuilder must discover them from
translation maps/directories/manifests rather than branch on TL or any other
named locale.

Legacy `en`/`tl` source fields may be read only through the centralized
backward-compatibility adapter while their owning domains migrate. New source
schema should use generic `translations` maps.

Adding a new locale must not require Python/Lua whitelist changes.

## P11B domain migration

Migrate one coherent domain at a time.

For each domain:

- inventory real callers and parameter placeholders;
- preserve existing tests as contracts;
- migrate callers directly to canonical Conversation content;
- preserve EN fallback and optional-locale placeholder parity;
- regenerate through CodeBuilder;
- run domain-focused tests;
- run full native Lua before accepting the slice;
- remove superseded keys only after production caller search is zero.

Do not create a broad runtime-key alias table.

## Git discipline

Use existing `main` unless the user explicitly selects another branch.

Before editing, inspect status and upstream state.

Do not:

- reset/rebase/stash/discard uncertain work;
- push without explicit authorization;
- publish Workshop content;
- mutate source saves;
- launch native Project Zomboid;
- edit root `AGENTS.md` with goal progress.

Commit coherent validated slices locally.

## Validation

Minimum for source/compiler changes:

- `git diff --check`;
- relevant focused Python tests;
- relevant focused Lua tests;
- full `python3 tests/run_tests.py --jobs 4` when runtime/generated behavior
  changes;
- two-pass CodeBuilder idempotence;
- Kahlua/static verification when the verifier is available.

Do not weaken tests or inflate timeouts to hide a regression.

## Continuous execution

A subphase passing is not permission to invent new work.

When authorized for unattended execution, continue only through the mandatory
P11 phases documented in `ROADMAP.md`.

Stop for repository ownership conflicts, a real public compatibility boundary,
missing required tooling with no accepted fallback, or a proven architecture
decision requiring the user.

No P12/new mandatory phase without explicit user approval.
