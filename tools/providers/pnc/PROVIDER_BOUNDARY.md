# Semantic harness provider boundary

Project Hoomans consumes the Core-owned semantic-harness protocol. Its worker
adds the Hoomans production modules and provider commands, while Core owns the
JSON-lines transport contract and serialization.

`tools/providers/pnc/lua/worker.lua` loads Core's `Protocol` module before
provider paths. The former Hoomans-local protocol implementation was removed;
new provider code must not reintroduce a second copy.

The Hoomans worker keeps the same request/response envelope and preserves the
legacy null behavior on decode. `Protocol.NULL` is available for explicit JSON
null values when building provider-neutral payloads.

This is the first Lua worker-boundary migration slice. Hoomans-specific worker
state, production module loading, and semantic policy remain provider-owned
until their own audited migration slices are completed.

PsychopatzCore also exposes a neutral optional-adopter worker loader. Adopters
may provide Lua package-path templates, adapter module names, and the selected
execution provider through `WorkerLaunchSpec`; Core validates and dispatches
the shared `SemanticExecution` contract without naming an adopter. The real
Project Hoomans worker remains the Hoomans-owned production composition, while
its Python lifecycle, process, session, and state mechanics continue to come
from Core.

The provider package contains only Hoomans adapters, production Lua worker
modules, provider fixtures/content policy, and provider tests. Shared
CodeBuilder sources, the executable Semantic Harness, launcher, UI,
inspection, generic testing, and mod manager live only in Core under
`tools/semantic_harness`. Launch the shared harness from Core with `--preset
pnc --repository <ProjectHoomans>` or compose it with Dynamic Trading using
`--preset pnc-with-dthoomans`.
