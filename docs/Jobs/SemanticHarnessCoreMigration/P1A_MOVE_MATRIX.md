# P1-A move matrix — Semantic Harness

Status: complete for the Python harness layer. Core owns the canonical
implementation and adopters import those canonical modules directly; no
compatibility façade or duplicate Python harness remains in an adopter.

| Core area | Canonical location | Owner |
| --- | --- | --- |
| Worker transport | `tools/semantic_harness/transport/` | PsychopatzCore |
| Lifecycle/state primitives | `tools/semantic_harness/core/` | PsychopatzCore |
| Provider discovery/composition | `tools/semantic_harness/providers/` | PsychopatzCore |
| Runtime discovery | `tools/semantic_harness/discovery/` | PsychopatzCore |
| GUI/CLI entrypoints | `tools/semantic_harness/entrypoints/` | PsychopatzCore |
| Production PNC worker | `tools/providers/pnc/runtime/` and `lua/` | Project Hoomans |

Project Hoomans and Dynamic Trading retain provider policy, production Lua
modules, fixtures/content, and provider tests. They do not retain Core
transport, lifecycle, registry, launcher, GUI, or CodeBuilder copies.

The remaining Lua extraction work is intentionally separate: production
worker modules such as relationship, save rehydration, inventory, and
provider-specific command handlers remain adopter-owned until their typed Core
capability contracts are implemented.
