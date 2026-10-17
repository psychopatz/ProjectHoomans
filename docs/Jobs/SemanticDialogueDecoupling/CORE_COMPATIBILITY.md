# Core compatibility — source and development checks, NOT Workshop deployment

## Revision reconciliation

At this documentation update:
- Hoomans remote main: `56288e50e6d782634df7f26ceaa0f0cb7c0922f9`.
- Core remote main: `44a4d534a9520440070ae7943d7ae9fb848f71ce` — source inspected and found `Parser.ParseCandidates`, candidate parser/selector + flow commit router hooks, and manifest-aware translation system registration.
- Historical Core main `0212491d` was missing these features; references to that version are **superseded**, not an instruction to republish Steam Workshop content.
- The user's Codex report mentions local work, including commit `27e1fd94`, not independently accessible from this GitHub session. Its local history/dirty files take precedence over assumptions about its contents.

## Small development preflight

1. Read the actual authorized Hoomans/Core local HEAD and `git status`, identify the active dependency path and script versions. Preserve unrelated mod/radio/asset edits.
2. Check existing Lua source contracts and capability diagnostics against those checked-out files; if a local Core checkout is older, explain exactly what's missing and use a safe non-destructive code synchronization approach when already authorized. No blind refresh or force.
3. Use the **existing Semantic Lab production Lua worker and visible interface** to verify Core candidate selection, routing/commit and manifest-backed EN/TL key lookup. The test is a DEVELOPMENT contract check, not installed Workshop verification.
4. If Hoomans fails to load with a dependency API mismatch, fix the narrow compatibility path in source and demonstrate the correction within the harness. Keep failure visible; never substitute fake fallback dialogs.
5. Once source pair is coherent and basic Semantic Lab diagnostics run, mark this development gate done and proceed with dialogue implementation. Do not wait for PZ or Steam Workshop.

## Absolutely out of scope for the agent

- Steam Workshop upload, update, republish, steamcmd, public release/publishing authorization.
- Launching, polling or requiring Project Zomboid, hosting a server, downloading Workshop copies, or restarting the user's game.
- Declaring failure/blocked because `apps=[]` or no PZ process exists.

The user's Workshop directory path is a **local working directory**, not consent to publish.

## Evidence format

Record Hoomans/Core local HEAD and remote references, actual Lua APIs, manifest lookup in the production worker, any failure and source-level remedy. Final native SP/MP verification appears only in `USER_LIVE_TEST_HANDOFF.md` and is not part of the developer implementation exit gate.
