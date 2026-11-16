# Roadmap — Semantic Test Subsystem Fixture Authority Repair

**Parent status:** COMPLETE (R1–R5 accepted).
**Completion boundary:** R1–R5 accepted.

## R1 — one provider-aware fixture authority

Establish a generic fixture discovery contract.

Requirements:
- Core owns fixture schema/loader/executor/comparator/batching only;
- PNC-specific fixtures are owned by the ProjectHoomans provider;
- future providers can declare their own fixture roots without Core source edits;
- active provider/workspace resolution selects fixture roots;
- explicit `--semantic-test-file` remains supported;
- no hard-coded PNC fixture path in generic Core CLI/GUI code.

Prefer extending provider metadata/discovery already used by the harness rather than adding a second registry.

**Gate:** active PNC provider resolves the ProjectHoomans fixture corpus, while a synthetic provider can declare another root without modifying generic fixture code.

## R2 — retire stale duplicate fixture corpora

Audit all PNC fixture copies under:
- `psychopatzCore/tools/semantic_harness/fixtures/`;
- `ProjectHoomans/tools/providers/pnc/fixtures/`.

Remove Core-owned PNC duplicates only after every caller is migrated.

Known stale duplicate v1 corpus:
- 17 files under Core use retired `pnc.semantic-test.v1`;
- provider copies use `semantic.harness-test.v1`;
- after schema normalization, 16/17 are otherwise equivalent;
- `observatory/core.json` also contains two corrected identity-prefix expectations in the provider copy.

Also migrate GUI regression callers currently reading old Core observatory fixtures.

**Gate:** no PNC-specific fixture corpus remains under generic Core ownership unless exact evidence proves it is provider-neutral.

## R3 — repair current corpus expectations

Run the complete provider corpus through real `LuaSemanticWorker` and repair only expectations proven stale.

Current failures:

```text
c0a.corpus.valid_mutating_request_control
  input: give me water
  fixture currently expects zero dispatch/tool calls
  historical semantic contract says explicit mutation is allowed
  current runtime correctly accepts GIVE and sends SemanticTaskRequest

c0a.corpus.malformed_mutating_request_tail_typo
  input: give me waterr
  fixture currently expects zero tool calls
  current runtime blocks authoritative mutation with clarification_required
  telemetry records one rejected action_dispatch
```

Assertions must test semantic/safety outcomes, not incidental telemetry counts.

Preferred safety assertions include:
- explicit request: accepted action/result and expected authoritative transport;
- uncertain typo: `dispatchTransport` remains empty, action rejected/blocked, reason `clarification_required`.

Do not weaken genuine negative controls.

**Gate:** full maintained provider corpus passes 116/116 against production Lua with truthful safety assertions.

## R4 — CLI / GUI / batch parity and regression gates

Make all public test entrypoints resolve the same fixture authority.

Cover:
- `python -m tools.semantic_harness.testing.cli` default discovery;
- main harness `--run-semantic-tests` without `--semantic-test-file`;
- explicit fixture-file execution;
- GUI regression/Observatory fixture actions;
- bounded batch and resume execution;
- fixture linter.

Add mandatory tests for default no-file discovery. Existing acceptance only covers explicit temporary fixture files and therefore missed this regression.

**Gate:** default and explicit paths execute the same canonical provider corpus and cannot silently select a stale duplicate.

## R5 — efficiency and committed-vector closure

Preserve the subsystem's original purpose: compact declarative behavioural testing with real production Lua.

Final acceptance:
1. lint full canonical fixture roots;
2. full canonical PNC corpus 116/116 PASS;
3. behaviour/pilot/observatory parity suites PASS;
4. real-Lua batch/cancel/resume PASS;
5. default CLI and main CLI smoke PASS with no explicit file;
6. focused GUI regression-controller tests PASS;
7. prove no stale `pnc.semantic-test.v1` active fixture authority remains;
8. prove no duplicate PNC fixture corpus remains in Core;
9. reconcile docs and commit participant Core first, ProjectHoomans last;
10. reconstruct exact committed vector and rerun acceptance.

**Gate:** the fixture-driven tester is again reliable as the canonical low-token semantic behavioural acceptance path.

## Non-goals

- do not rewrite semantic policy to make fixtures green;
- do not create another test engine or standalone UI;
- do not move generic testing machinery into ProjectHoomans;
- do not convert imperative low-level Lua contract tests merely for uniformity;
- do not claim native SP/MP acceptance.
