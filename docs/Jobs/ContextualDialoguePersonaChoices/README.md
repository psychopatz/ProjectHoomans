# Contextual Dialogue Persona & Choices

**Status:** REOPENED — behavioral completion required.  
**Current source-audit baseline:** ProjectHoomans remote main at 849f1951ed1d3fd4b6f78aedc2525b25368a157e (2026-10-22).  
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

The current goal is therefore **behavioral completion**, not another architecture rewrite.

## Companion bond requirement

Project Hoomans already persists detailed starting-companion relationship kinds such as:

- friend
- lover
- mother
- father
- sister
- brother

Dialogue must preserve the detailed kind while deriving only three coarse speech classes:

~~~text
friend
family
lover
~~~

Current mapping:

~~~text
friend                     -> friend
lover / partner / spouse   -> lover
mother / father
sister / brother
future cousin / aunt /
uncle / grandmother /
grandfather / etc.         -> family
~~~

The detailed kind is not replaced. It supplies localized relationship terms such as Mom, Dad, sister, cousin, or future terms. Family speech uses generic family realization templates plus localized term substitution so a new kinship type is data/translation registration rather than a new dialogue engine branch.

Bond is independent of current directed standing. For example:

~~~text
bondClass = family
bondKind  = mother
relationship.state = enemy
~~~

is valid: the NPC is still the player's mother, but currently hostile/estranged. Bond selects intimacy/kinship vocabulary; directed standing/personality/situation selects warmth, hostility, openness, deference, and other tone.

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
7. ROADMAP.md
8. HARNESS_ACCEPTANCE.md
9. PROGRESS.md **last** for current truth and the exact Next Chunk

No checked-in GOAL_PROMPT.md is allowed. The executable /goal remains chat-only.
