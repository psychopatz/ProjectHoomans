# Semantic Test Subsystem — A6R5–A6R8 Semantic Test Estate Normalization

**Status:** COMPLETE.

## Objective

Finish the All-in-One PSDL Semantic Tester by making the active test estate self-describing, domain-first, single-authority, duplicate-resistant, and easy for humans/agents to navigate without opening files merely to learn what they test.

The execution architecture is already accepted:

```text
provider fixture
→ generic resolver/loader
→ typed operation registry
→ compiler probe and/or real LuaSemanticWorker
→ normalized result
→ comparator
→ CLI / GUI / batch
```

The remaining problem is test-estate hygiene, not another harness redesign.

## Verified current baseline

Audited committed vector:

- PsychopatzCore `dde5b8c225c8`
- ProjectHoomans `5b4da57d9cb3`

Verified:

- Core fixture/authority acceptance: **16/16 PASS**
- canonical semantic fixture corpus: **180/180 PASS**
- discovered semantic domains: **11**
- active v1 fixture files: **33**
- remaining Python test modules: **181 / 772 methods**

## Audit findings that reopen closure

- **96 / 180** expanded fixture cases still expose historical/migration terminology in suite or case IDs.
- **14** active v1 fixture files carry milestone/batch names such as `c0a`, `a6r2`, `b3`, or `batch1`.
- **18 / 33** active fixture files live under a directory that disagrees with their declared semantic domain.
- **41** remaining Python test modules / **165 methods** still use milestone-style names such as `c7a`, `h4`, `r9`, `e4`, or `l2`.
- Provider metadata still exposes two fixture authorities: `semantic` and legacy `regression`.
- Nine non-v1 provider fixture files remain active, including old C0A and Observatory regression data.
- The historical C0A baseline subsystem remains active through `c0a_baseline.py`, its tests, fixtures, and reports.
- Global duplicate audit found an exact duplicate case across two suites that the current linter does not detect.
- Several fixture names claim suggestion/realization behavior while only asserting generic recognition/response existence.
- A structural re-scan still found **36 LOW_LEVEL direct-worker modules / 165 methods** whose detected worker calls are already supported by the fixture pipeline; these require another method-level review, not automatic deletion.

Git history is the archive for milestone provenance. Active names should describe current semantic responsibility.
