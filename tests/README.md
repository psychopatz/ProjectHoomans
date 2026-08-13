# Project Hoomans tests

Run the isolated Lua suite with compact output:

```sh
python3 tests/run_tests.py
python3 tests/run_tests.py profiler
python3 tests/run_tests.py --jobs 4 --verbose
```

The runner discovers the newest numeric Project Hoomans and PsychopatzCore
runtime directories, runs each test in a separate process, and prints successful
output only in verbose mode. Direct execution of migrated tests uses the fallback
versions in `tests/test_config.lua`; use the runner for unmigrated legacy tests.

New tests use the shared harness:

```lua
local T = require "tests/support/test"
local Subject = T.load("ProjectHoomans", "shared", "PNC/Path/Subject.lua")

T.truthy(Subject, "subject did not load")
T.finish("pnc_subject_smoke")
```

Generate that shell with:

```sh
python3 tests/new_test.py subject --layer shared --subject PNC/Path/Subject.lua
```

Do not add `42.xx` or full `Contents/mods/...` paths to new tests. The legacy
compatibility preload keeps old tests working across runtime upgrades while they
are migrated incrementally.
