local T = require "tests/support/test"

local coreRepository = os.getenv("PZ_TEST_CORE_REPOSITORY")
    or "../psychopatzCore"
package.path = coreRepository .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. coreRepository .. "/tools/semantic_harness/lua/?.lua;"
    .. package.path
package.path = "./tools/semantic_harness/lua/?.lua;"
    .. package.path

local Protocol = require "Protocol"
local RuntimeState = require "worker/RuntimeState"
local Values = require "worker/Values"
local TransportEvidence = require "worker/TransportEvidence"

T.equal(Protocol.VERSION, 1, "harness protocol version changed unexpectedly")
T.equal(Protocol.MAX_MESSAGE_BYTES, 1024 * 1024,
    "harness protocol message bound changed unexpectedly")

local encoded = Protocol.encode({
    greeting = "Mara",
    nested = { true, 4 },
    explicitNull = Protocol.NULL,
})
local decoded = Protocol.decode(encoded)
T.equal(decoded.greeting, "Mara", "protocol JSON round trip lost a string")
T.equal(decoded.nested[1], true, "protocol JSON round trip lost a boolean")
T.equal(decoded.nested[2], 4, "protocol JSON round trip lost a number")
T.truthy(string.find(encoded, '"explicitNull":null', 1, true),
    "protocol JSON round trip lost the Core null marker")

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

local source = { nested = { value = 3 } }
local bounded = Values.copy(source)
bounded.nested.value = 4
T.equal(source.nested.value, 3, "Core value copy aliased source state")
T.equal(Values.number("4", 0), 4, "Core number normalization failed")

local dispatches, facts = TransportEvidence.partition({
    { command = "SemanticInteractionLifecycle", id = 1 },
    { command = "UnknownCommand", id = 2 },
})
T.equal(#facts, 1, "Core transport evidence did not classify interaction fact")
T.equal(#dispatches, 1, "Core transport evidence lost unknown dispatch")

return T.finish("pnc_semantic_harness_worker_modules_smoke")
