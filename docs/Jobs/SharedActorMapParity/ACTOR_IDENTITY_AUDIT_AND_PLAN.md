# Actor identity and conversation audit

Date: 2026-11-09  
Scope: Project Hoomans, DTHoomans, standalone DTAbstract, PsychopatzCore, and shared Dynamic Trading conversation flow.

## Executive result

The latest runtime failure is a projection/identity integration defect, not a
failed physical access check. The server accepts the context-click request, but
the shared client conversation builder cannot find the selected actor in the
Core projection:

```text
semantic_audit ... handled=true reason="access_requested" result=true
[DT][WARN] conversation_open_failed trader=trader:world:1 reason=core_actor_projection_unavailable
```

`DTCommon.TraderConversation.BuildSpec` currently treats the selected raw ID as
the exact Core projection key. It calls `CoreClient.GetActor(actorID)` and
aborts when that key is absent. The Hoomans body can therefore be valid and the
server can authorize access while the client still cannot open the shared
conversation.

## Why the IDs differ

Rows such as `dt:dynamic_trading:...:member:N` and `npcJefferypatz_...` are
stable opaque IDs created by different producers. They are not, by themselves,
evidence of incompatible NPC engines:

- DTHoomans passes its planned member actor ID into the Hoomans spawn
  definition; the runtime log confirms a `dt:` actor can have a materialized
  Hoomans body.
- Existing Hoomans companions and colonists retain their `npc...` IDs.

The real defect is semantic overloading. Several paths use `actorID`, PNC
record ID, DT member ID, trader reference, and physical body ID as if they were
the same value. The fix must not be a prefix rewrite. Existing IDs should stay
stable and be resolved through one Core-owned identity contract.

## Confirmed code-level causes

1. **Projection eligibility is too narrow.** Core's survivor-world projection
   builder currently includes actors only when they have Core group,
   community, or faction context. A DTHoomans actor can exist in the Core actor
   registry and Hoomans mobile group while being omitted from the client
   projection.
2. **Projection publication is dirty-driven.** DTHoomans creation,
   materialization, body-lease transitions, dematerialization/rebase, and
   restore paths must mark the Core projection dirty. Otherwise the client can
   retain a stale snapshot even after the actor becomes eligible.
3. **Conversation has no resolver or bounded retry.** Client and server paths
   pass the selected raw ID through exact-match checks. There is no canonical
   alias resolution, projection refresh, or distinction between unresolved
   identity and a projection that is pending.
4. **Diagnostics flatten identity concepts.** The current marker rows can show
   `unknown` when provider state/body fields were not normalized. That label
   does not prove that no body exists; the diagnostics need to show the
   canonical actor, aliases, body incarnation, and projection revision
   separately.

## Agnostic target contract

Every person who can be displayed, selected, inspected, moved, or traded is a
Core actor. Dynamic Trading is a capability and commercial policy attached to
that actor, not a special NPC class.

The Core identity record should expose:

- `canonicalActorID`: stable logical identity;
- bounded `aliases`: legacy PNC ID, DT member ID, trader reference, and other
  accepted external references;
- `bodyID`: nullable current physical incarnation, never the logical identity;
- `providerID`: producer/adopter metadata only;
- `presenceState`: `materialized`, `abstract`, or `released`;
- `sourceID`, group/community/faction context, and capabilities such as
  `conversation` and `DT.trade`.

The only intended provider distinction is presence:

- **DTHoomans:** nearby actors may receive a Hoomans body and `bodyID`; remote
  actors remain abstract. The canonical actor and Core journey do not change.
- **DTAbstract:** actors remain on the same Core actor and journey contract but
  never receive a physical body.
- **Hoomans colonists/companions:** can receive the Dynamic Trading capability
  without being converted into a trader-specific NPC type.

## Implementation plan

### Phase A — Core identity and universal projection

- Add a Core-owned actor-reference resolver with indexed canonical and alias
  lookups. Return the canonical actor, alias kind, body ID, provider state, and
  projection revision.
- Extend the projection snapshot with bounded aliases, explicit body/presence
  fields, and capabilities.
- Make projection eligibility actor-based rather than requiring a
  SurvivorWorld group or affiliation. An individual actor remains valid even
  without a group.
- On PNC load/registration, adopt or create a Core actor while preserving
  existing `npc...` IDs as canonical IDs or aliases. Do not bulk-rewrite saves.
- Mark Core projection dirty on actor creation, materialization,
  dematerialization/rebase, lease changes, restore, and group updates.

**Gate:** every Hoomans, DTHoomans, and DTAbstract person has one resolvable
Core actor entry, regardless of provider or group membership.

### Phase B — Shared conversation migration

- Resolve the selected map/context-click reference before trader lookup and
  before `CoreClient.GetActor`.
- Carry `canonicalActorID`, `sourceRef`, and `bodyID` separately through client
  request, server authorization, and conversation spec.
- Have DTHoomans validate resolved live body/distance; have DTAbstract use the
  same canonical actor without requiring a body.
- Add one bounded projection refresh/retry for a spawn/projection race.
- Return precise reasons: `actor_identity_unresolved`,
  `actor_projection_pending`, `actor_not_materialized`, or
  `conversation_capability_missing`.

**Gate:** a nearby DTHoomans actor and a remote DTAbstract actor open the same
conversation contract; only presence/authorization differs.

### Phase C — Trading as an actor capability

- Treat `traderID` as commercial policy/stock identity and `actorID` as the
  canonical person identity.
- Bind a Dynamic Trading policy to any Core actor, including a Hoomans
  colonist or player-owned companion, through capability checks.
- Keep stock, budgets, quotes, and trade authority in DynamicTrading. Keep
  actor identity and presence in Core/Hoomans.
- Remove exact-ID assumptions from DTCommon, DTHoomans, DTAbstract, map
  presentation, and server access validation.

**Gate:** any eligible Core actor can become tradable without provider-specific
NPC duplication.

### Phase D — Crosswalk diagnostics and regressions

Add a selected-marker identity crosswalk showing canonical ID, aliases, body ID,
trader ID, source, provider state, projection revision, PNC/Core presence, and
capabilities.

Add focused tests for:

- canonical, legacy `npc...`, DT member, and trader-reference resolution;
- Hoomans actor adoption into Core projection;
- DTHoomans materialize/dematerialize while retaining the same actor and
  journey;
- DTAbstract conversation with Hoomans absent;
- Hoomans colonist/companion with trading capability;
- save/reload identity stability and stale-projection retry;
- projection dirty publication after spawn, lease change, and restore.

Native acceptance remains a separate user-owned gate: nearby materialized talk,
remote abstract talk, restart persistence, and dense-map performance in both
provider profiles.

## Audit conclusion

The requested architecture is aligned: DTHoomans and DTAbstract should share
one Core actor, travel, projection, and conversation contract. Materialization
is the only provider behavior that differs. The immediate blocker is the
missing universal Core projection/reference-resolution seam, not the visible
ID prefix. Implement Phase A before adding provider-specific conversation
fallbacks; then migrate the shared conversation path in Phase B.
