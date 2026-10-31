# Production work-item contract

Production owns the shared work-item capability and its server logistics.
Both extend the same `PNC.WorkItemService` table and use the same per-record
`runtime.workItems` leases. Inventory continues to own actual items; Equipment
owns primary-slot leases and native hand projection.

| Public entry (runtime-relative) | Responsibility |
| --- | --- |
| `shared/PNC/Core/Production/WorkItems/PNC_JobRequirements.lua` | Operation requirement registry, candidate types and validator IDs. |
| `shared/PNC/Core/Production/WorkItems/PNC_WorkItemService.lua` | Candidate selection, semantic validator registration and work-item/equipment intent. |
| `server/PNC/Production/PNC_WorkItemService_Logistics.lua` | Pickup/return transactions through existing work and storage contracts. |
| `shared/PNC/Core/Production/PNC_WorkItemsRuntime.lua` | Ordered registration of the two shared providers, after JobSystem. |

Activities retain fishing/lumber/farming policy and their explicit validator
callbacks. They consume Production's work policy and work-item contracts.
The shared files moved intact: candidate ordering, cached/preferred item checks,
validator failure boundaries, lease priority and return behavior are unchanged.

The legacy `PNC/Core/Jobs` requirement/service paths permanently forward to the
same canonical tables. The temporary mixed-owner `PNC_JobsRuntime` registrar is
removed. Expanded startup remains JobSystem, JobRequirements, WorkItemService;
all seven root traces and executable barriers remain equivalent.

Commands include validator/requirement registration, Ensure, SetSource and
Release. Historical `Check` also fills a missing item ID while inspecting a
candidate, so it is documented as a potentially mutating compatibility operation.
GetLease returns a borrowed lease for reading; Status preserves its existing
copy behavior. This migration introduces no second registry, lease or item store.

The Activities ↔ Production import SCC is removed through actual ownership and
public-path migration. Five former cycle-edge diagnostics represent that one
owner-level problem, not five independent cycles. `P7B_WORK_ITEMS_PROOF.json`
pins source identity, composition, tests and refreshed graph/guard evidence.
