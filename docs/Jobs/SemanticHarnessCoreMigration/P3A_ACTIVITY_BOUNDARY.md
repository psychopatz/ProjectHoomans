# P3-A — activity stream ownership

## Result

`PsychopatzCore.tools.semantic_harness.activity` now owns the bounded activity
stream implementation used by the harness GUI, CLI, and worker lifecycle:

- in-memory bounded history;
- optional cross-process JSONL append/read;
- truncation and inode/head reset handling;
- compact event formatting;
- state-root path derivation.

Project Hoomans keeps `runtime/activity.py` only as a compatibility facade for
existing imports. It does not contain a second implementation. The facade
exports the same public symbols, including `ActivityLog`, formatting, and the
shared byte limit.

## Gates

- Core activity tests pass from the Core package.
- Hoomans activity, app, profile, and runtime-package tests pass through the
  compatibility import path.
- No gameplay or provider policy moved into Core.
- Deletion of the Hoomans facade remains deferred until all Hoomans callers
  import the Core path directly.
