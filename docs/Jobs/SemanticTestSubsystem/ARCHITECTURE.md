# Architecture — Final Semantic Test Authority

## One behavioral authority

All provider semantic behavior is tested through:

```text
semantic.harness-test.v1
→ generic resolver/loader
→ typed operation registry
→ compiler probe and/or production Lua worker
→ generic comparator
→ CLI / GUI / batch
```

No GUI-specific hard-coded behavioral regression matrix may act as a second authority.

Named GUI Regression actions are presets over canonical semantic fixtures.

## Imperative tests

Imperative Python tests remain for implementation contracts:

- compiler/generation algorithms and determinism;
- fixture-engine internals;
- exact API validation/error/protocol envelopes;
- GUI widget/controller mechanics;
- save/persistence/native/network boundaries;
- performance/resource budgets;
- observatory/sweep/quality-analyzer algorithms;
- static ownership rules.

Running through `LuaSemanticWorker` is not itself evidence that a test is low-level.

## Identity and naming

Active fixture identity remains domain-first:

```text
fixtures/v1/<domain>/<semantic-concern>.json
suite = pnc.<domain>.<semantic-concern>
case  = <domain>.<semantic-concern>.<condition>
```

Retained imperative test files describe the implementation contract.

Human-facing descriptions, module docstrings, class names, and classification reasons should also use current semantic/contract language rather than obsolete roadmap milestones when practical.

Git history is the provenance archive.

## Assertion fidelity

A case must prove the concern named by its domain and ID.

Recognition evidence alone does not prove realization, suggestions, behavior, or flow outcome.

Prefer stable canonical evidence over prose text when available:

- semantic IDs;
- response pool/template/realization IDs;
- dialogue act/branch;
- flow transition;
- candidate/group IDs;
- grounded fact refs;
- typed action/result.

## Duplicate/overlap policy

- global exact behavioral duplicate → fail;
- same stimulus with distinct cross-domain assertions → allowed and reported;
- substantially subsumed fixture → consolidate unless a distinct contract is documented.

## Migration rule

Behavioral scenarios belong in fixtures after parity.

Imperative methods remain only when their primary responsibility is implementation-level.

Mixed files may be split at method responsibility.
