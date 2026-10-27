-- Semantic conversation-topic realization families.

local Builders = require
    "PNC/Semantics/PNC_SpeechRealization_FamilyBuilders"
local phraseFamily = Builders.phraseFamily

return {
    ["semantic.question.whats_up.weather"] = phraseFamily(
        "ConversationWhatsUpWeather",
        "The weather is the main thing on my mind right now.",
        "The weather is the main thing on my mind right now. How are you holding up?",
        "Watching the weather.",
        "Watching the weather. Stay focused."
    ),
    ["semantic.question.whats_up.traveling"] = phraseFamily(
        "ConversationWhatsUpTraveling",
        "I'm keeping moving and watching what is ahead.",
        "I'm keeping moving and watching what is ahead. Come along if you want.",
        "Keeping moving.",
        "Keeping moving. Don't slow me down."
    ),
    ["semantic.question.whats_up.busy"] = phraseFamily(
        "ConversationWhatsUpBusy",
        "I'm keeping busy and trying to stay useful.",
        "I'm keeping busy and trying to stay useful. There's always something to do.",
        "Keeping busy.",
        "Keeping busy. Don't distract me."
    ),
    ["semantic.question.whats_up.default"] = phraseFamily(
        "ConversationWhatsUpDefault",
        "Not much. I'm just trying to keep things together.",
        "Not much. I'm just trying to keep things together. Good to see you, though.",
        "Just getting by.",
        "Nothing worth discussing. Stay alert."
    ),
    ["semantic.question.whats_up.default_alt"] = phraseFamily(
        "ConversationWhatsUpDefaultAlt",
        "Same as ever. Staying alive and watching the road.",
        "Same as ever. Staying alive and watching the road. What about you?",
        "Staying alive.",
        "Staying alive. Keep your eyes open."
    ),
}
