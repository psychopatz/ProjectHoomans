> **P11 RELATIONSHIP SUPERSESSION (2026-10-23):** The historical bond section below predates the approved dynamic relationship model. P11 now owns relationship semantics: family remains authored/pre-existing; durable friend is earned automatically from high approval/respect/familiarity; lover requires existing compatibility + player proposal + server-authoritative NPC acceptance. Normal Semantic Lab must not expose arbitrary/hypothetical bond kinds. Use `RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md` as the current contract.

# Behavioral Completion — Persona, Bonds, Realization, and Choices

## Why this phase exists

The P0-P7 foundation is structurally useful and regression-tested, but source audit at ProjectHoomans 849f1951 shows the user-visible goal is not yet complete.

The current system can calculate actor/persona context, speech dials, ranking classes and provider metadata. It does not yet make those dimensions consistently visible across normal conversation. This phase closes that gap.

## 1. Companion Bond Context

### Authoritative source

Do not create a second persisted companion-relationship database.

Existing starting companions already persist a detailed relationship kind through generation / starting-relationship state, currently including:

~~~text
friend
lover
mother
father
sister
brother
~~~

Future kinds such as cousin, aunt, uncle, grandmother, grandfather, etc. must plug into the same metadata registry.

### Derived contract

Project a bounded transient bond context into ActorConversationContext:

~~~lua
bond = {
    class = "friend" | "family" | "lover" | nil,
    kind = "mother",
    source = "starting_companion_trait",
    term = {
        referenceKey = "...",
        addressKey = "...",
    },
}
~~~

class is derived metadata and must not be persisted separately.

### Class mapping

~~~text
friend -> friend

lover
partner
spouse -> lover

mother
father
sister
brother
cousin
aunt
uncle
grandmother
grandfather
...registered kinship kinds -> family
~~~

Use a registry/metadata table rather than a growing if-kind chain. Current Starting Companion definitions should register or reference this metadata.

### Bond vs directed relationship

Never conflate bond.class / bond.kind with:

~~~text
relationship.approval
relationship.respect
relationship.familiarity
relationship.state
~~~

A family member or lover can become a rival/enemy. A normal companion can be highly trusted without having a pre-outbreak family/lover bond.

Bond influences vocabulary/intimacy/address. Directed standing influences current tone and eligibility.

## 2. Translation-safe relationship terms

Family scalability should come from localized term registration, not separate sentence banks for every kinship subtype.

Conceptual keys:

~~~text
relationship.term.mother.reference
relationship.term.mother.address
relationship.term.father.reference
relationship.term.father.address
relationship.term.sister.reference
relationship.term.sister.address
relationship.term.cousin.reference
relationship.term.cousin.address
...
~~~

Examples:

~~~text
EN address:
mother -> Mom
father -> Dad
grandmother -> Grandma

TL address/reference:
mother -> Nanay
father -> Tatay
grandmother -> Lola
~~~

Whole-phrase realization templates remain language-owned. The resolver localizes the term first, then supplies it as a typed argument such as familyTerm / familyAddress.

Do not concatenate grammar from translated word fragments. If a future language needs a different grammatical form, register another term form rather than changing semantic IDs.

## 3. Bond-aware realization

Bond is an additional realization input, not a semantic decision owner.

Conceptual structure:

~~~text
semantic intent: REASSURE

friend:
  neutral / warm / terse / guarded

family:
  neutral / warm / terse / guarded
  + familyAddress / familyTerm argument

lover:
  neutral / warm / terse / guarded
~~~

Do not create separate semantic IDs such as reassure_mother, reassure_father, reassure_sister, reassure_cousin unless the semantic meaning itself is genuinely subtype-specific.

For family, prefer family realization + localized relationship term so adding cousin or grandmother requires only:

1. one relationship-kind registration;
2. EN/TL term translations;
3. tests proving the existing family templates accept the new term.

## 4. Speech-dial completion

Every Persona Lab control presented as a speech-affecting control must have documented behavior or be clearly informational.

Audit and resolve at minimum:

- socialStyle
- compassion
- sociability
- forgiveness
- bravery
- materialism
- aggression
- loyalty
- every registered trait exposed as speech-relevant
- companion bond class/kind
- directed relationship scores/state
- companion/trader/hostile roles
- health/activity/combat situation

Avoid a central hand-maintained trait-name switch where possible. Prefer declarative speech modifiers/metadata owned by trait definitions or a bounded speech-metadata registry.

Gender remains excluded from generic personality stereotypes. It may affect grammatical/address/reference realization where authored/localized rules require it.

## 5. Realization coverage

The existing realization mechanism must expand beyond greetings.

Maintain a machine-readable coverage inventory for production semantic response families. Representative mandatory coverage must include at least:

- greeting
- wellbeing
- needs
- medical
- identity
- knowledge/context-reference
- acknowledgement
- apology
- offer/help
- dispute/refusal
- threat/hostility
- gossip/event reaction when available
- companion/action acknowledgement
- Dynamic Trading/trader conversational entry
- quest/commitment conversational response when available

Not every template needs every style variant. Each family must declare its supported variants and deterministic fallback.

Acceptance is based on semantic-family coverage, not number of translation strings.

## 6. Choice-provider completion

The registry must become the actual generic discovery seam.

A newly registered provider that satisfies the provider contract should participate without editing a provider-specific CollectProvider call in the central suggestion builder.

The generic pipeline remains:

~~~text
registered providers
 -> bounded collect
 -> normalize
 -> eligibility/privacy
 -> dedupe
 -> semantic precedence/rank
 -> localized presentation
 -> semantic_click_frame
 -> existing DialogueInput/authority
~~~

Provider-specific effect execution remains forbidden.

Add real providers where useful for:

- social/contextual replies
- relationship/bond replies
- gossip/event follow-ups
- knowledge questions
- quest replies
- Dynamic Trading

Authored response-plan/flow branch offers remain valid and can coexist with providers.

## 7. Semantic Lab correction

Normal simulation must mimic production relationships.

### Directed standing

Editable:

- approval
- respect
- familiarity

Derived by production PNC.RelationshipStates.ResolveState:

- unknown
- neutral
- friend
- rival
- enemy

Do not expose an independently editable normal relationship state that can contradict the sliders. A malformed-state diagnostic mode may exist separately.

### Bond

Expose a production-backed bond-kind catalog. Normal UI selects the detailed kind and displays the derived class read-only:

~~~text
Bond kind: mother
Bond class: family
Localized address: Mom / Nanay
~~~

Future registered kinds must appear automatically.

### Tuning workflow

The Lab must support:

- numeric slider value labels;
- apply-and-replay current utterance;
- arbitrary utterance for A/B testing, not hard-coded hello;
- clone current scenario into A/B rows;
- sweep selected relationship/personality/bond dimensions;
- inspect final response text, semantic family, realization variant, term substitution and candidate ordering.

## 8. Acceptance examples

The same semantic fact must remain stable while wording changes. Family subtype substitution must not create new semantic IDs.

A mother/father/cousin/grandmother substitution test must prove the same family semantic family and style variant can resolve different localized terms.

A family member with enemy standing must remain family in bond context while using hostile/guarded tone from the directed relationship state.
