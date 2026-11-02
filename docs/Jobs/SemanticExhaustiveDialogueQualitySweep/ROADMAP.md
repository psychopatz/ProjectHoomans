# Roadmap — Semantic Exhaustive Dialogue Quality Sweep

## Parent completion condition

The developer-side goal is complete only when the Semantic Harness can discover the current production semantic interaction/response space, plan bounded but truthful coverage across it, execute production Lua in resumable batches, prove each case reached the intended semantic surface, expose complete compact context/provenance for every rendered NPC line, identify and cluster quality failures, browse all registered response pools/variants, and provide both CLI and a dedicated Quality Sweep workbench for inspection/replay.

The prior P7 completion claim was revoked by the independent post-implementation audit at `5af171b0`. Existing code is preserved as foundation; the reopened phases below close verified acceptance gaps.

## P0 — Source audit and architecture freeze — COMPLETE

Preserve:

- Semantic Test Subsystem as fixture/execution foundation;
- LuaSemanticWorker as production semantic authority;
- Response Observatory + Conversation Inspector as observability authority;
- production Simulation/persona catalogs as context sources;
- CodeBuilder/Dialogue Content as canonical authoring/source ownership.

No second semantic selector, runner, registry or authoring database.

---

## P1 — Evidence and dimension inventory — REOPENED

### P1A — Correct production evidence join

Repair compact evidence extraction against the **current** Conversation Inspector schema.

Required evidence, when exposed by production:

- actor IDs/roles/authority;
- personal relationship approval/respect/familiarity/identity trust/state;
- durable bond kind/class;
- NPC personality dimensions and social style;
- canonical traits;
- current needs, health state and activity/behavior;
- semantic frame, response template/variant, realization family/variant, phrase/translation identity;
- source/selection provenance;
- effects/authority.

Do not silently return empty structures when the inspector exposes the corresponding value.

### P1B — Catalog option normalization

Normalize enum/multi-select production options correctly.

Option objects such as `{value, label}` must preserve the canonical `value` while optionally carrying the label separately. Never stringify the whole object into the sweep domain.

### P1C — Functional lazy trace handle

A compact row's trace handle must resolve through a service into the existing full Conversation Inspector by replaying/locating the exact case/turn under compatible fingerprints.

### Gate

HARNESS_ACCEPTANCE B + F pass with real-worker assertions for populated relationship/persona/state evidence and functional inspector resolution.

---

## P2 — Production surface discovery and truthful coverage planner — REOPENED

### P2A — Discover interaction surfaces

Build the sweep surface inventory from current production-backed conversation/choice/semantic contracts.

At minimum distinguish:

- current root/landing/menu choices;
- typed/utterance semantic surfaces;
- active-flow/generated affordance surfaces where safely discoverable;
- explicit source-backed adapters for interaction classes that cannot be enumerated generically.

Hard-coded names may exist only as verified stable adapters and must fail loudly when production no longer exposes them.

### P2B — Executed-surface verification

Every case records both:

- planned surface;
- observed/reached semantic route.

If the case falls into clarification/fallback or a different route unexpectedly, mark it `INVALID_SURFACE` / failed coverage rather than counting it as successful exercise of the planned surface.

Expected clarification cases may be explicitly declared and remain valid.

### P2C — Coverage strategies

Repair smoke, boundary, pairwise, persona/relationship and full-bounded planning so meaningful parameterized cases are distributed across **valid current surfaces**.

Full-bounded coverage must report:

- planned surfaces;
- reached surfaces;
- invalid/missing surfaces;
- covered dimensions/buckets;
- pairwise gaps;
- truncation/caps;
- language coverage.

### Gate

HARNESS_ACCEPTANCE C + D pass against live-discovered surfaces. A large case count with stale/fallback-only routes does not pass.

---

## P3 — Batch, cancellation and resume correctness — REOPENED

### P3A — Resume state machine

Support safe continuation after:

- user cancellation;
- process interruption;
- partially completed batch;
- individual case failures.

A cancelled batch must become resumable without duplicating already accepted evidence rows.

### P3B — Manifest compatibility

Resume validates:

- catalog fingerprint;
- plan digest;
- sweep schema/planner version;
- relevant repository/Core/source fingerprints.

Do not resume into a different plan merely because the catalog fingerprint matches.

### P3C — Case-level accounting

Manifest/report must distinguish:

- completed valid;
- completed but invalid surface;
- failed execution;
- cancelled/incomplete;
- skipped by explicit constraint.

### Gate

HARNESS_ACCEPTANCE E passes, including directly tested cancel → resume and partial-batch recovery.

---

## P4 — Complete response-pool inventory and reachability frontier — REOPENED

### P4A — Paginate all registered pools

Enumerate every response pool and variant through bounded pagination until production reports `hasMore=false`.

Reports must state:

- production total;
- enumerated total;
- pagination completeness;
- skipped/error pools.

### P4B — Context-guided bounded reachability

For registered variants not observed in executed rows, use production `explain_response_selection` evidence and approved dimension buckets to search bounded candidate contexts.

Classify:

- UNTESTED;
- TESTED_INELIGIBLE;
- ELIGIBLE_NOT_SELECTED;
- SELECTED;
- SELECTED_UNDER_SUSPICIOUS_CONTEXT.

Never reconstruct semantic eligibility in Python and never claim global impossibility from finite search.

### P4C — Coverage frontier

Expose pools/variants with insufficient context exploration so an agent/user can request additional targeted cases.

### Gate

HARNESS_ACCEPTANCE G passes across the full paginated production registry.

---

## P5 — Run-level dialogue quality analysis and clustering — REOPENED

### P5A — Per-row rules

Preserve/fix existing high-confidence rules for fragments, placeholders, relationship/family misuse, identity/privacy and perspective suspicion.

### P5B — Cross-row rules

Add run-level analysis for:

- exact duplicate rendered text across semantically distinct cases;
- repeated recent response;
- variant IDs that collapse to identical wording;
- excessive generic acknowledgement concentration;
- repeated fallback/clarification output across intended non-clarification surfaces.

### P5C — Real defect proof

The family/intimacy and wrong-perspective classes must be demonstrated from production-Lua executions or a production-backed replay fixture that actually drives the relevant semantic response. Synthetic dictionaries remain unit controls only.

### Gate

HARNESS_ACCEPTANCE H + I pass with positive and negative controls and at least one real canonical-source cluster.

---

## P6 — Agent CLI, replay and dedicated Semantic Harness Quality Sweep GUI — REOPENED / EXPANDED

### P6A — CLI completeness

Support plan/run/resume/status/report/reachability/bundle/replay plus filters for:

- severity and flag;
- pool/template/variant/phrase;
- canonical source owner;
- strategy/batch/case;
- language;
- planned/reached surface;
- reachability state.

### P6B — Replay and inspector/source navigation services

Service layer must provide:

- selected case replay;
- cluster affected-case replay;
- lazy full Conversation Inspector resolution;
- canonical source locate/open metadata when verified;
- bounded export/review bundles.

GUI and CLI consume these same services.

### P6C — Dedicated Quality Sweep workbench

Create a **dedicated top-level Quality Sweep workspace inside the existing Semantic Harness**.

This replaces the current cramped Simulation-only ownership for broad sweep work.

Simulation remains the live/single-scenario workbench. Studio remains authoring. The dedicated Quality Sweep workspace owns broad batch coverage/review UX.

Required workbench capabilities are specified in `GUI_WORKBENCH.md`.

The existing Simulation Quality Sweep sub-tab may be migrated into the dedicated workspace or reduced to a compact launcher/status entry. Do not maintain two full implementations.

### P6D — Responsive execution

Long sweeps must not block the Tk event loop.

Use a safe background execution/queue pattern with Tk updates marshaled to the UI thread. Cancel must remain clickable and resume must work after cancellation.

### Gate

HARNESS_ACCEPTANCE J + K pass with hermetic GUI tests plus a real worker-backed plan/run/report/inspect/replay smoke.

---

## P7 — Integrated performance, regression and truthful developer closeout — REOPENED

### P7A — Real demonstration matrix

All required demonstrations must execute through production Lua.

Synthetic rows may validate heuristic unit behavior but cannot satisfy end-to-end acceptance.

Assertions must prove the claimed difference, for example:

- hostile and friendly results actually differ in the intended tone/selection evidence;
- anti-repeat actually changes/penalizes recent selection when alternatives exist;
- same variant is actually selected under multiple distinct parameter vectors;
- eligible-but-dominated is actually `ELIGIBLE_NOT_SELECTED`, not merely ineligible.

### P7B — Scale/performance

Measure:

- planning;
- surface discovery;
- pool pagination;
- cases/sec;
- worker startup/reuse;
- bytes/row and artifact growth;
- run-level quality analysis;
- lazy inspector resolution;
- GUI responsiveness/progress update overhead.

### P7C — Full regression

Run all gates in HARNESS_ACCEPTANCE.md, including existing Semantic Test/Observatory/Lua regressions and Kahlua/CodeBuilder checks when relevant.

### Gate

Only after all reopened P1–P7 gates pass may PROGRESS return to developer-complete.

---

## Deferred / optional after parent completion

- hosted/cloud LLM integration;
- automatic source rewriting without review;
- languages beyond approved current scope;
- distributed/CI farm sweep execution;
- native SP/MP automation beyond user-owned acceptance.
