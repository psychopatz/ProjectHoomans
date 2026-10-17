# Codex operating runbook — Contextual Dialogue & Quest Framework

## Ownership and authorization

This is a NEW goal under docs/Jobs/ContextualDialogueQuestFramework/. Do not rewrite the SemanticDialogueDecoupling or ContextualSemanticIntelligence roadmaps/progress ledgers as a shortcut. Their historical observations remain separately attributable. The user owns real Project Zomboid singleplayer/multiplayer live tests and all Steam Workshop publishing decisions. A local directory named Workshop does NOT authorize uploading.

Source edits and production-Lua Semantic Lab tests are normal development work when repository/branch authority and working-tree safety permit them. Do NOT run Project Zomboid, start/stop/poll its process, run MP servers, use steamcmd, upload Workshop content or present headless tests as native PZ acceptance. Missing GUI desktop automation is not automatic "blocked"; use a direct UI launch/click test where safely available and preserve untested labels otherwise.

## Repository and parallel-agent discipline

1. Inspect actual checkout, branch, HEAD, remote/upstream, status and open work before any write. This planning commit was authored against remote main a3eb2e4; it does NOT prove any local checkout is clean or equal. Verify the job documents are in the chosen working checkout before starting; do not assume the planning branch has merged.
2. Preserve unstaged/staged/untracked/user edits, unrelated radio/image assets, JSON fixtures and other agents' work. Never stash/reset/force-push/rebase uncertain changes, use ambiguous git pull, or destroy another agent's branch.
3. Scope production changes to one vertical slice at a time. If shared files are concurrently owned, coordinate before editing. Do not duplicate or replace existing Core/Conversation/Quest mechanisms on speculation.
4. Follow root AGENTS.md: executable PZ B42.20 Lua in the versioned media tree, portable authored definitions/translations in common/media. Never stage transient directories inside a running mod's watched media tree. No routine pcall/xpcall; only documented external callback boundaries.
5. Do not modify PsychopatzCore, MarketSense, PBrainZ or other repositories without independently verifying need, authority and their current state. Reuse public API boundaries.

## Autonomous development loop

1. Read PROGRESS's single Next Chunk and compare its baseline to current source; update evidence if HEAD has moved.
2. Implement that chunk rather than writing another vague plan. Audit a claimed existing feature before adding or replacing it. Preserve stable public parser/IR, presentation, translation and networking contracts.
3. Exercise the **real production Lua worker** through Semantic Lab. Inspect input, IR/candidates, context projection, selected gate + reason, flow transition, rendered response, effects, transport and LLM calls. A valid JSON object, pretty graph, isolated Python graph test, or conflict-free ledger alone is NOT product acceptance.
4. Run focused regression tests, syntax/Kahlua checks when Lua changed, and harness doctor/smokes where feasible. Test meaningful behavior with PBrainZ disabled, unknown facts and denial cases. Test GUI interaction where a display is available; record not-run otherwise.
5. Update only this job's PROGRESS current state and ROADMAP gates as evidence changes. Link real commits/test artifacts. Keep stable contracts in ARCHITECTURE/other design documents; do not duplicate diaries across documents.
6. Finish one Next Chunk, publish coherent code/docs only to an already authorized exact destination, then select the next bounded chunk from the roadmap. Stop for genuine conflicts or maintenance-ready completion.

## Invariants

- Client input/preview cannot grant rewards, mutate quest truth, inventory, relationship, NPC health, or memory commitments. Authoritative server commands revalidate all conditions at commit.
- Missing/unknown world facts cannot be assumed true; player claims are not authoritative quest completion evidence; one NPC must not inherit another NPC's knowledge.
- No second lexical parser or free-form Lua execution from an editor draft. No new per-tick full-population NLP/quest scan. Cache and dirty invalidation must be measured and explicit.
- Offline Lua is the baseline. PBrainZ is optional and cannot override deterministic authorization.
- Preserve EN/TL translation fallbacks and group participant isolation. Never store entire chat transcripts indiscriminately as NPC ModData.

## Stop conditions and reporting

Use blocked only for unsafe parallel worktree divergence, unavailable essential source/toolchain with no accepted fallback, proven missing capability or authorization. GUI automation absence, native PZ unavailability, Workshop publication, and normal test fixes are not blockers. When complete, mark implementation READY FOR USER LIVE TEST and provide a concise manual SP/MP test handoff; do not call native acceptance passed. Report exact branch/SHA, changed behavior, actual test results, skipped verification, known limitations and one Next Chunk or maintenance-ready.
