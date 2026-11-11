# P3-C — worker client configuration boundary

## Result

PsychopatzCore now owns the neutral worker-client metadata seam on
`WorkerLaunchSpec`:

- `from_profile_selection()` transfers validated profile/provider/materialization
  metadata into a generic launch spec;
- `neutral_environment()` emits only `SEMANTIC_HARNESS_*` worker metadata;
- `LuaProcess` consumes that seam while preserving adopter-supplied private
  environment aliases.

Project Hoomans retains the policy that selects its repository, runtime,
worker script, physical materialization, and worker arguments. Its
`build_worker_launch_spec()` adapter now constructs Core's client spec rather
than delegating through a Hoomans process wrapper.

## Removed duplicate paths

All production and test callers now import Core directly for protocol,
process, and serialized worker-session mechanics. The following unreferenced
duplicate Hoomans files were deleted:

- `tools/semantic_harness/transport/process.py`
- `tools/semantic_harness/transport/protocol.py`
- `tools/semantic_harness/core/worker_session.py`

Hoomans scenario defaults/validation, runtime discovery, activity-path
validation, UI, and production-module policy remain adopter-owned.

## Gates

- Core semantic-harness tests: 36 passing.
- Hoomans runtime/config/package/protocol/session/codebuilder/catalog and
  worker-harness regression slice: passing.
- DynamicTrading provider-adapter Python tests: 3 passing.
- DynamicTrading Lua Core-adapter smoke: passing.
- No Hoomans production/test import references remain for the three deleted
  runtime paths.

Native Project Zomboid SP/MP behavior remains a user-owned acceptance gate;
this phase does not claim Workshop publication or native-runtime validation.
