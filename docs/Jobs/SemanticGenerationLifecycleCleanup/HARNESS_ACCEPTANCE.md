# Harness Acceptance — Semantic Generation Lifecycle

**Status:** ACCEPTED.

## Package / source acceptance

- Self-contained Core, ProjectHoomans and DTCommon packages resolve through generic imports.
- Semantic owner follows package/domain meaning.
- `domainPath` derives from source hierarchy and preserves broad runtime `domain`.

## Generated topology acceptance

Across all owners:
- generated behavior/beat data mirrors source-package ownership;
- director/runtime-plan surfaces use the same semantic decomposition;
- no cross-owner false naming collision;
- no avoidable `__????????.lua` output;
- retired generated module references are absent.

## Variant-growth acceptance

Real compact-source fixtures prove:
- adding a variant changes only its semantic group on both runtime-plan and director surfaces;
- adding a new subdomain creates local modules without renaming unrelated groups;
- enumeration order does not change output;
- cross-owner identical semantic leaves coexist without hash fallback.

## Portability acceptance

- production compile lowers through Portable Dialogue Plan;
- backend dispatch is descriptor-driven;
- Reference VM and Lua ConvoProbe execute equivalent semantic traces for the accepted corpus;
- authored and canonical schema lineage remain distinct/truthful.

## Final committed-vector acceptance

Require:
- canonical check clean before repair;
- G9R, G9, G8R7, G8 and lifecycle suites pass;
- `audit-s6m8 --check-determinism` passes;
- isolated ledger-owned generated-output deletion/rebuild succeeds;
- second apply is a no-op;
- final check clean;
- active documentation agrees on COMPLETE.
