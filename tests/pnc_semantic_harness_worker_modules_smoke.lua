local T = require "tests/support/test"

package.path = "./tools/semantic_harness/lua/?.lua;"
    .. package.path

local Protocol = require "worker/Protocol"
local RuntimeState = require "worker/RuntimeState"

T.equal(Protocol.VERSION, 1, "harness protocol version changed unexpectedly")
T.equal(Protocol.MAX_MESSAGE_BYTES, 256 * 1024,
    "harness protocol message bound changed unexpectedly")

local encoded = Protocol.encode({
    greeting = "Mara",
    nested = { true, 4 },
})
local decoded = Protocol.decode(encoded)
T.equal(decoded.greeting, "Mara", "protocol JSON round trip lost a string")
T.equal(decoded.nested[1], true, "protocol JSON round trip lost a boolean")
T.equal(decoded.nested[2], 4, "protocol JSON round trip lost a number")

local runtime = RuntimeState.new()
runtime.queued = { "old" }
runtime.transcript = { "old" }
runtime.trace = { "old" }
runtime.transport = { "old" }
runtime.translationLookups = { "old" }
runtime.llmCalls = 3
runtime.now = 1004
runtime.turn = 4
RuntimeState.resetContainers(runtime)

T.equal(#runtime.queued, 0, "runtime reset did not clear queued messages")
T.equal(#runtime.transcript, 0, "runtime reset did not clear transcript")
T.equal(#runtime.trace, 0, "runtime reset did not clear trace")
T.equal(#runtime.transport, 0, "runtime reset did not clear transport")
T.equal(#runtime.translationLookups, 0,
    "runtime reset did not clear translation lookups")
T.equal(runtime.llmCalls, 0, "runtime reset did not clear LLM calls")
T.equal(runtime.now, 1000, "runtime reset did not restore worker time")
T.equal(runtime.turn, 0, "runtime reset did not restore turn count")

return T.finish("pnc_semantic_harness_worker_modules_smoke")
