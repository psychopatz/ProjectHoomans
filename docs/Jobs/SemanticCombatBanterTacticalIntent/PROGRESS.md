# Progress — Semantic Combat Banter & Tactical Intent

**Status:** ACTIVE — B0 characterization accepted; B1 horde episode/routing implementation is next.
**Planning base:** ProjectHoomans `8632bc30`, existing `main`.
**Parent foundation:** `docs/Jobs/OpenEndedSemanticCombatAwareness/` is developer-complete and remains accepted unless this job reproduces a regression in an owning layer.
**Native PZ:** user live regression supplied; new job's developer implementation/acceptance not yet run.

## Current verified truth

The new job is justified by current production/runtime evidence:

- live `social:zombie_horde_encounter` can realize through generic `semantic.combat.reaction.default`, producing the wrong line `Good work. Keep watching the area.`;
- the actual zombie-kill semantic path is separate and can select a kill-specific line such as `Good kill. Don't let up.`;
- horde episode observation can re-present a still-active encounter because the semantic clear transition is not reliably owned by current above-threshold callers;
- kill reactions already support grounded transient follow-ups, but combat/event response families are not uniformly classified as interactive vs autonomous/terminal;
- semantic response buttons are primarily tied to the open conversation surface; there is no general non-modal combat tactical-choice renderer;
- follower behavior already owns permanent `attackType`, owner-engaged state, self-defense, retreat and horde handling, but has no current-encounter `undecided/engage/avoid/hold` team intent;
- CombatResolution already has authoritative weapon item/full type, attack type, wound/body-part and kill state;
- Equipment/Firearms/Skills already classify firearm/melee family and weapon skill;
- the current NPC zombie-kill reaction call drops most of that weapon/action context;
- hostile-human NPC kills do not yet use an equivalent semantic combat-commentary path;
- there is no single general combat-banter arbiter across warnings, tactical prompts, kill boasts and silence.

## Required product behavior

The target is active co-op gameplay banter:

- NPCs speak while acting; they do not wait for the player to conduct a chat exchange;
- routine combat remarks are non-blocking `BARK`s;
- real tactical uncertainty is a `TACTICAL_PROMPT` with semantic choices;
- followers may ask whether to engage a horde when team intent is unresolved;
- player action can answer implicitly;
- trait/personality/mood affects enthusiasm, hesitation, profanity and terseness without one-trait stereotypes;
- NPC kills can comment on actual weapon/skill/body-part context;
- hostile-human kill commentary is distinct from zombie commentary;
- silence is common and valid.

## B0 accepted baseline

B0 regression/ownership characterization is recorded in `B0_BASELINE.md` and passes **3/3** focused Lua tests. It proves the live wrong-horde fallback, stable-horde re-open bug, missing semantic clear owner, active-conversation-only offer projection, absent presentation-class contract, and dropped weapon/action kill context.

## ONE current Next Chunk — B1

Implement canonical horde episode/routing:
1. make `PNC_ZombieObservation` the single semantic horde-observation caller and deliver both above- and below-threshold observations;
2. remove duplicate semantic horde calls from follow/combat behavior while preserving their gameplay threat logic;
3. make `ObserveZombieHorde` edge/episode driven with explicit start, material escalation/de-escalation, stable and clear outcomes;
4. route runtime `zombie_horde_encounter` into a dedicated horde semantic pool with correct EN/TL content and grounded quantity/location follow-ups;
5. keep stable hordes silent and add focused regression/scan guards.

## Remaining mandatory phases

B0 baseline -> B1 horde episode/routing -> B2 team tactical intent -> B3 non-modal combat choice -> B4 moment context/arbiter -> B5 weapon-aware zombie kills -> B6 hostile-human kills -> B7 content/branching standardization -> B8 observability -> B9 broad acceptance.

## Hard constraints

- no new global zombie scanner;
- no parallel combat or dialogue authority;
- no routine combat ModData/transcript;
- no per-kill LLM;
- no permanent `attackType` mutation for a temporary horde choice;
- no hand-edited generated Conversation Lua;
- no Workshop publication;
- native SP/MP acceptance remains user-owned unless explicitly reassigned.

## Evidence status

Planning/audit only at this revision. No B0–B9 gate is accepted yet.

Git history is the implementation diary; keep this file as current truth rather than appending per-commit narratives.
