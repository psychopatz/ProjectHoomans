# Semantic Dialogue Decoupling — current agent progress

**Updated:** 2026-10-17. **State:** ACTIVE — implementation and Semantic Lab repair. **Current phase:** D0. **Do not mark blocked for native game or Workshop.** One unified progress ledger.

## New source audit (connected GitHub; no local worktree assumed)
- Project Hoomans remote main before these docs: `56288e50e6d782634df7f26ceaa0f0cb7c0922f9`.
- PsychopatzCore remote main: `44a4d534a9520440070ae7943d7ae9fb848f71ce` **now contains** Core `Parser.ParseCandidates`, candidate/router hooks, and manifest-aware `scope.registerSystem`. The old `0212491d`-based Core-blocker language is superseded.
- The user's Codex transcript reports a local Hoomans commit `27e1fd94` and absent PZ process/Workshop authorization. Connected GitHub main did not contain that commit at this audit point; it is local/agent-report evidence. **Do not lose or overwrite it.**
- Hoomans code already includes candidates, flow registry/kernel, identity/wellbeing modules, response plan and 12 EN/TL shards. Actual desired flow response ownership/visual flow authoring remains incomplete.
- Historical tests reported Python 97/97, targeted Lua 68/68; 12 full-headless failures (native/UI related) and a Core legacy catalog-count mismatch. Not independently rerun. Semantic Lab's user-facing usability is not accepted and must be addressed.
- **User final live test:** pending by design. **Steam Workshop distribution:** not requested and forbidden to this agent. **PZ process:** optional/irrelevant to agent progress.

## ONE Next Chunk — D0A: restore useful Semantic Lab visual/production conversation loop

1. Inspect both actual local Hoomans/Core HEADs, status and compatible APIs; explicitly preserve all uncommitted work, including radio asset project JSON. If the reported local C0B handshake/detailed steps exist, retain them as evidence but **remove the false native/Workshop prerequisite from the active ledger**. Do not trigger any deployment operation.
2. Run/inspect the existing Semantic Lab **GUI + Lua worker** from its intended entry point. Identify its actual failure modes: startup/config, module load, scenario-to-real-NPC projection, transcript/replies, candidate/flow/translation trace, controls and render. Capture exact code/stack error or missing information; don't assume everything is broken.
3. Repair one coherent vertical slice of **existing** harness GUI/worker so it can show one full identity -> wellbeing -> status -> identity response conversation with real production Lua selected **displayed text**, flow and translation context, and absence of unintended identity request. If GUI cannot launch in current Codex desktop, fix source-proven issues, run focused real Lua worker, and document a short user-runnable GUI check; don't wait/poll for an app.
4. Add focused regression only for specific corrected production/harness behavior. No JSON-only fixture campaign, no new synthetic NLP implementation, no unrelated asset/radio edits.
5. Update this PROGRESS with exact paths, Hoomans/Core SHA, actual UI/worker tests and failures; next single D0B integration/GUI repair chunk if still needed, otherwise D1 flow reply authority. **Continue automatically; no PZ required.**

**D0A exit:** the existing harness is a meaningful observable guide to production Lua conversations, with known GUI limitations clearly recorded. No native SP/MP or Workshop action required.

## Roadmap
D0 harness and source compatibility -> D1 flow-selected replies -> D2 third flow -> D3 visual flow editor -> D4 real composition -> D5 EN/TL/domain regressions -> D6 user handoff. Completion state is `READY FOR USER LIVE TEST`, not `blocked` for unavailable native PZ.

The historical `IMPLEMENTATION_EVIDENCE.md` preserves previous phase claims; do not overwrite it just to reset the task count.
