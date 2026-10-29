# Progress — Semantic NPC Group Conversation

**Status:** PLANNED — G0 production baseline/ownership characterization is next.

**Planning base:** ProjectHoomans `6c11d218`, existing `main`.

## Accepted foundation

The predecessor `SemanticCombatBanterTacticalIntent` job is developer-complete through B0-B9 and must not be reimplemented.

Accepted reusable foundations include:
- episode-driven horde awareness;
- runtime follower `engage / avoid / hold` intent;
- semantic tactical offers and compact/full presentation parity;
- Combat Moment;
- Combat Banter Arbiter;
- weapon-aware zombie and hostile-human kill commentary;
- explicit `BARK / TACTICAL_PROMPT` classification;
- bounded Combat Observatory;
- Interaction Lifecycle semantic frames and NPCSpeech envelopes;
- CodeBuilder-owned EN/TL content.

## Verified planning truth

Current code supports parts of non-companion combat semantics, but not coherent autonomous group conversation:

- nearby managed NPCs can be selected as player-kill witnesses without a companion-only predicate;
- NPC self-kill/human-kill semantic barks exist, but delivery is normally player-facing;
- `NPCSpeech` already supports actor and target identity;
- faction IDs/member indexes and faction relationship authority exist;
- social context already classifies ally/friendly/neutral/stranger/hostile;
- follower Combat Encounter Intent is still keyed by player owner and rejects non-followers;
- NPC threat-group alert propagation is bounded/event-driven but also owner-team-specific;
- no generic Combat Cohort owner exists;
- no bounded NPC-to-NPC Combat Exchange Director exists;
- no recipient-vs-observer presentation contract exists for autonomous exchanges.

## ONE current Next Chunk — G0

Establish regression/ownership baselines before production behavior changes.

G0 must:
1. prove follower-only owner-key assumptions in `CombatEncounterIntent`;
2. characterize owner-group NPC threat propagation and its query/throttle/TTL behavior;
3. prove faction identity/member/leader lookup seams;
4. prove which combat reaction paths already admit neutral/hostile NPCs;
5. characterize current NPC self-kill speech as player-facing transport;
6. prove `NPCSpeech(actorID,targetID)` preserves directed semantic identity;
7. record current Combat Banter Arbiter budget/fanout behavior;
8. add static/performance guards forbidding a per-tick NPC conversation scan or whole-faction local-speaker loop.

Do not implement G1+ behavior inside G0 except minimal test/harness seams needed to observe production truth.

## Remaining mandatory phases

G0 baseline -> G1 generic Combat Cohort -> G2 generic Encounter Intent -> G3 NPC-to-NPC semantic speech/audience -> G4 bounded Combat Exchange Director -> G5 autonomous squad conversation -> G6 unified arbitration/performance -> G7 Observatory -> G8 broad acceptance.

## Native status

No post-implementation native SP/MP validation exists because implementation has not started. Native timing/feel remains user-owned.
