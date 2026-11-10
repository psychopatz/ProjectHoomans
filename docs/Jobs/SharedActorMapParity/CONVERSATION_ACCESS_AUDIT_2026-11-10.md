# Conversation access audit and plan

Date: 2026-11-10

Scope: Project Hoomans, PsychopatzCore, DTCommon, DTHoomans, and standalone
DTAbstract.

## Finding

The failed Talk action is a client-side asynchronous projection handoff, not a
failed DTHoomans access check.

The native console records:

```text
[PNC][INFO] semantic_audit event=native.talk.context_click entryID="dt:dynamic_trading:3141:2:faction_1794213905:member:3"
[PNC][INFO] semantic_audit event=native.talk.external_result ... handled=true reason="access_requested" result=true
[DT][WARN] conversation_open_failed trader=trader:world:1 reason=core_actor_projection_pending
```

The current flow is:

1. Project Hoomans delegates the context-menu Talk action to the shared
   `DT.trader` opener.
2. DTHoomans sends `ConversationAccessRequest` for the clicked member.
3. The server accepts the selected member and returns its actor ID.
4. The shared conversation builder cannot resolve that actor in the current
   client Core projection store, requests `SurvivorWorld` actors, and returns
   `core_actor_projection_pending` immediately.
5. The provider callback logs the pending result as a failure and drops the
   open request. Core has no completion callback into the conversation opener,
   so a later snapshot cannot recover the click.

This explains the apparent no-op. It does not prove that the subsequent Core
snapshot contains the member; that is the second verification gate below.

## Group-member audit

These are members of one Dynamic Trading commercial group, not an incompatible
NPC variety.

- The runtime log shows live Project Hoomans bodies for DT member IDs 1, 2, and
  3.
- `trader:world:1` is the commercial group/stock identity.
- `record.m` is the member roster; `record.ca` is the canonical actor/commercial
  policy reference.
- DTHoomans `traderActorFor()` checks the selected ID against the leader,
  physical actor, and `record.m`, then returns that selected member.
- DTHoomans access validation checks the selected live body, faction, and
  distance. The observed `access_requested` result places the failure after
  this boundary.

The map marker label `unknown` must be treated as a separate presentation or
knowledge-state problem. It does not establish that a physical body is absent.
Diagnostics should show logical actor ID, aliases, trader ID, body ID,
provider/presence state, and projection revision separately.

## Agnostic target

Core owns one person/actor identity and one projection contract. DynamicTrading
owns commercial group, stock, quote, and trade policy. Providers only implement
presence and access transport:

- DTHoomans may materialize a nearby actor into a Project Hoomans body.
- DTAbstract keeps the same Core actor and conversation contract without a
  physical body.
- A Hoomans colonist or player-owned companion can become tradable through a
  capability/policy binding, without conversion to a DynamicTrading-specific
  NPC class.

`traderID` therefore remains the commercial group identity and
`canonicalActorID` remains the person identity. Existing ID formats must remain
stable and be resolved through Core aliases rather than rewritten.

## Remediation plan

### Phase 1 — prove projection state

Add bounded diagnostics around the existing request path, without dumping full
snapshots:

- selected source actor ID and resolved canonical ID;
- client source revision and actor-entry count before and after the request;
- whether the requested actor is present in the applied snapshot;
- provider, presence state, body ID, trader ID, roster size, and selected roster
  index;
- one request ID and terminal reason.

This distinguishes “snapshot never arrived”, “actor omitted”, “alias miss”, and
“open raced the snapshot”.

### Phase 2 — shared pending-open coordinator

Put the retry state in the shared DTCommon/Core boundary, not in DTHoomans or
DTAbstract:

- queue an open keyed by trader ID plus source actor reference when Core returns
  `core_actor_projection_pending`;
- request the bounded Core projection once, with throttling and deduplication;
- retry on the Core snapshot-applied event, with a short tick fallback and a
  small attempt/TTL limit;
- re-resolve aliases on every retry before building the spec;
- open exactly once when the actor and portrait are available;
- report a visible, precise terminal reason such as projection timeout,
  identity unresolved, portrait unavailable, or capability missing.

The provider callbacks should treat `projection_pending` as accepted work in
progress, not as a failed conversation. Both providers must call this same
coordinator.

### Phase 3 — group/member contract

Normalize the shared roster contract and test every member:

- one commercial trader record may contain many canonical actor IDs;
- each member opens the same shared conversation content with its own actor
  identity and portrait;
- selected-member authorization uses the selected physical body for DTHoomans;
- DTAbstract uses the same selected actor without body validation;
- “next person” rotates through canonical roster IDs, resolving aliases at the
  point of use;
- leader fallback is used only when no member was selected.

No provider-specific duplicate conversation engine should be introduced.

### Phase 4 — projection publication gate

Verify and, if needed, repair the server snapshot path so all materialized or
explicitly projectable group members are included after generation, restart,
materialization, dematerialization, and provider-lease changes. The existing
dirty-driven publication path should remain the only publication cadence; do
not add per-click full-map discovery.

### Phase 5 — regression coverage

Add focused tests for:

- pending projection followed by snapshot arrival opens once;
- timeout and omitted actor produce visible terminal reasons;
- members 1/2/3 all map to one trader record and distinct actors;
- DTHoomans nearby body access and selected-member distance validation;
- DTAbstract conversation with no Project Hoomans loaded;
- aliases and save/reload stability;
- colonist/companion capability binding;
- duplicate clicks and stale snapshots do not duplicate windows or requests.

Native acceptance remains a user-owned gate: talk to each nearby group member,
restart, test remote abstract contact, and compare dense-map performance with
Project Hoomans enabled versus standalone DTAbstract.

## Audit status

No gameplay code was changed in this audit pass. The existing focused/unit
verification remains green for the prior identity/projection migration; the
missing regression is specifically the pending-projection-to-conversation
completion path described above.
