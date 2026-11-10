# PNC provider package

This directory contains Project Hoomans/PNC-specific adapters, production Lua
worker modules, fixtures, CodeBuilder source policy, and provider tests.

The executable Semantic Harness, launcher, UI, inspection, generic testing,
and Core contracts are owned by PsychopatzCore under
`tools/semantic_harness`. Launch the shared harness from Core with
`--profile pnc --repository <ProjectHoomans>`. This provider package must not
grow a second launcher or harness implementation.
