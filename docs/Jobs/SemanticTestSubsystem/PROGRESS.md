# Progress — All-in-One PSDL Semantic Tester

**Status:** COMPLETE.
**Current phase:** A1–A6 COMPLETE.
**Next Chunk:** None (parent objective achieved).

## Completed phases

- **A1 (Typed fixture operation registry):** Implemented `tools/semantic_harness/testing/operations.py` in `psychopatzCore` with allowlisted action IDs (`beat.*`, `behavior.*`, `interaction.preview`, `knowledge.*`, `backstory.*`, `commitment.apply`, `response.*`, `flow.*`, `fact.catalog`, `event.catalog`, `preview`), strict payload validation, and normalized `operation` + `result` envelopes. Added real-production declarative acceptance in `tools/providers/pnc/fixtures/v1/operations/a1_operation_registry.json`.
- **A2 (Declarative compiler probes):** Implemented `tools/semantic_harness/testing/compiler_probes.py` in `psychopatzCore` exposing `compiler.psdl_validate`, `compiler.psdl_inspect`, `compiler.canonical_ir`, `compiler.portable_plan`, `compiler.backend_projection`, and `compiler.source_lineage` over canonical CodeBuilder APIs, with lazy worker startup in `executor.py`. Added end-to-end `command.camp` + `beat.argument_escalation` acceptance in `tools/providers/pnc/fixtures/v1/compiler/a2_compiler_end_to_end.json`.
- **A3 (Domain model & all-in-one CLI/GUI):** Added provider-neutral `domain` and `semanticID` metadata in `schema.py` and `loader.py` (`filter_cases`, `discover_domains`), `--domain` / `--semantic-id` / `--list-domains` / `--batch-state` / `--batch-size` in `cli.py`, `execute_cases_batch` (cancel/resume) in `executor.py`, and domain/semantic-ID filtering + batch cancel/resume in the existing GUI Regression tab (`ui/regression_controller.py`, `ui/trace_conversation_builder.py`, `ui/shell.py`).
- **A4 (Behavioural migration with parity):** Migrated beat/arbitration (`pragmatic_beats_and_arbitration.json`), world knowledge gossip (`world_knowledge_gossip.json`), and follow/stay/wait_at (`follow_and_stay_wait_at.json`) after proving side-by-side parity, and removed the 6 superseded Python behavioural modules while retaining minimal API/inspector contracts (`test_pragmatic_interaction_authoring.py`, `test_world_knowledge_inspector.py`, `test_flow_catalog_contract`, etc.).
- **A5 (Exhaustive remaining-test classification):** Audited and classified all 194 remaining `tools/providers/pnc/tests/test_*.py` modules (801 methods) in `docs/Jobs/SemanticTestSubsystem/TEST_CLASSIFICATION.json`.
- **A6 (Final all-in-one acceptance & closure):** Verified full provider-aware fixture corpus (137/137 PASS, including original 116 baseline) and Core fixture/acceptance/authority/dispatch suites from committed vector.
