local T = require "tests/support/test"

local CLIENT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local speech = {}
local diary = {}
local player = {
    getUsername = function() return "alice" end,
}
local body = {}
local target = { id = "npc-one", name = "Morgan" }

PNC = {
    Core = { Now = function() return 1000 end },
    Semantics = {},
    Registry = {
        GetLiveZombie = function(id)
            return id == target.id and body or nil
        end,
        Get = function(id)
            return id == target.id and target or nil
        end,
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
    Conversation = {
        Diary = {
            Append = function(npcID, entry)
                diary[#diary + 1] = { npcID = npcID, entry = entry }
            end,
        },
    },
    SocialFlavorPresentation = {
        Receive = function(packet)
            speech[#speech + 1] = packet
            return true, "queued"
        end,
    },
}

getSpecificPlayer = function() return player end

T.load(CLIENT .. "PNC/Semantics/PNC_SemanticSpeechDelivery.lua")
local Delivery = PNC.Semantics.SemanticSpeechDelivery

local sessionMessages = {}
local session = {
    queueMessage = function(_, speaker, payload, metadata)
        sessionMessages[#sessionMessages + 1] = {
            speaker = speaker,
            payload = payload,
            metadata = metadata,
        }
    end,
}

local accepted, reason = Delivery.NPC({
    session = session,
    dedupeStore = {},
    eventID = "event-session",
    npcID = target.id,
    text = "Good.",
    semanticAct = "ACK",
    topic = "water",
    responsePlanID = "semantic.emote.reply",
    realizationFamily = "emote_reply",
    realizationID = "semantic.emote.reply.thumbsup",
    factRefs = { "fact:water" },
})
T.equal(accepted, true, "active conversation speech was not accepted")
T.equal(reason, "conversation_session", "active session route")
T.equal(#sessionMessages, 1, "active conversation delivered more than once")
T.equal(sessionMessages[1].speaker, "npc", "active session speaker")
T.equal(sessionMessages[1].payload.text, "Good.",
    "active session kept the selected semantic text")
T.equal(sessionMessages[1].metadata.source.realizationID,
    "semantic.emote.reply.thumbsup", "active session realization provenance")

local worldAccepted, worldReason = Delivery.NPC({
    dedupeStore = {},
    eventID = "event-world",
    npcID = target.id,
    target = target,
    playerActor = player,
    text = "Take care.",
    semanticAct = "FAREWELL",
    topic = "farewell",
    responsePlanID = "semantic.emote.reply",
    realizationFamily = "emote_reply",
    realizationID = "semantic.emote.reply.wavebye",
})
T.equal(worldAccepted, true, "world speech was not accepted")
T.equal(worldReason, "queued", "world speech route")
T.equal(#speech, 1, "world speech was delivered more than once")
T.equal(speech[1].text, "Take care.",
    "world route did not preserve resolved semantic text")
T.equal(speech[1].source.kind, "semantic_speech",
    "world route changed semantic speech provenance")
T.equal(speech[1].priority, 100,
    "world semantic speech is not protected from ambient suppression")
T.equal(speech[1].pumpImmediately, false,
    "generic world semantic speech changed its default pump policy")
T.equal(#diary, 0,
    "semantic delivery seam must not create a second diary write in this unit")

T.finish("pnc_semantic_speech_delivery_smoke")
