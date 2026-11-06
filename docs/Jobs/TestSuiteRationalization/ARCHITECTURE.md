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

## Review-state contract

Inventory and review are separate operations.

### `UNREVIEWED`

The test/family is known to exist but has not yet received a real production-subject, boundary, overlap, and cost review.

- This is the default for executable tests after inventory.
- It is not a keep decision.
- It is not deletion evidence.
- Any `pending_family_review` entry from the first pass is treated as `UNREVIEWED` unless later evidence proves a real review.
- Final acceptance requires **zero `UNREVIEWED` maintained families**.

### Reviewed classifications

After actual inspection, classify as one of:

- `KEEP_CANONICAL` — unique current contract/regression;
- `KEEP_BOUNDARY_SPECIFIC` — similar behavior, distinct execution/authority boundary;
- `MERGE` — meaningful assertions retained in a consolidated suite;
- `MOVE_TO_FOCUSED` — useful but not default-lane coverage;
- `MOVE_TO_ACCEPTANCE` — expensive/exhaustive developer acceptance;
- `DELETE_DUPLICATE` — equal-or-stronger current coverage proven elsewhere;
- `DELETE_SUPERSEDED` — only protects removed behavior/compatibility/migration path;
- `REPAIR` — intended current contract is valuable but the test is stale/broken;
- `UNKNOWN_KEEP` — the family was genuinely reviewed, but evidence remains insufficient to modify safely.

`UNKNOWN_KEEP` is not a fallback for skipped analysis. It requires specific evidence describing:
- production subjects inspected;
- execution/authority boundary;
- overlap candidates checked;
- why merge/delete/move is unsafe or unproven.

A generic sentence such as “no deletion proof found” does not satisfy review.

## Deletion gate

Delete a test only when repository evidence proves at least one:

1. the protected production behavior/path no longer exists;
2. equal-or-stronger current coverage exists at the same or more authoritative boundary;
3. all meaningful assertions were migrated into a consolidated suite and parity is proven;
4. it exclusively protects a deliberately removed compatibility/migration path.

Age, `smoke` naming, test count, or apparent similarity are never sufficient evidence.

## Desired topology

```text
FAST DEFAULT
  unit + cheap contract + essential regressions

FOCUSED
  subsystem/domain suites

INTEGRATION
  cross-domain / worker / process / network-boundary tests

ACCEPTANCE
  exhaustive matrices, parity sweeps, slow developer-side gates

NATIVE
  user-owned Project Zomboid SP/MP acceptance
```

A test's tier is separate from its usefulness. Moving a slow test out of default execution can be a successful optimization without deleting it.

## Domain-review model

The root Lua estate must be reviewed domain-by-domain, not merely by a global generated scan. Typical domains include semantic, NPC, conversation, inventory, faction/community, MP/network, facility/building, colony, abstract world/traversal, combat/zombies, presence/body, map, companion/tasking/work, fishing/scavenge, persistence, animation, compatibility, and remaining small families.

For each domain:
1. group tests by production subject/authority rather than filename alone;
2. inspect loaded modules/callers and assertion intent;
3. identify overlap, legacy paths, repeated mocks/setup, and one-contract-per-file fragmentation;
4. disposition each family with specific evidence;
5. consolidate/remove only after focused parity;
6. rerun the domain slice and broader regression as appropriate.

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

This job optimizes tests and test infrastructure. Do not change production behavior simply to make obsolete tests green. If a test reveals an actual current production defect, record the defect and fix it only when needed to preserve an approved current contract. Production changes discovered during test work must be separately justified; test cleanup is not blanket authorization for unrelated refactoring.

## Manifest

The audit manifest is a generated working artifact, not completion evidence by itself. It must contain enough information to prove actual review:

`path/family -> runner -> subject -> boundary -> review state -> classification -> overlap checked -> action -> specific evidence -> final disposition`.

Do not turn it into a manually maintained permanent database if it can be regenerated from repository truth.
