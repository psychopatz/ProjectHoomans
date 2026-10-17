# /goal — unified semantic dialogue implementation, harness-first

```text
/goal
Repository: psychopatz/ProjectHoomans with dependency psychopatz/psychopatzCore.
Single job: docs/Jobs/SemanticDialogueDecoupling/. Use existing checkout/main, no new branch, PR, TXT file or second goal.
READ AGENTS.md and the job README.md, AGENT_RUNBOOK.md, AUDIT.md, CORE_COMPATIBILITY.md, ARCHITECTURE.md, FLOW_CONTRACT.md, TRANSLATION_MIGRATION.md, ROADMAP.md, HARNESS_ACCEPTANCE.md, PROGRESS.md, USER_LIVE_TEST_HANDOFF.md. IMPLEMENTATION_EVIDENCE.md is historical, not current orders.

CRITICAL USER SCOPE: You IMPLEMENT and TEST using the existing Semantic Lab GUI and real production Lua worker. The USER alone performs final live Project Zomboid SP/MP testing after implementation handoff. Do not start/poll PZ processes, demand apps=[], request Workshop publication, package/upload/republish Steam Workshop mods, or mark goal blocked because game/Workshop is unavailable. A directory named "Workshop" is just the local project location; Git commits are NOT Workshop publishing.

Current source truth: Hoomans has a candidate/flow kernel, identity and wellbeing modules, response plans and EN/TL translation shards. PsychopatzCore GitHub main 44a4d534 now includes ParseCandidates, router candidate/flow hooks and manifest-aware translation registration; confirm local checkout compatibility rather than repeating the stale Core-release blocker. Preserve any local C0B work and unrelated radio assets.

START ONE NEXT CHUNK D0A in PROGRESS.md: examine and repair the EXISTING Semantic Lab GUI/worker production conversation visualization, verifying a real identity→wellbeing→status→identity sequence with selected NPC reply, flow state, EN/TL translation and no erroneous identity/relationship requests. If GUI display unavailable, diagnose and fix source issues, use focused real Lua worker as fallback, leave only GUI verification pending, and keep coding; do not wait on user launching PZ.

Then implement the remaining roadmap phases, one bounded accepted chunk at a time: D1 flow-owned reply selection, D2 third registered flow (no central intent branch edit), D3 usable visual flow browser/editor wired to actual Lua registry, D4 real multi-act EN/TL composition, D5 domain/translation regression, D6 concise USER live-test handoff. Keep original identity regression safe, offline Lua PBrainZ-optional, parser/IR/backwards compatibility, authoritative server actions and bounded state.

Harness is the PRIMARY agent testing guide. Repair it instead of generating redundant JSON fixtures or reporting only passing headless counts. Run focused real production Lua regressions and inspect actual selected text, flow/node, state, action request, translation. Do not claim unexecuted GUI/native tests passed.

Work safely in authorized repositories, preserve dirty work, no force/reset/plain git pull, source commits only where permitted. Update ONE PROGRESS.md with exact tests/SHAs and next chunk. Finish with READY FOR USER LIVE TEST; do not block on native game/Workshop and do not perform final live tests yourself.
```
