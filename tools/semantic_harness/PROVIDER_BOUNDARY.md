# Semantic harness provider boundary

Project Hoomans consumes the Core-owned semantic-harness protocol. Its worker
adds the Hoomans production modules and provider commands, while Core owns the
JSON-lines transport contract and serialization.

`tools/semantic_harness/lua/worker.lua` loads Core's `Protocol` module before
provider paths. The former Hoomans-local protocol implementation was removed;
new provider code must not reintroduce a second copy.

The Hoomans worker keeps the same request/response envelope and preserves the
legacy null behavior on decode. `Protocol.NULL` is available for explicit JSON
null values when building provider-neutral payloads.

This is the first Lua worker-boundary migration slice. Hoomans-specific worker
state, production module loading, and semantic policy remain provider-owned
until their own audited migration slices are completed.
