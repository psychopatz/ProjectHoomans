# Semantic Harness Test Isolation & Runtime Performance

**Status: REQUIRED P3C/P7 acceptance contract.** Functional correctness is not sufficient if the Semantic Harness regression workflow becomes materially slower, machine-state-dependent, or impractical for agent iteration.

## Why this phase exists

P3B correctly added production-authoritative startup presentation, remembered SAVE restoration, and automatic Studio Explore population. The first integrated Xvfb pass then exposed a separate developer-side regression:

- user UI/session persistence became implicit test input;
- many GUI tests still constructed `SemanticHarnessApp` with default arguments and therefore inherited the real user state file;
- when that state contained `active_source_kind=SAVE`, unrelated tests automatically rehydrated the user's real saved Player/NPC;
- many tests were changed from waiting for worker readiness to waiting for global `not app.busy`, placing SAVE restoration and Explore auto-load on unrelated tests' critical path;
- the acceptance strategy ran the full Python suite once headlessly and then again wholesale under Xvfb, converting previously skipped GUI tests into dozens of full Tk + Lua application launches while redundantly rerunning non-GUI tests.

This is a test-isolation and performance defect. Do not normalize it by increasing timeouts.

## Audited evidence

At the P3C audit point:

- the full Xvfb `unittest discover` run had exceeded 16 minutes and was still active;
- the repository contained roughly 54 `SemanticHarnessApp(...)` constructions across GUI tests;
- at least 15 GUI test modules/sites still used default app arguments and could read the real default UI-state file;
- the user's real state contained `active_source_kind=SAVE` plus a real Sandbox save/player/NPC;
- isolated fixture startup reached worker-ready + bounded Explore in about **1.9 s**;
- remembered-SAVE startup reached the same state in about **6.0 s** on the audited machine;
- one long-lived Lua worker was idle on its pipe while the Python runner continued spawning short-lived workers, so the suite was slow rather than deadlocked;
- only a few new P3B tests were added; the large wall-clock increase came from execution strategy and startup/session coupling, not hundreds of new test cases.

These values are audit evidence, not universal hardcoded thresholds. Establish a stable local baseline after isolation fixes and record the resulting budget.

## Non-negotiable test-isolation rule

> **User persistence is product input, never implicit test input.**

Except for tests whose explicit purpose is persistence/restore behavior, GUI tests must not read or depend on:

- the user's default Semantic Lab UI-state file;
- the user's last active SAVE/FIXTURE source preference;
- the user's real remembered Player/NPC identifiers;
- mutable state from another test.

Use one shared test helper/fixture that provides:

- a temporary `--ui-state` path;
- clean fixture intent by default;
- `--reset-ui-state` where appropriate;
- explicit opt-in state data only for persistence tests;
- deterministic cleanup.

Do not manually duplicate `TemporaryDirectory + --ui-state + --reset-ui-state` boilerplate across dozens of tests when one reusable helper can own the contract.

## Startup/background-work ownership

### Worker ready

`worker_ready` means the production Lua worker is ready to accept operations. Background read-only UI initialization must not redefine that concept globally.

### Explore auto-load

Explore auto-population remains required, but its first bounded read-only catalog query should use **local Explore loading state** rather than making the whole Semantic Lab globally busy when no user-visible Simulation operation is in progress.

Requirements:

- retain the same serialized worker/session authority;
- do not introduce concurrent unsafe access to the Lua worker;
- expose `Loading catalog…` on Explore itself;
- do not disable unrelated Simulation controls merely because Explore is fetching its first page;
- tests that only need worker readiness must not have to wait for Explore;
- tests that specifically need Explore content wait for the Explore-local completion signal.

### SAVE restoration

Remembered SAVE restoration is intentionally operational startup work and may keep the relevant source/loading state pending until complete. Only tests explicitly exercising remembered SAVE behavior should incur that cost.

## Test-suite topology

Do not use `DISPLAY` as a reason to rerun the entire Python suite.

The normal P7 workflow should be split by purpose:

### Fast headless regression

Run the full Python suite in the normal headless environment. GUI-only tests may skip.

This remains the broad semantic/runtime/CLI regression pass.

### Focused Xvfb GUI integration

Under Xvfb, run only the display-dependent GUI/lifecycle modules required for acceptance, including:

- P3B startup/session parity;
- surface consolidation;
- UI-state persistence;
- operational World Browser / saved-pair entrypoint;
- other explicitly classified Tk integration modules that own GUI behavior changed by the current goal.

Do not rerun hundreds of already-passed non-GUI tests merely because Xvfb provides `DISPLAY`.

If the repository wants a truly exhaustive all-tests-under-Xvfb job, keep it as an optional/CI/nightly diagnostic gate with an explicit runtime budget, not the ordinary edit-test feedback loop.

## Wait/timeout discipline

Timeouts are failure ceilings, not synchronization design.

- Prefer one shared event-loop-aware wait helper rather than ad hoc 10/15/45/60-second loops.
- Wait for the **specific condition owned by the test**: worker ready, Explore loaded, SAVE restored, response received, etc.
- Do not broadly replace `worker_ready` with `worker_ready and not app.busy` unless the test actually depends on the work represented by `busy`.
- Do not increase timeouts to conceal slow startup or state leakage.
- Record timeout failures with the awaited condition and current lifecycle/source/busy state.
- Use conservative but measured ceilings derived from isolated local baseline samples.

## Performance acceptance

P3C is accepted only when:

1. All GUI tests are hermetic by default; a user's real default UI state cannot change their behavior or runtime.
2. A dedicated test proves default GUI tests use isolated state while explicit persistence tests can opt into remembered SAVE state.
3. Fixture startup and remembered-SAVE startup have measured local baselines recorded in acceptance output.
4. P3B does not materially regress fixture startup versus the last accepted architecture without a documented reason.
5. Explore auto-load no longer extends global `app.busy` for unrelated work.
6. The standard full headless Python suite runs once.
7. The standard Xvfb acceptance command targets the bounded GUI module set instead of rediscovering the entire suite.
8. Focused P3B GUI acceptance completes within a bounded, practical wall-clock budget on the audited machine.
9. No normal GUI test reads or rehydrates the user's real save unless that real-save behavior is the explicit subject of the test.
10. Fail-fast failures surface promptly; no sequence of generic 45–60 second waits turns a simple regression into minutes of silence.
11. P3B functional behavior remains green: native Response Channel authority, saved-target restoration, safe fallback, and Explore auto-population.
12. Full Lua/Kahlua/CodeBuilder/data-safety gates remain unchanged and green.

## Recommended implementation sequence

1. Stop using the current exhaustive Xvfb-all-tests run as acceptance evidence if it is still active; the observed slowdown is itself the defect being repaired.
2. Introduce one shared hermetic GUI-test app/state fixture.
3. Migrate all ordinary GUI tests off the real default UI-state path.
4. Keep explicit persistence/restore tests opt-in and self-contained.
5. Separate Explore-local loading from global Simulation busy state without violating serialized worker access.
6. Replace broad busy waits with condition-specific shared wait helpers.
7. Define the focused Xvfb GUI module set.
8. Benchmark fixture startup, remembered-SAVE startup, focused P3B tests, full headless suite, and focused Xvfb suite.
9. Run P7 again using the split topology.
10. Update PROGRESS with actual wall-clock results and only then return to READY FOR USER LIVE TEST.

## Non-goals

- Do not remove remembered SAVE restoration merely to make tests fast.
- Do not disable Explore auto-load.
- Do not mock away the real Lua worker from acceptance tests that specifically require production parity.
- Do not weaken P3B assertions.
- Do not create parallel worker/session implementations for tests.
- Do not serialize a second test database of NPCs.
