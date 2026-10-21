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