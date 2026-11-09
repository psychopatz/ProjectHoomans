# Test Suite Rationalization — current progress

**Status:** DEVELOPER-SIDE ACCEPTANCE PASSED. Native SP/MP acceptance remains user-owned.

**Current phase:** R0–R6 complete. The previous generic P6 completion claim was revoked and superseded by the evidence below.

**Repository:** branch `main`, HEAD `9572b548f19b6229a7c5e7887047baa9cc783993`, synchronized with `origin/main` (`0/0` ahead/behind). The worktree is intentionally dirty; synchronization is not being represented as cleanliness.

## R0 — review-state model and worktree triage

- `tools/test_estate_audit.py` now starts inventoried executable tests as `UNREVIEWED`; it no longer synthesizes reviewed-looking generic `UNKNOWN_KEEP` evidence.
- `AUDIT_MANIFEST.json` records entry and family review states, domain accounting, active/deleted counts, tier counts, classifications, and test-cost metrics.
- `R0_DIFF_REVIEW.json` separates pre-existing unrelated edits, concurrent work preserved outside rationalization, evidence-backed production contract/ownership repairs, worker infrastructure changes, and the accepted test/evidence changes. No scope-drift production change was accepted as rationalization.
- The proven deletion of `tools/semantic_harness/tests/test_contextual_dynamic_trading.py` remains recorded as `DELETE_SUPERSEDED`.

## R1 — complete root Lua estate review

- `R1_ROOT_DOMAIN_REVIEW.json` contains path-specific review for all 1,007 root Lua smoke files across 19 production-ownership domains.
- Each family records production subjects and callers/owners, runtime/authority boundary, assertion intent, overlap candidates, legacy/history review, cost, focused validation, and disposition.
- All 19 focused domain slices passed: `1,007/1,007`.
- No filename-similarity deletion or merge was inferred. Root dispositions are canonical, boundary-specific, or one of the five separately evidenced repairs.

## R2 — repeated-contract review

- `R2_REPEATED_CONTRACT_AUDIT.json` reviewed presence-boundary (107 files), inventory (30), MP/network (92), persistence/migration (23), and NPC foundation/adopter (13) high-density groups.
- Similar setup was not proof of parity: authority boundaries, production subjects, state ownership, migration stages, and diagnostics differed.
- Result: zero unsupported merges, deletions, tier moves, or fixture extractions. Existing isolation and per-case diagnostics remain intact.

## R3 — legacy and migration review

- `R3_LEGACY_FAMILY_AUDIT.json` cross-referenced 1,505 legacy-looking marker lines across 308 files against current production paths, callers, and history.
- Eight representative removal/migration/authority families were reviewed path-specifically and retained because they protect supported behavior or authority boundaries.
- Only the DynamicTrading test deletion passed all deletion gates; no additional legacy/debris deletion was proven.

## R4 — Semantic Python slow-family review

- `R4_SEMANTIC_SLOW_REVIEW.json` reviews the 12 measured slowest families, including response observatory, sweep acceptance, fixture parity, harness, contextual talk, behavior, social reactions, speech behavior, and related parity families.
- Baseline: `PASS 198 / SKIP 11 / FAIL 0`, 209 active modules, `1,036.639s`.
- Final routed run: `PASS 198 / SKIP 11 / FAIL 0`, 209 active modules, `1,005.234s`.
- Ten resource-sensitive modules were routed through the existing exclusive lane after a contention-only parallel failure; the isolated rerun passed `10/10`. No production authority assertion was weakened and no opaque replacement framework was added.

## R5 — suite topology

- `R5_SUITE_TOPOLOGY.json` defines FAST, DEFAULT, FOCUSED, INTEGRATION, ACCEPTANCE, and NATIVE using the existing runners.
- `tests/run_tests.py --domain <reviewed-domain>` selects reviewed root-domain paths without introducing a competing generic framework.
- The Python runner labels slow acceptance modules and routes resource-sensitive modules through its existing exclusive scheduling path while retaining the ACCEPTANCE tier.
- Native fixtures are reviewed and inventoried but were not executed; native SP/MP acceptance remains the user-owned handoff.

## R6 — final developer-side acceptance

Final `AUDIT_MANIFEST.json` state:

- 1,776 tracked-scope files; 1,775 active after one accepted superseded deletion.
- 1,424 families; 1,423 active families; 1,300 active executable entries.
- `REVIEWED=1,776` entries and `REVIEWED=1,424` families.
- `UNREVIEWED=0`, `pending_family_review=0`, and `UNKNOWN_KEEP=0`.
- Classifications: `KEEP_CANONICAL=1,275`, `KEEP_BOUNDARY_SPECIFIC=495`, `REPAIR=5`, `DELETE_SUPERSEDED=1`.

Developer validation recorded in `R6_FINAL_EVIDENCE.json`:

- Root default: before `FAIL 5/1,007` in `9.63s`; after `PASS 1,007/1,007` in `9.60s`.
- Semantic Lua: before `FAIL 4/144` in `3.22s`; after `PASS 144/144` in `3.28s`.
- Focused root slices: persistence `11/11`, presence `101/101`, inventory `41/41`, MP/network `80/80`.
- Root Python `22/22`, unique-NPC `6/6`, refactor checks `3,340` passing, doctor checks passing, and PZ verification `3,316` checks with zero errors.
- No unsupported merge was made. One superseded test family was deleted. Semantic execution routing was optimized without changing the declared acceptance tier.

The final worktree contains 67 status entries (45 modified, 1 deleted, 21 untracked), including preserved concurrent work and evidence artifacts. No reset, stash, discard, branch creation, native Project Zomboid launch, or Workshop publication was performed.
