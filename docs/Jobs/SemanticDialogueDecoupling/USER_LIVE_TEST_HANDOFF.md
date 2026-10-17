# Final USER-OWNED Project Zomboid live-test handoff

This document is a future checklist, **not an agent task to run Project Zomboid**.

When all implementation chunks and meaningful Semantic Lab checks are complete, Codex should mark `PROGRESS.md` as **READY FOR USER LIVE TEST** and stop; it must NOT mark `blocked` due to `apps=[]` or lack of PZ process.

## Codex handoff output
- Source commit SHAs for Hoomans and Core; note any local uncommitted edits instead of overwriting.
- List actual implemented behaviors and Semantic Lab tests, plus GUI interactions actually verified vs user-pending.
- Known limitations and unresolved failures.
- A short manual test script with expected NPC replies/flow and what diagnostic trace or log to capture if something differs.
- No Steam Workshop publication instruction or approval request.

## Suggested tests for the user, whenever THEY choose
1. In singleplayer with their chosen local mods, NPC requests name -> player asks `are you okay` -> `im fine thanks` -> later supplies a valid name. No false identity penalty or wrong flow.
2. Try healthy/thirsty/injured NPC context and a real follow-up; observe coherent response and next-step behavior.
3. Exercise a newly added harmless third flow; verify it chooses the correct reply without legacy-switch changes.
4. EN/TL language switching/restart; confirm translated reply variants and safe fallback.
5. Two NPCs/group speaker isolation and optional PBrainZ off/on as desired.
6. Multiplayer/SP authority, save/rejoin and performance at a scale the user chooses.

## Responding to user findings
If the user reports a bug, record the precise scenario, source revisions, actual message/trace and a bounded regression Next Chunk; return to development. The agent must never spontaneously poll PZ, request a workshop upload or make its own live-test gating condition.
