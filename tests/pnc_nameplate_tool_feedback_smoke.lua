local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

local clock = 1000
getTimeInMillis = function() return clock end
UIFont = { Small = "Small", Medium = "Medium", Large = "Large" }
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value)
            return #tostring(value) * 7
        end,
        getFontHeight = function() return 12 end,
    }
end
PNC = {
    Core = { Now = function() return clock end },
    Nameplates = {
        Settings = {
            relationshipFeedbackScale = 1.0,
            nameplateTextScale = 1.0,
            nameplateBarScale = 1.0,
        },
    },
}
PNC.SettingsStore = {
    Set = function(_, key, value)
        PNC.Nameplates.Settings[key] = value
        return value
    end,
}

T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplateDisplaySettings.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplatePresentation.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplateToolFeedback.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplateToolFeedbackRenderer.lua")

local Feedback = PNC.NameplateToolFeedback
Feedback.Reset()
T.truthy(Feedback.PushResult({
    npcID = "npc-stay",
    commandID = "stay",
    accepted = true,
    reason = "commanded",
    requestID = "request-1",
    callID = "call-1",
    commandSource = "llm_tool",
}, clock), "accepted LLM order publishes feedback")

local accepted = Feedback.Get("npc-stay", clock + 100)
T.equal(accepted.status, "accepted", "accepted feedback status")
T.equal(Feedback.GetDisplayText(accepted),
    "Switching to Guard mode", "stay order uses guard-mode label")
T.falsy(Feedback.PushResult({
    npcID = "npc-stay",
    commandID = "stay",
    accepted = true,
    reason = "commanded",
    requestID = "request-1",
    callID = "call-1",
}, clock + 120), "duplicate tool result is ignored")

T.truthy(Feedback.PushResult({
    npcID = "npc-follow",
    commandID = "follow",
    accepted = false,
    reason = "not_owner",
    requestID = "request-2",
    callID = "call-2",
}, clock + 140), "rejected LLM order publishes feedback")
local rejected = Feedback.Get("npc-follow", clock + 160)
T.equal(rejected.status, "rejected", "rejected feedback status")
T.equal(Feedback.GetDisplayText(rejected),
    "Follow mode unavailable", "rejected order uses command label")
T.truthy(Feedback.Get("npc-stay", clock + 200),
    "separate NPC feedback remains independent")

local handlers = {}
PNC.Const = {
    CMD_CONVERSATION_RELATIONSHIP = "ConversationRelationship",
    CMD_LLM_SOCIAL_REACTION_RESULT = "LLMSocialReactionResult",
    CMD_PLAYER_EMOTE_INTERACTION_RESULT = "PlayerEmoteInteractionResult",
    CMD_COMPANION_COMMAND_RESULT = "CompanionCommandResult",
    CMD_SOCIAL_GREETING = "SocialGreeting",
    CMD_MAP_COMMAND_RESULT = "MapCommandResult",
    CMD_FACTION_TOLL = "FactionToll",
    CMD_CONVERSATION_CEASEFIRE_RESULT = "ConversationCeasefireResult",
    CMD_CONVERSATION_BLOCK = "ConversationBlock",
    CMD_CONVERSATION_OUTCOME = "ConversationOutcome",
    CMD_CONVERSATION_RECRUIT_RESULT = "ConversationRecruitResult",
    CMD_CONVERSATION_SETTLEMENT_ADMISSION_RESULT =
        "ConversationSettlementAdmissionResult",
    CMD_CONVERSATION_DEPARTURE_RESULT = "ConversationDepartureResult",
}
PNC.Network = { ClientState = {} }
PNC.Client = {
    Internal = {
        RegisterServerCommand = function(command, callback)
            handlers[command] = callback
        end,
    },
}
PNC.Conversation = {}
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_InteractionResults.lua")
Feedback.Reset()
handlers.CompanionCommandResult({
    commandID = "stay",
    id = "npc-router",
    requestID = "request-router",
    callID = "call-router",
    commandSource = "llm_tool",
    accepted = true,
})
T.equal(Feedback.GetDisplayText(Feedback.Get("npc-router", clock)),
    "Switching to Guard mode",
    "LLM command result enters the nameplate feedback pipe")

local calls = { rects = {}, texts = {} }
local manager = {
    drawRect = function(_, x, y, width, height, alpha, r, g, b)
        calls.rects[#calls.rects + 1] = { x, y, width, height, alpha, r, g, b }
    end,
    drawText = function(_, value)
        calls.texts[#calls.texts + 1] = value
    end,
}
local rendered = PNC.NameplateToolFeedbackRenderer.Draw(
    manager,
    "npc-router",
    100,
    80,
    { currentTime = clock + 200, zoom = 1 }
)
T.truthy(rendered, "active tool feedback renders")
T.truthy(#calls.rects > 0, "tool feedback renders a status marker")
T.contains(table.concat(calls.texts, "|"), "Guard mode",
    "tool feedback renderer draws the command label")

clock = clock + Feedback.DURATION_MS + 1
T.falsy(Feedback.Get("npc-router", clock),
    "tool feedback expires")

T.finish("pnc_nameplate_tool_feedback_smoke")
