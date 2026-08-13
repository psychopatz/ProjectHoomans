# Pilot Evaluation Gate

## Verdict

The Needs → Provision → Supply → Inventory pilot is accepted as the migration
convention, with two constraints:

1. canonical entries are deterministic composition and navigation seams, not a
   requirement to rename every stable public method; and
2. `Commands` / `Queries` groupings are added only when their semantics are
   honest. Hydration or normalization helpers that mutate state are not queries.

Live SP, hosted-MP, and dedicated-server startup remain release checks. Their
absence does not authorize further bootstrap timing changes.

## Gate Evidence

| Criterion | Result | Evidence |
|---|---|---|
| Ownership | Pass | Needs, Provision, Supply, Inventory, and Colony Storage have distinct documented state and writers. |
| Dependency direction | Pass after repair | Inventory mutation now publishes `NPC_INVENTORY_CHANGED`; Provision subscribes from its canonical entry. Inventory no longer calls `ProvisionScheduler` directly. |
| Authority | Static pass | Supply and Provision orchestration remain server-loaded and retain `NPCSupplyService.Process`; clients receive no new mutation capability. |
| Network | Pass | No module, command, payload, response, snapshot, or registration change. |
| Persistence | Pass | No schema, serialized field, repository, dirty-state owner, save timing, or retry change. |
| Load order | Static pass | Supply and Provision entries preserve prior internal order. All `00_*Init.lua` anchors remain unchanged. Live startup modes remain pending. |
| Performance | Pass with audit note | Scheduler cadence and work limits are unchanged. One protected event dispatch replaces one direct callback per successful inventory delta; it adds no recurring scan or tick. |
| Regression tests | Pass with known exclusions | Focused pilot tests pass. The repository-wide sweep retains the four unrelated failures recorded before this gate. |
| Fragmentation | Pass | Supply has 9 files and Provision 5. Their new ~154/~203-token entries are justified canonical seams, not one-function implementation fragments. |
| Abstraction | Pass | No empty architecture tables, mandatory wrappers, protocol objects, or generalized framework were added. Direct compatibility methods remain. |

The architecture audit currently reports 83.5/100 health and classifies 86
subsystems. That classification is materially different from earlier
single-`PNC` scans, so the apparent baseline score increase and finding-ID churn
cannot be attributed to the pilot. The gate uses the audit for scoped findings
and source inspection for dependency claims.

The event repair introduces one low-confidence audit warning because the
inventory mutation file publishes an event. This is accepted: the publisher is
successful `ApplyDelta`, not a recurring tick, and the event replaces an
existing callback with one protected subscriber. The audit's broader
Composition/Colony/Inventory cycle remains a separate finding; the concrete
Inventory → Provision source dependency is removed.

## Context Locality

The preferred working set remains within the target entry plus one to five
implementation files. Approximate counts use `pz_verify`'s four-characters-per-
token estimator because the exact local token detector could not run without
its optional `tiktoken` dependency.

| Typical change | Expected files | Estimated tokens |
|---|---:|---:|
| Supply selection rule | Supply entry + selector + item utility | 3,616 |
| Provision evaluation | Provision entry + evaluator + resolver | 3,967 |
| Inventory mutation | Inventory entry + mutation module | 4,039 |
| Need consumption orchestration | Need bridge + Supply entry + supply service | 5,587 |

The largest relevant files remain `PNC_NPCSupplyService.lua` (~4,630 tokens),
Inventory items (~4,842), Inventory mutations (~3,777), and Provision evaluator
(~3,142). They are recorded candidates for a later explicit decoupling pass;
they are not split during this early migration.

## Convention Retained for Later Chunks

- Keep thin `00_*Init.lua` runtime anchors and explicit composition roots.
- Give substantial domains one canonical deterministic entry when timing
  permits; document interleaved timing rather than forcing an entry.
- Keep stable direct APIs as compatibility contracts.
- Add command/query tables selectively and return safe projections from queries.
- Use semantic post-mutation events to remove reverse domain dependencies when
  the fact has zero-or-more consumers; do not use events as request/response RPC.
- Preserve bounded work, authority, persistence, and protocol behavior before
  optimizing static scores.

## UI Migration Selection

Chunk 6 begins with the Provision Settings UI as a bounded pilot-adjacent
feature. It already has four files, each below the 2,000-token threshold, and a
dedicated model. This permits auditing business-rule leakage and request flow
without beginning with the 908-code-line Inventory window or performing a
monolithic UI split.
