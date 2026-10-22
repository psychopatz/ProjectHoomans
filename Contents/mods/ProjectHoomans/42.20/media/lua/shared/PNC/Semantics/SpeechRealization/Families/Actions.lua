-- Generated action and companion response realization families.

local Builders = require
    "PNC/Semantics/PNC_SpeechRealization_FamilyBuilders"
local phraseFamily = Builders.phraseFamily

return {
    ["UI_PNC_Conversation_Semantic_GeneratedFollowQueued"] = phraseFamily(
        "CompanionFollow", "Of course, I'll follow.", "Of course, I'll follow you.",
        "I'll follow.", "I'll follow. Stay close."
    ),
    ["UI_PNC_Conversation_Semantic_GeneratedFollowQueuedFriendly"] = phraseFamily(
        "CompanionFollow", "Of course, I'll follow.", "Of course, I'll follow you.",
        "I'll follow.", "I'll follow. Stay close."
    ),
    ["UI_PNC_Conversation_Semantic_GeneratedFollowQueuedWithdrawn"] = phraseFamily(
        "CompanionFollow", "Of course, I'll follow.", "Of course, I'll follow you.",
        "I'll follow.", "I'll follow. Stay close."
    ),
}
