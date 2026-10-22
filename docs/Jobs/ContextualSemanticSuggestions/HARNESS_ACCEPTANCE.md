# Required real-Semantic-Lab acceptance
Use the EXISTING tools/semantic_harness production Lua worker, Tk workflow, CodeBuilder, inspector and scenario editor. A JSON schema checker, Python mock, isolated fake Lua evaluator, or CLI fixture alone cannot close this goal.
## Required scenarios
1. Player types 'Are you okay?' -> topical suggestions; NPC reports tired/injured -> different relevant follow-ups. Verify semantic input and response-plan source separately.
2. Identity flow awaiting name; wellbeing interruption -> flow-specific suggestions with correct suspend/resume, no misclassified name claim or false relationship adjustment.
3. FOLLOW/STAY/WAIT_AT clickable buttons -> same approved dispatcher outcome as typed command; denied/negated/stale do not dispatch; WAIT_AT unresolved slot clarifies.
4. Relationship trust/affection boundary immediately below/equal threshold; trait true/false/unknown; unsupported provider; NPC busy/hostile; player inventory available/unavailable -> correct visible/disabled/hidden traces.
5. Romance/social options: compatible/incompatible/unknown adult participants with relationship and consent validation; no assumptions based on lone 'gay' trait; no private-data leakage to player UI, dossier, PBrainZ or client diagnostics.
6. Knowledge fact unknown/suspected/authorized-disclosed -> no secret button preview; no label/tooltips revealing a secret; harness privileged traces separate from player output.
7. EN and TL from actual translation manager, including code-switching, localized generated utterances, missing-key diagnostics, and no unintended English normal-path fallback.
8. NPC switch, stale turn, repeated click, simultaneous/MP-intended requests -> no cross-NPC action, duplicate command, item transfer, relationship change or authorization bypass.
9. Real Tk UI (Xvfb permitted) visibly renders actionable suggestions and edited scenario reproduces changed output. Clicking button actually advances worker and transcript. Verify generated Lua/translation assets land in the actual mod media directories.
10. Baseline/performance: bounded candidate count, predicate evaluations, latency and trace bytes; no every-tick parsing or unnecessary ModData growth.
Record run command, repository SHAs for Hoomans+Core, actual case, raw input, selected IR/plan, candidate list, predicate trace (privileged only), projected buttons, click semantic, response/result, test totals, errors and artifacts. Label native SP/MP NOT TESTED until user runs it.

## Recorded developer acceptance — 2026-10-22

- Hoomans checkout: `main`, commit `a390bdb0`; Core checkout: `main`, commit `ba60095`. Both were verified clean after commit. No push or Workshop/release action was taken.
- Initial worker projection exposed production root candidates grouped into topic, conversation-action, conversation-utility, and owned-companion groups. The visual UI kept five rows per selected group while the inspector retained the bounded projection.
- Real worker interaction: `conversation.root:menu:projecthoomans:whats_up` was clicked and entered the authored `ConversationBlock`; a root goodbye action queued the existing response; duplicate root replay was rejected; hostile/neutral profile changes did not expose owned-companion actions. EN/TL labels resolved through the existing translation manager.
- Xvfb `test_contextual_suggestions_s4` passed 4/4, including visual rendering, inspector access, real root click transition, NPC profile switching, responsive 1080x700 layout, and runtime control visibility. The UI readiness gate prevents submission before the initial worker projection is painted.
- Full headless Python discovery passed 320 tests with 5 expected GUI skips. Relevant production Lua smoke tests passed 22/22. Doctor required checks passed; changed PZ Lua Kahlua lint with `--severity=ERROR --luac` reported no issues; JSON/Python/Lua syntax and `git diff --check` passed. Bounded worker performance used 3 samples, 1 warmup, and 12 serial turns; sequence and event bounds held.
- Native Project Zomboid SP/MP, actual in-game installation, server authority, and multiplayer behavior remain **UNTESTED** and are reserved for the user. Handoff: **READY FOR USER LIVE TEST**.
