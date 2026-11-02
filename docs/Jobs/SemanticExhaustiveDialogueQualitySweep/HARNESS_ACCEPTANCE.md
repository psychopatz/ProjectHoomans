# Acceptance — Semantic Exhaustive Dialogue Quality Sweep

## A. Core product behavior

A normal user can open Quality Sweep and perform the main task without understanding testing internals:

1. click **Generate Sentences**;
2. see real NPC sentences appear;
3. read the player/menu trigger for each line;
4. read compact context for each line;
5. filter suspicious or repeated lines;
6. click a line to inspect why it happened.

No strategy/batch/reachability knowledge is required.

## B. Sentence visibility

A completed or partially completed run with persisted evidence must display those rows.

Acceptance explicitly fails if:

- manifest says completed but table is empty;
- an analyzer exception prevents otherwise valid rows from rendering;
- categorical production values such as `identityTrust="unknown"` crash review.

## C. Trigger/context correctness

For representative real-worker rows, show:

- original input/menu trigger;
- language;
- planned and reached route;
- relationship/bond;
- personality/style/traits;
- needs/health/activity where available;
- semantic template/variant;
- realization/phrase/translation;
- source owner or UNKNOWN.

## D. Exact Full Inspector replay

Selecting a row and opening Full Inspector must recreate the same interaction.

For a real wellbeing row:

- original intent/subject must remain wellbeing;
- replay must not default to greeting/hello;
- rendered response must match or explain deterministic variation under the recorded context.

## E. Production surface discovery

Normal review uses current production-discovered executable surfaces.

Expected fallback probes are excluded unless explicitly requested.

Stale/missing surfaces must be marked invalid and must not count as successful coverage.

## F. Balanced bounded review

Under a bounded case cap:

- every selected surface receives baseline coverage;
- every selected surface receives parameterized context coverage when budget allows;
- no first surface may consume the majority of the cap merely because of ordering;
- language coverage is explicit.

A regression test must assert bounded distribution fairness.

## G. Stop / resume

- Stop remains responsive;
- completed evidence stays visible;
- resume/continue does not duplicate accepted rows;
- manifest compatibility is validated;
- partial progress survives interruption.

Normal UI may hide the word “resume”; behavior may be automatic behind Generate Sentences.

## H. Full response registry

- paginate until production says complete;
- enumerated pool count matches reported total unless explicit errors explain otherwise;
- enumerate all registered variants;
- maintain observed selected-variant counts from real sentence rows.

## I. Variant-guided frontier

For unobserved variants, bounded frontier search must:

- use production explain evidence;
- try relevant approved context buckets;
- go beyond a fixed two-profile probe;
- classify SELECTED / ELIGIBLE_NOT_SELECTED / TESTED_INELIGIBLE / unresolved honestly;
- never claim global unreachable from finite search.

Acceptance requires a real run where frontier targeting discovers at least one additional unique selected variant beyond baseline review, unless production evidence proves no eligible target exists within the documented bounded search.

## J. Quality analysis

Per-row controls:

- empty/fragment;
- one-word suspect;
- placeholder/translation leak;
- unsupported family/intimacy;
- identity/privacy misuse;
- perspective suspicion;
- generic acknowledgement.

Run-level controls:

- duplicates;
- repeated text;
- variant collapse;
- fallback saturation;
- generic-response concentration.

Quality analysis must not suppress sentence display if one heuristic fails.

## K. Real defect demonstrations

Synthetic dictionaries may validate analyzers but cannot satisfy end-to-end acceptance.

Use real production Lua or faithful production-backed replay to prove:

1. supported family/bond wording;
2. unsupported family/intimacy defect class;
3. perspective defect plus valid control;
4. canonical-source cluster across multiple real suspicious rows;
5. targeted replay of affected cases.

## L. Anti-repeat

Prove actual history-sensitive behavior where alternatives exist.

Acceptable evidence includes:

- different selected phrase/variant after repetition;
- production anti-repeat penalty/reason that changes selection outcome;
- bounded history trace showing the recent candidate was suppressed.

Field presence alone is insufficient.

## M. Genuine eligible-but-dominated case

Produce a real explain result where:

- target candidate is `eligible=true`;
- another candidate is selected;
- target therefore classifies `ELIGIBLE_NOT_SELECTED`.

An ineligible candidate does not satisfy this gate.

## N. Sentence-first GUI

Default page contains:

- Generate Sentences;
- Stop;
- Languages;
- Max examples;
- Reload Results;
- Advanced…;
- sentence table;
- detail panel.

Default page does **not** require separate coverage/batch/pool tabs.

Direct filters include:

- free text;
- suspicious/flagged only;
- duplicates/repeated only;
- language.

Advanced diagnostics may expose strategy/reachability/export internals.

## O. GUI threading

- sentence generation off Tk thread;
- advanced reachability scan off Tk thread;
- UI remains responsive;
- evidence appears incrementally;
- close/cancel does not corrupt manifest.

## P. Regression

Before completion:

- focused sweep/service tests pass;
- GUI/Xvfb tests pass;
- Semantic Test Subsystem regressions pass;
- Response Observatory regressions pass;
- production Lua semantic regression passes;
- `git diff --check` passes;
- unrelated work is preserved.

Native PZ remains user-owned unless separately requested.

## Q. Completion honesty

Do not declare COMPLETE based on:

- number of generated cases;
- a green manifest;
- synthetic defect rows;
- GUI existence;
- full response-pool pagination alone.

Completion requires the real sentence-generation, frontier, quality and replay gates above.
