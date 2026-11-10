local T = require "tests/support/test"

local CORE_ROOT = T.path("PsychopatzCore", "root", "")
local aired = {}
local callbacks = {}

PsychopatzCore = {
    CustomRadio = {
        AirEvent = function(channelID, eventType, context)
            aired[#aired + 1] = {
                channelID = channelID,
                eventType = eventType,
                context = context,
            }
            return true, { lines = { { text = "hello" } } }
        end,
    },
}

T.load(CORE_ROOT .. "shared/PsychopatzCore/Radio/PsychopatzRadioBroadcasts.lua")
local Broadcasts = PsychopatzCore.RadioBroadcasts

T.truthy(Broadcasts.RegisterProvider("test.radio", {
    channelID = "test.channel",
    onAired = function(result, specification)
        callbacks[#callbacks + 1] = {
            providerID = result.providerID,
            player = specification.player,
            context = result.context,
        }
    end,
}), "Core accepts a provider-neutral radio broadcaster")

local player = {}
local context = { event = "market_news" }
local ok, message, returnedContext = Broadcasts.Air("test.radio", {
    eventType = "news",
    context = context,
    player = player,
})
T.equal(ok, true, "Core airs provider content through CustomRadio")
T.truthy(message, "Core preserves the selected radio message")
T.equal(returnedContext, context,
    "Core preserves the provider context for post-air handling")
T.equal(#aired, 1, "Core uses one shared engine delivery call")
T.equal(aired[1].channelID, "test.channel",
    "provider channel is used when the request omits one")
T.equal(#callbacks, 1, "Core invokes the provider after accepted delivery")
T.equal(callbacks[1].providerID, "test.radio",
    "post-air callback receives the registered provider identity")
T.equal(callbacks[1].player, player,
    "post-air callback receives request-owned runtime context")

local mismatch, mismatchReason = Broadcasts.Air("test.radio", {
    channelID = "other.channel", eventType = "news",
})
T.equal(mismatch, false, "Core rejects a provider channel mismatch")
T.equal(mismatchReason, "broadcast_channel_mismatch",
    "Core reports the channel contract failure")

local missing, missingReason = Broadcasts.Air("missing.radio", {})
T.equal(missing, false, "Core rejects unknown broadcast providers")
T.equal(missingReason, "broadcast_provider_unavailable",
    "Core reports an unknown provider explicitly")

T.finish("pnc_core_radio_broadcast_service_smoke")
