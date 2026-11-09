# Project Hoomans tests

Run the isolated Lua suite with compact output:

```sh
python3 tests/run_tests.py
python3 tests/run_tests.py profiler
python3 tests/run_tests.py --jobs 4 --verbose

# Select a reviewed root-Lua domain from the R1 ownership ledger.
python3 tests/run_tests.py --domain root_lua:inventory
python3 tests/run_tests.py --domain root_lua:presence_body
python3 tests/run_tests.py --domain root_lua:mp_network --list

# Detect private local helpers referenced across split Lua modules
python3 tests/refactor_binding_smoke.py
python3 tests/refactor_binding_smoke.py --all
```

The runner discovers the newest numeric Project Hoomans and PsychopatzCore
runtime directories, runs each test in a separate process, and prints successful
output only in verbose mode. Direct execution uses the fallback versions in
`tests/test_config.lua`.

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

Do not add `42.xx` or full `Contents/mods/...` paths to tests. Resolve source
through `T.load`, `T.read`, `T.path`, and `T.addPackagePaths` so runtime upgrades
require no test edits.

Suite tiers are explicit: the root runner is FAST/DEFAULT and supports focused
domain selection; the existing Semantic Harness Python runner is ACCEPTANCE
(`acceptance_slow` labels identify measured expensive modules without sharing
workers); refactor scans are FOCUSED; native fixtures are NATIVE and require
the user-owned Project Zomboid runtime. Integration/acceptance commands remain
on their existing runners rather than introducing another generic framework.
