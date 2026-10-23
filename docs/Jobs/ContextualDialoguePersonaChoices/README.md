# Contextual Dialogue Persona & Choices

**Status:** REOPENED — P11 runtime-parity foundation retained; P11J native Talk shared-entry parity is the current mandatory gap.  
**Current source-audit baseline:** ProjectHoomans remote main at c9385c4f2b1b86feb09ed24144896e473bd6fec8 (2026-10-23).  
**Dynamic Trading provider baseline:** psychopatz/DynamicTrading at 5db64cbcc764f035146f044fdc34e930ce47d7c8.  
**Native Project Zomboid SP/MP:** untested; user-owned acceptance.

## Goal

Make deterministic NPC dialogue and contextual reply choices visibly reflect the authoritative actor state already owned by Project Hoomans—identity/gender where grammatically relevant, registered traits, persistent social personality, directed approval/respect/familiarity/state, companion bond, roles/capabilities, and current situation—without letting style invent semantic facts or bypass gameplay authority.

The existing P0-P7 implementation is retained as foundation, but the 2026-10-22 corrective audit found the player-facing behavior incomplete:

- speech style is calculated broadly but authored realization variants are effectively greeting-only;
- several exposed Persona Lab controls have little or no visible speech effect;
- relationship sliders do not yet derive state through the production hysteresis resolver;
- the choice registry is a real normalization seam but the central suggestion builder still manually orchestrates most provider discovery;
- persona-aware ranking is narrow;
- the Semantic Lab persona matrix is fixed around a few hello scenarios rather than being a flexible tuning surface.

The P8 behavioral foundation is now implemented, but the 2026-10-22 UI/routing audit found a new product gap: Semantic Lab still hides real conversation branching, and typed authored-category utterances such as `whatsup` redundantly produce an `Ask what's up` button instead of entering the already-recognized category directly.

P10 hub/control infrastructure and the P11 actor/relationship/runtime-graph work are retained. A later Talk audit found that the harness-side P11J matrix now models the correct Colonist/Follower/Neutral/Hostile cases, but native `PNC.Conversation.Open` still does not consume the same Talk-start projection. The current mandatory gap is therefore **P11J native Talk parity: converge native Talk and Semantic Lab onto one production Talk-start boundary**.

## Relationship / bond direction

Current relationship standing and durable social bond are separate.

Standing remains production-derived from approval/respect/familiarity:

~~~text
unknown
neutral
friend
rival
enemy
~~~

Durable bond is social history:

~~~text
none
friend
lover
family
~~~

The approved runtime model is now:

~~~text
family
    authored/pre-existing only

none
    -> earned friend after high relationship threshold

friend
    -> lover only after
       compatibility + player proposal + NPC acceptance
~~~

Family uses only currently real supported kinship producers such as mother/father/sister/brother. Do not expose hypothetical future kinds in the normal harness.

Friend is automatically earned from the existing relationship record. Lover is not automatic: romance eligibility uses the existing gender/orientation/trait/social-profile compatibility logic, then a player proposal and server-authoritative acceptance evaluation.

A durable friend/lover bond may remain while current standing later becomes rival/enemy; this supports estranged-friend/lover dialogue without threshold oscillation.

## Preserve

This job builds on and must not duplicate:

- docs/Jobs/ContextualSemanticSuggestions/
- docs/Jobs/ContextualDialogueQuestFramework/
- docs/Jobs/SemanticDialogueDecoupling/
- docs/Jobs/CoreNPCFoundationMigration/
- docs/Systems/SocialProfiles.md
- docs/Systems/Relationships.md
- existing Starting Companion relationship-kind persistence
- Dynamic Trading's existing provider/conversation ownership

## Read order

1. repository root AGENTS.md
2. this README.md
3. AGENT_RUNBOOK.md
4. AUDIT.md
5. ARCHITECTURE.md
6. BEHAVIORAL_COMPLETION.md
7. SEMANTIC_LAB_CONVERSATION_VISUALIZATION.md
8. SEMANTIC_SIMULATION_UX_AND_CONTEXTUAL_HUB.md
9. RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md
10. NATIVE_TALK_PARITY.md
11. ROADMAP.md
12. HARNESS_ACCEPTANCE.md
13. PROGRESS.md **last** for current truth and the exact Next Chunk

No checked-in GOAL_PROMPT.md is allowed. The executable /goal remains chat-only.
