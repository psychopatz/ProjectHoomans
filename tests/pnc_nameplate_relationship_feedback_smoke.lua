local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

local clock = 1000
getTimeInMillis = function() return clock end
UIFont = { Small = "Small", Medium = "Medium", Large = "Large" }
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value) return #tostring(value) * 7 end,
        getFontHeight = function() return 12 end,
    }
end
getCore = function()
    return { getZoom = function() return 1 end }
end

PNC = {
    Core = { Now = function() return clock end },
    Network = { ClientState = {} },
    Conversation = {},
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
    "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedback.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplatePresentation.lua")
local defaultMetrics = PNC.NameplatePresentation.ScaleFor(0)
PNC.NameplateDisplaySettings.SetNameplateBarScale(1.5, false)
local largeMetrics = PNC.NameplatePresentation.ScaleFor(0)
T.equal(largeMetrics.barWidth, defaultMetrics.barWidth * 1.5,
    "nameplate bar setting scales health and stamina width")
T.equal(largeMetrics.barHeight, defaultMetrics.barHeight * 1.5,
    "nameplate bar setting scales health and stamina height")
T.equal(largeMetrics.barGap, defaultMetrics.barGap * 1.5,
    "nameplate bar setting scales the health-stamina gap")
PNC.NameplateDisplaySettings.SetNameplateBarScale(1.0, false)
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedbackRenderer.lua")
T.load("ProjectHoomans", "client",
    "PNC/Conversation/PNC_ConversationRelationship.lua")

local Feedback = PNC.NameplateRelationshipFeedback
Feedback.Reset()
T.falsy(Feedback.Observe("npc-initial", nil, {
    approval = 8,
    respect = 4,
}, { approval = 0, respect = 0 }, {
    source = "initial_presentation",
}, clock), "initial relationship presentation has no delta")

T.truthy(Feedback.Push("npc-up", {
    approval = 3,
    respect = 1,
}, { source = "gift", revision = 2 }, clock),
    "positive relationship delta publishes feedback")
local up = Feedback.Get("npc-up", clock + 120)
T.equal(up.direction, "up", "positive relationship uses an up arrow")
T.equal(up.score, 4, "positive feedback preserves the signed score")
T.truthy(up.alpha > 0, "positive feedback starts visible")
T.falsy(Feedback.Push("npc-up", {
    approval = 3,
    respect = 1,
}, { source = "duplicate", revision = 2 }, clock + 130),
    "same relationship revision is deduplicated")

T.truthy(Feedback.Push("npc-down", {
    approval = -4,
    familiarity = -1,
}, { source = "llm_tool", revision = 3 }, clock + 140),
    "negative relationship delta publishes feedback")
local down = Feedback.Get("npc-down", clock + 240)
T.equal(down.direction, "down", "negative relationship uses a down arrow")
T.equal(down.score, -5, "negative feedback preserves the signed score")

clock = clock + Feedback.DURATION_MS + 1
T.falsy(Feedback.Get("npc-up", clock), "expired feedback is removed")

Feedback.Reset()
local relationship = PNC.Conversation.Relationship
relationship.ReceivePresentation({
    npcID = "npc-observe",
    approval = 10,
    respect = 5,
    familiarity = 2,
    revision = 1,
})
relationship.ReceivePresentation({
    npcID = "npc-observe",
    approval = 14,
    respect = 7,
    familiarity = 2,
    revision = 2,
})
local observed = Feedback.Get("npc-observe", clock + 100)
T.equal(observed.direction, "up",
    "relationship presentation changes enter the feedback pipe")

local calls = { lines = {}, rects = {}, texts = {}, fonts = {} }
local manager = {
    drawLine2 = function(_, x1, y1, x2, y2, alpha, r, g, b)
        calls.lines[#calls.lines + 1] = {
            x1, y1, x2, y2, alpha, r, g, b,
        }
    end,
    drawRect = function(_, x, y, width, height, alpha, r, g, b)
        calls.rects[#calls.rects + 1] = {
            x, y, width, height, alpha, r, g, b,
        }
    end,
    drawText = function(_, value, _, _, _, _, _, _, font)
        calls.texts[#calls.texts + 1] = value
        calls.fonts[#calls.fonts + 1] = font
    end,
}
local rendered = PNC.NameplateRelationshipFeedbackRenderer.Draw(
    manager,
    "npc-observe",
    100,
    80,
    { currentTime = clock + 100, nameWidth = 30, zoom = 1 }
)
T.truthy(rendered, "relationship feedback renderer draws an active record")
T.truthy(#calls.lines > 0, "renderer emits arrow strokes")
T.truthy(#calls.rects > 0, "renderer emits the arrow stem")
local defaultArrowHeight = calls.rects[1][4]
T.truthy(defaultArrowHeight > 0,
    "renderer uses a readable relationship arrow size")
T.equal(PNC.NameplateDisplaySettings.GetRelationshipFeedbackFont(), UIFont.Small,
    "relationship feedback defaults to the nameplate text font")
T.equal(PNC.NameplateDisplaySettings.GetNameplateFont(), UIFont.Small,
    "nameplate text defaults to the small nameplate font")
PNC.NameplateDisplaySettings.SetNameplateTextScale(1.25, false)
T.equal(PNC.NameplateDisplaySettings.GetNameplateFont(), UIFont.Medium,
    "nameplate text size selects a larger readable font tier")
PNC.NameplateDisplaySettings.SetNameplateTextScale(1.0, false)
T.equal(calls.texts[1], "Approval +4.0",
    "renderer labels the approval relationship amount")
T.equal(calls.texts[6], "Respect +2.0",
    "renderer labels the respect relationship amount")
T.equal(PNC.NameplateRelationshipFeedbackRenderer.Colors.up.g, 1.0,
    "positive arrow uses green")
T.equal(PNC.NameplateRelationshipFeedbackRenderer.Colors.down.r, 1.0,
    "negative arrow uses red")

PNC.NameplateDisplaySettings.SetRelationshipFeedbackScale(0.5, false)
calls.lines = {}
calls.rects = {}
calls.texts = {}
calls.fonts = {}
rendered = PNC.NameplateRelationshipFeedbackRenderer.Draw(
    manager,
    "npc-observe",
    100,
    80,
    { currentTime = clock + 100, nameWidth = 30, zoom = 1 }
)
T.truthy(rendered, "relationship feedback remains drawable at minimum size")
T.truthy(calls.rects[1][4] < defaultArrowHeight,
    "relationship feedback setting scales the arrow geometry")
T.equal(calls.fonts[1], UIFont.Small,
    "relationship feedback setting selects smaller detail text")

local handlers = {}
PNC.Const = {
    CMD_CONVERSATION_RELATIONSHIP = "ConversationRelationship",
    CMD_LLM_SOCIAL_REACTION_RESULT = "LLMSocialReactionResult",
}
setmetatable(PNC.Const, {
    __index = function(_, key) return key end,
})
PNC.Client = {
    Internal = {
        RegisterServerCommand = function(command, callback)
            handlers[command] = callback
        end,
    },
}
PNC.Conversation.Diary = { Append = function() return true end }
PsychopatzCore = {
    DebugTrace = { IsEnabled = function() return false end },
}
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_InteractionResults.lua")
Feedback.Reset()
handlers[PNC.Const.CMD_LLM_SOCIAL_REACTION_RESULT]({
    requestID = "request-feedback",
    callID = "call-feedback",
    npcID = "npc-llm",
    accepted = true,
    relationship = {
        npcID = "npc-llm",
        approval = 7,
        respect = 4,
        familiarity = 1,
        revision = 8,
    },
    relationshipDelta = {
        approval = -3,
        respect = -1,
        familiarity = 0,
    },
    relationshipBefore = {
        approval = 10,
        respect = 5,
        familiarity = 1,
    },
    relationshipRevision = 8,
    eventID = "event-feedback",
})
local llmFeedback = Feedback.Get("npc-llm", clock + 100)
T.equal(llmFeedback.direction, "down",
    "LLM relationship results publish negative nameplate feedback")

handlers[PNC.Const.CMD_CONVERSATION_RELATIONSHIP]({
    source = "treated_wound",
    eventID = "event-treatment",
    summary = {
        npcID = "npc-treatment",
        approval = 14,
        respect = 12,
        familiarity = 3,
        revision = 9,
    },
    relationshipBefore = {
        npcID = "npc-treatment",
        approval = 10,
        respect = 10,
        familiarity = 2,
        revision = 8,
    },
    relationshipDelta = {
        approval = 4,
        respect = 2,
        familiarity = 1,
    },
})
T.equal(PNC.Network.ClientState.lastConversationDelta.source,
    "treated_wound", "central relationship transport preserves source")
T.equal(PNC.Network.ClientState.lastConversationDelta.delta.approval, 4,
    "central relationship transport preserves delta")
T.equal(PNC.Network.ClientState.lastConversationDeltas["npc-treatment"]
    .after.approval, 14, "central relationship transport stores after state")

T.finish("pnc_nameplate_relationship_feedback_smoke")
