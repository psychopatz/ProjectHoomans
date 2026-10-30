# Persistence ownership

## Verified responsibility map (P4A)

| Responsibility | Current implementation | Canonical owner |
| --- | --- | --- |
| Save timing, ordered durable commits, dirty rollback | server `PNC_PersistenceCoordinator` | Persistence coordination |
| Pre-save physical-body retirement | coordinator calls Presence public seam | Presence; preserve M12 |
| NPC record envelope/version, record collection | Persistence Serialize/Deserialize/Collections | Persistence envelope |
| Domain compact item schema and seed/delta/full modes | Inventory Persistence/CoreBridge/CoreDeltaCodec | Inventory |
| Event arrays, backstory selection metadata | Conversation Memory | Conversation memory repository |
| NPC health/body and stamina schema | Health.Repository; private Body/Compact codecs | Health |
| Immutable identity, voice and appearance provenance | Identity.Repository | Identity |
| Traits/social/progression/order/body envelope fields | remaining Persistence helpers plus public domain normalizers | remaining P4 ownership review |
| Exact-version validation, ModData read/write/reset diagnostics | Persistence Reset | schema-neutral storage mechanism |
| Domain stores (knowledge, world discovery, work, needs, etc.) | each existing repository/service Load/Save | each owning domain |
| Portable Core migration/import plan | CoreMigration / ImportPlan providers | explicit compatibility adapter |
| Portable Core provider handoff | CoreProvider | optional adapter; Hoomans retains body authority |
| Portable Core knowledge/social/presentation projections | CoreKnowledge/CoreSocial/CorePresentation | owning projection adapter; no save UI callback |

The coordinator already calls domain `Save` methods and preserves all initial
dirty flags on partial failure. Preserve work-before-storage checkpoint order,
GlobalModData flush and pre-save body retirement. Splitting its 191-line Commit
solely because it is large would obscure one ordered transaction boundary.

## Cycle interpretation

Fresh literal imports show thirteen domain stores using the small Reset
mechanism as their only return edge into Persistence's broad logical SCC.
Serialize/Deserialize explicitly load the entire Conversation Memory facade,
including text/gossip/context/recording and semantic provider binding, to use
event storage and backstory metadata. These are different dependency problems;
they are not thirteen independent cycles or a reason to remove conversation
features. No Persistence file participates in an actual literal file-import SCC.

The inspected serializer/deserializer/finalizer contains no window refresh,
UI callback or conversation-session dispatch. Journal import and travel restore
are domain state restoration; retain their ordering and Follow reconciliation.
CorePresentation is an optional read-only bridge, not a deserialize callback.
P6 separately reviews actual UI authority. This bounded conclusion uses all
Persistence-folder source plus exact relevant call snippets, not empty MCP traces.

## Accepted first P4B/C slice

1. Give schema-neutral ModData storage a standalone public mechanism, retaining
   the existing Reset table/path as a compatibility alias. Migrate current
   repositories to the public mechanism so loading it cannot pull in the record
   envelope, conversation or UI. Keep exact version/reset behavior.
2. Establish Conversation Memory's persistence repository and bounded storage
   bootstrap. Persistence calls its public schema surface; full gossip/context
   and interaction recording remain available through the existing Memory facade.
3. Move deferred item snapshot serialization/restoration into Inventory's
   existing repository implementation, preserving lazy hydration and old-version
   promotion. Persistence coordinates placement/timing, not item schema policy.

The standalone `PNC_ModDataStore` owns the same Reset table. Twenty-four literal
consumers now import its public path. The old import is a two-line forwarder;
the old namespace aliases that same object. Store method bodies are unchanged.
This is an independent mechanism with no return dependency on record-envelope
coordination, rather than a renamed lifecycle service.

`Memory.Repository` owns preparation, serialization and restoration. It loads
the existing bounded schema/catalog providers without contextual realization,
target resolution, interaction recording or gossip rendering. The declarative
gossip catalog was separated from rendering because common definitions also
load in partial persistence compositions. The full facade still extends the
same Memory/Events objects and binds the existing semantic adapter.

`Inventory.Repository` works without eager item hydration. Current snapshots
copy through; old envelope versions promote through the existing inventory
codec; restoration retains the lazy snapshot and exact revision. The save
checkpoint may advance/promote item state exactly as before, so it is a command
boundary, not advertised as a pure read query.

Validation (`P4A_VALIDATION.json`): full Lua **979/979**; focused persistence,
restart/body-binding/knowledge matrix **42/42**; diagnostic Python **21/21**;
installed PZ Kahlua **34/34**, static Kahlua zero errors. Body-hint serialization,
restoration and journal/travel helpers have identical source bodies. No native
PZ was launched.

The broad owner SCC splits into three smaller groups; Persistence and storage
are outside them. There are 82 current boundary/cycle manifestations, 107 fewer
than P3, with zero new debt. This is not 107 independent cycles removed: most
are indirect manifestations of the old mechanism/orchestration coupling. The
three-file UI/debug literal SCC remains for P6. Debt endpoints were not added.

Memory's bounded owned-file import closure drops from 15 files / 2,633 lines /
83,367 bytes to 9 / 1,795 / 55,416. External text/identity/Core contracts stop
this supplementary traversal. Fixed gameplay probes total 33 files / 4,638
lines / 172,836 bytes, **36,686 bytes below P0**. The persisted-inventory probe's
four-file working set and unchanged handoff depth are explained in `RETRIEVAL.md`;
envelope callers remain traced and integration-tested.

Pre-change callers/dependencies: `P4_ARCHITECTURE_PRE.json` and
`P4_PRE_MCP_TRACES.json`. Post-change: `P4A_MCP_TRACES.json`,
`P4A_RETRIEVAL.json`, `P4A_MEMORY_RETRIEVAL.json`. Exact coverage is clean at
64 pre-change paths and 38 changed/test/tool paths; MCP heuristics and missing
statement-form imports still require source/literal-import supplementation.

Remaining domain codec ownership and optional Core adapter aliases must be
resolved/classified before P4 acceptance. P4 remains active; this first slice
does not satisfy the whole phase or the parent objective.

## Health and Identity schema boundaries

Persistence now invokes `PNC_HealthRepository` and `PNC_IdentityRepository`.
Health retains the useful distinction between body normalization and compact
encoding in private owned modules. Its public entry exposes normalized health,
compact serialization and stamina restoration. Identity keeps its cohesive
immutable profile/voice/provenance codec together behind five explicit public
functions. Neither repository loads envelope coordination or dialogue.

The shared scalar/map/point helpers are a stateless Hoomans Foundation utility;
domain-specific defaults, bounds and versions stay in their owning codecs.
The old Persistence health provider paths were removed after caller review;
no shims were added. Moved method bodies and generic helpers compare exactly
with revision `034766f9`. Runtime/repair/collection initialization order remains
asserted with the new public entries in place of their old providers.

MCP now discovers and traces the public functions before their implementation.
Health-and-stamina schema context remains four files, shrinking from 1,111
lines / 43,166 bytes to 455 / 17,694. Identity changes move from one mixed
583-line / 21,594-byte file to two cohesive files totaling 425 / 14,144.
The extra generic-helper file/public handoff is an explicit ownership boundary;
file count alone did not drive this choice. The seven fixed gameplay probes
remain unchanged at the first P4 slice's improved footprint.

Validation: full isolated Lua **980/980**, focused **51/51**, diagnostic Python
**22/22**, installed Kahlua **11/11**, static Kahlua zero errors. Zero new debt;
82 manifestations remain. A private implementation-scope guard prevents foreign
imports into Health's codecs. Standalone repository tests cover restart clock
reset, compact body/stamina behavior, profile copying and fail-closed voice
validation. See `P4B_VALIDATION.json`, `P4B_MCP_TRACES.json` and
`P4B_CODEC_RETRIEVAL.json`. Remaining P4 work is still mandatory.
