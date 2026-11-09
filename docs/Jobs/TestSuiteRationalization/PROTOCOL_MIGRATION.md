# Semantic worker protocol migration

The reviewed Hoomans-local semantic worker protocol was migrated to
PsychopatzCore in commit `3abbb21`.

| Migration record | Current owner | Hoomans adoption |
| --- | --- | --- |
| `migration:semantic-worker-protocol` | `psychopatzCore/tools/semantic_harness/lua/Protocol.lua` | `tools/semantic_harness/lua/worker.lua` imports Core `Protocol` |

The old Hoomans-local Lua implementation is deleted. The test-estate JSON
artifacts retain the review disposition under the migration record so their
historical coverage decision remains traceable without pointing at a file that
no longer exists.

The protocol boundary is covered by Core's protocol/JSON smoke tests and the
Hoomans worker-module and persistent-worker integration tests. This record does
not claim that the remaining provider-specific worker modules have migrated to
Core.
