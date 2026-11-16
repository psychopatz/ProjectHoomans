# Agent Runbook — Portable PSDL / ConvoEngine

## Startup

For each participant repository:
1. read root `AGENTS.md`;
2. inspect branch/HEAD/upstream/worktree;
3. preserve unrelated work;
4. use compact inspection before broad source reads;
5. inspect exact source/tests when changing semantic/compiler behavior.

## Semantic authoring

Classify logic as:

```text
portable declaration → PSDL source
portable reusable algorithm → standard runtime
game/engine implementation → capability adapter
```

Put adopter-domain semantic programs in the adopter package. Keep reusable semantic stdlib in Core.

Organize variants by coherent semantic `domainPath` before generated size sharding.

## Inspection

Prefer progressive disclosure:

```text
psdl locate <id>
psdl get <id> --summary
psdl impact <id>
→ targeted source
→ canonical IR / portable plan
→ generated backend output only when necessary
```

## Generated output

Never hand-edit, hand-move or hand-rename generated artifacts.

Fix canonical source/package/naming authority and reconcile.

A hash suffix is not evidence of staleness; reconciliation owns staleness decisions.

## Validation

For changes affecting semantic grouping or generation, run focused tests first, then the relevant package/portability/lifecycle suites and canonical reconciliation/determinism gates.

Variant-growth changes must remain local to the affected semantic group.

## Git

Preserve unrelated staged/unstaged/untracked work. Stage exact phase-owned paths only. Participant commits precede primary/job-doc commits. Never push/publish/rebase/amend/force-update without explicit authorization.

Git history is the archive for completed roadmap phases.
