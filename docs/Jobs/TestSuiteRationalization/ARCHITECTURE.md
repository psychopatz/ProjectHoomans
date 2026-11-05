# Architecture — Rationalized Test Estate

## Core rule

Every maintained test must justify itself with at least one unique current value:

- a distinct production contract;
- a distinct failure mode;
- a distinct authority/runtime boundary;
- a historically important regression that is still possible;
- a distinct integration path;
- or acceptance evidence that cheaper tests cannot provide.

Similarity of file names or inputs is not enough to classify tests as duplicates.

## Classification contract

Each maintained test/family is classified as one of:

- `KEEP_CANONICAL` — unique current contract/regression;
- `KEEP_BOUNDARY_SPECIFIC` — similar behavior, distinct execution/authority boundary;
- `MERGE` — meaningful assertions retained in a consolidated suite;
- `MOVE_TO_FOCUSED` — useful but not default-lane coverage;
- `MOVE_TO_ACCEPTANCE` — expensive/exhaustive developer acceptance;
- `DELETE_DUPLICATE` — equal-or-stronger current coverage proven elsewhere;
- `DELETE_SUPERSEDED` — only protects removed behavior/compatibility/migration path;
- `REPAIR` — intended current contract is valuable but the test is stale/broken;
- `UNKNOWN_KEEP` — purpose cannot yet be proven; deletion forbidden.

## Deletion gate

Delete a test only when repository evidence proves at least one:

1. the protected production behavior/path no longer exists;
2. equal-or-stronger current coverage exists at the same or more authoritative boundary;
3. all meaningful assertions were migrated into a consolidated suite and parity is proven;
4. it exclusively protects a deliberately removed compatibility/migration path.

Age, `smoke` naming, test count, or apparent similarity are never sufficient evidence.

## Desired topology

The suite should converge, where practical, toward:

```text
FAST DEFAULT
  unit + cheap contract + essential regressions

FOCUSED
  subsystem-specific suites

INTEGRATION
  cross-domain / worker / process / network-boundary tests

ACCEPTANCE
  exhaustive matrices, parity sweeps, slow developer-side gates

NATIVE
  user-owned Project Zomboid SP/MP acceptance
```

A test's tier is separate from its usefulness. Moving a slow test out of default execution can be a successful optimization without deleting it.

## Consolidation principles

Prefer:
1. removing truly dead/superseded coverage;
2. shared fixtures/helpers for repeated setup;
3. table-driven/declarative cases when the execution boundary remains identical;
4. existing test frameworks over new competing harnesses;
5. clear case IDs and failure localization;
6. bounded process reuse only when state isolation is proven.

Preserve:
- server/client and SP/MP authority contracts;
- persistence and supported migrations;
- identity/incarnation/presence lifecycle;
- inventory/state ownership;
- live/abstract transitions;
- network cleanup/reconnect/death behavior;
- semantic actions that can mutate gameplay/relationships;
- public domain/module contracts;
- still-reproducible historical bug regressions.

## Production boundary

This job optimizes tests and test infrastructure. Do not change production behavior simply to make obsolete tests green. If current production is actually defective, record the defect separately and only fix it when required to preserve an approved current contract.

## Manifest

P0 must create a machine-readable or generated audit manifest outside watched `media/` (format chosen from existing tooling where possible) containing enough information to prove every maintained test family was reviewed:

`path/family -> runner -> subject -> boundary -> classification -> overlap -> action -> evidence -> final disposition`.

Do not turn the manifest into another manually maintained permanent database if it can be regenerated from repository truth.
