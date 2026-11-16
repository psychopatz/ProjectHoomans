# Semantic Test Subsystem — Fixture Authority Repair

**Status:** IN PROGRESS.

## Objective

Restore the declarative Semantic Test subsystem as the canonical low-token behavioural acceptance surface after the PSDL/package/runtime refactors.

Target architecture:

```text
Semantic Harness Core
  schema + loader + executor + comparator + batching + fixture resolver

provider package
  provider-owned semantic fixtures

active provider
  → fixture resolver
  → same CLI / GUI / batch executor
  → real production Lua
```

The subsystem itself is still healthy. The repair is about fixture ownership, discovery, stale expectations and acceptance coverage.

## Verified current baseline

- ProjectHoomans provider corpus: 17 files / 116 expanded cases.
- Explicit current fixture execution works through both Semantic Test CLIs.
- Lint, behaviour parity and real-Lua batch/cancel/resume tests pass.
- Full provider corpus: 114 PASS / 2 FAIL.
- Both default runners currently fail before execution because they discover the stale Core copy using retired `pnc.semantic-test.v1` instead of current `semantic.harness-test.v1`.
- GUI regression fixture loading still points directly at Core-owned PNC fixture copies.

Git history is the archive for the completed original P0–P7 implementation.
