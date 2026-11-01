# Current dependency-cycle review

Scope: maintained current-runtime Lua and recorded literal imports. Dynamic
imports, callbacks and heuristic alias edges need direct source review. Counts
of analyzer manifestations are not counts of independent architecture problems.

## Resolved directions

- Persistence coordinates envelopes/timing and uses domain-owned repositories.
  Storage is a separate schema-neutral mechanism. Persistence and Storage are
  outside the current owner SCCs; deserialization needs no UI behavior.
- Conversation uses the public Presentation palette query. The implementation
  moved intact from `client/PNC/UI/PNC_NPCTypePalette.lua` to
  `client/PNC/Presentation/PNC_NPCTypePalette.lua`. Conversation is outside the
  UI-related owner SCC. Maintained callers use the canonical entry.
- The old palette require path is a permanent public compatibility forwarder.
  It returns the same palette/color table; it contains no implementation or
  duplicate state. Bootstrap canonicalization verifies the pure forwarder and
  preserves the expanded provider order.

- Activities now consumes Production work policy/items in one direction. The
  shared work-item capability and server logistics extend one Production-owned
  namespace; two implementations moved intact to canonical Production paths.
  The mixed-owner temporary JobsRuntime registrar is removed, while exact
  expanded startup order is retained. `WORK_ITEMS.md` and
  `P7B_WORK_ITEMS_PROOF.json` record the real ownership split and repair.
  Five cycle-edge diagnostics resolved; this was one owner-level group.

## Retained UI navigation SCC

The all-phase import report contains one three-file SCC, wholly owned by UI.
Paths in this table are relative to `client/PNC/`:

| Edge | Execution evidence |
| --- | --- |
| `UI/NPCPresentationDebug/PNC_NPCPresentationDebug.lua` → `UI/PNC_AnimationSceneDebugWindow.lua` | `openScenes`, lines 154–168, requires the destination on demand; Animation tab action dispatch calls it at line 292. |
| `UI/PNC_AnimationSceneDebugWindow.lua` → `UI/PNC_AnimationSceneDebugWindow_Actions.lua` | Top-level assembly of that window's actions. |
| Actions → Presentation Debug window | `onOpenXML`, lines 81–94, requires the destination on demand. Core binds this method as the Open XML Player button callback, lines 117–129. |

This reviewed SCC contains no all-top-level require loop. It is two explicit
window-navigation routes inside one owner, with permission checks still in the
public Open methods. Retain the lazy loads: adding a callback registry or moving
window-opening policy into gameplay domains would add machinery without
improving authority or change-local context. The diagnostic SCC remains visible.

`P5D2_MCP_TRACES.json` records coverage and trace limitations;
`P5D2_ARCHITECTURE_PROOF.json` pins source hashes and exact unchanged palette
bytes. The existing animation-scene debug route/smoke tests remain green.

## Retained Companions / Knowledge / Networking / UI relations

All 24 cross-owner literal imports in this four-owner group were enumerated
against current source (`P7H_PRESENTATION_CYCLE_PROOF.json`). They are public
contracts at distinct phases, with no cross-owner file-import SCC:

| Direction | Concrete contract and execution phase | Ownership reason |
| --- | --- | --- |
| Companions/UI → Knowledge | Client `NPCIdentityPresentation` queries; GetName/GetKnownName/GetFaction read player-scoped knowledge/snapshot mirrors. | Knowledge owns disclosure meaning; windows and command labels use its presentation query. The cached placeholder set is presentation-only. |
| UI/Networking → Knowledge | Client `KnowledgeInterest.Require/CollectNPCIDs/ConsumeFlush`; request consumers declare demand and bootstrap consumes the existing 100 ms debounce. | One deduplicated interest set and existing hydrated/missing checks; no synchronous request callback into a window. |
| Knowledge → Networking | Server `ColonyJournalFeed.GetDelta` uses shared `ColonyJournalProtocol.ToWire`. | Stateless typed row encoding, primitive string bounds, batch 32 and retained feed 512; it loads no client/router/UI implementation. |
| Networking → UI | Colony result → `ColonyUIShared.NotifyBuildFailure/NotifyBuildQueued`; companion result → `NameplateToolFeedback.Push`; toll result → `FactionTollUI.HandleServerMessage`. | Typed delivery to presentation. Halos, window state and 128-entry/3600 ms feedback are UI-owned. Toll choices submit a server command; money, treaty and admission rules remain authoritative elsewhere. Colony UI is loaded inside the result function; toll UI is loaded on receipt when absent. |
| Networking → Companions | SP debug spawn and server debug handler → `DebugCompanionInitialization.ApplyKnownCompanion`. | One public companion application operation calls player identity, relationship baseline and knowledge owner APIs, then sends the resulting snapshot. The MP client sends its existing request before the SP implementation branch. |

The reverse edges join different runtime layers and functions: a server wire
codec and client result presentation do not form a reentrant initialization
chain. Explicit typed delivery preserves the single inbound transport choke
point. A new generic callback registry would add discovery and wiring cost to
these existing public operations. Retain these relations and their diagnostics.
This justification applies to the enumerated paths, not arbitrary future UI or
transport authority. Four selected public-call traces, source hashes, coverage
limitations and 30 passing focused tests are recorded in the P7H proof.

## Retained Identity / Semantics / Social / World relations

The Identity / Semantics / Social / World owner grouping encompasses distinct
functional layers and phase-isolated runtime contracts. Source and graph
inspection confirms 0 circular dependencies, 0 foreign-private boundary
violations, and no reentrant execution loops:

| Direction | Concrete contract and execution phase | Ownership reason |
| --- | --- | --- |
| Semantics/Social → Identity | `PNC_IdentityRepository`, `PNC_UniqueNPCDefinitionStore`, `PNC_NPCTraits`, `PNC_SocialTraits`. Reads immutable traits, archetypes, and appearance/voice metadata. | Identity owns character definition schema, archetype profiles, and authoring definitions. Semantics consumes these as immutable values for speech style dimension calculation (`PNC_SpeechStyleContext`) and persona-conditioned behavior selection. Social uses traits to establish baseline personality profiles. Neither domain mutates Identity state at runtime. |
| Semantics → Social | Pre-turn: `RelationshipState.GetState`, `PNC_SocialProfiles`, `PNC_RelationshipRepository`. Reads affinity, respect, familiarity, and bond terms (`Mom`, `Nanay`). Post-turn: records accepted interaction facts (apologies, insults, compliments, gift exchanges). | Social owns relationship dynamics, conduct history, and familial bond terminology. Semantics queries social standing to evaluate dialogue policies and resolve address terms; post-turn, Semantics publishes accepted dialogue facts which Social aggregates into conduct/affinity adjustments. The execution is strictly phase-isolated: pre-turn read, post-turn event emission. |
| Semantics/Social → World | `PNC_SpatialIndex`, `PNC_WorldDiscovery`, `PNC_CampGeometry.RuntimeAccess`. Reads spatial proximity, room bounds, and known landmarks. | World owns spatial partitioning, discovery state, and camp geometry. Semantics queries World for grounded spatial facts to resolve knowledge questions (`semantic.question.knowledge.*`) and camp destination hints (`PNC_DynamicCampDestinations`). World exposes public runtime query seams without depending on dialogue or social logic. |
| Semantics → World/Tasking | Companion command dispatches (`CAMP`, `FOLLOW`, `WAIT_AT`) via public `PNC.Client.SendCompanionCommand` and command executors. | Semantics interprets dialogue acts into high-level order intents; command executors coordinate task leases and pass validated spatial targets to Tasking/World executors. Semantics never mutates world grid state directly. |

These contracts represent legitimate, unidirectional public runtime composition
and immutable vocabulary sharing. All 93 private roots remain guarded with 0
foreign-private leaks, and the ratchet enforces 0 new debt.
