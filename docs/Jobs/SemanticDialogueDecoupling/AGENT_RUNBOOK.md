# Unified semantic decoupling agent — corrective execution

## One goal, existing checkout, main publication
- Work in the user's existing authorized Project Hoomans checkout. Inspect actual `git status`, HEAD, branch, remotes/upstream, installed Workshop mod path(s), and related PsychopatzCore local/remote state before writing. GitHub remote cleanliness does **not** prove a local worktree is clean.
- The user does not want new branches or PRs; never create one by default. Hoomans direct `main` commits/pushes are allowed only by safe, authorized, current-expected-SHA fast-forward. No force, destructive reset, stash of others' changes, ambiguous `git pull`, or overwrite of a divergent checkout.
- Core is a separate repository: verify Core-specific permissions, remote divergence, the agent's unpublished commits and unrelated radio/UI/asset changes. Do not presume the current Hoomans publication authorization applies to Core. Stage/commit only owned files; if Core publication is unsafe, provide a precise non-destructive integration plan.
- Update only `docs/Jobs/SemanticDialogueDecoupling/PROGRESS.md` as the active ledger. Earlier implementation report is archived in `IMPLEMENTATION_EVIDENCE.md`; other Jobs' progress remains read-only.

## Execution
1. Read `AUDIT.md`, `ARCHITECTURE.md`, `FLOW_CONTRACT.md`, `TRANSLATION_MIGRATION.md`, `DEPLOYMENT_ACCEPTANCE.md`, `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, `PROGRESS.md`; check current production code and actual installed files.
2. Execute **only the current Next Chunk**. Start with C0A dependency and installed-pair audit. Do not repeat completed flow/kernel/shard implementation and do not launch a broad refactor before the C0 compatibility gate.
3. Prefer real-game reproduction and low-volume in-game diagnostic instrumentation for presentation/authority/flow claims; use focused production Lua worker for local pure contracts or regressions. If native game cannot be controlled, document the exact blocker and small user-runnable live checklist; never simulate successful SP/MP.
4. Check each bounded change's effect on identity wellbeing regression, server authority, persistent flow state, EN/TL translation, existing Core consumers and (when applicable) multiplayer transport. Keep tests meaningful, not a count target.
5. Record exact SHAs and installed file source, command/live steps, actual outputs, pass/fail/not-tested, persistent headless failures and next single bounded chunk; commit coherently after safe publication checks. Advance C0A -> C0B only after a defensible measured gate, and through ROADMAP thereafter.

## Invariants
- Existing deterministic offline Lua remains available without PBrainZ; no conversational flow or parser bypasses authoritative server identity, relationship, task, inventory or MarketSense policy.
- Core APIs and IR v1, existing response IDs/network payloads, multilingual keys, native PZ Translate and authored conversation bundles remain stable.
- No new monolith, duplicate parser/state store, Jess-like rule port, global WordNet runtime, per-NPC OnTick semantic scan, or extra standalone job.
- Flow preview is pure; accepted turn commits once; each NPC/addressee has bounded isolated state.
- No temporary staging directories under watched live `media/`. Follow repository `AGENTS.md` with protected calls and file watchers.

## True blockers and completion
A missing native game control surface blocks the **native acceptance gate**, not safe independent documentation or Core compatibility checks. Unsafe divergence/unauthorized Core push is a real publication blocker; report it, don't bypass. Completion requires the C0–C6 gates with real SP/MP evidence, not headless green tests or an unchanged failure count. Once mandatory gates pass, set maintenance-ready and stop.
