# Agent runbook — Contextual Dialogue & Quest Framework

## Purpose / permitted work

Execute the ONE Next Chunk in `PROGRESS.md` autonomously with repository-safe, small source/test/documentation commits, using actual Semantic Lab's production Lua worker as the primary behavioral evidence. Keep one goal; do not start a new roadmap for every correction. This job now prioritizes *complete procedural semantic interactions* over more attractive graph visuals, synthetic fixture churn or documentation-only "progress."

**Developer work authorization ≠ native release authority.** Source editing, syntax/test runs and existing real-Lua Semantic Lab authoring/debugging are permitted after safe checkout verification. The user alone runs Project Zomboid SP/MP live acceptance and makes Workshop publish/republish/upload/install decisions. Never start/poll PZ, run MP hosting, use steamcmd, upload or claim game acceptance. Absence of a native UI/process does not block developer work.

## Read and act

1. Inspect actual checkout, branch/HEAD/upstream, status, shared file owners and linked Core revision. Remote `382e93a3` audit is a checkpoint, not proof of local cleanliness. Preserve staged/unstaged/untracked assets, unrelated work and other-agent branches; never force push, reset or stash uncertain work; no ambiguous `git pull`.
2. Read root `AGENTS.md` and all job docs in `README.md` read order, ending with `PROGRESS.md`. Select ONE bounded Next Chunk; implement it rather than endlessly re-audit or rewrite plan. Follow current Build 42.20 vs common/media placement, Kahlua restrictions and translation conventions. Never put generated deliverables solely in `tools`, temp JSON or an uncommitted asset directory.
3. Reuse published production contracts. Core parses language; Hoomans owns policy/flow/context; domain command/task/gift/inventory/Quest services own effects; no new generic parser, runtime scripting VM, duplicate dispatch or parallel quest/task engine. No arbitrary code executed from graph editor, copied raw functions in compiler definitions or insecure client-side reward claims.
4. Test a *real end-to-end production Lua behavior* each chunk: specific input → selected pattern/IR → eligible gate/flow → actual adapter + mock-authority result (when action) → NPC text/translation and side effects. Include useful negative cases. Save/reload generated source where phase requires; GUI click-through when environment available. Python-only graph/unit tests and JSON conflict ledgers supplement, never replace this.
5. Run focused command/flow tests, compiler tests when changed, worker doctor, syntax/Kahlua checks, translation validation and `git diff --check`. Report tool and exact outputs, skipped gates and source revision. Don't waste quota generating dozens of redundant JSON fixtures when a small real-Lua scenario is more diagnostic.
6. Update **only this job's `PROGRESS.md`** as live phase ledger, edit `ROADMAP.md` only at meaningful transitions, keep architecture contracts in dedicated files. When chunk accepted, select precisely one next chunk. Do not modify historical `SemanticDialogueDecoupling` or `ContextualSemanticIntelligence` records.

## Crucial safety and error policy

- Action trigger catalog ≠ action binding ≠ authorized dispatch ≠ actual completion. Simulator must never claim success just because it chose a response pool. No synthetic-success camouflage.
- Preview has zero commands/effects and does not consume pending dialog. Committed action uses existing approved dispatcher, exact identity/target/session, relevant capability and server-side authorization, with correlated result. Unresolved/negated/question/ambiguous command fails closed; duplicate messages never cause unbounded repeated effects.
- Engine fact/event bus remains observational; server owns gameplay truth. Unknown facts never unlock sensitive actions; NPC cannot know events or promises without source evidence. Reuse existing Social, Personality, Memory, Conversation Blocks and Inventory owners.
- PBrainZ optional, not default. Avoid per-frame population-wide polling, huge ModData transcripts, unsafe WordNet expansions and generated monoliths. Keep generated Lua load order explicit and checksum/diff reproducible.
- Coordinate if another agent owns target files or remote branch advanced; a real unsafe conflict is a blocker, not justification for stomping local user work.

## Completion and reporting

Report: exact repo branch SHA, modified canonical source files, production Lua input/IR/actual response/command/authority results, test commands and outcomes, limitations, GUI status, current PROGRESS Next Chunk. Never say native PZ SP/MP passed or use Workshop publication to satisfy a goal gate. Once development acceptance gates pass and no mandatory chunks remain, record **READY FOR USER LIVE TEST** and stop; user performs live acceptance independently.
