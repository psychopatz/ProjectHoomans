# Progress — Semantic Combat Banter & Tactical Intent

**Status:** ACTIVE — B0 and B1 accepted; B2 tactical follower encounter intent is next.
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

## B1 accepted — canonical horde episode/routing

Accepted implementation:
- `PNC_ZombieObservation` is the sole semantic horde transition caller and observes both above/below threshold from the existing Perception frame;
- follow/combat behavior no longer independently emits semantic horde events;
- horde runtime state is edge-driven: `started / stable / escalated / deescalated / cleared`;
- stable hordes stay silent regardless of elapsed presentation cooldown;
- a new episode is possible only after a real clear;
- runtime `zombie_horde_encounter` and legacy `zombie_horde_detected` route through `semantic.combat.horde`;
- horde start/escalation/de-escalation/default have authored EN/TL content and grounded location/quantity/happened offers.

B1 evidence:
- focused B0/B1 + social/follow/combat matrix: **6/6 PASS**;
- full `pnc_semantic` selection: **111/111 PASS**;
- horde content: **4/4 EN+TL**, non-identical translations;
- two consecutive CodeBuilder generations: byte-identical, **180 files / 419 phrase families**;
- changed/untracked Lua through installed Kahlua compiler: **15/15 PASS**;
- `git diff --check`: clean;
- no new global zombie scan.

## ONE current Next Chunk — B2

Implement runtime-only follower tactical encounter intent:
1. add a bounded current-horde intent owner with `undecided / engage / avoid / hold`, separate from permanent `record.attackType`;
2. bind intent to the active horde episode and clear it when that episode clears;
3. choose at most one eligible follower spokesperson for the unresolved prompt;
4. expose semantic engage/avoid/hold offers through the existing response-plan/click authority;
5. let owner attack behavior resolve `engage` implicitly and clear stale prompt state;
6. preserve immediate self-defense regardless of intent;
7. add personality-aware acknowledgement strategy after engage/avoid/hold without blocking combat.

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
