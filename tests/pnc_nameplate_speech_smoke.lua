local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = {}
local now = 1000
local worldHours = 30
getTimeInMillis = function() return now end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
    }
end

T.load("PsychopatzCore", "common",
    "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common",
    "PsychopatzCore/Conversation/PsychopatzConversationMessage.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplateSpeech.lua")

local Message = PsychopatzCore.Conversation.Message
local Events = PsychopatzCore.Events
local Speech = PNC.NameplateSpeech
local received = Message.New({
    saveUUID = "speech-save",
    conversationID = "speech-conversation",
    sequence = 1,
    speaker = "npc",
    speakerID = "npc-one",
    speakerName = "One",
    speakerKind = "npc",
    text = "A full response that remains attached to the canonical message.",
    worldAgeHours = worldHours,
})

Message.Publish(received)
local record = Speech.Get("npc-one")
T.truthy(record, "nameplate receives canonical speech")
T.equal(record.message, received, "nameplate keeps canonical message identity")
T.equal(record.text, received.text, "short speech remains unchanged")

PsychopatzCore.Conversation.instance = {
    session = { conversationID = "speech-conversation" },
}
T.falsy(Speech.Get("npc-one"), "active conversation owns speech presentation")
PsychopatzCore.Conversation.instance = nil
T.truthy(Speech.Get("npc-one"), "speech returns when UI closes")

now = now + Speech.MAX_DURATION_MS + 1
T.falsy(Speech.Get("npc-one"), "expired speech leaves nameplate cache")

worldHours = 49
local nextMessage = Message.New({
    conversationID = "next-conversation",
    sequence = 1,
    speaker = "npc",
    speakerID = "npc-two",
    speakerKind = "npc",
    text = "New day.",
    worldAgeHours = worldHours,
})
Message.Publish(nextMessage)
T.falsy(Speech.Get("npc-one"), "day change clears previous speech")
T.truthy(Speech.Get("npc-two"), "new day speech is retained")

Events.clearOwner(Speech)
T.finish("pnc_nameplate_speech_smoke")
