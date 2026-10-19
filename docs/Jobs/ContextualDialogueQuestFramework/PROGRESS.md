# Contextual Dialogue & Quest Framework — current progress

**S0A update (2026-10-19):** The existing semantic compiler is now embedded
under `tools/semantic_harness/codebuilder/`. Its reviewed JSON inputs remain
single-source under `tools/semantic_compiler/`; the legacy Python modules are
thin compatibility wrappers. Semantic Lab authoring and headless authoring
operations use the embedded CodeBuilder, with no second compiler, writer, or
runtime interpreter.

S0A evidence:

- `python3 -m unittest discover -s tools/semantic_compiler/tests -p 'test_*.py' -q` — **15/15 passed**.
- `python3 -m unittest tools.semantic_harness.tests.test_codebuilder_consolidation -v` — **5/5 passed**, including legacy/embedded API identity, dialogue and semantic writer parity, checked-in generated Lua/manifest bytes, and headless CLI/GUI routing.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **184/184 passed**, including actual Lua-worker conversations and authoring/worker restart tests.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures** in gift/inventory/local-route/state-response behavior; no Lua source changed in S0A, and the failures match the documented baseline rather than being promoted to green.
- `git diff --check`, Python compilation, direct and module legacy build `--help`, and embedded CodeBuilder direct `--help` — **PASS**.

The requested `SEMANTIC_STUDIO_CONSOLIDATION.md` and documentation commit
`a76a2edbac7e` were unavailable in the local checkout; the available
architecture, workbench, compiler, pipeline, roadmap, runbook, acceptance,
and historical documents were used instead. Native Project Zomboid SP/MP and
live external PBrainZ remain user-owned.

**ONE Next Chunk:** **S0B — establish one canonical authoring/build service
object shared by Semantic Lab GUI, headless CLI, and Codex API, preserving the
S0A CodeBuilder entrypoints and deterministic artifact contract.**

**Updated:** 2026-10-19, after the C6-C optional-provider parity slice and S0A acceptance.

## Prior accepted foundation (preserved, NOT invalidated)

The previous `PROGRESS.md` has been archived verbatim in `HISTORY_C0_C6_20261019.md` and remains recoverable in Git at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`. It records the action-flow/quest work and C0–C6 contextual conversation, small reviewed dataset codebuilding, Tk X11, worker, performance, EN/TL and optional-provider parity acceptance, ending READY FOR USER LIVE TEST for that **earlier scoped implementation**. Native PZ SP/MP and live external PBrainZ validation remain user-owned, unclaimed.

**Current goal status:** **S0A accepted; prior C6 developer gates remain preserved, and native Project Zomboid SP/MP plus live external PBrainZ validation remain user-owned.**

The prior user-live-test handoff is historical evidence and is superseded for
this consolidation goal by the single S0B chunk above; it was not re-run or
claimed as part of S0A.

## Productization roadmap

`SEMANTIC_STUDIO_CONSOLIDATION.md` and `ROADMAP.md` define S0A→S0B→S1 Dataset Library→S2 typed semantic block registry→S3 graph/code composer→S4 licensed corpora→S5 complete approved generation/reload workflow→S6 UX/performance handoff.

User alone runs actual Project Zomboid and manages Steam Workshop publication/install; no such steps are authorized for Codex by this goal.
