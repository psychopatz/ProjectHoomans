# Installed Core/Hoomans compatibility and live-game acceptance

This is the **first corrective phase gate**. Project Hoomans and PsychopatzCore are independently versioned repositories; matching headless Lua tests using a local modified Core do not prove the published pair is compatible.

## Versions from 2026-10-17 audit
- Hoomans published main `d345e5c3ba41ba752517b405320e6d61e847a3f8`.
- Core published main `0212491d2af3597cceaa7353e62f01ef54adca44` (old API).
- Core local revision `afc1bda0f5f3aaec1bbe1693f1264cd5d990ed5d` and related parser/router commits were described in the agent ledger but not found on connected Core GitHub. Their presence in a user's installed Core or the local worktree is **unverified**.
- Hoomans `42.20/mod.info` declares `require=PsychopatzCore,MarketSense` without a feature-specific Core minimum. Do not invent a tested minimum. Introduce an explicit capability/version contract after validating actual supported compatibility.

## Preflight — existing local checkout, NO destructive sync
1. Collect `git status --short`, `git rev-parse HEAD`, `git branch -vv`, `git remote -v` and `git ls-remote origin refs/heads/main` independently in both authorized repositories. Never infer local cleanliness from GitHub or overwrite another agent's dirty files.
2. Inspect live Workshop/mod deployment path(s) and game mod list. Record which Core script bytes and Hoomans script bytes PZ actually loads, with checksum or source marker; note duplicates/cached/old installs.
3. Verify Core parser exports `ParseCandidates`, router accepts optional candidate parser/selection/flow-commit hooks, translation scope registration accepts optional manifest, plus existing IR and translation APIs.
4. Run a version/capability **read-only** check from the live PZ environment if available; make mismatch fail with actionable diagnostics rather than default-text appearing to pass. Feature detection must not disable existing offline dialogue or relax server authority.
5. Compare local, remote and installed versions. If Core has isolated, committed unpublished changes, publish only with separately verified Core authorization and safe fast-forward preconditions; if divergent/dirty overlap, coordinate a non-destructive merge/integration plan and **stop unsafe publication**. Never reimplement all Core features within Hoomans to avoid resolving the dependency.
6. Test with the actual installed matched versions: identity, wellbeing, EN/TL shard lookup and native relationship/transport events. A headless test may corroborate a specific parser/manifest contract but does not replace the game.

## Evidence record per deployed pair

    Hoomans source SHA:
    Core source SHA:
    Actual installed Hoomans file path/checksum:
    Actual installed Core file path/checksum:
    PZ Build and mod list:
    Core parser/router/translation capability checks:
    EN/TL native Conversation shard lookup + rendered text:
    Player/NPC IDs + IR, flow transition, selected response, action transport:
    SP status (pass/fail/not-tested):
    MP status (pass/fail/not-tested):
    Limitations / next safe integration action:

## Native scenario matrix

- **SP:** first-time introduction, identity interruption, `im fine thanks`, true/false explicit name, urgent NPC need, refused question, different speaker, response pool/translation key, subsequent follow-up.
- **MP:** correct actor/npc authorization, no relationship penalty on unrelated reply, duplicate/replayed request protection, two clients/NPCs, session reset/rejoin and server-client reply parity.
- **Localization:** EN/TL actual rendered text and language restart, absent key fallback and telemetry; native files and authored conversation bundles unaffected.
- **Performance:** on-dialogue allocations/CPU, no `OnTick` parsing, bounded NPC sessions across live and abstract populations; measure against pre-integration baseline.
- **Optional PBrainZ:** when enabled, may rephrase selected content but never change authorized semantic action; disabled mode works normally.

No game process or controllable session available? Do NOT label all native checks passed or synthesize results. Record the blocker and prepare small, clear in-game steps/log capture for the user; continue only independent safe checks. Manual user confirmation is evidence of observed behavior, but distinguish limited spot check from a scripted SP/MP gate.
