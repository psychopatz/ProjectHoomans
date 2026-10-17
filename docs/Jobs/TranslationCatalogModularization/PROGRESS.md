# Translation Catalog Modularization — current progress

**Date:** 2026-10-17. **State:** planning committed; no new loader, shards or translation migrations implemented. **Current phase:** 0 — inventory and baseline. **Native runtime:** not tested for this job.

## Source-verified anchors
- ProjectHoomans main `c96cadda1570f59810552f9d3fc55d5c957ba670`; active semantic implementation branch sampled at `fd852d746241d7e2f61df1c349ff63754afbe5ed` on 2026-10-17 (previous PR #2 open).
- PsychopatzCore main `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`.
- Main EN/TL Conversation custom catalog: 495/495 keys; feature branch 521/521 at observed revision. Loader single-file path and existing 15-system registration verified in source. Historical translation audit reports prior checks; not independently rerun.
- `Trading/Trading.json` exists but bootstrap registration/segment route missing in inspected branch. Actual consumer/lookup behavior unknown.
- Existing authored conversation translations live in separate small bundles and are NOT the target of this split.
- No code/test/CI/native changes or acceptance were executed in creating these documents.

## ONE Next Chunk — Phase 0A inventory, tests and loader contract evidence
1. Check both repos' actual local branches, SHAs, current feature changes and overlapping agent ownership; choose the correct **latest** Hoomans Conversation file rather than older main silently.
2. Snapshot EN/TL key-value/placeholder sets and owners of Conversation custom catalog, 15 registered systems/segments and relevant translation call sites. Record duplicate/missing counts and migration groups to `MIGRATION_MATRIX.md`.
3. Run existing Core custom translation smoke, Hoomans catalog and Conversation fallback tests, and a real Semantic Lab identity/wellbeing scenario in EN/TL. Capture actual lookup/fallback/selected text, not just JSON syntax.
4. Trace `Trading` route with an actual public lookup and an existing call site. Label bug only if confirmed.
5. Write a narrowly scoped proposal for **optional** manifest/shard reader API and specify minimal failing Core tests for Phase 0B; avoid implementing broad Core changes before recording baseline.

**Exit 0A:** reproducible exact-sha baseline + first manifest API decision + identified semantic integration/translation conflicts. **Then** update Next Chunk to 0B and execute bounded Core tests. If no runnable environment, leave gate open with specific missing components.

## After 0A
0B failing Core tests -> 1 optional Core loader -> 2 Hoomans pilot -> 3 full Conversation split -> 4 developer tooling -> 5 native EN/TL acceptance. Follow roadmap, not old agent text.
