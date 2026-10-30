# Inventory capsule pilot

Status: P2 developer pilot accepted; full parent goal and semantic-tooling baseline gates remain open.
Source anchor: `24d61abc` after P1 tooling (production still matches P0).

## Ownership and preserved contracts

- `PNC.Inventory` owns compact item/container/revision meaning and seed/delta/full
  persistence. `PNC.ServerInventory` owns authoritative player transfer/actions.
- Equipment owns native equipment projection; ActionProps owns temporary client
  action props. These are Inventory subdomains, not competing item stores.
- Supply owns requests, indexing/selection and acquisition/consumption workflows.
  It consumes Inventory mutations and owns native rollback effects, not the
  canonical compact table. Provision owns policy/evaluation/dirty scheduling.
- Registry supplies identity/body lookup; Networking delivers unchanged commands
  and payloads; medical/tasking/conversation retain their existing authorities.
- No new network route or saved field is needed. Public command names, return
  arity, cache/revision restoration, physical undo order and bounded gift replay
  capacity (32) must remain unchanged.

## Evidence before implementation

P1's exact import debt identifies twelve foreign CoreStateCodec imports:
six Colony source adapters and six Supply providers. Exact literal/source review
finds only four uses: AbstractNPC compact encoding, Supply native matching,
Supply core-record decoding, and ItemUtility's descriptor decoding. Eight
bindings are unused provider boilerplate. MCP both-direction traces corroborate
those calls; incorrect aliases for Core utility functions are rejected as in P0.

Two foreign Equipment imports occurred in the held-item debug controller.
Native item creation is an independently consumed, now documented public factory
entry. The private classifier call passed the Internal table as the item through
its method helper, so maintained production always returned `barehand` and used
local debug inference. Both debug controllers now keep that same inference
without importing/reaching into combat hand internals. An opaque native-firearm
characterization passed before and after removal; combat classification stays
unchanged inside Equipment.

Five direct foreign `record.inventory = snapshot` rollback writes occur in
Supply and Colony. Their existing snapshots and native rollback order are useful;
move only the canonical-table restoration behind Inventory's mutation contract.
Do not copy snapshots again or introduce a second authoritative store.

The generic transfer operation currently requires both `_Transfer.lua` (285
lines) and `_Transfer_Handle.lua` (257 lines). The parent combines a medically
specific command/validation with gift replay helpers and an artificial handoff
table. The child has only that one loader. Gift-cache helpers have no independent
caller/test seam; medical sharing has an independently called command. Keep the
medical operation distinct and move gift replay into the transaction owner.

## Implemented seams

1. Public Inventory item-state queries expose compact encoding and core-state
   decoding; codec layout and pseudo-native item adapters stay private.
2. Four real foreign codec consumers use that value contract; eight unused
   imports disappear. Internal persistence users keep their focused codec.
3. Inventory snapshot restoration owns canonical-table replacement/cache rebuild;
   foreign workflows retain their existing snapshots and physical undo behavior.
4. Equipment exposes bounded descriptor/runtime queries and native state-apply
   commands using the same owned functions. Combat, Scavenge, authoring UI,
   Lumber and Visuals use public APIs. Supply exposes NativeCandidates as a
   public query for production, refill and optional Companion Dogs consumers.
   Declared private-root scans now report zero foreign accesses for the pilot.
5. Generic transfer owns its gift replay cache directly. The independent medical
   supply command/validator stays a distinct Inventory application responsibility.
   Remove the superseded private handoff/file rather than retaining a shim.

## Context and validation gates

The fixed transfer probe is now 4 files / 699 lines / 27,265 bytes / 2 handoffs
(previously 5 / 966 / 38,241 / 3). Gift replay and validation no longer require an
artificial transfer handoff plus unrelated medical command implementation.
Medical sharing remains independently callable and tested. Both public command
bodies are text-identical to P0; only ownership/wiring/helper placement changed.

Aggregate fixed probes: 36 files / 5,269 lines / 198,850 bytes: one fewer file,
261 fewer lines and 10,672 fewer bytes. Persisted Inventory's hub grew six lines
/ 304 bytes to register public queries; networking's server hub grew one line /
71 bytes for explicit medical-before-transfer order. These bounded increases
preserve existing useful seams while reducing the aggregate context.

Validation: full isolated Lua **978/978**, focused migration matrix **109/109**,
architecture diagnostic tests **13/13**, installed PZ compiler **36/36**, static
Kahlua errors **0**, diff check clean. The guard has zero new debt; fifteen
previous import/composition violations are resolved, including all fourteen
foreign pilot implementation imports. Five foreign compact rollback assignments
now delegate to Inventory. No persistence schema, payload, budget, cadence,
queue or snapshot copy was added. The semantic-tooling baseline's pre-existing
failures are a separate, still-open P5/final gate.

`P2_VALIDATION.json`, `P2_RETRIEVAL.json` and `P2_MCP_TRACES.json` preserve the
bounded evidence. MCP still produces known heuristic false aliases (including
wrong Registry/Get and Core encode targets), so source contracts and literal
facts remain authoritative for those edges. Generated job trace/measurement
JSON is excluded from executable graph indexing via `.cbmignore`; orientation
contracts and authored source remain discoverable.
