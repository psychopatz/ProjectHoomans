# Roadmap — Semantic Exhaustive Dialogue Quality Sweep

## Parent completion condition

The goal is complete when the Semantic Harness can generate a broad and progressively expanding set of **real production NPC sentences**, show the trigger/context behind every line in the simple sentence-review GUI, target meaningful unobserved response variants, flag/cluster awkward dialogue, and satisfy all real-worker acceptance gates without exposing testing-engine complexity as the primary UX.

The prior completion claim is revoked. Current accepted state is recorded in `PROGRESS.md`.

## P0 — Architecture / source audit — COMPLETE

Preserve the existing Semantic Test Subsystem, Lua worker, Observatory/Inspector and canonical content ownership.

No duplicate semantic engine or runner.

---

## P1 — Trustworthy sentence evidence — SUBSTANTIALLY COMPLETE

### Required

- current Inspector paths for persona/relationship/state;
- canonical trait option normalization;
- planned/reached surface identity;
- actual input identity;
- semantic/realization/phrase/source provenance;
- quality analyzer tolerant of real production value types;
- functional exact-turn Full Inspector replay.

### Remaining gate

Keep focused real-worker regression coverage for evidence projection and replay.

---

## P2 — Production surface discovery and balanced review planning — SUBSTANTIALLY COMPLETE

### Required

- production-discovered default surfaces;
- expected fallback probes excluded from normal review;
- baseline coverage for every selected surface;
- balanced parameterized cases across all selected surfaces;
- no early-surface starvation under case caps;
- truthful invalid-surface detection.

### Remaining gate

Maintain regression proving all selected surfaces receive meaningful parameterized cases under bounded review.

---

## P3 — Reliable generation / stop / resume — SUBSTANTIALLY COMPLETE

### Required

- bounded batches;
- responsive Stop;
- persisted completed rows;
- restart/resume without duplicates;
- compatible plan/catalog validation;
- live evidence visibility after completed batches.

### Remaining gate

Keep GUI and service tests proving stopped runs preserve usable sentence rows.

---

## P4 — Variant-guided sentence expansion — ACTIVE NEXT PHASE

This is now the main missing product capability.

### P4A — Full response registry

Enumerate all production pools/variants with complete pagination and fingerprints.

### P4B — Observed-variant ledger

For every real sentence row, identify the selected response variant when production evidence allows.

Maintain counts by:

- pool;
- variant;
- language;
- trigger/surface;
- representative context.

### P4C — Context-guided frontier search

For unobserved variants:

1. obtain production explain evidence;
2. inspect failed/eligible conditions;
3. map relevant conditions to approved sweep dimensions/buckets;
4. generate bounded candidate contexts;
5. execute through real Lua;
6. record whether the target becomes:
   - SELECTED;
   - ELIGIBLE_NOT_SELECTED;
   - TESTED_INELIGIBLE;
   - bounded unresolved.

Search must go beyond the current fixed neutral/friendly probes and must not silently ignore declared rival/family profiles.

### P4D — Feed reached variants into sentence review

Newly reached sentences must appear in the **same main sentence table**.

The user should not need to open a reachability dashboard to benefit from frontier exploration.

### Gate

The sentence-review run must demonstrate that frontier targeting increases unique observed production variants compared with baseline balanced coverage.

---

## P5 — Real dialogue-quality defect proof — ACTIVE AFTER P4

### P5A — Real family/intimacy defect class

Drive a real production/replay case that yields the relevant family/intimacy wording and prove supported vs unsupported contexts using actual semantic evidence.

Synthetic dictionaries remain unit tests only.

### P5B — Real perspective defect class

Produce or production-back an adversarial perspective output and prove the analyzer catches it while a valid perspective control passes.

### P5C — Real canonical-source cluster

Produce multiple real suspicious outputs that share one canonical phrase/source cause and verify clustering + targeted replay.

### P5D — Repetition and anti-repeat

Prove:

- run-level duplicate/repetition detection;
- actual history-sensitive response/phrase rotation or production penalty where alternatives exist.

### Gate

HARNESS_ACCEPTANCE quality demonstrations pass using real production-Lua or faithful production-backed replay cases.

---

## P6 — Sentence-first Quality Sweep GUI — SUBSTANTIALLY COMPLETE

### Default UX

Keep:

- Generate Sentences;
- Stop;
- Languages;
- Max examples;
- Reload Results;
- Advanced…;
- one sentence table;
- one selected-line explanation panel.

Do not restore smoke/full/pairwise/batch/coverage concepts as primary controls.

### Remaining work

- make variant-frontier enrichment transparent to the normal Generate Sentences action;
- finish direct canonical source navigation if existing Studio/source-lineage APIs permit it cleanly;
- keep advanced reachability/export actions non-blocking;
- preserve simple filter/search workflow.

### Gate

A user can review generated sentences without understanding planner/batch terminology.

---

## P7 — Truthful integrated acceptance — MANDATORY FINAL PHASE

### Required real demonstrations

- wellbeing across distinct contexts;
- identity/privacy;
- hostile/friendly contrast;
- supported and unsupported family/intimacy behavior;
- perspective defect + control;
- EN/TL;
- true anti-repeat behavior;
- same variant under distinct contexts;
- genuine `ELIGIBLE_NOT_SELECTED`;
- canonical defect cluster + targeted replay;
- invalid-surface detection;
- stop/resume without duplicates;
- full response registry pagination;
- variant-frontier expansion producing additional unique observed variants.

### Regression

Run all relevant sweep, GUI, Observatory, Semantic Test Subsystem and Lua semantic tests.

### Closeout rule

Only mark COMPLETE when real acceptance matches the claims in PROGRESS.md.

---

## Deferred / optional

- hosted LLM API integration;
- automated source rewriting without review;
- distributed sweep execution;
- languages beyond approved current scope;
- native PZ automation.
