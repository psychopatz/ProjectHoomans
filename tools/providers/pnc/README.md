# PNC provider package

This directory contains Project Hoomans/PNC-specific adapters, production Lua
worker modules, provider fixtures/content policy, and provider tests. The
shared CodeBuilder and Semantic Lab implementation live only in Core.

The executable Semantic Harness, launcher, UI, inspection, generic testing,
mod manager, and Core contracts are owned by PsychopatzCore under
`tools/semantic_harness`. Launch the shared harness from Core with
`--preset pnc --repository <ProjectHoomans>` or compose it with Dynamic
Trading using `--preset pnc-with-dthoomans`. This provider package must not
grow a second launcher or harness implementation.

The provider manifest declares Project Hoomans' semantic, identity,
suggestion, world-discovery, and radio capabilities. Core resolves those
capabilities alongside future providers and routes them through one activation
plan.
