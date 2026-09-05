local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")

PsychopatzCore = { Conversation = {} }
local diaryEntries = {}
local state = {
    snapshots = {
        ["npc-one"] = { id = "npc-one", name = "Mara" },
    },
}
local player = {
    getUsername = function() return "player-one" end,
}
local body = {
    isDead = function() return false end,
    Say = function() error("ambient greeting should use canonical message bus") end,
}

PNC = {
    Core = { Now = function() return 1234 end },
    Network = { ClientState = state },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
    Conversation = {
        Diary = {
            Append = function(npcID, entry)
                diaryEntries[#diaryEntries + 1] = {
                    npcID = npcID,
                    entry = entry,
                }
                return true
            end,
        },
    },
    Registry = {
        Get = function(id) return state.snapshots[id] end,
        GetLiveZombie = function(id)
            return id == "npc-one" and body or nil
        end,
    },
}

package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
getSpecificPlayer = function() return player end

T.load("PsychopatzCore", "common",
    "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common",
    "PsychopatzCore/Conversation/PsychopatzConversationMessage.lua")
T.load(CLIENT .. "PNC/UI/Nameplates/PNC_NameplateSpeech.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavor.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua")
T.load(CLIENT .. "PNC/Commands/PNC_CompanionCommandPresentation.lua")

local Message = PsychopatzCore.Conversation.Message
local Speech = PNC.NameplateSpeech
local Presentation = PNC.CompanionCommandPresentation

T.equal(
    Presentation.HandleSocialGreeting({
        eventID = "conversation:proximity_greeting:one",
        npcID = "npc-one",
        flavorID = "social_greeting_npc_neutral_warm_first",
        npcType = "neutral",
        relationshipTier = "warm",
        greetingState = "first",
        greetingDay = 1,
        relationshipDelta = { approval = 2, familiarity = 2 },
        relationshipBefore = { approval = 30 },
        relationshipAfter = { approval = 32 },
        applied = true,
    }),
    true,
    "ambient greeting is presented"
)
local speech = Speech.Get("npc-one")
T.truthy(speech, "ambient greeting reaches nameplate speech")
T.equal(speech.message.speakerKind, "npc", "ambient greeting is NPC speech")
T.equal(speech.message.presentationState.tts, true,
    "ambient greeting remains eligible for shared NPC TTS")
T.truthy(speech.text and speech.text ~= "",
    "ambient greeting resolves dynamic flavor text")
T.equal(#diaryEntries, 1, "ambient greeting is written to the diary")
T.equal(diaryEntries[1].entry.kind, "npc_proximity_greeting",
    "diary identifies the proximity greeting")
T.equal(
    Presentation.HandleSocialGreeting({
        eventID = "conversation:proximity_greeting:one",
        npcID = "npc-one",
        flavorID = "social_greeting_npc_neutral_warm_first",
    }),
    false,
    "duplicate ambient event is ignored"
)
T.equal(Message.GetGameDay(speech.message.worldAgeHours), 0,
    "canonical speech message carries game-day metadata")

return T.finish("pnc_social_greeting_presentation_smoke")
