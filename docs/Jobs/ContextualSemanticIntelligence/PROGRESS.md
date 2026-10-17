# Contextual Semantic Intelligence — current progress

**As audited:** 2026-10-17. **Phase:** 0 — Semantic Lab correctness baseline. **State:** planned; implementation not started. **Evidence:** static GitHub source audit only.

## Revision identity

- Project Hoomans main source audit: `c96cadda1570f59810552f9d3fc55d5c957ba670`.
- PsychopatzCore main source audit: `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`.
- PBrainZ main source audit: `43cc879e673d8d0494d7e77b4ade28fd20a6d4c4`.
- No claim about any local worktree. Semantic Lab, Lua and Project Zomboid were **not run** in this audit. GitHub Actions runs result was empty; no CI pass claimed.
- Job planning docs are distinct from tested code. Read the latest HEAD before coding.

## Accepted existing code foundation (source-verified only)

- Parser/IR/policy and guarded deterministic route exist.
- Wellbeing, social and situational response pools with contextual conditions exist.
- Bounded dialogue/mentions/pending requests and select follow-up behavior exist.
- Offline WordNet compiler and common interaction source exist.
- Semantic Lab persistent Lua worker, production module loader, scenario replay, output trace, conflict ledger and unittest/smoke framework exist.

These are **implemented in code**, not fully accepted by live Project Zomboid test.

## Outstanding gaps

- Semantic Lab wellbeing context currently hardcodes healthy/idle and sources NPC needs from scenario.world.
- Replay conflict-free status is not a semantic behavior assertion.
- No recorded exact-HEAD Semantic Lab baseline for healthy/injured/thirsty/unknown wellbeing dialogue.
- Contextually distinct reaction behavior and multi-turn wellbeing follow-up not proven by real worker.
- Native SP/MP and performance acceptance outstanding.

## One Next Chunk (mandatory): Phase 0A — realistic harness wellbeing projection

1. Inspect current Semantic Lab `scenario.py`, `lua/worker/Conversation.lua`, production situation/context projection and related tests. Record existing case behavior and whether schema already supports fields under `npc`.
2. Implement the smallest necessary fixture/context changes to vary **NPC** healthState, activeBehavior, needs, conditionStats and relationship through existing production contracts, retaining compatibility with current world-level mock defaults. Do not hardcode expected semantics in worker.
3. Add explicit test assertions using real `LuaSemanticWorker`: actual module loaded; different scenario values enter the production decision path; trace/IR/response/context available; zero LLM usage; no unintended tool or transport side effects. Record baseline shortcomings honestly — do not implement new reaction policy in this chunk.
4. Run Semantic Lab doctor, targeted real-worker unittest, existing Lua semantic tests and conflict replay. Report Lua availability and any missing native game evidence.

**Exit gate:** Harness can genuinely represent and trace at least healthy, injured, urgent thirst and unknown/missing-state cases without rewriting the NPC's reality. Tests assert real Lua outputs and preserve historical behavior. If a scenario input is unsupported, document exactly which adapter prevents it. Phase 0B becomes Next Chunk only after 0A passes.

## Subsequent work

0B baseline matrix -> Phase 1 wellbeing reaction -> Phase 2 multi-turn continuity -> Phase 3 social reactions -> Phase 4 reviewed paraphrases -> Phase 5 optional PBrainZ/groups -> Phase 6 live-game SP/MP and performance.

**Publication status:** Job docs are being prepared; code not modified by this planning step. Future agent updates must replace this statement with actual revision evidence.
