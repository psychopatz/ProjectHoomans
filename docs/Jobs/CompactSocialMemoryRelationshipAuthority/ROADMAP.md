# Roadmap — Project Hoomans Portable Social State Adoption

**Status:** ACTIVE — H0-H7 accepted; H8 pending after Core P11-P12.
**Canonical parent:** PsychopatzCore Docs/portable_social_state/ P0-P12.
**Participant completion:** H0-H8 plus relevant parent gates are required; Hoomans alone never completes the multi-repo parent.

## H0 — Hoomans overlap and ownership audit

Support parent P0 by mapping exact Hoomans writers/readers for RelationshipService, SocialEvents, ConversationMemory, Conduct, Knowledge, faction/hostility, player identity and semantic evidence.

Classify every relevant field/path as:

- portable Core candidate;
- Hoomans-specific authoritative state;
- derived projection/cache;
- duplicate generic state to migrate;
- obsolete/legacy candidate.

**Gate:** no migration begins until the overlap map is source/test verified.

## H1 — Core adapter contract

After parent P1, implement the thinnest Hoomans adapters for actor/event/relationship/evidence projection.

No PNC-specific type may leak into Core canonical contracts.

**Gate:** Hoomans can read/write accepted portable contracts without replacing current game-specific authorities prematurely.

## H2 — Generic relationship/memory writer reconciliation

Under parent P2/P4, move generic shared relationship/memory writes to the accepted Core authority.

Preserve Hoomans-only dimensions/effects behind explicit adapters/extensions where justified.

Remove superseded duplicate writers only after caller-zero and migration tests.

**Gate:** one generic directed relationship/history is authoritative for a Core actor pair.

## H3 — CodeBuilder social policy adoption

Move first-party Hoomans portable social event memory/relationship metadata into Hoomans-owned canonical Social Policy source compiled by Core CodeBuilder.

Hoomans-specific gameplay consequences remain domain adapters/effects.

**Gate:** canonical source generates deterministic runtime policy with no hand-edited downstream tables.

## H4 — Semantic evidence and conversation integration

Ensure Unified Semantic Evidence and Semantic Social Conversation Director query the normalized Core/Hoomans projections.

Prove direct witness/hearsay, grievance/assistance, relationship, threat/faction and knowledge context remain bounded.

**Gate:** no full social-store dump and no new conversation/memory authority.

## H5 — Multiplayer and actor continuity (Accepted)

Prove NPC-to-NPC, NPC-to-player, player-caused events, reconnect identity and any Core provider/materialization transitions preserve authoritative social state.

Clients cannot author relationship/memory outcomes.

**Gate:** protocol/harness cases pass with bounded projections.

## H6 — Scale and participant acceptance (Accepted)

Stress sparse contacts, repeated events, anchor/retention pressure, many abstract/non-live actors and long world time.

Run Hoomans social/semantic/director regressions and parent-required cross-mod fixtures.

**Gate:** participant is accepted only when Hoomans-specific gates pass and parent Core integration remains green.


## H7 — Single-persistence Core social authority (Parent P10) — ACCEPTED

Remove the second persisted copy of generic social relationship and memory state from Project Hoomans for Core-backed actors.

Requirements:

- preserve PNC-owned morale, conduct, bond or romance, interaction journal and other genuinely Hoomans-specific state;
- hydrate generic approval, respect, familiarity, baselines, memories and revisions from Core at runtime instead of independently serializing them through RelationshipRepository.SerializeRecord;
- route generic mutations to Core authority once, then refresh the PNC runtime view;
- provide explicit versioned migration for supported older PNC saves that still contain generic social state;
- do not retain a permanent dual-write compatibility shim;
- prove save and reload, semantic evidence, SocialEvents, Conduct, conversation and relationship presentation remain correct;
- add a combined Core plus PNC payload test that fails if the same generic social history is persisted twice.

**Gate:** a Core-backed Hoomans NPC has one persisted generic social history in Core plus an independently persisted PNC-specific extension envelope.

## H8 — Final Hoomans regression under parent P12

After Core P11 and player-identity cleanup, rerun Hoomans social, conduct, semantic evidence, reconnect alias, combined DTAbstract to DTHoomans continuity and persistence-footprint tests.

**Gate:** all Hoomans portable-social tests pass with no duplicate generic persistence and the known unrelated full-suite baseline is unchanged or improved.

## Stop rules

Continue participant work as requested by the Core parent roadmap. Do not declare the multi-repo parent complete from H6 alone.

Do not create a second Hoomans generic social engine, permanent compatibility shim, new branch, destructive Git operation, native-game automation or Workshop publication.
