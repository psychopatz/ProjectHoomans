# P4-B — final ownership audit

## Inventory

The audited harness roots currently contain:

| Repository | Python | Lua | Test modules | Ownership conclusion |
| --- | ---: | ---: | ---: | --- |
| PsychopatzCore | 31 | 11 | 12 | Core protocol, process/session, state/scenario documents, projections, registry, launch metadata, and reusable CodeBuilder contracts |
| ProjectHoomans | 894 | 96 | 211 | Hoomans authoring/UI/test estate; 19 runtime adapters, 23 policy-bearing CodeBuilder modules, and 95 physical/provider worker modules |
| DynamicTrading | 2 | 3 | 4 adapter tests | DTCommon/DTAbstract/DTHoomans manifest and thin abstract/physical adapters |

The Hoomans total includes the broad adopter UI/inspection/testing estate; it
is not evidence of duplicate Core ownership. Its remaining runtime modules
are scenario policy, save/profiler ingestion, physical worker composition,
Hoomans conversation operations, authoring, knowledge, matrix, and provider
projection adapters.

## Boundary checks

- Core has no imports of Project Hoomans or Dynamic Trading.
- Deleted Hoomans Core-only paths are absent: process, protocol,
  worker-session, activity, state, CodeBuilder naming/translation facades, and
  their duplicate generic tests.
- `dtabstract` and `dthoomans` both feed Core `WorkerLaunchSpec` and preserve
  abstract versus physical materialization.
- Hoomans adds DTHoomans launch metadata only when the optional DT runtime is
  discovered; the no-DT profile remains loadable.

## Developer-side gates

- Core full suite: 36 passing.
- Hoomans P4-A boundary/app/CodeBuilder suite: 26 passing.
- DynamicTrading provider matrix: 4 passing; Lua adapter smoke passing.
- Broad Hoomans harness: the three pre-existing catalog/translation failures
  remain documented (false-name disclosure, Tagalog identity translation,
  Tagalog identity/self-reflection catalog use); no migration-related import
  failure remains.

## Remaining acceptance

The parent goal is not marked complete yet. The remaining gate is native
Project Zomboid SP/MP validation: restart persistence, optional-mod enable /
disable combinations, nearby physical DTHoomans materialization, DTAbstract
abstract traversal, and cross-provider conversation/trade interaction. Those
checks require the user's running game/save authority and are not claimed by
the Python/Lua harness alone.
