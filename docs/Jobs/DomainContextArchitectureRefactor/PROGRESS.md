# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS. P0–P4 developer gates accepted; P5/P6 review remains open. P7 is active with domain-boundary slices; remaining P7–P8
and final acceptance remain mandatory. Continue automatically after each chunk.

## Objective and repository

Complete the entire `ROADMAP.md` and `ACCEPTANCE.md` on existing `main`.
Planning baseline: `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
Fresh upstream/worktree review found no unsafe concurrent conflict. Preserve the
unrelated DynamicTrading edit and other worktrees. No native PZ launch or
Workshop publication has occurred.

MCP project: `project-hoomans`, explicitly refreshed against current source.
Statement-form imports and heuristic alias/builtin CALLS need the recorded
literal/source fallback; clean coverage is a best-effort signal.

## Current architecture

- Inventory/Supply/Provision pilot uses public item-state, rollback, Equipment
  visual and Supply candidate contracts. Obsolete transfer fragment removed.
- Forty-seven policy-free domain registrations preserve all seven expanded
  composition roots and their executable barriers. Domains retain internal
  providers; roots no longer enumerate the same leaf detail.
- Persistence coordinates envelopes/timing; domain repositories own schema and
  restoration. Storage is schema-neutral. One canonical NPC record remains;
  saved-live/body-lease proof and Follow travel reconciliation are preserved.
- Conversation Lifecycle exposes Create/Finish. Close delivery is independent
  of start/heartbeat support. Semantics owns working-state cleanup and active
  view query/release through a cold-load public session seam.
- Forty-four semantic entry paths expose interpretation, policy/flow, client
  application, interaction facts, realization and diagnostics subdomains.
  Foreign implementation/private namespace access is guarded.
- NPC type palette queries belong to Presentation. Maintained callers use the
  canonical Presentation entry; the old public UI path is a pure compatibility
  forwarder returning the same palette/color table. Function bytes are unchanged.
- Identity authoring now exposes draft/definition-store entries outside UI;
  five cohesive internal providers remain. Preview records stay unregistered.
  Stable editor-model require is a pure same-table forwarder; old private
  provider/storage paths are removed. See `UI_OWNERSHIP.md`.
- Tasking corpse hauling and Pathing body-ownership checks now use public
  BodyLifecycle contracts. Seven direct function references preserve existing
  engine policy; foreign BodyLifecycle.Internal access is guarded. Focused
  corpse/body/path matrix passes **22/22**. See `BODY_CONTRACTS.md`.
- Persistence, Storage and Conversation are outside the current owner SCCs.
  Remaining groups: Companions/Knowledge/Networking/UI;
  Identity/Semantics/Social/World. Review their real paths individually.
- Shared work-item requirements/selection and server logistics now have one
  Production owner. Activities retains specific validators and uses public
  contracts. Activities/Production SCC removed; exact composition expansion
  preserved. Two legacy public require paths forward to canonical tables; the
  temporary mixed-owner JobsRuntime registrar is removed. See `WORK_ITEMS.md`.
- Tasking recovery and Production claim coordination now expose existing
  functions through public Commands; foreign Internal access is guarded.
  Bind-before-capture order and exact owner function identity are preserved.
  Focused coordination matrix: **32/32**. See `COORDINATION_CONTRACTS.md`.
- The one three-file UI SCC is retained same-owner deferred window navigation,
  evidenced in `CYCLE_REVIEW.md`. Its all-phase diagnostic remains visible.
- Maintained runtime: 3,324 files versus P0's 3,258; file count is not a target.
  Boundary/cycle manifestations: 69, zero new debt. The 193-entry ratchet has
  124 resolved entries; these are manifestations, not independent cycle counts.

## Current retrieval evidence

Seven fixed probes: **33 files / 4,505 lines / 167,545 bytes**, versus P0's
37 / 5,530 / 209,522: **-41,977 bytes**. No unexplained individual regression.

- Task lease: same files/hops; +317 bytes / 4 lines for public commands bound
  before executors capture them. This small contract addition is explained.
- Transfer: 5 → 4 files, 3 → 2 handoffs, -10,976 bytes.
- Persisted inventory: 7 → 4 files, same depth, -25,710 bytes.
- Close: same seven-file count as P0, 3 → 2 handoffs, -5,608 bytes. Its owning
  semantic-session seam explains the extra file relative to the P5A slice.
- Semantic cleanup alone: one file, 7,115 → 1,164 bytes. Health/stamina and Memory
  supplementary slices also shrink; machine reports retain membership reasons.

## Current validation and limitations

- Full isolated Lua: **983/983**, 4 workers, 12.58 seconds.
- Palette/Conversation/composition matrix: **28/28**; debug routes **2/2**;
  current semantic parity/translation Python **6/6**; dependency/bootstrap Python
  **22/22**. Prior session/authority/translation slice: **16/16** Python.
- Puppet Opera definition storage moved byte-for-byte from UI to its owning
  client domain. Two maintained callers use its public entry; no UI-path shim
  retained. Cold storage/schema/error matrix and Opera suite pass **19/19**.
- Changed runtime installed-PZ Kahlua: **14/14** current coordination slice (work items/body 10/10 each); static zero errors. Bootstrap
  ordering and diff checks pass. No game execution is implied by compiler checks.
- Full semantic-tooling evidence remains explicit: P5B's 195 isolated modules
  yielded 155 pass / 40 fail, no timeouts, 786 tests. Focused inspector and
  contract-fixture repairs yield a derived **167 pass / 28 remaining failures**;
  this is not a second full run. A fresh run of those 35 completed: one additional module passed, 34 still fail,
  and none timed out. Three further wording-ownership modules now pass 9/9 tests
  after typed source-location and pre-existing locale snapshot alignment. The
  remaining 28 are open individual gates. The apology module now passes 4/4,
  including eight EN/TL family cases and a cold no-antecedent clarification check;
  catalog selection and final authored utterance are checked separately. Two
  further modules pass 9/9 after published locale-key and registered-flow-count
  alignment. C7G still fails alone at 0.403s mean against 0.30s; keep this
  pre-existing performance finding open rather than blaming only contention.
- Tooling retains complete wire traffic and lifecycle facts separately from
  executable dispatch evidence. Unknown commands remain dispatches. GUI tests
  use the proven per-process XIM fallback; no desktop setting was changed.
- Remaining fixture failures require individual repair or supersession proof;
  no blanket waiver. Separate paused wording-authoring work is not resumed.

## Navigation

Current contracts: `DOMAIN_CONTRACTS.json`, `SEMANTIC_SURFACES.md`,
`PERSISTENCE_OWNERSHIP.md`, `COMPOSITION_SEAMS.md`, `INVENTORY_PILOT.md`,
`OWNERSHIP.md`, `UI_OWNERSHIP.md`, `BODY_CONTRACTS.md`, `WORK_ITEMS.md`,
`COORDINATION_CONTRACTS.md`, `CYCLE_REVIEW.md`. Detailed P0/P2–P5 evidence remains in bounded
job-local reports and Git. Historical giant logs are not required reading.

## Next mandatory chunk

**Continue P7 private-boundary review; close P5/P6 gates, then all P8 gates.**

1. Inspect the refreshed remaining-tooling results. Repair assertions against
   current public meaning/presentation/authoring contracts; preserve gameplay,
   semantic IR, suggestions, queued tasks, optional LLM and SP/MP authority.
2. Finish source/caller review of the remaining semantic/domain cycles. Migrate
   real foreign-private coupling; justify retained protocol/composition relations
   with exact paths, phases and canonical owners rather than analyzer counts.
3. Complete P6 UI authority/persistence classification and owning public seams.
4. Complete P7's mandatory domain/transport/performance review, including remaining
   Presence/Pathing and domain-private coupling. Tasking/BodyLifecycle access
   has migrated; the broader mandatory domain review remains. Re-read M12 before
   touching body/presence/network authority and preserve its current contracts.
5. Complete every P8 cleanup and final validation gate, including a current full
   isolated suite, focused matrices, retrieval comparison, installed Kahlua,
   performance/persistence audit, compatibility classification and Git review.

Only after all developer work is complete may renewed M12 hosted/dedicated
native acceptance remain user-owned. Keep root AGENTS and historical logs unchanged.
