# Domain navigation and enforcement

`DOMAIN_CONTRACTS.json` maps every maintained runtime Lua path to one logical
owner and retains the deployment layer separately. Exact path rules precede
folder aliases. This is ownership metadata, not a request to move those files.
The diagnostic emits the complete path map on demand; agents need only retrieve
the relevant owner's count, contract, probe and source slice.

## Boundaries

| Owner | Canonical responsibility | Public orientation / next seam work |
|---|---|---|
| Inventory | Compact item/container/revision state | `PNC_Inventory`, server `PNC_ServerInventory`; equipment/action-prop subdomains retain engine boundaries |
| Supply | Supply requests, indexing, selection, consumption | `PNC_Supply`; consume through Inventory, never shadow its item store |
| Provision | Provision evaluation, policy and bounded scheduling | `PNC_Provision`; shared rule catalogs remain separate from server scheduler |
| Tasking | Arbitration, active leases, cancellation | `PNC_Tasking`, `PNC_TaskLeaseService`; providers own their work effects |
| Conversation | Scene leases, session lifecycle, memory | Scene / Lifecycle / server authority; presentation is a distinct internal responsibility |
| Semantics | IR interpretation, dialogue policy/flow, realization, diagnostics | P5 must establish bounded subdomain entries; do not introduce one giant semantic facade |
| Persistence | Save/load/reset timing and compatibility coordination | Coordinator and `PNC_Persistence`; domain repositories own field meanings |
| UI | Windows, row/view models, local interaction and preferences | Domain queries/commands; per-user column settings stay local |
| Presence | Materialization, body lifecycle/leases, binding and replica reconciliation | Presence / BodyLifecycle / binding protocol and client runtime; preserve M12 contracts |
| Networking | Transport routing, validation and delivery | Command routers and payload APIs; no gameplay ownership |
| Composition | Explicit ordered startup/tick wiring | Existing shared/server/client composition entries; no business policy |
| Registry | NPC record identity/storage/live indexes | Existing Registry contract; not the owner of every record field |
| Social | Relationships, conduct, social events and gifts | Distinct named subdomains keep their state and authority; no semantic IR ownership |
| Identity | Identity, generation traits and archetype profiles | Identity/trait public surfaces; no social journal duplication |
| Knowledge | Owned knowledge, world facts and journals | Knowledge repositories; observations remain Perception-owned |
| World / Perception | World/discovery state versus observation adapters | Keep observation, knowledge and world state separate |
| Colony / Settlement / Production | Colony application, settlement state, production policy | Separate owners; P7 audits the seams, not a mechanical combined capsule |
| Factions / Communities | Faction authority versus community membership | Separate state owners and public services |
| Pathing / Travel | Engine movement versus journeys/handoffs | Separate runtime contracts; Presence consumes handoff decisions |
| Needs / Health / Activities | Need policy; health/medical rules; named work activities | Preserve task-provider and engine effects boundaries |
| Director | Spawn/encounter direction | Policy remains Hoomans-owned |

Other explicit owners are listed in the machine map: Player, Facilities,
Companions, Behavior, Presentation, Scavenge, Skills, Vehicles, PuppetOpera,
Quests, Foundation, Diagnostics and Adapters. Grouped labels retain independently
named subdomains; grouping does not authorize arbitrary access to their internals.
In particular, `shared` and `server` never become state owners.

## Current evidence and limitations

P1 maps 3,258 maintained executable runtime files to 42 logical owners. Common
declarations and generated catalogs stay outside this runtime graph, as in P0.
ServerInventory is Inventory despite its legacy Server folder. The shared body
binding protocol is Presence despite its transport deployment folder. Correcting
these labels changes folder SCC membership; it does not prove any cycle fixed.
The initial logical graph has one large SCC, with 173 participating literal
import edges. Treat this as an investigation set, not 173 independent defects.

The public entry inventory is complete enough to enforce the P2 pilot and to
orient the highest-pressure domains. P5/P7 must refine the semantic and remaining
domain sub-surfaces from actual callers before enforcing their deep-import rule.
The machine policy intentionally does not manufacture Commands/Queries files.
Existing roots that populate `PNC` without a table return retain that contract.

## Guard rules

`tools/domain_contracts.py` validates:

- unmapped files, missing entries and conflicting declared namespace authorities;
- foreign literal imports into `Internal` directories/providers;
- foreign implementation imports for domains whose public seams are enforced;
- domain -> UI and UI -> Persistence implementation imports;
- composition -> provider imports where a compatible runtime entry exists;
- literal edges participating in cross-domain SCCs.

It cannot resolve arbitrary Lua namespace aliases, prove absence of foreign
table mutation, or infer callback ownership. MCP/source/affected-test review
remains mandatory. Migrations must review lazy global dependencies as well.

`DEPENDENCY_DEBT.json` records **existing unresolved** violations with required
phases, exact endpoints and source lines. It is not a permanent waiver and does
not satisfy final architecture acceptance. New endpoints fail the guard even
when a similar pre-existing violation exists. Line-only movement is not new
debt. Remove resolved entries after an evidence-backed migration; no automatic
accept/rebaseline CLI is supplied. Final acceptance must classify every retained
cycle and remove temporary/mandatory boundary debt, not merely pass this ratchet.

## Run

Refresh architecture-audit with the PZ profile, then:

```sh
python3 tools/domain_context_audit.py \
  --contracts docs/Jobs/DomainContextArchitectureRefactor/DOMAIN_CONTRACTS.json \
  --check-debt docs/Jobs/DomainContextArchitectureRefactor/DEPENDENCY_DEBT.json \
  --output /tmp/hoomans-domain-contracts.json
python3 -m unittest discover -s tests -p test_domain_context_audit.py -q
```

Inspect `contracts.issues`, `contracts.debt_comparison` and the relevant owner in
the report. Compare fixed retrieval probes using `RETRIEVAL.md`; file counts
alone never decide whether a split or merge is accepted.
