# P2-D — Core profile bootstrap

## Contract

`PsychopatzCore.tools.semantic_harness.profile_loader` now composes optional
adopter registrars into the Core registry and returns a validated
`ProfileSelection`. The selection exposes only neutral launch metadata:

- `SEMANTIC_HARNESS_PROFILE`;
- `SEMANTIC_HARNESS_PROVIDER_IDS`;
- `SEMANTIC_HARNESS_MATERIALIZATION_MODE`.

The Core Lua worker consumes that metadata for its handshake and still loads
only Core modules. It does not import DynamicTrading or Project Hoomans, and
it does not infer provider policy from a profile name.

DynamicTrading now resolves `dtabstract` through this loader. Its provider
manifest remains the owner of the optional provider composition; the Core
loader only validates and transports the result.

## Deliberate boundary

This phase is bootstrap metadata, not the final DT conversation runtime. Core
does not claim that the minimal Core worker can execute merchant dialogue yet.
P3 will connect provider callbacks and materialization capability; P4 will
remove obsolete Hoomans worker/runtime duplicates only after those gates pass.
