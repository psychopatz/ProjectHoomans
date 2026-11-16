# Progress — Semantic Test Subsystem Fixture Authority Repair

**Status:** COMPLETE.
**Current phase:** R5 (R1–R5 accepted).
**Next Chunk:** None (all developer-side R1–R5 gates passed).

## Verified closure state

- **R1 (Provider-aware fixture authority):** `ModManager` / `ProviderSpec` / `ActivationPlan` support `fixtureRoots` in `provider.json`; `tools/semantic_harness/testing/resolver.py` resolves `semantic` and `regression` fixture roots from active providers; `ProjectHoomans/tools/providers/pnc/provider.json` declares `semantic` (`tools/providers/pnc/fixtures/v1`) and `regression` (`tools/providers/pnc/fixtures`).
- **R2 (Retire duplicate Core fixtures):** All 26 PNC-specific duplicate fixture files under `psychopatzCore/tools/semantic_harness/fixtures/` were removed after migrating `testing/cli.py`, `testing/lint.py`, `entrypoints/cli.py`, and `ui/regression_controller.py` to `resolve_fixture_roots` / `resolve_fixture_file`. Active `pnc.semantic-test.v1` fixture authority = 0; duplicate PNC corpus under Core = 0.
- **R3 (Repair stale fixture expectations):** Updated `c0a.corpus.valid_mutating_request_control` and `c0a.corpus.malformed_mutating_request_tail_typo` in `ProjectHoomans/tools/providers/pnc/fixtures/v1/c0a/semantic_corpus.json` to assert authoritative `actionResult` and `dispatchTransport` safety rather than incidental telemetry counts.
- **R4 (CLI / GUI / batch parity):** Added `tools/semantic_harness/tests/test_fixture_authority.py` covering active PNC resolution, synthetic second provider isolation, missing/invalid root diagnostics, duplicate-corpus/retired-schema guards, GUI regression controller resolution, default `testing.cli --list`, and default main CLI `--run-semantic-tests` without `--semantic-test-file`.
- **R5 (Full corpus & parity acceptance):**
  - canonical PNC fixture lint (`17` files, `116` cases): PASS;
  - full maintained PNC corpus via default discovery + `LuaSemanticWorker`: `116 / 116` PASS;
  - behavior, pilot, and observatory parity suites (`16` tests): PASS;
  - lint, subsystem, and real-Lua batch/cancel/resume (`17` tests): PASS;
  - Core `test_fixture_authority` + `test_mod_manager` (`20` tests): PASS.
