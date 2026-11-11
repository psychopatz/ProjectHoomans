# Live composition bootstrap contract

PsychopatzCore owns the single manifest-driven composition path. It is injected
as infrastructure and is never exposed as a standalone user preset.

The canonical product compositions are:

| Selection | Resolved providers | Live shared bootstraps |
| --- | --- | --- |
| `pnc` | `PsychopatzCore`, `ProjectHoomans` | Core |
| `dtabstract` | `PsychopatzCore`, `DTCommon`, `DTAbstract` | Core, DTCommon, DTAbstract |
| `pnc-with-dthoomans` | `PsychopatzCore`, `ProjectHoomans`, `DTCommon`, `DTHoomans` | Core, DTCommon, DTHoomans |

Provider manifests declare the real shared-runtime entrypoints. Core resolves
those paths against the live repository checkouts, validates required files,
loads them in dependency order, and only then creates provider adapters.

The headless path adds only the selected shared/runtime module paths. It does
not copy client, server, UI, or fixture files into a second mod tree. The old
provider registry, profile loader, and adopter adapter-registration modules
were removed; `ModManager`, manifests, and `ActivationPlan` are the only
composition path.
