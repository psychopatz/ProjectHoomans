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
