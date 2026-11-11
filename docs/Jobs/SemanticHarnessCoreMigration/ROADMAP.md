# Roadmap — Live semantic harness compositions

**Parent status:** developer-side implementation complete.

**Completion boundary:** a single manifest-driven harness can select each
product composition, inject Core first, load real shared-runtime files from the
live repositories, and expose the same contract to the GUI, CLI, and workers.

## Ownership

- PsychopatzCore owns discovery, validation, dependency resolution, activation
  plans, runtime bootstrap loading, transport, worker lifecycle, and generic
  UI/CLI selection.
- Project Hoomans owns PNC semantic/world policy and its provider manifest.
- Dynamic Trading owns DTCommon, DTAbstract, DTHoomans policy and its provider
  manifest.
- Future expansions add manifests and data presets; Core does not gain product
  branches.

## Phases and gates

1. **Manifest migration.** Every provider declares dependencies, routes,
   materialization, and live bootstrap entrypoints. Core is infrastructure, not
   a selectable product. Gate: canonical selections resolve deterministically.
2. **Runtime activation.** The Lua worker loads Core and selected provider
   shared entrypoints in dependency order, with bounded diagnostics. Gate:
   `runtimeBootstraps` reports actual existing files and provider adapters load.
3. **Adopter convergence.** PNC and Dynamic Trading consume the same plan;
   fixture flags and old adapter-registration shims do not control activation.
   Gate: PNC, DTAbstract, and DTHoomans live smoke checks pass.
4. **Surface and regression coverage.** GUI/CLI expose only canonical product
   compositions and tests cover future manifest-based providers. Gate: Core
   suite, focused PNC configuration tests, syntax checks, and `run_harness.sh`
   smoke checks pass.

Native Project Zomboid SP/MP validation remains a separate user-owned gate.
