# Persistence ownership

## Current public contracts

Persistence owns record envelope/version and save/load timing. Domain APIs own
field normalization and restoration. There is one canonical NPC record and no
new shadow store. Entry paths below are relative to `shared/PNC/`.

| Owner | Public entry | Responsibility |
| --- | --- | --- |
| Storage mechanism | `Core/Persistence/PNC_ModDataStore` | Exact-version checks, ModData access and reset diagnostics; domains supply versions/validators |
| Inventory | `Core/Inventory/PNC_InventoryRepository` | Lazy snapshot copy/restore, old-envelope promotion through existing seed/delta/full codec |
| Conversation memory | `Conversation/Memory/PNC_ConversationMemoryRepository` | Compact event/topic schema and immutable selection metadata; shared canonical Memory/Events objects |
| Health | `Core/Health/PNC_HealthRepository` | Health/body compact format, saved alive/dead derivation and stamina; private Body/Compact codecs remain separate |
| Identity | `Core/Identity/PNC_IdentityRepository` | Portable immutable profile, voice and appearance provenance queries |
| Identity hydration | `Core/Identity/PNC_IdentityRestoration` | NPC trait and runtime identity restoration commands, separate from portable codec queries |
| Needs | `Core/Needs/PNC_NeedsRecordRepository` | Authored/generated physiological and dynamic traits, condition state |
| Skills | `Core/Skills/PNC_SkillsRepository` | Authored levels, progression bounds and the existing recruitment learning gate |
| Social | `Core/Relationships/PNC_RelationshipRepository` | Closed social schema, derived conduct-score omission and stale generated-profile interpretation |
| Companions | `Core/Commands/PNC_CompanionRecordRepository` | Saved directives, patrol points and separate departure/abandonment marker schemas |
| Combat | `Core/Combat/PNC_CombatRecordRepository` | Existing typed combat intent and partial-composition fallback; no executor bootstrap |
| Presence | `Core/Presence/PNC_BodyRepository` | Corpse and durable carrier-proof schema; no native body calls or active lease assignment |
| Travel | `Core/Travel/PNC_TravelRepository` | Route restoration/Follow reconciliation; reports a directive transition for Companions to commit |

Existing public Faction, RecipeKnowledge, MapPresentation, semantic projection/
ActionPlan, Journal and trait-model APIs retain their own schema meaning.
Persistence keeps envelope placement, version, default omission and record-ID
link checks. Runtime reset is a cold application composition operation; live
health, task, body and gameplay authorities remain in their domains.

`PNC_Types` is Registry aggregate construction, not a reusable Foundation
mechanism. Its tactical policy submodule belongs to Combat; scalar/map/point
helpers remain stateless Foundation code. The shared MapPresentation module
owns bounded world visibility metadata, not a UI window. These explicit logical
owners avoid misleading conclusions from old Base/Map folder names.

## Timing and authority

- Server `PNC_PersistenceCoordinator` retains ordered domain Save calls, dirty
  rollback, work-before-storage checkpoint order and GlobalModData flush.
- Pre-save body retirement remains delegated to Presence. No coordinator,
  networking, visual-authority, materialization or startup-reconciliation policy
  was moved into a schema codec.
- Restore ordering remains traits → identity/social → stamina/inventory → runtime
  reset/repairs → journal/travel → source version/carrier hints.
- M12 identity/lease/online-ID/wasLive proof, legacy lease fallback and saved-live
  admission are preserved. Schema restoration keeps records abstract and cannot
  assign an active physical incarnation. Native hosted/dedicated acceptance
  remains user-owned.
- Inventory serialization is a save checkpoint that can advance/promote existing
  item state, as before; it is not advertised as a pure query.
- Queries produce normalized values/snapshots. Explicit restoration commands
  commit owned fields. No event bus, generic service locator or state replica
  replaces direct calls.

## Compatibility and composition classification

- `PNC_Persistence_Reset` is a pure forwarder. `PNC.Persistence.Reset` and
  `PNC.ModDataStore` are the identical table; strict method bodies are unchanged.
- Full Conversation Memory still extends the same registry with contextual
  realization, recording, gossip rendering and semantic binding. Its repository
  loads only required schemas/catalogs; common definition loading still works.
- Public `PNC.Persistence` functions remain. `Types.NormalizeSkillLevels` forwards
  to Skills; foreign private `Types.Internal` use was removed.
- Old private Primitives, RecordState and Health provider paths were retired.
  No shims were added for these private implementations. The unused camp-state
  serializer was removed; save/load already omitted/discarded that runtime cache.
- CoreKnowledge, CoreSocial, CorePresentation and CoreProvider remain supported
  optional public adapters under their historical `PNC.Persistence.Core*` names.
  They belong to Adapters, not envelope schema ownership. Hoomans retains record,
  ModData and body authority; explicit portable-Core handoff/projection is not a
  new duplicate Hoomans store. CoreMigration/ImportPlan remain migration adapters.
- The legacy public Persistence hub still loads these optional adapters in its
  established order. This is bootstrap composition, not a save/deserialization
  dependency on UI behavior. None invokes a Hoomans window refresh or session
  dispatch during save/load. CorePresentation builds read-only Core projections.

## Cycle and context evidence

P0's broad Persistence owner SCC included domain stores importing the small
Reset mechanism. Separating that mechanism and owned repositories leaves
Persistence/Storage outside the remaining three owner SCCs. There are **82**
current boundary/cycle manifestations and **zero new debt**. These are not 82
independent defects. The existing three-file UI/debug import SCC remains for P6.
No Persistence file participates in a literal file-import SCC.

The seven fixed behavior probes total **33 files / 4,638 lines / 172,836 bytes**,
**36,686 bytes below P0**. Persisted inventory uses four owned files instead of
seven mixed envelope/bootstrap files; removed context and unchanged handoff depth
are justified in `RETRIEVAL.md` and integration-tested.

Supplementary whole-file working sets:

- Memory owned import closure: 15 → 9 files, 83,367 → 55,416 bytes.
- Health/stamina schema at P4B: four files in both sets, 43,166 → 17,694 bytes.
- Immutable Identity at P4B: one mixed file → two cohesive files,
  21,594 → 14,144 bytes; the generic-helper boundary is explicit.
- Carrier-proof schema: four mixed files → two owned files,
  32,132 → 6,658 bytes. Native admission policy remains a separately tested
  stopping boundary; this set does not alone explain every startup decision.

MCP now discovers named public methods before implementation. Fresh literal
imports and exact source supplement incomplete statement-form imports and known
alias/builtin heuristic errors. `P4*_MCP_TRACES.json`, `P4*_RETRIEVAL.json` and
`P4*_ARCHITECTURE*.json` retain bounded evidence; missing retired paths were
verified against immutable pre-change source.

## Validation

Latest full Lua **981/981**; broad persistence/restart/body/traits/social/companion
matrix **118/118**; diagnostic Python **22/22**; NPC tooling **6/6**. Installed
PZ Kahlua compiled all **19** changed runtime files; static Kahlua found zero
errors. Fourteen moved method bodies, carrier-hint conditions and trait/profile
restoration statements compare with pre-change source after namespace rebinding.
Save formats and public payloads are unchanged. Diff checks are clean.

No new per-frame scans, queues, unbounded fanout or state copies were introduced.
Domain delegation adds bounded cold-load/save calls and module-owned tables.
No native Project Zomboid was launched and no Workshop content published.
P4 is developer-validated; P5–P8 and final gates remain mandatory, including the
pre-existing semantic-tooling failures/timeouts.
