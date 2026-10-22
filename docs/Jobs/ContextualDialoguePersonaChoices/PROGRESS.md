# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22  
**Parent status:** REOPENED — P0-P7 foundation exists, but behavioral acceptance was incomplete.  
**Current mandatory phase:** P8A — Bond vocabulary + production-faithful Lab baseline.  
**Corrective source audit baseline:** ProjectHoomans main 849f1951ed1d3fd4b6f78aedc2525b25368a157e.  
**Dynamic Trading provider baseline:** 5db64cbcc764f035146f044fdc34e930ce47d7c8.  
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation to preserve

The current source genuinely contains:

- canonical ActorConversationContext in production conversation and semantic paths;
- transient SpeechStyleContext;
- presentation-only speech realization that preserves semantic response identity;
- EN/TL realization infrastructure;
- semantic choice ranking classes;
- bounded DialogueChoiceRegistry/provider metadata;
- optional Dynamic Trading trader provider with trade state/effects still owned by Dynamic Trading;
- Semantic Lab persona controls, inspector output, and real Lua worker integration;
- broad regression evidence from the previous P7 run.

Do not discard these systems.

## Corrective findings

The previous READY FOR USER LIVE TEST statement is superseded.

Current source still shows:

1. persona wording realization is effectively greeting-only;
2. some exposed personality controls are not actually used by SpeechStyleContext;
3. trait speech effects are hand-coded for only a small subset;
4. Semantic Lab relationship sliders do not derive state through production hysteresis;
5. normal UI can still carry an independently inconsistent relationship state;
6. provider registry is not yet the generic discovery boundary;
7. contextual/persona ranking rules are narrow;
8. Persona matrix is fixed around a few hello cases rather than an arbitrary current utterance.

## Companion-bond evidence

Current starting companion definitions already own detailed kinds:

~~~text
friend
lover
mother
father
sister
brother
~~~

The existing assignment path stores relationshipKind in starting-companion generation/memory data and applies stronger lifelong relationship baselines. Network detailed/roster projections already expose startingRelationship.kind.

This detailed kind is the authoritative source.

Do not replace it with only three persisted values.

### Target derived speech classes

~~~text
friend -> friend
lover / partner / spouse -> lover
mother / father / sister / brother / future kinship -> family
~~~

Family subtype must remain available for localized term substitution.

## Current Exact Next Chunk — P8A

On the user's actual local checkout:

1. read root AGENTS.md and all current ContextualDialoguePersonaChoices docs in the documented order;
2. verify local ProjectHoomans/Core/DynamicTrading branch, HEAD, upstream/divergence and concurrent/user changes; existing main only;
3. inspect the exact current starting-companion relationshipKind storage, network projection, actor-context build, RelationshipStates resolver, Semantic Lab scenario/settings/worker, and translation manager;
4. introduce the smallest bounded relationship-kind metadata registry or equivalent declarative contract for:
   - friend -> class friend
   - lover -> class lover
   - mother/father/sister/brother -> class family
   - extensible future registered kinship;
5. project transient bond.class / bond.kind / term metadata into ActorConversationContext without new persisted fields;
6. add EN/TL reference/address term translations for current kinds;
7. fix Semantic Lab normal relationship state so approval/respect/familiarity are resolved through production PNC.RelationshipStates.ResolveState instead of an independently editable ordinary state;
8. add a production-backed bond-kind catalog/selector and read-only derived class/term display;
9. add numeric slider value labels;
10. add focused real-worker and Tk/Xvfb tests proving:
    - bond kind/class mapping;
    - mother/father/sister/brother all reuse family class;
    - bond remains unchanged if directed standing becomes rival/enemy;
    - no redundant bond class is persisted;
    - relationship sliders derive production state;
    - EN/TL term resolution works;
11. update this ledger with exact evidence and proceed automatically to P8B if the gate passes.

## P8A non-goals

Do not yet expand every response family in the same chunk.

Do not rewrite the choice registry in P8A.

Do not add cousin/grandmother as required production gameplay selections unless useful as a synthetic registry-extension test. The architecture must make those future additions data-only.

## Handoff condition

Do not report READY FOR USER LIVE TEST until P8A-P8E all pass.

Native PZ SP/MP remains user-owned and must remain UNTESTED unless the user supplies evidence.
