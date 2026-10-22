# Hoomans Adoption Contract

W0 contract freeze (2026-10-22): Hoomans remains the sole owner of faction, NPC health/death, zombie observation, community, and Project Zomboid world authority. Core receives typed facts and actor references only. The full source matrix and unknown/42.20 limitations are in `AUDIT.md`.

## Hoomans producers

Register adapters over current authoritative owners; do not move their state:
- ZombiePressureFactAdapter: consume existing cached/bounded zombie threat observations and meaningful band changes.
- FactionFactAdapter: consume committed faction incidents/treaties/status transitions.
- NPCDeathFactAdapter: consume canonical NPC death/cause attribution only when available.
- Community/Settlement adapters only where a committed lifecycle transition exists.
- PZWorldStateAdapter: read authoritative helicopter/power/water/season state after W0 source verification.

Adapters publish typed facts to Core. They do not write another Hoomans gossip ModData registry.

## Hoomans acquisition policy

Hoomans decides which Core actors can learn Hoomans facts:
- experienced/witnessed uses existing presence/perception/identity authority;
- faction distribution uses canonical faction membership/roles/policy;
- public/environmental facts use audited observability rules;
- nearby-faction/world propagation must be bounded and event-driven.

Do not infer omniscience from being a Hoomans NPC.

## Conversation

Preserve existing Core/Hoomans conversation path and semantic GOSSIP branch. Provide a bounded WorldKnowledge context provider that:
1. queries the speaking Core actor's known fact refs;
2. filters authorization/channel/player visibility;
3. ranks a small number by relevance/novelty;
4. realizes localized statements or typed fact descriptors through existing translation/response mechanisms;
5. populates the existing npcGossip projection or its agreed compatible Core replacement.

Do not reparse an NPC's generated prose to decide what fact they know.

## NPC-to-NPC propagation

Use real social opportunities or explicit conversation/radio events. A transfer stores a fact reference plus provenance, not copied prose/full fact data. Pair/fact cooldowns and dedupe are runtime bounded. Do not run an all-NPC gossip simulation every tick.

V1 does not fabricate false facts. Confidence/provenance controls phrasing and certainty only.

## Semantic Lab

Extend existing Semantic Lab with:
- Fact Ledger;
- Actor Knowledge;
- Propagation Trace;
- Gossip Candidate/Ranking/Provenance;
- editable authoritative scenario facts;
- final offline/PBrainZ authorized context comparison.

The worker must exercise production Lua modules. Scenario injection must be visibly labeled as test evidence, not a claim that a PZ runtime hook fired.

## Hoomans acceptance

Mandatory examples include:
- horde/zombie-pressure knowledge from existing cached path;
- member killed by zombie, hostile NPC/faction or player only when authoritative cause is known;
- faction destruction;
- helicopter/power/water/season adapters;
- Alice knows vs Bob does not;
- Alice tells Bob and Bob later reports told provenance;
- EN/TL final gossip;
- optional PBrainZ cannot invent or access unauthorized facts;
- save/reload and bounded footprint;
- no additional population-wide zombie enumeration.

Native PZ SP/MP remains user-owned final acceptance.

## W2 implementation evidence (2026-10-22)

The shared adapter is loaded by the existing Hoomans compositions and the existing semantic cognition transport remains the only gossip route. The new source wrappers publish only after the owning operation reports success; missing death attribution is represented as unknown and never assigned a guessed killer. Zombie pressure is sourced from the existing bounded observation input. The dedicated Hoomans smoke test covers a real authorized pressure statement, player-caused death classification and faction dissemination with explainable faction provenance. The worker regression confirms the pre-existing production Lua semantic path remains intact after the projection change.

## W3/W4 implementation evidence (2026-10-22)

World-state observation is deliberately guarded. The default reader calls only the audited candidate methods when those methods are actually present; any unavailable or errored method becomes an explicit unknown state. An adopter or exact Build 42.20 owner can inject the verified reader without changing the ledger contract. No global zombie enumeration or periodic all-actor scan was added. Propagation is an explicit event API for a real bounded conversation/radio/faction opportunity, with authorization, dedupe and cooldown checks; it is not a polling social simulation.

## W5-W8 implementation evidence (2026-10-22)

The existing production worker and Semantic Lab UI use the same Hoomans/Core path: `PNC.WorldKnowledge.BuildConversationContext` produces bounded candidates and `npcGossip`, `PNC_SemanticCognitionService` projects it through the existing `GOSSIP_RECEIVED` route, and the client/PBrainZ surfaces retain the same fact references. `WORLD_KNOWLEDGE_INSPECT` explains fact ID, producer, learned/acquisition path, source actor, confidence, timing, ranking and final realization. `WORLD_KNOWLEDGE_PROPAGATE` is explicit and authorized.

The existing GUI's new `World Knowledge` trace tab is a read-only bounded projection over the live worker. The GUI test ran under `xvfb` and verified the rendered ledger, actor explanation, ranking and final source/localization fields. Scenario-owned fixture facts are visibly labeled in the projection and are not claims that a native PZ hook fired.

PBrainZ receives only the existing `npcGossip` projection with same-fact metadata; it has no ledger accessor. Save/reload uses the Hoomans-owned `PNC.WorldKnowledge` ModData envelope while Core filters ephemeral and derived-current facts and actor references by retention policy.

## Native Debug Hub inspector (2026-10-22)

The native Project Hoomans client now registers a dedicated `pnc.worldKnowledge` tool in the existing PsychopatzCore Debug Hub. It uses the existing Core/Hoomans debug authorization and the canonical server diagnostic request path. The window is intentionally read-only: it traverses the bounded authoritative ledger projection, selected actor references, `Explain` provenance/ranking, final `npcGossip` realization and propagation trace without publishing facts or directly mutating knowledge.

The implementation is Hoomans-owned and optional for DynamicTrading. DTAbstract/DTHoomans can continue to consume shared Core actor knowledge and provider facts without depending on this Hoomans UI or duplicating trader state.
