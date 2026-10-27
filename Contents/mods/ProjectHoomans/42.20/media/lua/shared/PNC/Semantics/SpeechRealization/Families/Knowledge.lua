-- Identity, knowledge, gossip, and activity realization families.

local Builders = require
    "PNC/Semantics/PNC_SpeechRealization_FamilyBuilders"
local phraseFamily = Builders.phraseFamily
local bondPhraseFamily = Builders.bondPhraseFamily
local identityKnownFamily = Builders.identityKnownFamily

return {
    ["semantic.question.identity"] = phraseFamily(
        "Identity", "I'll tell you my name once we've established some trust. What's yours?",
        "I'll tell you my name once we know each other. What should I call you?",
        "Not yet. Your name?", "I don't share my name yet. What's yours?"
    ),
    ["semantic.question.identity.known"] = identityKnownFamily(),
    ["semantic.question.knowledge.unknown"] = phraseFamily(
        "KnowledgeUnknown", "I don't have reliable information about that.",
        "I don't know enough about that to help.", "I don't know.",
        "I don't know that. Don't guess."
    ),
    ["semantic.question.knowledge.known"] = phraseFamily(
        "KnowledgeKnown", "I know about that.",
        "I know about that. I can share what I remember.", "I know it.",
        "I know enough."
    ),
    ["semantic.gossip.unknown"] = bondPhraseFamily(
        "GossipUnknown", "I haven't heard any news lately.",
        "I haven't heard any news, sorry.", "No news.",
        "I don't have anything to share."
    ),
    ["semantic.question.activity.fishing"] = phraseFamily(
        "ActivityFishing", "I'm trying to catch something.",
        "I'm trying to catch something. Give me a moment.", "Fishing.",
        "I'm fishing. Don't distract me."
    ),
    ["semantic.question.activity.dataset.keep_moving"] = phraseFamily(
        "ActivityKeepMoving", "I'm doing what I can to keep things moving.",
        "I'm doing what I can to keep things moving. Thanks for asking.",
        "Keeping busy.", "I'm keeping busy. Don't distract me."
    ),
}
