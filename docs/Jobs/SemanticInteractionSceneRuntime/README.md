# Semantic Interaction Scene Runtime

**Status:** DEVELOPER COMPLETE — S0–S8 accepted; READY FOR USER LIVE TEST.

## Parent objective

Productionize Project Hoomans' existing generic Interaction Scene foundation into the canonical bounded, event-driven autonomous/multi-actor semantic conversation subsystem without creating combat-, gossip-, faction-, settlement- or task-specific dialogue engines.

The normal player conversation session remains the mature player-facing frontend. Interaction Scene Runtime is the autonomous/multi-actor frontend. Both reuse the same semantic providers/evidence, Pragmatic Resolver, Interaction Director, generated behavior/content catalog, plans and gameplay-authority boundaries.

## Accepted steady state

The subsystem now provides:

- one production Project Hoomans managed-NPC actor adapter over existing identity, personality, relationship, faction, condition, activity and knowledge authorities;
- one global bounded Scene Runtime/Scheduler with deterministic IDs, active-scene/participant/turn/history caps, TTL expiry, actor-unavailable closure and explicit visibility/LOD updates;
- semantic continuation driven only by selected plan/behavior metadata, including deterministic prior-source and other-participant targets, player-input waits and loop/turn guards;
- directed speaker/recipient/observer transport where nearby observers receive already-selected speech but no response authority, while an addressed player can resume the exact waiting Scene through the existing semantic response surface;
- a bounded public Opportunity registry/admission manager with deterministic priority ranking, active-key/cooldown suppression and no polling/world scan;
- one server-side adopter hub over the same Runtime for combat horde exchanges, grounded WorldKnowledge disclosure and community excursion phase chatter;
- a read-only bounded Scene Observatory plus real Semantic Harness worker fixture/inspection commands;
- a synthetic fourth-domain proof that public Catalog/Opportunity seams are sufficient without changes to SceneRuntime, InteractionDirector, Scheduler or generic continuation algorithms.

## Production adopter behavior

Combat horde conversation is triggered only at the authoritative horde episode transition. Existing Encounter Intent remains engage/avoid/hold gameplay authority and Combat Banter Arbiter remains chatter-budget authority. Local same-owner or same-faction NPC cohorts are selected through bounded spatial actor lookup; solo actors do not fabricate partners.

Grounded social news requires the speaker to know the exact WorldKnowledge fact. Follow-up remains semantic and grounded; unknown facts fail before disclosure.

Community excursion conversation listens to the existing authoritative excursion phase-change boundary and uses the excursion's participant IDs. Dialogue does not mutate excursion state.

## Core invariants

- no rendered-dialogue reparsing;
- no autonomous Scene ModData root;
- no transcript, generated-choice, InteractionPlan or reasoning-trace persistence;
- no routine autonomous-scene LLM opt-in;
- no SceneRuntime tick loop, full NPC scan or global zombie scan;
- no per-observer semantic rerun;
- no pairwise sub-scene explosion;
- at most one bounded local actor query where an adopter needs locality;
- generated/authored dialogue remains downstream of canonical CodeBuilder source;
- player conversation remains compatible rather than being rewritten for symmetry.

## Minimal read order

1. root `AGENTS.md`;
2. this README;
3. `ARCHITECTURE.md`;
4. `AGENT_RUNBOOK.md`;
5. `ROADMAP.md`;
6. `HARNESS_ACCEPTANCE.md` only when revisiting an acceptance invariant;
7. `PROGRESS.md` last for final evidence and live handoff.

Read `AUDIT.md` or `S0_BASELINE.md` only when revision-specific historical evidence is needed.

## Live handoff

Developer-side S0–S8 is complete. Native Project Zomboid SP/MP timing, readability and feel are user-owned.

Representative live checks should cover:
- brave/cautious/steady horde teammate reactions;
- follower, faction/raider/neutral-team and solo behavior;
- nearby player overhearing with no response buttons;
- addressed-player response handoff;
- grounded NPC news with coherent follow-up;
- community excursion departure/return chatter;
- burst combat/social activity without duplicate scene spam or noticeable new lag.

A native failure should reopen only the smallest owning adapter/runtime/presentation/content layer supported by Observatory evidence. Do not restart S0–S8 wholesale.
