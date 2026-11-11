---
handoff_schema: 2
checkpoint_mode: committed_handoff
target_repo: /home/psychopatz/Zomboid/Workshop/ProjectHoomans
branch: main
phase: Self-contained CodeBuilder recipe migration
chunk: source migration, compiler cleanup, runtime parity, and harness verification
retrieval_tier: COMPLETE
parent_status: COMPLETE
phase_commit: self
phase_commit_phase: Self-contained CodeBuilder recipe migration
phase_commit_message: refactor: make conversation recipes self-contained
phase_commit_vector: project-hoomans=self;psychopatz-core=10de3b1;dynamic-trading=45250e3e
state: CLEAN_CHECKPOINT
updated_at: 2026-11-12T00:00:00+08:00
---

# Unified Semantic Catalog Handoff

## Current state

PsychopatzCore is the sole semantic CodeBuilder authority. Conversation source
recipes use `psychopatz.semantic.shard.v3` and carry their own locale maps.
Phrase IDs and runtime translation keys are derived during compilation from
semantic template, style, and append-only slot order.

The Core authoring `translations/` directory and its catalog reader, generator,
contract, and hydration tests are removed. `conversation_bundles.json` carries
inline locale text and `conversation_bundle_catalog.py` writes the same
package-owned runtime bundle files under each mod's `common/media/translation`
tree. The DT external pack uses the same v3 Core schema.

The authoring service preserves its locale-facing editor view while writing
source shards directly. Dataset provenance is resolved from manifest profiles
in memory, so source recipes do not regain repeated metadata envelopes.

## Verification

- Core CodeBuilder tests: 80/80.
- Full PNC conversation suite: 48/48.
- Dynamic Trading smoke suite: 88/88.
- Real Core → PNC → DT build: 297 generated files, 505 phrase families, 56
  patterns, 13 UI definitions.
- Runtime EN/TL content and bundle wording parity verified against the
  pre-migration catalogs.
- Harness `--ping --no-gui` passes for `pnc`, `pnc-with-dthoomans`, and
  `dtabstract`.
- Source audit reports zero legacy identity fields and no authoring translation
  directory; only three expected preferred-size advisories remain.

Unrelated dirty work in all repositories remains preserved and unstaged. The
existing Tkinter observatory teardown finding is outside this phase.
