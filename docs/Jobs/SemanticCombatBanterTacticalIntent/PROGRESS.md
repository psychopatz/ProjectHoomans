# Progress — Semantic Combat Banter & Tactical Intent

**Status:** ACTIVE — B0–B3 accepted; B4 unified combat-moment context and banter arbiter is next.
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

## B2 accepted — tactical follower encounter intent

Accepted implementation:
- new runtime-only `PNC_SemanticCombatEncounterIntent` owns team `undecided / engage / avoid / hold` state keyed to the current owner/horde episode;
- first eligible follower is the sole prompt spokesperson; additional followers join the same team state without duplicate prompts;
- prompt choices are typed semantic branch offers: `COMBAT_ENGAGE / COMBAT_AVOID / COMBAT_HOLD`;
- branch clicks preserve the active horde event reference as a stale-episode guard and bind `SELF` to the speaking follower without reparsing text;
- actions reuse the existing semantic command adapter and server companion-command authority through transient `combat_engage / combat_avoid / combat_hold` commands;
- stale encounter choices are rejected by the live intent owner;
- permanent `record.attackType` is unchanged;
- owner combat implicitly resolves `undecided -> engage`;
- `avoid / hold / undecided` gate proactive engagement only; immediate self-defense remains before the encounter-intent gate;
- successful tactical command acknowledgements use personality-aware horde ack content: eager/brave may say `Fuck yeah. Let's go.`, shaken may say `Fuck... alright. I'm with you.`, with distinct avoid/hold replies;
- tactical prompt, acknowledgements and choice labels are compiler-owned EN/TL content.

B2 evidence:
- focused prompt/intent/command/companion/follow matrix: **6/6 PASS**;
- full `pnc_semantic` selection: **114/114 PASS**;
- tactical choice localization: EN/TL complete (`Take them. / Sugurin natin.`, `Go around. / Umikot tayo.`, `Hold for now. / Hinto muna.`);
- two consecutive CodeBuilder generations: byte-identical, **180 files / 435 phrase families**;
- changed/untracked Lua through installed Kahlua compiler: **30/30 PASS**;
- static guard: no added ModData root, `getZombieList()`, or `getCell()` hot-path traversal;
- `git diff --check`: clean.

## B3 accepted — non-modal tactical response surface

Accepted implementation:
- closed-conversation tactical prompts project the same lifecycle `offerIDs` through normal `DialogueSuggestions` into a runtime-only headless semantic host;
- compact rows retain canonical typed `semantic_click_frame` payloads and submit through `DialogueInput.SubmitSemanticFrame`;
- transient surface submissions suppress chat transcript/duplicate deterministic-response presentation only; action dispatch remains the existing semantic/companion authority;
- the compact strip is hidden whenever the full conversation for the same NPC is open, leaving the existing Response Channel as presentation owner;
- explicit choice, timeout, authoritative implicit engage and horde clear invalidate the compact prompt;
- server-to-client intent state sync is bounded runtime presentation state only;
- the combat strip is non-modal and does not capture gameplay input.

B3 evidence:
- focused surface/state-sync/tactical/input matrix: **5/5 PASS**;
- full `pnc_semantic` selection: **116/116 PASS**;
- client router/companion/speech/input selection: **3/3 PASS**;
- changed/untracked Lua through installed Kahlua compiler: **14/14 PASS**;
- `git diff --check`: clean;
- static guards: no new `getZombieList`, ModData or routine LLM path;
- native visual/feel gate not run and remains user-owned.

## ONE current Next Chunk — B4

Implement the unified Combat Moment Context + banter arbiter:
1. project one bounded authoritative moment contract for combat speech candidates;
2. feed existing kill coalescing into one arbiter rather than creating a parallel kill throttle;
3. rank urgency/novelty and enforce speaker/family/team chatter budgets;
4. make silence an explicit common result for ordinary repeated kills;
5. let urgent tactical/warning moments outrank ordinary boasts;
6. expose bounded arbiter decision/rejection reasons for later Observatory work;
7. prove bounded fanout with multiple nearby NPCs and burst kills, with no new all-NPC scan, persistence or LLM path.

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

B0–B3 are developer-accepted with focused and broad evidence above. B4–B9 remain mandatory. Native SP/MP visual/feel acceptance has not been run for this job.

Git history is the implementation diary; keep this file as current truth rather than appending per-commit narratives.
