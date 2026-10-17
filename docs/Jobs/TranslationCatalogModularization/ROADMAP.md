# Translation Catalog Modularization — ordered roadmap

**State: PLANNED.** Progress gates are unaccepted in this job. Scope is the **custom translation loader and Conversation custom catalog** only; authored conversation data and native PZ Translate domains remain independent.

## Phase 0 — inventory and exact compatibility baseline (ACTIVE)
0A (Next Chunk): Select exact current integration SHAs for Hoomans (including pending semantic branch additions) and Core; enumerate registered systems, every EN/TL `Conversation.json` key, placeholders, lookup consumers, existing 15 systems, segment map and Trading registration inconsistency. Run existing Core/Hoomans translation smoke + Semantic Lab EN/TL identity and wellbeing before changes; capture diagnostic and value snapshot. Identify any current broken lookup (including Trading) with actual evidence.
0B: Decide the minimal new optional Core manifest API; write failing focused Core tests for one shard, duplicates, missing localized shard, old single-file fallback, manifest path security, lazy caching and language change. Commit contract; no migration of live Conversation yet.

**Gate:** Exact before snapshot and reproducible tests; public API ownership stable and tests proving intended failure written. If Core/Hoomans checkout unavailable, mark runtime gate open, not passed.

## Phase 1 — optional Core multi-file reader
Implement and test finite manifest-driven shards with deterministic ownership, path guards, caching, per-key English fallback, warnings and coverage parity. Legacy `registerSystem` users behave identically.

**Gate:** Core real Lua smoke results, no existing Core catalog regression, bounded memory/time, checked Core SHA and reviewed cross-repo publication.

## Phase 2 — Project Hoomans minimal pilot
Integrate optional registration via Hoomans bootstrap and migrate one low-risk Conversation family using an **explicit** source-mode switch. Preserve old public lookup/keys, old fallback and rollback; use the real Semantic Lab and actual EN/TL localization.

**Gate:** same production response key and exact EN/TL text before/after; translation traces show selected shard; no silent duplicate or missing key.

## Phase 3 — migration of complete Conversation custom catalog
Migrate remaining families in small shards according to audited ownership. Recompute exact latest key count; reject missing/duplicate EN/TL keys and placeholder drift. Delete obsolete source only after verified source-of-truth cutover and integration agreement.

**Gate:** 100% EN/TL parity for expected keys, stable existing public lookups and actual response variants through real worker. All stale keys/consumers identified.

## Phase 4 — easier future additions and tooling
Provide a small manifest/schema validator, key-ownership/duplicate finder, localized placeholder auditor and Semantic Lab bundle diagnostics. New dialogue module adds one bundle plus registration, no monolith edits. Keep versioned manifest stable.

**Gate:** add a sample translation variant in its correct folder, register, test through production Lua without central JSON changes or unintended new high-volume cache costs.

## Phase 5 — native Build 42 and multi-language acceptance
Controlled live PZ conversation window + player/NPC EN/TL, language switching/restart, fallback, missing bundle/audit warnings, packaged reader behavior; SP/MP presentation and any applicable dedicated server initialization.

**Gate:** record exact SHAs/game build, real native evidence and performance. Once all mandatory gates passed, maintenance-ready.

## Progress discipline
Each iteration updates this job's `PROGRESS.md` with one Next Chunk, actual tests, exact revisions and native evidence; do not auto-advance on JSON syntax checks alone.
