# Audit — Semantic Test Subsystem After PSDL Refactors

**Evidence:** CODE_VERIFIED, TEST_VERIFIED, RUNTIME_VERIFIED.

## Tester engine

The declarative fixture engine remains functional:
- current schema/validator works;
- loader expands matrices deterministically;
- executor runs isolated cases through real `LuaSemanticWorker`;
- comparator/projection remains active;
- lint works;
- bounded batch/cancel/resume works, including real Lua execution.

## Maintained corpus

`ProjectHoomans/tools/providers/pnc/fixtures/v1` contains:
- 17 files;
- 116 expanded cases;
- current schema `semantic.harness-test.v1`.

Explicit execution works through both fixture CLI paths.

## Default-discovery regression

Core still contains a duplicate 17-file corpus under `tools/semantic_harness/fixtures/v1` using retired `pnc.semantic-test.v1`.

Both:
- `python -m tools.semantic_harness.testing.cli` default discovery;
- main `python -m tools.semantic_harness --run-semantic-tests` without explicit files;

select the stale Core directory and fail schema validation before running cases.

Existing mandatory CLI acceptance missed this because it always supplies a temporary `--semantic-test-file`.

## Duplicate-content drift

After normalizing only the schema field, 16/17 v1 duplicate files are otherwise equivalent.

`observatory/core.json` also differs in two identity-key prefix expectations: provider copy uses `question.identity`, while Core stale copy uses `question.identity.`.

GUI regression controller additionally loads older PNC observatory fixtures directly from Core `tools/semantic_harness/fixtures/`; ProjectHoomans has provider-owned copies and some have diverged.

## Full-corpus execution

Full maintained provider corpus through production Lua:

```text
PASS 114
FAIL   2
TOTAL 116
```

Failures:

1. `c0a.corpus.valid_mutating_request_control` / `give me water`
   - historical semantic contract: explicit authoritative mutation allowed;
   - current runtime: GIVE accepted, `SemanticTaskRequest` sent;
   - fixture expectation of zero dispatch/tool calls is stale.

2. `c0a.corpus.malformed_mutating_request_tail_typo` / `give me waterr`
   - current runtime: confidence 0.89, action rejected/blocked with `clarification_required`;
   - authoritative `dispatchTransport` remains empty;
   - one rejected diagnostic `action_dispatch` appears in `toolCalls`;
   - zero-tool-call assertion is stale; authoritative-mutation safety remains intact.

## Conclusion

Repair fixture authority/discovery rather than rebuilding the tester. Move all PNC fixture ownership to the provider, update stale expectations, add default-discovery acceptance, and retire Core duplicates only after every caller migrates.
