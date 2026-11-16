# Agent Runbook — Semantic Test Subsystem Repair

1. Inspect branch/HEAD/status and root `AGENTS.md` in ProjectHoomans and PsychopatzCore. Preserve unrelated work.
2. Read `PROGRESS.md`, `HANDOFF.md`, active ROADMAP phase and ARCHITECTURE before edits.
3. Treat production Lua/runtime behavior and explicit semantic contracts as stronger evidence than stale fixture expectations.
4. Keep generic fixture machinery in Core and provider-specific data in provider packages.
5. Migrate callers to provider-aware discovery before deleting duplicate fixture files.
6. Never implement Python semantic-policy logic merely to make fixtures pass.
7. For a failing fixture, inspect exact runtime record: IR, action result, authority transport, response/flow and diagnostics. Decide whether fixture or production is wrong before editing.
8. Validate focused changes first, then full 116-case corpus and entrypoint parity.
9. At accepted phase boundaries, reconcile docs, stage exact phase-owned paths, commit Core participant first and ProjectHoomans/job docs last. No push/publication without authorization.
10. Continue automatically through R1–R5 unless blocked.
