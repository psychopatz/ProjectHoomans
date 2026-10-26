# Agent runbook — Semantic Observatory & Dialogue Quality Harness

## Operating goal

Deliver the **entire** approved Observatory-first system in the existing Semantic Lab: actual production registry introspection, explainable response selection, usable Studio view, grounded quality matrices, concise agent CLI and safe variant change/replay. Start at PROGRESS's Next Chunk, but proceed autonomously through remaining ROADMAP phases after each accepted chunk. Never equate a unit test, phase or documentation pass with full completion.

## Safe checkout and document order

1. Work only in /home/psychopatz/Zomboid/Workshop/ProjectHoomans on **existing main**; read root AGENTS.md, this runbook, ARCHITECTURE.md, HARNESS_ACCEPTANCE.md, ROADMAP.md, AUDIT.md, related job authority docs; **read PROGRESS.md last**.
2. Inspect local git branch/status/HEAD, worktrees, origin/main remote and concurrent edits before writing. Prefer explicit fetch and verified fast-forward-only sync where needed. No new branches, blind pull, automatic stash, checkout/reset/rebase, force push, overwrite of user/agent files or unrelated doc churn.
3. Inspect the current production code instead of assuming the P0 audit SHA still applies. Protect PsychopatzCore and DynamicTrading as separate owners; don't alter sibling repositories without an approved, verified cross-repo requirement and safe Git ownership.
4. Changes only to this job's docs for execution/progress. Do not append goal status to root AGENTS.md or rewrite old goals. Do not check in GOAL_PROMPT.md; /goal stays in ChatGPT.
5. Coherent code/test/doc commits on authorized existing main after safety verification. Remote publication only through the project's established authorization/workflow; **never** publish Steam Workshop or install/release game mods.

## Implementation principles

- Production Lua determines semantic behavior; Python serves a read-only projection and worker control. Reuse FlowEditor, ResponseCatalog, Conversation Inspector, CLI, Studio and CodeBuilder; no duplicate registry, translator, selector, data store or code generator.
- Make observability default side-effect-free. Preview/explain must not dispatch authoritative actions, alter worker selection history, or mutate save/mod data. Runtime scenario execution may mutate only disposable fixture/isolated worker state; reset it appropriately.
- Match outputs to registered pool IDs, variants, actual flow, translation keys, source revisions and source owner. Mark provenance UNKNOWN when not verifiable. Avoid semantic overclaims from grep/regex or a reconstructed Python evaluator.
- Support both human GUI and LLM agents. Implement bounded machine-readable service first; connect visible Tk views to that same service. No screenshots as routine acceptance or bloated JSON dumps.
- Treat proposed language variants as untrusted content. Never allow agent text to invent NPC facts, expose unrevealed names/private dossier, issue gameplay tools or alter plan/when/priority without explicit scope. English and Tagalog must both work.
- Temporary work and generated previews go outside PZ watched media and outside actual user saves. No staging directory under any loaded media/ tree. Observe existing translation loader paths and manifests; never blindly relocate artifacts.
- Preserve server authority and client presentation, fresh worker import/reload correctness, bounded persistence and optional PBrainZ compatibility. No runtime LLM/cloud dependency.

## Acceptance discipline

- Before each change: define concrete observable behavior and negative control from HARNESS_ACCEPTANCE.md. After: validate against production Lua + Core with isolated fixtures and exact source hashes. A generated JSON manifest or synthetic standalone test is not acceptance.
- Use tools/semantic_harness/.venv/bin/python for tests when available (Python 3.12 + Tk); shell default Homebrew Python 3.14 previously lacked _tkinter. Confirm actual toolchain instead of treating environment errors as implementation failures.
- Prioritize focused Python unittest modules under tools/semantic_harness/tests, production Lua tests via tests/run_tests.py, worker doctor, relevant GUI/Tk/Xvfb exercise, Kahlua verification and generation idempotence. Record exact commands, tests run/pass/fail, worker kind, missing dependencies and hashes.
- Do not "repair" tests by weakening game authority or hardcoding fixture responses. Maintain negative permission cases and actual final rendered text.
- Benchmark startup/paging/replay/output/memory before performance claims. Respect and explicitly report resource/report bounds; cap truncation is not PASS.
- Never initiate native Project Zomboid/SP/MP, edit source saves or Workshop publish for acceptance. All developer-owned work must be completed before user live-test handoff.

## Progress and failure behavior

Keep PROGRESS.md concise/current: status, exact revision, accepted evidence, known limitations, one Next Chunk, remaining mandatory phases. Link audits/roadmap instead of duplicating history. Continue through P0–P7 autonomously. If unrelated test/environment blocked, record it precisely and keep doing independently testable work. If real blocker/authorization conflict, report why no safe action can proceed. Final report includes files/code, evidence, remaining gaps, commit and explicit no-native/no-Workshop statement.
