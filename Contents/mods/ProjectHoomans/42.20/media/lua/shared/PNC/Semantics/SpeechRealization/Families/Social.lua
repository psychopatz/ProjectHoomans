-- Social, bond, conflict, and boundary realization families.

local Builders = require
    "PNC/Semantics/PNC_SpeechRealization_FamilyBuilders"
local phraseFamily = Builders.phraseFamily
local bondPhraseFamily = Builders.bondPhraseFamily

return {
    ["semantic.social.acknowledged"] = bondPhraseFamily(
        "Acknowledged", "All right.", "All right. I hear you.", "All right.",
        "Understood. We'll leave it there."
    ),
    ["semantic.social.offer_friendly"] = bondPhraseFamily(
        "OfferHelp", "That's kind of you. I'll keep it in mind.",
        "Thank you. I'll keep it in mind.", "Thanks.",
        "No, thanks. I'll handle it."
    ),
    ["semantic.social.dispute_friendly"] = phraseFamily(
        "Dispute", "I see it differently, but we're okay.",
        "I see it differently, but we're still okay.", "I disagree.",
        "I disagree. Leave it there."
    ),
    ["semantic.social.dispute_stressed"] = phraseFamily(
        "DisputeStressed", "I hear you, but I need a moment.",
        "I hear you, but I need a moment before we continue.", "Need a moment.",
        "I hear you. Not now."
    ),
    ["semantic.social.dispute_trusted"] = phraseFamily(
        "DisputeTrusted", "I respect that. I still don't agree.",
        "I respect that. I still don't agree, but we can talk it through.",
        "I still disagree.", "I still don't agree. Leave it there."
    ),
    ["semantic.social.dispute_withdrawn"] = phraseFamily(
        "DisputeWithdrawn", "Let's leave it there.",
        "Let's leave it there for now.", "Leave it.",
        "Let's leave it there."
    ),
    ["semantic.social.threat_boundary"] = phraseFamily(
        "Threat", "Back off.", "Step back, please.", "Back off.",
        "Back away. Now."
    ),
    ["semantic.social.hostile_short"] = phraseFamily(
        "HostileShort", "Watch your mouth.", "Watch your mouth, please.",
        "Watch it.", "Watch your mouth. Now."
    ),
    ["semantic.social.hostile_withdrawn"] = phraseFamily(
        "HostileWithdrawn", "Then leave me alone.",
        "Please leave me alone for now.", "Leave me alone.",
        "Leave me alone. Now."
    ),
    ["semantic.social.hostile_stressed"] = phraseFamily(
        "HostileStressed", "That's enough. Keep it up and we're done.",
        "That's enough. Step back and we'll keep this calm.", "Enough. Back off.",
        "That's enough. Back away."
    ),
    ["semantic.social.hostile_boundary"] = phraseFamily(
        "HostileBoundary", "Don't talk to me like that.",
        "Please don't talk to me like that.", "Don't.",
        "Don't talk to me like that."
    ),
    ["semantic.conversation.acknowledged.default"] = phraseFamily(
        "ConversationAcknowledged", "All right. Ask if you want to talk more.",
        "All right. I'm here if you want to talk more.", "All right.",
        "Understood. We'll leave it there."
    ),
}
