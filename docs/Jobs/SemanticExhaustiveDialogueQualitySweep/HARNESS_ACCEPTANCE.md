# Acceptance — Semantic Exhaustive Dialogue Quality Sweep

The prior developer-complete claim is revoked. Passing unit scaffolding is not enough: required behavior must be proven through the current production Lua worker, current Inspector contracts and the dedicated Quality Sweep workflow.

## A. Baseline and reuse

- Record exact ProjectHoomans/Core revisions and relevant catalog/registry fingerprints.
- Existing Semantic Test Subsystem, Observatory, Conversation Inspector and production Lua remain authoritative.
- No second semantic selector/runner/registry is introduced.
- Existing focused regressions remain green.

## B. Dimension and surface discovery

- Editable dimensions come from current worker catalogs or narrowly justified source-backed adapters.
- Object options preserve canonical values; trait multi-select options use real production trait IDs.
- Read-only derived controls are never mutated.
- Prerequisites are enforced.
- Current root/landing/menu interaction surfaces are discovered from production projection rather than assumed from stale strings.
- Planner reports missing/unsupported surfaces explicitly.

## C. Evidence projection correctness

For real-worker representative turns, compact rows expose, when production provides them:

- planned and reached surface;
- relationship approval/respect/familiarity/identity trust/state;
- durable bond kind/class;
- personality dimensions and social style;
- traits;
- needs, health/activity/behavior;
- actor authority/roles;
- semantic/response/realization/phrase/translation identity;
- final text/fallback;
- selection/source provenance;
- effects/action/authority.

A value present in current Conversation Inspector may not silently become empty/None in compact evidence without an explicit reason.

Trace handles must be functionally resolvable into the existing full Inspector.

## D. Semantic bucket and planning correctness

- Numeric buckets are bounded and reproducible.
- Production thresholds and provenance are recorded where available.
- Smoke covers every selected discovered surface.
- Boundary/pairwise/persona strategies target valid surfaces.
- Pairwise reports complete permitted-pair coverage or explicit gaps.
- Full-bounded reports planned/reached/invalid surface counts and dimension/bucket coverage.
- Same revision/input yields deterministic case IDs/order.
- Caps/truncation are explicit.

## E. Executed-surface verification

For every case:

- planned surface is recorded;
- observed semantic/flow/choice route is recorded;
- mismatch is classified.

Unexpected clarification/fallback does **not** count as successful coverage of the planned surface.

A real regression test must catch a stale/missing root-choice ID.

## F. Batch, cancellation and resume

- Each batch remains bounded, normally <=64 cases.
- Real Lua worker executes cases.
- Cancellation remains responsive.
- A cancelled sweep can be resumed and completes remaining compatible cases.
- Partial-batch resume does not duplicate accepted evidence.
- Resume validates catalog fingerprint **and plan digest/schema/revision compatibility**.
- Manifest distinguishes valid, invalid-surface, failed, cancelled/incomplete and skipped cases.

## G. Complete reachability frontier

- Enumerate response pools across all pages until `hasMore=false`.
- Assert enumerated pool count matches production-reported total, unless explicit bounded error records explain a mismatch.
- Enumerate variants for all discovered pools.
- Report UNTESTED / TESTED_INELIGIBLE / ELIGIBLE_NOT_SELECTED / SELECTED / SELECTED_UNDER_SUSPICIOUS_CONTEXT.
- Non-selected variants receive bounded production-explain/context exploration where applicable.
- Finite search never claims global unreachability.

## H. Dialogue quality flags

Positive and negative controls must cover:

- empty/one-word/very-short fragment;
- placeholder/translation-key leak;
- unsupported family/intimacy;
- identity/private-name misuse where evidence exists;
- perspective suspicion;
- generic acknowledgement;
- duplicate rendered text;
- repeated recent text;
- repeated clarification/fallback saturation.

Legitimate short responses and supported family/lover terms must not be definite failures solely because of their form.

## I. Run-level clustering and replay

- Cross-row duplicates/repetition are analyzed after execution.
- Canonically identical causes cluster together.
- Same visible text from distinct semantic causes remains distinguishable.
- Clusters expose counts, context ranges, representative examples, case IDs and source identity/UNKNOWN.
- Affected case replay works after cancellation and after content changes.

## J. CLI and review output

CLI supports:

- plan/run/resume/status/report;
- reachability;
- bundles/export;
- selected case/cluster replay;
- filters by severity/flag/pool/template/variant/phrase/source/strategy/batch/case/language/surface/reachability state.

Review bundles are bounded and advisory.

## K. Dedicated Quality Sweep GUI

A dedicated first-class **Quality Sweep** workspace exists in the Semantic Harness.

It must:

- browse discovered surfaces, dimensions, response pools and variants;
- choose scope, strategy, languages, caps and batch size;
- show case/batch estimates before execution;
- run, cancel and resume without freezing the GUI;
- display live progress and valid/invalid/failed counts;
- filter evidence rows and clusters;
- show triggering parameters plus persona/relationship/state context;
- show semantic path, selected variant, phrase/translation and source;
- open the full existing Conversation Inspector for a selected row;
- navigate to verified canonical source metadata;
- show response-pool/variant reachability and coverage gaps;
- replay selected case/cluster;
- export bounded evidence/review bundles.

The old Simulation sweep sub-tab may become a launcher/summary or be migrated away. There must not be two independent sweep UIs/runners.

Hermetic GUI tests must run under Xvfb/Tk and must not alter user save-selection state.

## L. GUI responsiveness

- Long sweeps execute outside the Tk event thread.
- UI updates are marshaled safely to the Tk thread.
- Cancel can be triggered while work is running.
- Closing the GUI during a run does not corrupt the manifest.
- Resume from a cancelled GUI run is proven.

## M. Performance and storage

Measure/report at minimum:

- surface/dimension discovery time;
- pool pagination time;
- planning time;
- cases/sec;
- batch overhead;
- bytes per compact row;
- run-level quality-analysis time;
- artifact size/growth;
- lazy inspector resolution time;
- GUI progress overhead/bounded responsiveness proxy.

No giant generated snapshot is committed.

## N. Required real production-Lua demonstrations

Synthetic dictionaries may be used for unit controls but **cannot** satisfy these demonstrations.

At minimum prove through real worker execution:

1. ordinary wellbeing response across multiple actual persona/relationship contexts;
2. known-vs-unknown identity wording with privacy evidence;
3. hostile vs friendly case where the resulting selection/tone evidence actually differs;
4. supported family/bond wording and unsupported-family defect class;
5. real or production-backed adversarial perspective case plus known-good control;
6. EN and TL output with translation/fallback evidence;
7. anti-repeat where repeated eligible turns actually demonstrate history-sensitive selection;
8. same response variant selected under at least two distinct parameter vectors;
9. a truly `ELIGIBLE_NOT_SELECTED` variant shown by production explain evidence;
10. one canonical source causing multiple real suspicious/bad rows and one targeted replay;
11. stale/missing planned surface correctly marked invalid rather than successful;
12. cancel → resume completes remaining work without duplicate evidence;
13. full response-pool pagination count matches production total.

## O. Regression and closeout

Before developer-side completion:

- all new focused tests pass;
- Semantic Test Subsystem parity tests pass;
- Response Observatory tests pass;
- relevant full Python harness regression passes;
- production Lua semantic regression passes;
- GUI tests pass under Xvfb;
- Kahlua verification passes for touched Lua;
- CodeBuilder/content idempotence passes if canonical content is touched;
- `git diff --check` passes;
- unrelated user work is preserved.

Native Project Zomboid SP/MP remains user-owned unless separately requested.
