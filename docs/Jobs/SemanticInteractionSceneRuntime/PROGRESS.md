# Progress — Semantic Interaction Scene Runtime

**Status:** DEVELOPER COMPLETE — S0–S8 accepted; READY FOR USER LIVE TEST.
**Branch:** existing main.
**Planning anchor:** ProjectHoomans `47aaad69`.
**Implementation head before final S8 commit:** `9231b6a1`.
**Current phase:** developer acceptance complete.
**Next authority:** user-owned native Project Zomboid SP/MP timing/readability verification only. Reopen the smallest owning phase if live evidence contradicts an accepted invariant.

## Final developer acceptance — 2026-10-29

The parent developer objective is complete:

- production managed NPCs enter the same normalized InteractionProviders contract as synthetic actors without a second actor/social database;
- one global Scene Runtime/Scheduler owns autonomous multi-actor lifecycle, caps, TTL, actor loss and LOD;
- NPC continuation is semantic-plan/behavior driven and never reparses rendered dialogue;
- player conversation and autonomous Scenes share Director semantics while retaining their appropriate frontends;
- recipient, participant and observer roles are explicit; observer-only players receive no affordances or resume token;
- Opportunity providers are bounded, event-driven and ranked by proposal priority before the final top-K cap;
- combat, grounded social knowledge and community excursion are real production adopters of the same runtime;
- the Scene Observatory and Semantic Harness expose bounded read-only admission/participant/turn/grounding/continuation/LOD diagnostics without transcript text;
- a synthetic fourth domain adopts through public Catalog/Opportunity seams with no SceneRuntime, Director, Scheduler or generic-continuation conditional;
- routine autonomous Scene state stays transient: no new ModData root, transcript, generated-choice, InteractionPlan, reasoning-trace or routine LLM persistence path.

## S8 extensibility and scale evidence

- synthetic fourth-domain `TASK_EVENT` resolves prompt → semantic continuation → acknowledgement/termination through public behavior registration plus Opportunity admission;
- generic core files contain no synthetic-domain/provider conditional;
- Opportunity evaluates all bounded registered providers and retains only the best bounded proposals, so a later urgent proposal cannot be starved by earlier low-priority registration order;
- the existing admission policy remains one policy: proposal priority for the current event, active-key/cooldown suppression and one global Scheduler capacity; no second preemption scheduler was introduced;
- 20 burst events admit exactly the configured 16 simultaneous Scenes and reject the overflow;
- a synthetic unrelated registry of 1,000 records is never scanned;
- four explicit participants create one Scene, not six pairwise sub-scenes;
- TTL expiry, turn-limit closure and actor death/leave produce explicit compact closure reasons;
- distant/unperceived Scenes execute semantic-only with one Director decision and no speech/emote/flavor realization;
- audience remains capped at eight and fanout reuses the already-selected semantic turn;
- same-owner followers form a combat cohort even across different faction IDs;
- same-faction cohort selection is role-agnostic, so faction/raider/neutral teams are not made player-dependent;
- solo combatants reject group-scene admission with `scene_horde_no_local_teammate`;
- static guards reject polling hooks, full-NPC/global-zombie scans, rendered-text reparsing, autonomous Scene ModData, routine LLM opt-in and transcript/rendered-text storage.

## Final verification

Latest final acceptance on the S8 completion slice:

- S8 extensibility/stress Lua: **1/1 PASS**;
- S6 production-adopter + S8 stress matrix after cohort-edge additions: **2/2 PASS**;
- full isolated Lua suite after final test changes: **944/944 PASS**;
- focused semantic/dialogue/conversation/player regressions: **188/188 PASS**;
- real worker Scene/Combat Observatory + S8 acceptance: **7/7 PASS**;
- source/save immutability acceptance: **10/10 PASS**;
- content/translation + worker Observatory targeted matrix: **7/7 PASS**;
- deterministic CodeBuilder double generation: **190 files / 493 phrase families / 54 patterns / 10 UI definitions**, byte-identical including EN/TL Conversation translations;
- S8/S6 completion Lua through installed Project Zomboid Kahlua compiler: **3/3 PASS**;
- S8 Python module `py_compile`: PASS;
- `git diff --check`: PASS.

## Native handoff

No native Project Zomboid instance was launched for developer acceptance.

User-owned SP/MP verification should focus on:

- horde episode timing and whether brave/cautious/steady dialogue reads naturally under combat pressure;
- NPC team conversation for followers, neutral/faction/hostile groups and the no-partner solo case;
- observer-only players hearing NPC↔NPC speech without buttons;
- addressed players receiving relevant existing semantic choices and resuming the exact Scene;
- grounded NPC news never claiming facts the speaker does not know;
- excursion phase chatter not mutating excursion gameplay state;
- no noticeable duplicate-scene spam, long combat hitch or abnormal save growth.

If live evidence fails, use the Scene Observatory to identify provider/admission/participant/behavior/continuation/presentation ownership and reopen only that layer.

## Safety

No Workshop publication, new Git branch, native game launch, source-save mutation, new autonomous-scene persistence store, transcript persistence, routine LLM path, feature-specific conversation engine or global polling scan was used for developer acceptance.
