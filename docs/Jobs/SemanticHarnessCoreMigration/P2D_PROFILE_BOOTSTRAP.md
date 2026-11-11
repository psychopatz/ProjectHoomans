# P2-D — Core profile bootstrap

Status: complete.

`PsychopatzCore.tools.semantic_harness.providers.profile_loader` composes
optional adopters through the Core provider registry and returns validated,
provider-neutral launch metadata:

- `SEMANTIC_HARNESS_PROFILE`
- `SEMANTIC_HARNESS_PROVIDER_IDS`
- `SEMANTIC_HARNESS_MATERIALIZATION_MODE`

The launcher and profile manager are Core-owned. Project Hoomans and Dynamic
Trading contribute manifests and production adapters; neither provides a
second profile loader or harness entrypoint.
