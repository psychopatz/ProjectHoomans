local T = require "tests/support/test"
T.addPackagePaths()

local layout = {
    defaults = {},
    GetNormalized = function() return {} end,
}
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"] =
    function() return layout end

PsychopatzCore = {
    BridgeBootstrap = {
        IsEnabled = function() return true end,
    },
    Conversation = {
        Layout = layout,
        History = { Append = function() end },
        Text = { Resolve = function(value)
            return type(value) == "table" and value.fallback or tostring(value or "")
        end },
    },
}
PNC = { Network = { ClientState = {} } }
getTimeInMillis = function() return 1000 end
getCurrentSaveName = function() return "ambient-llm-test" end

T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_HoomansLLM.lua")
local Integration = PNC.HoomansLLM
local callbackText
local item = {
    eventID = "ambient:event:one",
    family = "combat_commentary",
    speakerID = "npc-one",
    speakerName = "Mara",
    playerUUID = "player-one",
    context = {
        name = "Mara",
        player = "Alexandra Maximilian Longsurname",
        playerFullName = "Alexandra Maximilian Longsurname",
        socialRole = "neutral",
        relationshipState = "neutral",
        relationshipTier = "reserved",
        eventType = "witnessed_player_kill",
    },
}
T.truthy(Integration.SubmitAmbientFlavor(item, function(value)
    callbackText = value
end), "ambient LLM request is accepted on the client")
local packet = Integration.Poll()
T.equal(packet.conversation_context.metadata.mode, "ambient_social",
    "ambient request identifies its non-gameplay mode")
T.equal(packet.conversation_context.npc_uuid, "npc-one",
    "ambient request scopes the NPC")
T.equal(#packet.conversation_context.available_tools, 0,
    "ambient request exposes no gameplay tools")
T.truthy(string.find(packet.conversation_context.message, "zombie", 1, true),
    "ambient request carries the witnessed-kill prompt")
T.equal(packet.conversation_context.player_name, "Alexandra",
    "ambient LLM receives the player's first name for speech")
T.equal(packet.conversation_context.player_full_name,
    "Alexandra Maximilian Longsurname",
    "ambient LLM retains the player's full identity separately")
T.equal(packet.conversation_context.player_surname,
    "Maximilian Longsurname",
    "ambient LLM receives the player's surname separately")
T.truthy(string.find(packet.conversation_context.message,
    "only their first name", 1, true),
    "ambient LLM is instructed not to address the player by full name")
local result = Integration.Deliver({
    request_id = packet.request_id,
    response_text = "That was impressive.",
})
T.truthy(result.accepted, "ambient LLM response is accepted")
T.equal(callbackText, "That was impressive.",
    "ambient response returns through the Core callback")
T.equal(Integration.Poll().status, "idle",
    "ambient request is cleared after delivery")

local teammateCallbackText
local teammateItem = {
    eventID = "ambient:event:teammate",
    family = "combat_commentary",
    speakerID = "npc-one",
    speakerName = "Mara",
    playerUUID = "player-one",
    context = {
        name = "Mara",
        player = "Alexandra Maximilian Longsurname",
        playerFullName = "Alexandra Maximilian Longsurname",
        victim = "Jordan Longsurname",
        victimFullName = "Jordan Longsurname",
        victimFirstName = "Jordan",
        victimSurname = "Longsurname",
        victimNPCID = "npc-two",
        socialRole = "colonist",
        relationshipState = "friend",
        relationshipTier = "warm",
        eventType = "witnessed_teammate_hurt",
    },
}
T.truthy(Integration.SubmitAmbientFlavor(teammateItem, function(value)
    teammateCallbackText = value
end),
    "teammate hurt LLM request is accepted")
local teammatePacket = Integration.Poll()
T.truthy(string.find(
    teammatePacket.conversation_context.message,
    "teammate take damage",
    1,
    true
), "teammate hurt LLM receives the correct event prompt")
T.equal(teammatePacket.conversation_context.victim_first_name, "Jordan",
    "teammate hurt LLM receives the injured first name")
T.equal(teammatePacket.conversation_context.victim_surname, "Longsurname",
    "teammate hurt LLM retains the injured surname separately")
local teammateDelivery = Integration.Deliver({
    request_id = teammatePacket.request_id,
    response_text = "Jordan Longsurname, Alexandra Maximilian Longsurname.",
})
T.truthy(teammateDelivery.accepted,
    "teammate hurt LLM response is accepted")
T.equal(teammateCallbackText, "Jordan, Alexandra.",
    "ambient LLM output uses first names at the presentation boundary")

T.finish("pnc_hoomans_llm_ambient_smoke")
