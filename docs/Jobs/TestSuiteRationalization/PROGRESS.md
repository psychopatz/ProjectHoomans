# Test Suite Rationalization — current progress

**Status:** IN PROGRESS — previous P6 completion REVOKED after repository audit.
**Current continuation phase:** R0 — Correct review-state model and preserve evidence.
**Repository branch:** `main`.
**Baseline HEAD used by first pass:** `2d882b952ea41c855b8bcf3658c7b75b36945632`.
**Current worktree:** intentionally dirty with prior rationalization changes and evidence artifacts; branch synchronization must not be described as worktree cleanliness.

## Accepted evidence from the first pass

The following remains useful evidence, subject to final diff/scope review:

- P0 inventory established 1,776 scoped files, 1,424 path families and 1,301 executable entries.
- Root Lua baseline/final evidence: 1,007 smoke files; final regression `PASS 1007/1007` in about 9.82s.
- Root Lua source footprint measured after audit: about 176,886 LOC / 6.24 MB / ~23,244 assertions.
- Semantic Python final regression: 198 PASS, 11 SKIP, 0 FAIL across 209 active modules in about 1,036.64s.
- Five manifest-tracked stale-test repairs have specific historical/current-contract evidence.
- Refactor-binding, worker/doctor and related repairs produced passing focused evidence, but production changes still require scope review before final acceptance.
- `tools/semantic_harness/tests/test_contextual_dynamic_trading.py` has specific `DELETE_SUPERSEDED` evidence tied to the retired Hoomans trade graph and replacement DynamicTrading ownership tests.

## Invalidated completion claims

The previous P2/P6 completion claim is not accepted.

Post-run audit found:
- 1,217 of 1,424 families remained `UNKNOWN_KEEP` with `finalDisposition: pending_family_review` — **85.5% unresolved**.
- The audit generator defaulted executable coverage to `UNKNOWN_KEEP` and generated generic “no deletion proof” evidence; this was inventory conservatism, not review.
- Root Lua: 1,002 of 1,007 files remained generic `UNKNOWN_KEEP`; only five were repairs.
- Non-semantic root subset: 854 of 855 entries remained generic `UNKNOWN_KEEP`.
- At distinct root executable-family level, roughly 95.5% still contained unresolved `UNKNOWN_KEEP` coverage.
- No root Lua test was deleted/merged by the first pass.
- Most implementation/test edits centered on semantic/Harness work.
- The only proven deletion was one Semantic Harness Python module.
- The worktree was not clean despite 0/0 branch synchronization.

These facts directly violate final acceptance's requirement for no unreviewed maintained family.

## Revised review-state interpretation

Until R0 rewrites/regenerates the manifest:

- all generic `UNKNOWN_KEEP` entries whose final disposition is `pending_family_review` are treated as **`UNREVIEWED`**;
- only entries with specific evidence-backed dispositions count as reviewed;
- final acceptance requires zero `UNREVIEWED`.

## Current phase — R0

### Immediate Next Chunk

1. Recheck current local branch/HEAD/status/worktrees without discarding the existing dirty rationalization work.
2. Review the current diff and separate:
   - valid evidence artifacts and test-only repairs;
   - production changes required by proven current contracts;
   - any scope-drift production changes needing separate treatment.
3. Update `tools/test_estate_audit.py` so executable tests default to `UNREVIEWED`, not `UNKNOWN_KEEP`.
4. Remove the generic evidence path that converts an unreviewed entry into a reviewed-looking keep decision.
5. Regenerate the manifest and add review-state/domain-summary fields so remaining work is measurable.
6. Preserve the proven DynamicTrading deletion and specific repair evidence.
7. Establish the first non-semantic root domain batch for R1, prioritizing high-density/repeated-contract families rather than returning to semantic-only work.
8. Update PROGRESS with exact R0 evidence and continue automatically into R1.

## Remaining mandatory gap

R1-R6 remain mandatory. In particular:
- actually review the non-semantic root Lua estate;
- consolidate repeated contract families where parity permits;
- remove real legacy/migration/refactor debris;
- rationalize the 17-minute Semantic Python estate;
- establish useful suite/domain routing;
- reach zero unreviewed families before final acceptance.

Do not mark this goal complete because all current tests pass or because the raw count stays above/below 1,000.
