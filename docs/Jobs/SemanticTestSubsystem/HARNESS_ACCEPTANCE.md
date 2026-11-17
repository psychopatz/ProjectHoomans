# Harness Acceptance — Final State

**Status:** COMPLETE.

## Broad runtime

- Core discovery: 284/284 PASS.
- PNC discovery: 645 tests PASS within 900 seconds; 27 skips are environment-gated.
- GUI journeys: 4/4 PASS under Xvfb.
- Zero new test-owned Lua workers after acceptance.
- Zero Tk cleanup/unraisable errors.

## Behavioral authority

- Canonical fixture estate: 48 files / 290 cases.
- Fixture lint: PASS with zero exact duplicates, naming violations or domain/path mismatches.
- Full fixture corpus: 290/290 PASS.
- Remaining imperative tests protect implementation mechanisms rather than duplicate pure semantic outcomes.
- Classification ledger: 165 modules / 648 methods; 59 LOW_LEVEL direct-worker modules / 217 methods.
- Direct-worker reason guard: PASS.

## Reproducibility

- PsychopatzCore, ProjectHoomans and DynamicTrading were reconstructed as isolated sibling repositories from exact commits.
- Hardcoded live workspace paths are rejected by guards.
- DynamicTrading is pinned read-only at e21387081776e3c8c8e2ba34d419a83441be801f.
- Held-out evaluation: PASS.
