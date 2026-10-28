# Harness Acceptance — Pragmatic Interaction Director

The Semantic Lab/harness is the primary developer acceptance surface.

## Truth source

All semantic/pragmatic/behavior/beat decisions must come from the real production
Lua worker and shared production providers.

Python may:

- display;
- edit canonical source;
- schedule scenarios;
- compare;
- filter;
- visualize.

Python must not implement a second interaction director.

## Required per-interaction evidence

For a direct player turn or NPC semantic act, expose enough bounded evidence to
recover:

1. source stimulus;
2. human NLU candidates/IR when applicable;
3. actor/relationship/world/knowledge projections actually used;
4. active/suspended flows;
5. pragmatic interpretation;
6. one-shot behavior candidates;
7. situation/beat candidates where applicable;
8. failed predicates;
9. contextual modifiers;
10. active beat before/after;
11. selected behavior or explicit no-op;
12. InteractionPlan;
13. ResponsePlan / EmotePlan / GameplayIntent projections;
14. Dialogue Content lineage when speech is realized;
15. translation lookup;
16. final player-visible speech/emote/flavor;
17. authoritative side effects;
18. harness override status.

## String/content acceptance

All speech/flavor wording must be editable through ordinary Dialogue Content
authoring.

Acceptance must prove:

- open a content family referenced by a behavior;
- edit EN and one additional locale;
- validate;
- preview;
- write canonical source;
- compile;
- regenerate;
- reload worker;
- select it through the intended interaction behavior.

No director-specific string editor is required.

## Structural authoring acceptance

The integrated interaction module view must support bounded editing of:

- situation/beat definitions;
- behavior definitions;
- stimulus bindings;
- predicates;
- contextual modifiers;
- capability requirements;
- references to Dialogue Content IDs.

It must expose:

- canonical source;
- draft;
- worker overlay;
- provenance;
- generated diff.

## Natural vs forced acceptance

Harness diagnostic modes may force or disable eligibility for focused testing.

Every forced result must show a visible `HARNESS_OVERRIDE` marker.

Forced cases do not satisfy natural-selection acceptance.

## Direct dialogue scenarios

Protect at minimum:

- typoed recognized hostility;
- ambiguous low-confidence clarification;
- active flow response ownership;
- argument escalation;
- reconciliation;
- first-contact context;
- interruption and resumption of unrelated grounded flows where applicable.

## NPC-to-NPC acceptance

At least one 2-NPC scene must prove:

- no player participant required;
- NPC A emits a semantic act/fact/topic;
- NPC B consumes the semantic event directly;
- generated English is not reparsed;
- response behavior depends on B's projected state/relationship/knowledge;
- only perceived speech/emote is realized.

## Multi-NPC acceptance

At least one 3+ actor scene must prove:

- bounded participant count;
- explicit speaker/target roles;
- no pairwise explosion;
- bounded turn count;
- interruption/exit works.

## Emote/flavor acceptance

At least one semantic behavior must be presented in more than one mode, such as:

- speech;
- emote;
- ambient flavor.

The semantic decision must remain shared.

## World-event/gossip acceptance

At least one real/synthetic grounded world event must:

- enter through a typed stimulus;
- become available only to actors allowed to know it;
- influence interaction behavior/topic;
- never invent unsupported world facts.

## Third-party adapter acceptance

Provide a synthetic adapter that does not use Project Hoomans NPC internals.

Prove it can:

- project actor capability/disposition/condition;
- project relationship/knowledge as available;
- participate in the same behavior/beat system;
- remain valid with some fields unknown.

## LOD/performance acceptance

Instrument and verify:

- definitions considered per stimulus;
- predicates evaluated;
- behaviors considered;
- scene participants;
- active scenes;
- turns per scene;
- trace bytes;
- semantic-memory writes.

Required proof:

- no whole-catalog/all-NPC per-tick scan;
- nearby perceived scenes may realize text;
- non-perceived scenes can skip realization;
- distant actors do not simulate flavor conversation turn-by-turn;
- candidate evaluation remains bounded under synthetic high-NPC scenarios.

## Persistence acceptance

No full transcript persistence.

If a scene creates durable knowledge, assert the persisted result is a bounded
semantic fact/event rather than rendered prose.

## Compiler acceptance

Prove:

- modular source-root discovery;
- stable canonical IDs;
- deterministic generated indexes;
- duplicate/collision/reference validation;
- EN fallback;
- data-driven additional locale;
- two-pass byte-identical generation;
- no manual generated-file edits.

## Final developer acceptance

R9 completes only when the harness can explain and exercise:

- direct conversation;
- NPC-to-NPC interaction;
- multi-NPC scene;
- emote/flavor reuse;
- grounded world stimulus;
- third-party adapter;
- bounded performance;

while also proving:

- one semantic authority;
- one interaction/context authority;
- one ResponsePlan/Dialogue Content speech path;
- one gameplay authority.

Native Project Zomboid SP/MP remains user-owned unless explicitly reassigned.
