local T = require "tests/support/test"

local CLIENT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local speech = {}
local diary = {}
local playerFlavorCalls = 0
local npcFlavorCalls = 0
local player = {
    getUsername = function() return "alice" end,
}
local target = { id = "npc-one", name = "Morgan" }
local body = {}

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
    Network = { ClientState = {} },
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
    CompanionCommandPresentation = {
        Internal = {},
    },
}

PNC.CompanionCommandPresentation.Internal.Registry = PNC.Registry
PNC.CompanionCommandPresentation.Internal.Flavor = {
    Resolve = function(_, speaker)
        if speaker == "npc" then npcFlavorCalls = npcFlavorCalls + 1 end
        if speaker == "player" then playerFlavorCalls = playerFlavorCalls + 1 end
        return "compatibility text"
    end,
}
PNC.CompanionCommandPresentation.BuildFlavorContext = function()
    return { name = target.name, names = target.name, count = 1 }
end

getSpecificPlayer = function() return player end

T.load(CLIENT .. "PNC/Commands/PNC_CompanionCommandPresentation_PlayerEmoteResult.lua")

local result = {
    requestID = "request-1",
    eventID = "interaction-1",
    emote = "thumbsup",
    targets = {
        {
            npcID = target.id,
            accepted = true,
            resolvedText = "Good.",
            responsePlanID = "semantic.emote.reply",
            realizationFamily = "emote_reply",
            realizationID = "semantic.emote.reply.thumbsup",
            factRefs = { "fact:water" },
            interactionType = "player_emote_thumbs_up",
            interaction = {
                source = "emote",
                act = "ACK",
                topic = "water",
            },
            replyInteraction = {
                source = "npc_speech",
                act = "ACK",
                topic = "water",
            },
        },
    },
}

local handled = PNC.CompanionCommandPresentation
    .HandlePlayerEmoteInteractionResult(result)
T.equal(handled, true, "semantic emote result was not handled")
T.equal(#speech, 1, "resolved semantic reply was not delivered once")
T.equal(speech[1].text, "Good.",
    "semantic result delivery changed the resolved text")
T.equal(speech[1].responsePlanID, "semantic.emote.reply",
    "semantic result lost response plan provenance")
T.equal(speech[1].realizationID, "semantic.emote.reply.thumbsup",
    "semantic result lost realization provenance")
T.equal(speech[1].family, "emote_interaction_reply",
    "semantic emote reply was left in the player emote queue family")
T.equal(speech[1].priority, 100,
    "semantic emote reply is not suppressed by the player emote queue")
T.equal(speech[1].pumpImmediately, true,
    "semantic emote reply is not pumped immediately")
T.equal(speech[1].source.deliveryOwner, "player_emote",
    "semantic emote reply diary ownership is not explicit")
T.equal(npcFlavorCalls, 0,
    "resolved semantic text was fed back through NPC Flavor selection")
T.equal(playerFlavorCalls, 1, "player emote presentation was not resolved")
T.equal(#diary, 1, "semantic emote result was not recorded once")
T.equal(diary[1].entry.npcText, "Good.",
    "diary did not retain the delivered semantic text")

local duplicate = PNC.CompanionCommandPresentation
    .HandlePlayerEmoteInteractionResult(result)
T.equal(duplicate, false, "duplicate emote result was replayed")
T.equal(#speech, 1, "duplicate semantic reply was delivered")
T.equal(#diary, 1, "duplicate semantic reply was recorded")

T.finish("pnc_semantic_emote_result_delivery_smoke")
