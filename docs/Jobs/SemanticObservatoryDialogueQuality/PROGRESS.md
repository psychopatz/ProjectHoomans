# Semantic Observatory & Dialogue Quality Harness — current progress

**Status: READY FOR USER LIVE TEST — P3C and all developer-side P7 gates pass.** P0/P1/P2/P4/P5/P6 remain accepted. P3B product behavior is preserved.

## Audited revisions

- ProjectHoomans baseline at this run: `95ccae5a61d2df422d4a38b54009ce6c9817c608` on `main`.
- PsychopatzCore baseline recorded by the job docs: `cf28189c57f7810f31d25c46c11eb88080f47baa`.
- No source-save mutation, native Project Zomboid launch, or Workshop operation occurred.

## Phase reconciliation

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Baseline/contracts | **COMPLETE** | Production source, registration, selection, translation, and no-write contracts remain accepted. |
| P1 — Runtime catalog | **COMPLETE** | Catalog/detail/provenance/CodeBuilder lineage remain accepted. |
| P2 — Explain/provenance | **COMPLETE** | Semantic identity and rendered phrase identity/style separation remain accepted. |
| P3 — Human surfaces | **COMPLETE (P3C)** | P3B startup/session parity is preserved; GUI test state is hermetic; Explore loading is local to Studio; waits and acceptance topology are condition-specific. |
| P4 — Grounded scenarios | **COMPLETE** | Leave Group and grounded EN/TL/authority coverage remain accepted. |
| P5 — Agent CLI | **COMPLETE** | Existing bounded headless services remain accepted. |
| P6 — Quality + phrase registry | **COMPLETE** | Canonical promotion, Dialogue Content Registry, and phrase identity split remain accepted. |
| P7 — Integrated acceptance | **COMPLETE (developer-side)** | Split Python, focused Xvfb, native Lua, installed-PZ Kahlua, CodeBuilder/content idempotence, data-safety, and diff checks pass. Only explicitly user-owned native SP/MP validation remains. |

## P3C acceptance evidence

- Shared `gui_test_support.py` constructs ordinary `SemanticHarnessApp` instances with temporary `--ui-state` and reset fixture intent, owns cleanup, and provides bounded worker/Explore/operation waits. No ordinary GUI test relies on the developer’s default state file.
- `test_p3c_test_isolation.py` poisons an isolated default-state home with a remembered SAVE target and proves the ordinary helper still starts in FIXTURE mode. It also proves automatic Explore loading leaves foreground `app.busy` false.
- Studio Explore uses the existing serialized `WorkerSession` through a background read-only lifecycle and reports local `Loading catalog…`; Simulation readiness and controls do not wait for catalog population. Search, paging bounds, lazy detail loading, and actionable catalog errors remain intact.
- P3B real-worker lifecycle coverage remains green: fresh startup has zero fake Response Channel buttons, native open rows match production IDs/labels/enabled state/frames, SAVE continuity survives worker restart and app recreation, invalid/reset/explicit-source precedence is safe, and the first bounded Explore page auto-loads.

## Measured normal topology

- Fixture worker-ready: **1.403s**; fixture through bounded Explore: **1.424s**.
- Remembered-SAVE worker-ready: **1.412s**; remembered-SAVE restoration: **3.744s**.
- Full headless Python: **630 discovered; 574 PASS, 56 GUI SKIP, 0 FAIL; 964.02s**.
- Focused Xvfb GUI Batch A: **65/65 PASS; 156.56s**. Batch B: **42/42 PASS; 89.43s**. Combined focused acceptance: **107/107 PASS; 245.99s** across two bounded interpreters.
- The prior exhaustive Xvfb-all-tests run exceeding 16 minutes remains diagnostic regression evidence and is not counted as acceptance.

## P7 re-acceptance evidence

- Full native Lua suite: **87/87 PASS**.
- Installed Project Zomboid Kahlua verifier: **3/3 PASS**, including the negative syntax case; no game launch or Lua execution.
- CodeBuilder / Dialogue Content / lineage idempotence set: **25/25 PASS**.
- Source/save data-safety set: **18/18 PASS**; real-save hashes remained unchanged.
- P3B focused lifecycle: **4/4 PASS; 15.99s** on the final rerun.
- `git diff --check`: PASS after the final documentation and code review.

## Retained product contracts

- Before native conversation open, visible Response Channel rows are empty with a clear `No conversation open` state; diagnostic suggestions remain Inspect/Debug data only.
- After native conversation open, visible rows and submitted frames come exclusively from `semantic.native_conversation_view.v1.responseChannel`.
- SAVE restoration persists only bounded source intent and identifiers, uses the existing read-only importer and immutable worker source snapshot, and falls back to fixture with one actionable warning when invalid.
- Explore requests one bounded production response-pool page after worker readiness; it does not dump the registry or eagerly fetch variants.

## Scope / stop rules

- Do not redesign the semantic architecture or introduce another save database, simulator, selector, worker, or persistence system.
- Do not mutate source saves, launch native Project Zomboid, publish Workshop content, or modify root `AGENTS.md`.
- The developer-side gate is complete. Only the explicitly user-owned native SP/MP validation remains.
