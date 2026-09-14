local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 1000
local spoken = {}
local tickHandlers = {}
local messages = {}

getTimeInMillis = function() return now end
getText = function(key) return key end
getSpecificPlayer = function()
    return {
        getUsername = function() return "player-one" end,
        getDisplayName = function() return "Alex Survivor" end,
        Say = function(_, text) spoken[#spoken + 1] = text end,
    }
end
Events = {
    OnTick = {
        Add = function(handler) tickHandlers[#tickHandlers + 1] = handler end,
    },
}

PsychopatzCore = { Conversation = {} }
PNC = {
    Core = { Now = function() return now end },
    Conversation = {},
    Network = {
        ClientState = {
            playerContext = { characterUUID = "player-uuid" },
            conversationRelationships = {},
        },
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
}

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
local Farewell = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationFarewell.lua"
)

EventBus.subscribe(Message.EVENT_TYPE, function(message)
    messages[#messages + 1] = message
end, Farewell)

local function spec(id, entry)
    return {
        npcID = id,
        context = {
            player = getSpecificPlayer(0),
            npcName = "Mara Stone",
            entry = entry,
            conversationRelationshipID = "Acquaintance",
            tacticalClass = "neutral",
        },
    }
end

local familySpec = spec("npc-family", {
    id = "npc-family",
    snapshot = { name = "Mara Stone" },
    record = { generation = { relationshipKind = "sister" } },
})
local familyState = { npcID = "npc-family", token = "family-token" }

Client.Reset()
Farewell.Reset()
Farewell.RollChance = function() return true end
T.equal(Farewell.ResolveSocialRole(familySpec), "family",
    "family relationship resolves before farewell text selection")
local accepted, reason = Farewell.Schedule(
    familySpec,
    familyState,
    "close_button"
)
T.truthy(accepted, "ordinary close schedules a farewell exchange")
T.equal(reason, "scheduled", "farewell schedule reason")
T.equal(#spoken, 1, "player speaks immediately on the client")
T.truthy(spoken[1] ~= "", "family relationship produces player flavor")
T.equal(#Client.GetQueueSnapshot(), 0,
    "NPC line waits for the local farewell delay")

now = now + Farewell.NPC_DELAY_MS
Farewell.Pump(now)
T.equal(#Client.GetQueueSnapshot(), 1,
    "NPC line is queued after the local delay")
Client.Pump(now)
T.equal(#messages, 1, "NPC farewell publishes one canonical local message")
T.equal(messages[1].speakerID, "npc-family", "NPC farewell speaker identity")
T.equal(messages[1].presentationState.nameplate, true,
    "NPC farewell targets the nameplate")
T.equal(messages[1].presentationState.conversationUI, false,
    "NPC farewell stays out of the conversation UI")
T.equal(messages[1].source.eventType, "conversation_farewell",
    "farewell remains an ambient client event")

local hostile = spec("npc-hostile", {
    id = "npc-hostile",
    hostility = { attackPlayers = true },
})
T.equal(Farewell.ResolveSocialRole(hostile), "hostile",
    "hostility takes precedence over friendly presentation")

local lover = spec("npc-lover", {})
PNC.Network.ClientState.conversationRelationships["npc-lover"] = {
    state = "Lover",
}
T.equal(Farewell.ResolveSocialRole(lover), "lover",
    "server relationship summary selects lover presentation locally")

Farewell.Reset()
Client.Reset()
spoken = {}
Farewell.RollChance = function() return false end
T.falsy(Farewell.Schedule(
    familySpec,
    { npcID = "npc-family", token = "no-farewell" },
    "escape"
), "chance roll can suppress the exchange")
T.equal(#spoken, 0, "suppressed chance produces no player line")
T.equal(#Client.GetQueueSnapshot(), 0,
    "suppressed chance produces no NPC line")

Farewell.Reset()
Farewell.RollChance = function() return true end
local activeState = { npcID = "npc-family", token = "reopened" }
T.truthy(Farewell.Schedule(familySpec, activeState, "escape"),
    "reopened conversation initially schedules farewell")
PsychopatzCore.Conversation.instance = { spec = { npcID = "npc-family" } }
Farewell.Pump(now + Farewell.NPC_DELAY_MS)
T.equal(#Client.GetQueueSnapshot(), 0,
    "reopening the same NPC cancels the delayed farewell")

T.truthy(#tickHandlers > 0, "farewell installs a client tick pump")
T.finish("pnc_conversation_farewell_smoke")
