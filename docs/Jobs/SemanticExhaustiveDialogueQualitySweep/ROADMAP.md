# Roadmap — Semantic Exhaustive Dialogue Quality Sweep

## Parent completion condition

The developer-side goal is complete only when Project Hoomans can systematically plan and execute bounded production-Lua dialogue-quality sweeps across the declared semantic context space, explain each rendered sentence with triggering parameters and provenance, identify/cluster likely quality defects for efficient LLM/human review, expose the workflow through CLI and existing Simulation UI, rerun affected cases after edits, and pass all acceptance/performance/regression gates.

## P0 — Source audit and contract freeze — COMPLETE (planning)

### Objective

Ground the job in the current completed Semantic Test Subsystem and Observatory rather than designing from historical assumptions.

### Accepted planning evidence

- existing deterministic matrix expansion and 64-case fixture safety cap verified;
- Observatory production-worker quality matrix verified;
- conversation fuzz distinguished from response-quality sweep;
- worker control/persona catalogs verified as dimension sources;
- persona/turn inspectors verified to expose response/realization/family/bond/source evidence;
- current missing orchestration capabilities documented in AUDIT.md.

P0 planning acceptance does not imply any new runtime capability exists.

---

## P1 — Sweep evidence contract and production-backed dimension inventory

### P1A — Compact evidence row

Implement a versioned compact per-rendered-sentence evidence schema and serializer using existing Observatory/Inspector outputs.

Required:

- deterministic case/sweep identity;
- parameter vector;
- semantic/response/realization/phrase identity;
- final text;
- bounded persona/relationship/state summary;
- selection/source fingerprints;
- authority/effect summary;
- quality flag slots;
- lazy full-trace lookup/replay handle.

### P1B — Dimension discovery

Build a production-backed sweep dimension inventory from worker simulation/persona controls plus narrowly justified explicit adapters.

Required:

- enum/boolean/numeric/multi-select normalization;
- scenario path ownership;
- read-only and prerequisite handling;
- stable production source metadata;
- explicit unsupported-control diagnostics.

### Gate

HARNESS_ACCEPTANCE B + F representative evidence passes through real worker projection.

---

## P2 — Semantic buckets and deterministic coverage planner

### P2A — Bucket policies

Implement bounded semantic bucket policies for numeric dimensions.

Prefer actual production thresholds when available. Include provenance and threshold-neighbor behavior where meaningful.

### P2B — Coverage strategies

Implement deterministic:

- smoke;
- boundary;
- pairwise;
- persona/relationship;
- full-bounded union/deduplication.

Planner must estimate case count/batches before execution, enforce configured scope/caps and produce stable case IDs/order.

### Gate

HARNESS_ACCEPTANCE C + D pass, including pairwise coverage proof and deterministic rerun.

---

## P3 — Bounded batch execution, artifacts and resume

### P3A — Batch executor

Compose planned cases into existing safe batches, normally <=64, and run them through the canonical Semantic Test/Lua worker execution path.

### P3B — Manifest and resume

Add versioned sweep manifest/artifact management outside watched media and saves.

Required:

- planned/completed/failed/incomplete batches;
- repository/Core/catalog fingerprints;
- safe resume;
- stale fingerprint rejection;
- cancellation/interruption safety;
- compact JSONL storage;
- no giant committed snapshots.

### Gate

HARNESS_ACCEPTANCE E + L batch/storage portions pass.

---

## P4 — Selection provenance and variant reachability frontier

### P4A — Evidence/provenance join

Ensure every executed output row joins the deepest currently available production evidence without rebuilding selector logic in Python.

### P4B — Variant reachability

Enumerate registered pools/variants and classify tested state:

- untested;
- tested-ineligible;
- eligible-not-selected;
- selected;
- selected-under-suspicious/rare context.

Use bounded context exploration guided by production explain/coverage traces.

### Gate

HARNESS_ACCEPTANCE F + G pass. No finite matrix result may overclaim global unreachability.

---

## P5 — Dialogue quality analyzer and canonical-source clustering

### P5A — Deterministic quality flags

Implement bounded flags from QUALITY_RUBRIC.md with confidence classes and negative controls.

Mandatory initial classes include:

- fragment/one-word/empty;
- placeholder/translation leak;
- duplicate/repeat;
- unsupported relationship/family;
- perspective suspicion;
- identity/private-term misuse where evidence allows;
- generic acknowledgement suspicion.

### P5B — Clustering

Group defects by canonical semantic/phrase/source cause and quality signature.

Clusters include representative examples, context ranges, affected case IDs and verified source/UNKNOWN.

### P5C — Known defect-class proof

Demonstrate that a family-class one-word/intimacy defect can be surfaced with family/bond/semantic provenance and distinguished from legitimate supported family wording.

### Gate

HARNESS_ACCEPTANCE H + I pass.

---

## P6 — Agent CLI, review bundles, targeted replay and Simulation UI

### P6A — CLI/JSONL

Expose planner/run/resume/status/report/filter operations through the existing Semantic Harness CLI/service architecture.

Support bounded filters by:

- severity/flag;
- pool/template/variant/phrase;
- source owner;
- strategy/batch/case;
- selected reachability state.

### P6B — LLM review bundles and affected replay

Generate compact cluster bundles suitable for an LLM and support replaying selected/affected case IDs after content changes.

### P6C — Simulation Quality Sweep surface

Add the human UI to existing Simulation only:

- scope + coverage strategy;
- plan estimate;
- run/cancel/resume status;
- results/cluster filters;
- compact evidence;
- full Inspector link;
- verified source navigation;
- targeted replay.

No duplicate Studio Test Lab/Coverage runner.

### Gate

HARNESS_ACCEPTANCE J + K pass with CLI/GUI service parity and hermetic GUI tests.

---

## P7 — Integrated performance, regression and developer closeout

### P7A — Scale/performance characterization

Measure planning, batch throughput, compact row size, artifact growth, worker/runtime overhead and lazy trace cost for representative large sweeps.

Optimize only from measured bottlenecks. Preserve correctness and boundedness.

### P7B — End-to-end quality workflow

Demonstrate:

plan → run batches → identify/cluster suspicious dialogue → inspect canonical cause → make or preview an authorized text-only correction if appropriate → targeted affected replay → broader regression.

The workflow must prove non-text semantic/authority invariants remain unchanged for text-only fixes.

### P7C — Full developer acceptance

Run all relevant new/focused tests plus current repository regression requirements described by HARNESS_ACCEPTANCE.md.

Update docs to current truth. Mark parent goal developer-complete only when every mandatory gate passes or only explicitly user-owned native acceptance remains.

### Gate

HARNESS_ACCEPTANCE L + M and all earlier gates pass.

---

## Deferred/optional after parent completion

These are not required to declare the parent goal complete unless promoted by the user:

- external hosted LLM API integration;
- automated source rewriting without explicit review;
- statistical language-model perplexity scoring;
- multilingual languages beyond currently supported scope;
- CI farm/distributed sweep execution;
- exhaustive native SP/MP automation.
