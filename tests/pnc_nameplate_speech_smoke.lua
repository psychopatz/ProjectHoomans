local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = {}
UIFont = { Small = "Small", Medium = "Medium" }
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
T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplatePresentation.lua")

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
    presentationState = {
        nameplate = true,
        speechColor = { r = 34, g = 68, b = 255, a = 0.8 },
    },
})

Message.Publish(received)
local record = Speech.Get("npc-one")
T.truthy(record, "nameplate receives canonical speech")
T.equal(record.message, received, "nameplate keeps canonical message identity")
T.equal(record.text, received.text, "short speech remains unchanged")
local speechColor = PNC.NameplatePresentation.GetSpeechColor(record)
T.equal(speechColor.r, 34 / 255, "nameplate speech red color")
T.equal(speechColor.g, 68 / 255, "nameplate speech green color")
T.equal(speechColor.b, 1, "nameplate speech blue color")
T.equal(speechColor.a, 0.8, "nameplate speech alpha")

local createdSpeechObject
TextDrawObject = {
    new = function(...)
        local object = {}
        object.setDefaultColors = function(_, r, g, b, a)
            object.defaultColor = { r = r, g = g, b = b, a = a }
        end
        object.setOutlineColors = function(_, r, g, b, a)
            object.outlineColor = { r = r, g = g, b = b, a = a }
        end
        object.ReadString = function(_, font, text, maxChars)
            object.font = font
            object.text = text
            object.maxChars = maxChars
        end
        createdSpeechObject = object
        return object
    end,
}
PNC.NameplatePresentation.CreateSpeechTextObject(
    "first line\nsecond line",
    speechColor,
    12
)
T.equal(createdSpeechObject.font, "Medium", "speech uses player-sized font")
T.equal(createdSpeechObject.text, "first line[br/]second line",
    "speech preserves explicit line breaks")
T.equal(createdSpeechObject.maxChars, 12,
    "speech uses bounded word-wrap width")
T.equal(createdSpeechObject.defaultColor.b, 1,
    "speech applies message color")
T.equal(createdSpeechObject.outlineColor.r, 0,
    "speech applies dark outline")

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
