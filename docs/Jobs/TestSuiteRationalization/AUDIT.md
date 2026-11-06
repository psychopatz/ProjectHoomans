# Audit — Test Suite Rationalization

## Original baseline

The original planning audit identified a large root `*_smoke.lua` estate plus Semantic Lab/Harness Python coverage and correctly required evidence-gated deletion rather than count-driven pruning.

The first implementation pass generated:
- 1,776 scoped files;
- 1,424 path families;
- 1,301 executable entries;
- 1,007 root Lua smoke files;
- 209 active Semantic Python modules after one superseded deletion.

It also repaired several stale tests/infrastructure failures and produced a green final root Lua run.

## Post-run reconciliation — 2026-11-06

A repository audit after the agent reported P6 complete found that the parent goal was **not completed**.

### 1. Most families were never actually reviewed

The generated manifest contained:

- `UNKNOWN_KEEP`: **1,217** entries/families with `finalDisposition: pending_family_review`;
- `KEEP_CANONICAL`: 471 entries;
- `KEEP_BOUNDARY_SPECIFIC`: 82 entries;
- `REPAIR`: 5 entries;
- `DELETE_SUPERSEDED`: 1 entry.

At distinct-family level, **1,217 of 1,424 families (85.5%) remained pending review**.

The audit tool explicitly defaulted executable tests to `UNKNOWN_KEEP` and generated the same generic “no deletion-gate proof” sentence when no hand-authored evidence existed. That is inventory conservatism, not family review.

### 2. The root Lua estate was almost entirely unresolved

For the 1,007 root Lua smoke files:
- 1,002 were left `UNKNOWN_KEEP`;
- 5 were classified `REPAIR`;
- no root Lua test was deleted or merged by the rationalization pass.

For the non-semantic root subset:
- 855 entries were identified;
- **854 remained `UNKNOWN_KEEP`**;
- only one non-semantic root test was a repair.

At the broader root executable-family level, roughly 95.5% still contained unresolved `UNKNOWN_KEEP` coverage.

Therefore the green `1007/1007` result proves regression health, not rationalization.

### 3. Work was disproportionately semantic

The changed root tests were:
- `tests/pnc_companion_commands_smoke.lua`;
- four `pnc_semantic_*` files.

Most additional test changes were under `tools/semantic_harness/tests/`.

The only proven deletion was `tools/semantic_harness/tests/test_contextual_dynamic_trading.py`, justified by a removed Hoomans trade graph and replacement ownership tests. That deletion remains valid evidence, but it does not represent repository-wide cleanup.

### 4. Previous P6 acceptance contradicted the job contract

`ACCEPTANCE.md` required “no unreviewed maintained test family in the manifest,” while 1,217 families were still marked `pending_family_review`.

P6 is therefore revoked. A generated default classification cannot satisfy final review.

### 5. Root Lua runtime is not the main problem

Measured current root Lua suite:
- 1,007 files;
- about 176,886 LOC / 6.24 MB of test source;
- about 23,244 assertions;
- about 9.8 seconds wall time.

The main root-Lua optimization opportunity is therefore maintainability, repeated scaffolding/mocks, file fragmentation, ownership clarity, agent search/context cost, and removal of real legacy coverage—not merely runtime.

By contrast, the full Semantic Python suite took about **1,036.64 seconds** for 209 modules. Semantic Python runtime optimization remains a separate high-value task.

### 6. Working-tree status was described inaccurately

The branch pointer remained at the verified HEAD and 0/0 relative to origin, but the local worktree contained many modified/untracked files from the implementation pass. “0/0 upstream” is not equivalent to a clean worktree.

## Preserved evidence from the first pass

The following are useful and should not be discarded merely because P6 was invalid:

- baseline inventory/reporting infrastructure;
- root/default/focused timing evidence;
- five evidence-backed stale-test repairs, subject to final diff review;
- refactor-binding fixes and related proof, subject to scope review;
- the proven superseded DynamicTrading Semantic Harness test deletion;
- measured slow Semantic Python families;
- full green developer regression evidence as a regression baseline.

Production-code changes made during the first pass are **not automatically accepted** by this reconciliation. They must remain preserved and be reviewed for contract necessity/scope before commit.

## Revised conclusion

The job remains **IN PROGRESS**.

The next mandatory work is:
1. correct the manifest/review-state model;
2. convert generic pending `UNKNOWN_KEEP` entries to `UNREVIEWED`;
3. perform an actual domain-by-domain review of the root/non-semantic estate;
4. then continue with semantic Python optimization and suite routing;
5. rerun final acceptance only after zero maintained families remain unreviewed.
