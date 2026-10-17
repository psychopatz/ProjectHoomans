# Acceptance protocol — LIVE PZ first, Semantic Lab supporting

The primary product is a Project Zomboid Build 42 NPC conversation. A real production-Lua worker is useful for isolated parser/state/catalog questions; its mocked UI, network, world, relation and scheduler do **not** prove that the game behaves correctly.

## Evidence hierarchy
1. **Actual installed Hoomans/Core compatibility**: check the exact scripts loaded by native PZ and runtime capability handshake.
2. **Controlled native PZ SP/MP**: correct text, current flow/next step, authority, localization, session and gameplay effects.
3. **Focused production Lua worker / Core unit tests**: contract-level regression support, never the only evidence for user-visible acceptance.
4. **Pure Python/JSON/static fixtures**: data and registration validity only.

## Live trace requirements
Opt-in in-game diagnostics should show the **production** IR/candidate ID, eligibility/rejection reason, selected flow/node/transition, response-pool ID and final template key/text, before/after pending obligations, speaker/addressee, actual server request/result, language and Core feature handshake. Debug UI/logging must be rate-bounded and normally disabled.

## High-value controlled native conversations
- Identity requested -> player asks `are you okay` -> player `im fine thanks` -> identity resumes -> explicit true or false name; no unintended evasion action.
- `I'm hungry`, `I'm fine, thank you`, context-sensitive `no` and meaningful follow-ups; grounded NPC health/needs, not worker fake values.
- One additional pilot flow created without changing the central intent policy, selecting actual contextual response and next node.
- EN/TL real mod-installed translation shards, restart and missing-key fallbacks; composed two-act reply when implemented.
- Two NPCs, SP and MP (server authority, no duplicate transport, per-speaker isolation, save/rejoin).
- Provider disabled, then optional PBrainZ with identical semantic authority.

## Existing headless evidence and failures
Historical progress reports real-worker suites 97/97 Python and 68/68 Lua, but the full headless Lua suite 12/836 fails in existing UI/native-associated paths. Core legacy translation-catalog test reports count 316 vs 334 after unrelated edits. Keep them classified **unresolved**; do not hide, delete, or auto-exempt. Reproduce and tie a failure to a genuine missing native/mock dependency before deciding whether to adapt it. No new giant JSON-only suite just to increase pass counts.

Worker acceptance may demonstrate pure preview vs commit, candidate bounds, duplicate registration, translation key/value parity, and response-plan rendering. These are necessary but **not sufficient** for live completion.

## Reporting
For each corrective phase: exact Hoomans/Core SHA and **installed version**; environment/game build; exact test commands or live steps; observed actual game text/IR/node/transport; expected vs actual; pass/fail/skipped; untested MP and performance; next chunk. Never claim native tests passed from worker trace, PZ source verifier, user spot-check alone, or the absence of new errors.
