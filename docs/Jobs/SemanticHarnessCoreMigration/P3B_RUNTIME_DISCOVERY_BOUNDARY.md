# P3-B — runtime discovery boundary

## Result

PsychopatzCore now owns the provider-neutral local discovery helpers:

- numeric Build runtime selection;
- Lua/LuaJIT executable discovery;
- bounded Lua version probing;
- the shared runtime-directory pattern and configuration error type.

Project Hoomans retains its provider-specific repository and Dynamic Trading
discovery plus `HarnessConfig`, but imports the generic helpers from Core. The
old Hoomans import path remains available while callers migrate.

## Gates

- Core runtime-discovery tests pass.
- Existing Hoomans runtime-config, core-profile, runtime-package, and activity
  compatibility tests pass.
- No Hoomans production policy or Dynamic Trading merchant policy moved into
  Core.
