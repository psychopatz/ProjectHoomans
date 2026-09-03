local T = require "tests/support/test"

T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 1000
local tickHandlers = {}
getTimeInMillis = function() return now end
getCurrentSaveName = function() return "social-flavor-test" end
getText = function(key) return key end
Events = {
    OnTick = {
        Add = function(callback) tickHandlers[#tickHandlers + 1] = callback end,
    },
}

PsychopatzCore = { Conversation = {} }
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Flavor = require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
local Names = require "PsychopatzCore/Conversation/PsychopatzNameParts"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"

local messages = {}
local deliveries = {}
local parts = Names.Split("Alexandra Maximilian Longsurname")
T.equal(parts.fullName, "Alexandra Maximilian Longsurname",
    "name helper retains the full identity")
T.equal(parts.firstName, "Alexandra",
    "name helper extracts the first name")
T.equal(parts.surname, "Maximilian Longsurname",
    "name helper extracts the surname")
T.equal(parts.addressName, "Alexandra",
    "name helper exposes the short spoken address")
EventBus.subscribe(Message.EVENT_TYPE, function(message)
    messages[#messages + 1] = message
end, "social-flavor-message-test")
EventBus.subscribe(Client.EVENT_DELIVERED, function(payload)
    deliveries[#deliveries + 1] = payload
end, "social-flavor-delivery-test")

Flavor.Register("test.social_comment", {
    npc = { "default line" },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = { "hostile line" },
        },
    },
})
T.equal(
    Flavor.Resolve("test.social_comment", "npc", "hostile", {
        socialRole = "hostile",
    }),
    "hostile line",
    "role-specific flavor variant"
)

Client.Reset()
Client.SetLLMProvider(nil)
local accepted = Client.Enqueue({
    eventID = "event:one",
    flavorID = "test.social_comment",
    family = "test_family",
    speakerID = "npc-one",
    socialRole = "hostile",
    context = { socialRole = "hostile" },
})
T.truthy(accepted, "normal flavor enters the queue")
T.equal(#tickHandlers, 1, "Core installs one client pump")
Client.Pump(now)
T.equal(#messages, 1, "normal flavor publishes a canonical message")
T.equal(messages[1].text, "hostile line", "message uses resolved flavor")
T.equal(messages[1].source.kind, "social_flavor", "message source is reusable")
T.equal(messages[1].source.excludeFromLLM, true,
    "routine flavor does not enter durable LLM memory by default")
T.equal(#deliveries, 1, "delivery event is emitted")

Client.Reset()
local first = Client.Enqueue({
    eventID = "event:merge:one",
    flavorID = "test.social_comment",
    family = "merge_family",
    speakerID = "npc-one",
    mergeKey = "npc-one:merge",
    context = { socialRole = "neutral" },
})
local second = Client.Enqueue({
    eventID = "event:merge:two",
    flavorID = "test.social_comment",
    family = "merge_family",
    speakerID = "npc-one",
    mergeKey = "npc-one:merge",
    context = { socialRole = "neutral" },
})
T.truthy(first, "first merge candidate enters queue")
T.truthy(second, "second merge candidate is accepted")
local snapshot = Client.GetQueueSnapshot()
T.equal(snapshot[1].mergedCount, 2, "same source events are merged")
Client.Pump(now)
T.equal(#messages, 2, "merged event publishes once")

Client.Reset()
local completeLLM
Client.SetLLMProvider(function(_, complete)
    completeLLM = complete
    return true
end)
T.truthy(Client.Enqueue({
    eventID = "event:llm",
    text = "deterministic fallback",
    family = "llm_family",
    speakerID = "npc-one",
    priority = 90,
    llmEligible = true,
}), "LLM-eligible event enters queue")
T.equal(Client.Pump(now), false, "LLM event waits during its grace period")
T.truthy(completeLLM, "client provider receives an async completion callback")
completeLLM("LLM reaction", { ttsManaged = true })
now = now + 1
T.truthy(Client.Pump(now), "LLM result becomes deliverable")
T.equal(messages[3].text, "LLM reaction", "LLM text wins over fallback")
T.equal(messages[3].source.llm, true, "LLM provenance is preserved")
T.equal(messages[3].presentationState.tts, false,
    "streamed ambient TTS suppresses the final duplicate voice packet")

Client.Reset()
Client.SetLLMProvider(nil)
T.truthy(Client.Enqueue({
    eventID = "event:normal:blocked",
    text = "ordinary chatter",
    family = "priority_family",
    speakerID = "npc-one",
    priority = 35,
}), "normal event enters priority queue")
T.truthy(Client.Enqueue({
    eventID = "event:critical",
    text = "Zombie behind you!",
    family = "threat_warning",
    speakerID = "npc-one",
    priority = 100,
}), "critical event enters priority queue")
Client.Pump(now)
T.equal(messages[4].text, "Zombie behind you!",
    "critical event outranks normal chatter")

Client.Reset()
T.truthy(Client.Enqueue({
    eventID = "event:collision:one",
    text = "First observer line",
    family = "collision_family",
    speakerID = "npc-one",
}), "first collision candidate enters queue")
T.truthy(Client.Enqueue({
    eventID = "event:collision:two",
    text = "Second observer line",
    family = "collision_family",
    speakerID = "npc-two",
}), "second collision candidate enters queue")
Client.Pump(now)
now = now + 5000
T.falsy(Client.Pump(now),
    "same-family queued chatter is suppressed after one delivery")
T.equal(#messages, 5, "cooldown prevents a second ambient line")

EventBus.clearOwner("social-flavor-message-test")
EventBus.clearOwner("social-flavor-delivery-test")
T.finish("pnc_social_flavor_core_smoke")
