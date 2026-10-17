# Semantic Dialogue Decoupling — current corrective state

**Updated:** 2026-10-17. **Phase:** C0 — deployed Core/Hoomans compatibility. **State:** corrective implementation needed; **NOT maintenance-ready**. This is the **one active progress ledger** for the goal.

## Verified sources and evidence status
- Project Hoomans GitHub `main` audited at `d345e5c3ba41ba752517b405320e6d61e847a3f8` (exact current agent checkout may differ).
- PsychopatzCore GitHub `main` audited at `0212491d2af3597cceaa7353e62f01ef54adca44`, missing reported Core additions `ParseCandidates`, candidate/commit router hooks and manifest-aware `scope.registerSystem`.
- Previous implementation ledger reports locally committed Core `afc1bda0f5f3aaec1bbe1693f1264cd5d990ed5d` plus other candidate/router commits, **not found on connected Core remote** at audit. Exact local state/permissions and installed PZ Core version are UNVERIFIED.
- Hoomans already has candidate eligibility, bounded flow registry/kernel, two registered flows, response-plan types and 12 EN + 12 TL Conversation shards. Do **not** recreate these.
- Flow is not yet the final response authority: old intent branch selects reply, while flow transition is attached as additional state/diagnostics. Real multi-act `Compose` and visual flow editor are not established in ordinary production use.
- Agent-reported previous headless results: 97/97 Python, 68/68 focused Lua; full 12/836 headless failures. Core legacy translation catalog test has hard-coded count mismatch. These remain REPORT-DERIVED and unresolved; see `IMPLEMENTATION_EVIDENCE.md`.
- User reports limited successful live game testing. No controlled exact-version native SP/MP matrix has been archived; mark **NOT ACCEPTED**, not `works in PZ`.
- No CI or live test run performed in this documentation update. No runtime or Core code changed by this docs-only commit.

## ONE Next Chunk — C0A: verified installed dependency contract

1. In the **existing** Hoomans and Core checkouts collect actual branch/HEAD, clean/dirty path ownership, remote divergence and installed PZ mod file paths/checksums. Do not overwrite unrelated Core radio/UI/asset edits or assume GitHub remote is the installed Core.
2. Prove exactly which Core APIs the *installed* game and Hoomans production files use: `Parser.ParseCandidates`, optional router candidate parser/selector/flow commit, and optional manifest-aware `scope.registerSystem`; inspect actual Hoomans `Conversation` manifest/shard loading under that Core.
3. Establish an explicit compatibility/capability matrix: latest GitHub Hoomans vs published Core, Hoomans vs local Core, Hoomans vs game-installed Core. Record EN/TL real lookup/fallback outcomes where a controllable native session exists; distinguish fallback strings from loaded translations.
4. If dependency is mismatched, outline the smallest **safe** Core release/synchronization and Hoomans fail-visible capability diagnostic. Do not silently merge, force-push or substitute a fake Hoomans parser/translation loader. Fixing/deploying Core belongs to **C0B after evidence**.
5. Record checks, exact SHA/path/version, actual results and outstanding blockers. Then update this PROGRESS with one Next Chunk, C0B (safe publication and installed-pair verification) or a narrower confirmed fix. Do not begin C1–C6 in this chunk.

**C0A exit:** real installed/published/local dependency matrix plus an actionable safe integration path. No arbitrary count of headless tests can substitute for this evidence.

## Remaining corrective roadmap
C0B publish/install/verify compatible Core -> C1 controlled live dialogue baseline -> C2 flow-authoritative response selection -> C3 visual flow authoring/debugging -> C4 real composition -> C5 translation/domain integration -> C6 SP/MP/perf acceptance. The prior 0A–8 implementation remains preserved, with product gates open.

**Native SP:** user spot-tested; controlled acceptance not established. **Native MP:** not tested. **Published Core compatibility:** not established. **Full headless suite:** reported 12 failures. **Next goal state:** still active.

For the historical test commands, hash details and per-implementation phase record, read `IMPLEMENTATION_EVIDENCE.md`; that archive is not a second PROGRESS ledger.
