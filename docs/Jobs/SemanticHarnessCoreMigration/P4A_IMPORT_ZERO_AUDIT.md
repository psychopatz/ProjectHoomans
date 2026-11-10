# P4-A — obsolete ownership and import-zero audit

## Result

The provider-neutral Hoomans-owned duplicates found by the migration audit
are now removed from both runtime and tests:

- process/protocol/worker-session facades;
- activity/state facades;
- CodeBuilder catalog-naming/translation-support facades;
- duplicate Hoomans protocol, activity, generic session, and catalog-naming
  tests.

Remaining Hoomans runtime modules are policy-bearing adapters: scenario
defaults/validation, save/profiler ingestion, Hoomans conversation command
projection, authoring/knowledge/matrix operations, and physical worker
selection. They are not copies of Core mechanics and remain in Hoomans by
design.

## Evidence

- Core owns the only Python protocol, process, session, activity, state,
  scenario document, and generic CodeBuilder implementations.
- Hoomans production/test imports contain no references to the deleted
  compatibility paths or local generic CodeBuilder facades.
- Core generic protocol/session/activity/CodeBuilder tests remain in the Core
  suite; Hoomans keeps only adopter behavior and GUI-specific tests.
- Focused Hoomans CodeBuilder boundary tests pass (13 tests).

The broader Hoomans harness retains the three previously documented
translation/identity catalog failures. Native Project Zomboid SP/MP acceptance
is still user-owned.
