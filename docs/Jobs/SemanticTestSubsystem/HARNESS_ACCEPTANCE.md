# Harness Acceptance — Fixture Authority Repair

## Discovery

Test provider-aware fixture discovery with:
- current PNC provider;
- explicit fixture-file override;
- synthetic second provider/root;
- missing/invalid fixture-root diagnostics.

Generic Core code must not require ProjectHoomans path constants.

## Corpus authority

Require exactly one active PNC v1 behavioural corpus.

Fail acceptance if:
- active Core fixtures still use `pnc.semantic-test.v1`;
- default runner discovers a stale duplicate;
- GUI and CLI resolve different PNC fixture authorities.

## Full corpus

Run all current PNC provider fixtures through real production Lua.

Expected current case count: 116 unless fixture additions/removals are explicitly justified and documented.

All cases must pass. The two audited mutating-request fixtures must assert current semantic safety rather than zero telemetry.

## Entrypoint parity

Mandatory tests:
- standalone testing CLI, no explicit file;
- main harness `--run-semantic-tests`, no explicit file;
- explicit `--semantic-test-file`;
- suite/filter selection;
- GUI regression fixture resolution;
- lint;
- real-Lua batch/resume.

## No false green

Do not change production semantics solely to satisfy stale fixtures. If runtime behavior and prior semantic contract agree, update the fixture. If they disagree, treat it as a semantic regression and fix production.

## Final closure

From exact committed Core + ProjectHoomans vector:
- canonical provider corpus lint PASS;
- full corpus PASS;
- parity/batch/default CLI/GUI tests PASS;
- no stale duplicate provider corpus in Core;
- docs agree on COMPLETE.
