# Unified semantic decoupling agent — operating rules

## Working target and publication
Use the user's **existing authorized Project Hoomans checkout** and verify its actual branch, HEAD, status, upstream, Core dependencies and other agent ownership before any edit. Do not create new feature branches/PRs by default; the user explicitly prefers direct authorized `main` changes. **Direct main publication is permitted only as a safe fast-forward based on a freshly checked expected SHA and applicable repository permissions.** Never force push, destructively reset, stash others' work, create a replacement checkout over working files, or use ambiguous `git pull`.
For changes to **PsychopatzCore**, verify repository-specific permissions and the dependency deployment; this Hoomans goal does not silently grant Core main authorization.

## One goal and concurrency
One `docs/Jobs/SemanticDialogueDecoupling/PROGRESS.md`, one `ROADMAP.md`, one `GOAL_PROMPT.md`. Chapters for parser, flow, translation, authored dialogue and harness all belong to this goal. `docs/Jobs/ContextualSemanticIntelligence` is historical accepted evidence with native checks still open, not this goal's progress ledger. Never spawn competing goal ledgers simply to separate code subsystems.

## Execution loop
Read root `AGENTS.md`, this job's AUDIT/ARCHITECTURE/FLOW_CONTRACT/TRANSLATION_MIGRATION/ROADMAP/HARNESS_ACCEPTANCE/PROGRESS, then actual production code. Execute exactly ONE Next Chunk, using existing modules and preserving the freshly committed identity safety fix. Execute focused real-Lua tests, broader semantic suites and targeted native PZ scenarios where required. Update only this PROGRESS with revision+evidence and one new Next Chunk. Make coherent direct-main commits **only after safe HEAD/status checks and user/repo policy authorization**; if divergent/uncommitted overlap exists, stop and report rather than overwrite.

## Invariants
- Offline Lua first; no PBrainZ requirement for any basic dialogue action; provider may not bypass game authority.
- Parser or flow is never server authority. Keep existing identity, trust, tasks, inventory, MarketSense and MP lease/replay checks.
- Avoid new monolithic policy/translation files, Jess clones, global runtime WordNet scans, full-NPC-tick grammar runs or a second transcript datastore.
- Keep new Flow behavior in bounded small Lua modules, translation in keyed EN/TL fragments, and in-game UI loaded from the Build 42 runtime conventions.
- Never use `pcall`/`xpcall` for normal program logic; follow repository `AGENTS.md`.
- Avoid temporary staging **directories** under live watched `Contents/mods/**/media` trees.
- Never claim CI, native SP/MP or live provider acceptance from a mocked worker, stale report or JSON syntax alone.

## Stop conditions
A proven unsafe divergent checkout, missing required authorization, unresolvable missing dependency/runtime, or required shared-file ownership conflict is a true blocker. Finishing an individual chunk is not a reason to stop the job if mandatory phases remain. After all mandatory gates are evidenced, set maintenance-ready rather than creating more features.
