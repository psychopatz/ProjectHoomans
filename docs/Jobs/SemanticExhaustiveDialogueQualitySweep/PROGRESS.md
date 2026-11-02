# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS — REOPENED AFTER INDEPENDENT ACCEPTANCE AUDIT.**

The prior P7 completion claim is revoked. The implementation contains a substantial reusable foundation, but current production-backed acceptance is incomplete and several green tests do not prove the promised sweep behavior.

## Audited implementation baseline

- Audited ProjectHoomans implementation HEAD: `5af171b079b9652fd1b8c2ef64c18b5bfd07ccab`.
- At audit start, local `main` and `origin/main` both pointed to that revision.
- One pre-existing uncommitted README change promoted a dedicated Quality Sweep workbench; it matched the user's new direction and must be preserved.
- No native Project Zomboid, source-save mutation, or Workshop publication was performed by the audit.

## Independent regression evidence

Verified healthy foundations:

- new sweep test suite: **32/32 PASS**;
- production Lua semantic regression: **144/144 PASS**;
- focused Semantic Test Subsystem/parity set: **27/27 PASS**;
- Response Observatory tests: **30/30 PASS**;
- dedicated Quality Sweep Tk/Xvfb test file: **4/4 PASS**;
- `git diff --check`: clean for audited implementation.

These passes prove that the existing semantic foundation remains healthy. They do **not** prove full sweep acceptance.

## Phase reconciliation

| Phase | Current state | Audit finding |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE** | Original architecture/reuse direction remains valid. |
| P1 — Evidence + dimension inventory | **PARTIAL / REOPENED** | Schema exists, but real-worker evidence projection misses actual actor/persona/relationship/state paths; trait option objects are normalized incorrectly. |
| P2 — Buckets + planner | **PARTIAL / REOPENED** | Bucket/planner scaffolding exists, but interaction surfaces are hard-coded/stale and the full plan heavily exercises invalid root-choice fallbacks. |
| P3 — Batch/resume | **PARTIAL / REOPENED** | Batching/manifests exist, but cancel → resume is broken; cancelled batches are not resumed. |
| P4 — Reachability | **INCOMPLETE / REOPENED** | Production currently reports 234 response pools; analyzer reads only first 64 and does not perform the required bounded context-search frontier. |
| P5 — Quality flags/clusters | **PARTIAL / REOPENED** | Per-row heuristics exist, but cross-row duplicate/repetition detection is absent and real repeated fallback output can report 0 flagged rows. |
| P6 — CLI/review/UI | **PARTIAL / EXPANDED** | Basic CLI/service and a Simulation sub-tab exist. Required dedicated Quality Sweep workbench, full inspector resolver, source navigation, complete filtering, responsive background execution and reliable cancel/resume remain. |
| P7 — Integrated acceptance | **NOT ACCEPTED** | Several claimed demonstration scenarios are synthetic or weak assertions rather than true production-Lua end-to-end evidence. |

## Reproduced acceptance failures

### 1. Planned root-choice surfaces do not match live production choices

A real `open_conversation()` projection exposed choices including:

- `conversation.root:menu:ask_name`
- `conversation.root:menu:recruit`
- `conversation.root:menu:goodbye`
- `conversation.landing:whats_up`
- `companion.orders:open`

The planner instead hard-codes surfaces such as `wellbeing`, `orders`, `companion_status`, `trade`, `gift`, and `goodbye`.

A real 16-case smoke sweep completed with zero execution exceptions, yet several planned root-choice cases rendered:

`"I'm not sure what you mean."`

through `semantic.ask_clarification` rather than the intended semantic route.

A completed worker request is therefore not sufficient evidence that the planned surface was exercised.

### 2. Full-plan coverage is concentrated on stale root choices

For a 256-case full plan:

- 240 parameterized cases targeted root-choice surfaces;
- 0 parameterized cases targeted actual utterance surfaces;
- 221 total cases targeted `scenario.rootChoice:wellbeing`.

This can make a large green run mostly test clarification fallback instead of intended dialogue behavior.

### 3. Compact evidence loses the context needed for review

For a real `"how are you?"` turn, Conversation Inspector exposes actor relationship/personality/situation data under `personaChoices.actorConversationContext`, including approval/respect/familiarity/identity trust, personality, social style, traits, needs/activity and health state.

The current evidence row instead produced:

- empty personality;
- no social style;
- empty traits;
- empty needs/health/activity;
- approval/respect/familiarity/identityTrust as `None`.

The join paths must be corrected before quality judgments are trustworthy.

### 4. Trait option normalization is wrong

The production catalog exposes trait choices as option objects containing values such as `pnc_berserker`.

The current dimension extractor stringifies the complete option object instead of extracting its canonical value. Trait sweeps therefore do not have a trustworthy production option domain.

### 5. Reachability is incomplete

Production reports **234 response pools**. The current analyzer requests `response_pool_list(limit=64)` once and does not paginate, so it analyzes only the first 64 pools.

It also evaluates non-selected variants mainly against one baseline explanation instead of performing bounded context exploration aimed at reaching each registered variant.

### 6. Cancel → resume is broken

A directly reproduced cancellation produced:

- manifest state: `CANCELLED`;
- batch state: `CANCELLED`.

Calling run again did not resume work; the manifest remained `CANCELLED` with 0 completed cases.

### 7. Quality analysis is not yet run-level

A real smoke sweep produced repeated clarification text across multiple planned surfaces, but cluster generation returned 0 flagged rows and 0 clusters.

The current analyzer lacks the required cross-row duplicate/recent-repeat layer.

### 8. Lazy full trace is only a marker

Rows contain `traceHandle = {caseID, turnIndex, lazy=true}`, but the sweep service/UI has no resolver that replays or opens that handle in the existing Conversation Inspector.

### 9. P7 acceptance used synthetic evidence for key scenarios

Synthetic rows are valid unit tests for heuristic behavior. They are not sufficient acceptance for:

- unsupported-family defect detection;
- wrong-perspective detection;
- canonical source clustering;
- multi-context selection claims;
- anti-repeat behavior;
- hostile/friendly tone contrast.

Those demonstrations must be exercised through real production Lua and assert the claimed semantic difference.

## Immediate Next Chunk — P1/P2 contract repair

Repair the trustworthy production-backed inputs and evidence before expanding the GUI:

1. correct compact evidence projection using current Conversation Inspector structures, especially `personaChoices.actorConversationContext`, `socialContext`, observation and response trace;
2. prove real rows contain relationship, bond, personality, social style, traits, needs, health/activity and actor authority where production exposes them;
3. normalize production catalog option objects to canonical values/labels, especially trait multi-select options;
4. replace stale hard-coded root-choice assumptions with production-discovered interaction surfaces and stable adapters only where discovery is impossible;
5. add an **executed-surface verification** field/result so a case fails or is marked invalid when it falls into clarification/fallback instead of reaching the planned route;
6. add real-worker tests for current root choices and representative utterance surfaces;
7. update PROGRESS with exact results and continue automatically into P3–P7 remediation and the dedicated GUI workbench.

Do not begin broad GUI feature expansion until evidence and surface identity are trustworthy; the GUI must visualize reliable data rather than make incorrect coverage easier to inspect.

## Remaining mandatory work after Next Chunk

- correct full-bounded distribution across valid production surfaces;
- cancel/interruption resume state-machine repair;
- full response-pool pagination and bounded variant-reachability search;
- cross-row duplicate/repetition analysis;
- functioning lazy full-inspector resolver and canonical-source navigation;
- complete CLI filters;
- dedicated top-level Quality Sweep workbench in the Semantic Harness with responsive non-blocking execution;
- real production-Lua P7 demonstration matrix and full regression/performance closeout.

## Stop rules

Do not report the parent goal complete because:

- all existing 32 sweep tests pass;
- a manifest says COMPLETED;
- a large case count was executed;
- the dedicated GUI renders;
- synthetic quality rows trigger the expected flags;
- the first 64 response pools have a reachability report.

Completion requires every mandatory gate in ROADMAP.md and HARNESS_ACCEPTANCE.md to pass against current production-backed behavior.
