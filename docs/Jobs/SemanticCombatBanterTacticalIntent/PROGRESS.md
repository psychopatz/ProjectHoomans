# Progress — Semantic Combat Banter & Tactical Intent

**Status:** ACTIVE — B0–B5 accepted; B6 hostile-human kill commentary is next.
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

## B4 accepted — unified Combat Moment Context + banter arbiter

Accepted implementation:
- new `semantic.combat.moment.v1` is the bounded runtime contract shared by horde/tactical awareness and kill chatter;
- the moment carries event/actor/target/outcome, pressure, mood/style/relationship, encounter, attack/weapon slots, burst, urgency/priority and presentation class while forcing routine `llmEligible=false / memoryEligible=false`;
- one `CombatBanterArbiter` now owns burst stream coalescing, speaker cooldowns, semantic-family cooldowns, team/audience priority holds and speaker budgets;
- the former per-record `runtime.semanticCombatReaction` throttle and separate awareness-player cooldown registry are retired from production decision logic;
- rapid kills still coalesce before the spatial witness query;
- tactical/horde warnings share the same arbiter and can suppress lower-priority ordinary kill boasts for the same player;
- silence is explicit and explainable through bounded decision reasons such as `stream_cooldown`, `speaker_cooldown`, `higher_priority_active` and `team_budget`;
- arbiter runtime maps and recent decision trace are bounded.

B4 evidence:
- focused arbiter/kill/profile/horde/social matrix: **7/7 PASS**;
- full `pnc_semantic` selection: **117/117 PASS**;
- changed/untracked Lua through installed Kahlua compiler: **6/6 PASS**;
- existing player-kill fanout test still proves one spatial NPC query, max two speakers and pre-query coalescing;
- static scan finds no production `semanticCombatReaction`, `PlayerReactionState`, `reserveAwarenessPresentation` or `recentAwarenessByPlayer` throttle remnants;
- `git diff --check`: clean.

## B5 accepted — weapon/action-aware zombie kill banter

Accepted implementation:
- authoritative zombie resolution forwards the exact hit `weaponItem`, `weaponFullType`, attack type/kind, body part and wound type to the semantic kill service;
- one runtime `CombatWeaponContext` reuses existing `Skills.ResolveWeaponSkill / GetLevel` and performs no inventory/world scan or item creation;
- normalized families cover firearm, short/long blade, axe, spear, short/long blunt, unarmed and unknown/other melee;
- bounded skill bands and hit zones support grounded selection; blade teeth/gore variants require an actual head/neck result;
- safe actual display names are optional flavor only, reject module-qualified IDs, and are substituted before presentation;
- high-skill firearm confidence and low-skill shaken/relief variants are distinct;
- unknown/modded weapons degrade to existing generic safe fallbacks;
- 26 new EN/TL weapon-aware phrase families live in a dedicated `combat_banter` CodeBuilder ownership domain after the existing `event` index correctly rejected further growth;
- internal weapon provenance may remain in the bounded combat moment for diagnostics, but raw full-type IDs are never used as visible weapon names.

B5 evidence:
- focused weapon context/selection/service/resolver/boundary/catalog matrix: **6/6 PASS**;
- full `pnc_semantic`: **119/119 PASS**;
- new combat-banter content: **26/26 EN+TL**, including bounded weapon-name token coverage;
- two consecutive CodeBuilder generations: byte-identical, **184 files / 461 phrase families**;
- changed/untracked Lua through installed Kahlua compiler: **16/16 PASS**;
- no new global zombie scan, routine persistence or LLM path;
- `git diff --check`: clean.

## ONE current Next Chunk — B6

Implement hostile-human NPC kill commentary:
1. emit one authoritative semantic combat moment when an NPC kill transitions a hostile human NPC to dead;
2. pass the same actual weapon/action context through `CombatWeaponContext`;
3. keep existing death/faction/social side-effect owners unchanged and exactly-once;
4. route human-kill semantics to distinct content families that cannot select zombie-only gore wording;
5. use grounded personality/relationship/faction context only when already available;
6. keep routine human-kill chatter transient, non-LLM and non-memory;
7. prove zombie and hostile-human kill families remain distinct and no duplicate death/relationship/faction mutation occurs.

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

B0–B5 are developer-accepted with focused and broad evidence above. B6–B9 remain mandatory. Native SP/MP visual/feel acceptance has not been run for this job.

Git history is the implementation diary; keep this file as current truth rather than appending per-commit narratives.
