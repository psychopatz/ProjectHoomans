-- Semantic navigation exchange realization families.

local Builders = require
    "PNC/Semantics/PNC_SpeechRealization_FamilyBuilders"
local phraseFamily = Builders.phraseFamily

return {
    ["semantic.navigation.orders"] = phraseFamily(
        "NavigationOrders",
        "All right. What do you need?",
        "Sure. What do you need?",
        "What do you need?",
        "All right. What is it?"
    ),
    ["semantic.navigation.camp"] = phraseFamily(
        "NavigationCamp",
        "Where should we set up?",
        "Where should we set up camp?",
        "Where?",
        "Where do you want to risk it?"
    ),
    ["semantic.navigation.camp_empty"] = phraseFamily(
        "NavigationCampEmpty",
        "I don't see a good place to set up here.",
        "I don't see a safe place to set up here.",
        "No good place here.",
        "There is nowhere safe to set up here."
    ),
    ["semantic.navigation.subject_change"] = phraseFamily(
        "NavigationSubjectChange",
        "All right. What did you want to talk about?",
        "Sure. What did you want to talk about?",
        "What else?",
        "All right. What is it?"
    ),
    ["semantic.navigation.default"] = phraseFamily(
        "NavigationDefault",
        "All right. What would you like to discuss?",
        "Sure. What would you like to discuss?",
        "What is it?",
        "All right. What now?"
    ),
}
