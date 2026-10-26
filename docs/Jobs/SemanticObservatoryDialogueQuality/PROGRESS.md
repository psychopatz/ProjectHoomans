# Semantic Observatory & Dialogue Quality Harness — current progress

**Status: IN PROGRESS — developer-side acceptance reopened by live Semantic Lab findings.** P0/P1/P2/P4/P5/P6 remain accepted. P3 and P7 are reopened for a bounded **P3B Startup & Session Parity** repair before the goal may return to `READY FOR USER LIVE TEST`.

## Audited revisions

- ProjectHoomans: `25fe2cb95eec238f264328cb478af819fc73285b` (`main` = `origin/main` before this documentation update).
- PsychopatzCore: `cf28189c57f7810f31d25c46c11eb88080f47baa`.
- The repository was clean at audit start.
- No source save mutation, native Project Zomboid launch, or Workshop operation occurred during the audit.

## Phase reconciliation

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Baseline/contracts | **COMPLETE** | Existing production source/registration/selection/translation contracts and no-write baselines remain accepted. |
| P1 — Runtime catalog | **COMPLETE** | Catalog/detail/provenance/CodeBuilder lineage remain accepted. |
| P2 — Explain/provenance | **COMPLETE** | Semantic identity, rendered phrase identity/style and provenance separation remain accepted. |
| P3 — Human surfaces | **REOPENED / IN PROGRESS** | Core Simulation/Studio consolidation exists, but live use exposed three developer-side startup/session defects: empty Explore until manual Search, diagnostic fixture suggestions shown as Response Channel before a production conversation is open, and remembered save/player/NPC selection not automatically restored as the active Simulation source after app restart. |
| P4 — Grounded scenarios | **COMPLETE** | P4A Leave Group and grounded EN/TL/authority coverage remain accepted. |
| P5 — Agent CLI | **COMPLETE** | Existing bounded headless services remain accepted. |
| P6 — Quality + phrase registry | **COMPLETE** | Canonical greeting promotion, Dialogue Content Registry and phrase identity split remain accepted; P3B must preserve them. |
| P7 — Integrated acceptance | **REOPENED / IN PROGRESS** | The prior 624-Python / 889-Lua pass was real but insufficient: it did not test first-run Response Channel parity, auto-populated Explore, or active saved-target restoration across Semantic Lab application restarts. |

## Reproduced live defects

### 1. Response Channel startup parity

Fresh fixture worker evidence:

- `conversationPresentation.schema = semantic.native_conversation_view.v1`;
- lifecycle state is `loaded`;
- native production `responseChannel.rows = 0` before conversation open.

However `worker_ready_controller.py` currently reads `capabilities.suggestions`, fabricates an accepted `{type="turn"}` response, and renders those diagnostic fixture suggestions as the visible Response Channel. That produces legacy/contextual buttons such as `Check in with them`, `How are you doing?`, `Follow me`, and `Go Home` before a conversation exists.

A real `CONVERSATION_OPEN` on the same worker produces only the production native root rows (currently Ask Name, Recruit, Goodbye, What's Up and Companion Orders for the audited fixture).

**This is a parity bug.** Diagnostic semantic suggestions may remain inspectable, but only native production `conversationPresentation.responseChannel` may drive the visible Response Channel.

### 2. Saved-target continuity

The UI-state file already persists:

- `saved_world_save_path`;
- `saved_world_player_id`;
- `saved_world_npc_id`.

But `initialize_app()` always starts `save_backed_mode = False` with the default fixture, and `worker_ready()` only auto-imports a saved pair when explicit CLI `--save --player --npc` arguments were supplied.

Therefore a normal app restart remembers the World Browser selection but does **not** restore that Player/NPC pair as the active Simulation source.

The core Lua-worker restart path itself is correct: after importing a real SAVE pair, `worker.restart()` re-imports the immutable source snapshot and preserves source kind, source ID and NPC. The missing behavior is **application-session restoration**, not worker-source persistence.

### 3. Studio Explore startup population

`SemanticObservatoryPane` intentionally starts with an empty response tree and status `Production Lua catalog · choose Search to inspect`. The real production catalog is already available, so requiring a manual Search to initialize Explore is unnecessary and makes the primary browser appear broken.

## Immediate Next Chunk — P3B Startup & Session Parity

Implement the contract in `SURFACE_CONSOLIDATION.md` under **P3B Startup & Session Parity**.

### P3B required changes

1. **Production-authoritative Response Channel**
   - On worker ready, do not render `capabilities.suggestions` as a fabricated accepted turn.
   - Before a native conversation is open, Response Channel is empty/disabled with a clear `No conversation open` state.
   - After `Open conversation`, visible rows come only from `semantic.native_conversation_view.v1.responseChannel`.
   - Generic semantic/context suggestion projections remain diagnostic/Inspect data only.
   - Clicking a visible Response Channel button must submit the exact native semantic frame/row it represents.

2. **Restore the last active save-backed target across app launches**
   - Persist an explicit active-source/session preference in addition to browser selection, e.g. `active_source_kind=SAVE` plus the existing save/player/NPC identifiers.
   - When the previous active source was SAVE, after worker readiness validate the remembered save/player/NPC and automatically call the existing read-only `import_saved_selection()`.
   - Show `Restoring saved target…` while doing so, then a clear SAVE banner with player/NPC/save identity.
   - If the save/pair is missing or invalid, remain safely in FIXTURE mode, clear/disable the stale active-source marker, and show one actionable warning.
   - `--reset-ui-state` must suppress restoration.
   - Explicit CLI `--save --player --npc` remains higher priority than remembered UI state.
   - A normal Lua `Restart worker` must continue restoring from the already-imported immutable source snapshot without rereading disk.

3. **Auto-populate Studio Explore**
   - When the production worker/catalog is ready, automatically request the first bounded response-pool page with an empty filter.
   - Search remains a filter/refetch action, not the initialization action.
   - Preserve bounds/paging and never eagerly dump all variant details.

4. **Lifecycle acceptance tests**
   - Fresh GUI startup: no fake Response Channel buttons before conversation open.
   - Production conversation open: visible Response Channel IDs exactly equal the native production presentation rows.
   - Fixture diagnostic suggestions remain available only in Inspect/Debug surfaces.
   - Load save/player/NPC → `worker.restart()` → same SAVE source/NPC remains active.
   - Load save/player/NPC → close Semantic Lab → recreate it using the same UI-state file → the same pair auto-restores as active Simulation source without manual World Browser reload.
   - Invalid/missing remembered save or actor falls back safely to FIXTURE with an explicit warning.
   - `--reset-ui-state` starts clean fixture mode.
   - Studio Explore contains bounded registered pools automatically after worker-ready without pressing Search.
   - Existing World Browser selection persistence, phrase registry, Studio Dialogue Content, Review, CLI and native Lua tests remain green.

## P7 re-acceptance gate

After P3B passes, rerun the integrated developer gate. At minimum:

- focused new P3B Tk/Xvfb lifecycle tests;
- existing surface consolidation + UI state persistence + operational World Browser tests;
- full Python semantic-harness suite fail-fast;
- full native Lua suite;
- changed-Lua Kahlua verification;
- CodeBuilder/dialogue-content idempotence;
- `git diff --check`.

Only then may `PROGRESS.md` return to **READY FOR USER LIVE TEST**.

## Scope / stop rules

- Do not redesign the semantic architecture, phrase registry, Studio ownership, or World Browser.
- Reuse existing `conversationPresentation`, `import_saved_selection`, source snapshot, UI-state and catalog services.
- Do not create a second persistence database or duplicate saved-NPC records.
- Remember identifiers/source intent, not a serialized mutable NPC copy.
- Do not automatically mutate or rewrite source saves.
- Do not launch native Project Zomboid or publish Workshop content.
- Do not modify root `AGENTS.md`.
- Continue automatically from P3B into P7 re-acceptance; a focused test passing is not the completion boundary.
