-- Relationship-sensitive insult, thumbs-down, and first-contact replies.
PNC = PNC or {}
PNC.CompanionCommandFlavor = PNC.CompanionCommandFlavor or {}
local Flavor = PNC.CompanionCommandFlavor
local registerTypedReplies = (Flavor.DefinitionInternal or {}).registerTypedReplies
local registerDailyTypedReplies = (Flavor.DefinitionInternal or {}).registerDailyTypedReplies

registerTypedReplies("insult", "Insult", {
    hostile = { "Say that again and you'll regret it.", "Careful. I'm not in the mood." },
    neutral = { "That's unnecessary.", "Keep it respectful." },
    colonist = { "We're on the same side. Cut it out.", "Don't talk to me like that." },
    lover = { "You're lucky I know you.", "I know you're upset, but don't push me." },
    family = { "Watch your mouth.", "We're family; don't make this worse." },
})
registerTypedReplies("thumbsdown", "ThumbsDown", {
    hostile = { "Then stay out of my way.", "Keep making that face." },
    neutral = { "I got the message.", "You could just say what's wrong." },
    colonist = { "If you have a problem, tell me.", "We need to work together." },
    lover = { "I know that look. Talk to me.", "Tell me what bothered you, love." },
    family = { "I see the disapproval.", "Say what you mean." },
})
registerDailyTypedReplies("wavehi", "WaveHi", {
    hostile = {
        first = { "Keep your distance.", "I see you. Don't come closer." },
        returning = { "Still here? Keep moving.", "We already saw each other." },
    },
    neutral = {
        first = { "Hello.", "Morning." },
        returning = { "Hey again.", "There you are again." },
    },
    colonist = {
        first = { "Morning, good to see you.", "Hey, we're all here." },
        returning = { "Hey again, ready to work?", "Back again? Stay safe." },
    },
    lover = {
        first = { "There you are, love.", "Good morning, sweetheart." },
        returning = { "Hey, love. Again.", "I was hoping you'd come back." },
    },
    family = {
        first = { "There you are.", "Good to see you." },
        returning = { "Hey again.", "Already back?" },
    },
})

return Flavor
