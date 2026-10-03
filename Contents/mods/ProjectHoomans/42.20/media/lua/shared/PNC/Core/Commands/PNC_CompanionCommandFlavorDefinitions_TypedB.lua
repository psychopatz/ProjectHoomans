-- Social greetings and the remaining relationship-sensitive emote replies.
PNC = PNC or {}
PNC.CompanionCommandFlavor = PNC.CompanionCommandFlavor or {}
local Flavor = PNC.CompanionCommandFlavor
local Helpers = Flavor.DefinitionInternal or {}
local registerSocialGreeting = Helpers.registerSocialGreeting
local registerTypedReplies = Helpers.registerTypedReplies

local SOCIAL_GREETING_LINES = {
    warm = {
        neutral = {
            first = { "Good to see you.", "I was hoping we'd cross paths." },
            returning = { "Back again already?", "Good, you're still around." },
        },
        colonist = {
            first = { "Good to see you. How's the camp holding?", "There you are. Ready for another day?" },
            returning = { "Back again. How's the work going?", "Good to see you again. Need anything?" },
        },
        lover = {
            first = { "There you are, love.", "I was hoping I'd see you today." },
            returning = { "Back so soon, love?", "I was hoping you'd come back." },
        },
        family = {
            first = { "There you are. You doing alright?", "Good to see you. Come here." },
            returning = { "Back again? You holding up?", "Good to see you again." },
        },
    },
    familiar = {
        neutral = {
            first = { "Hey. How have you been?", "Didn't expect to see you." },
            returning = { "Hey again. How's it going?", "There you are again." },
        },
        colonist = {
            first = { "Hey. Everything holding together?", "Good timing. We could use you." },
            returning = { "Hey again. Everything under control?", "Back again? Stay safe." },
        },
        lover = {
            first = { "Hey, love. How are you holding up?", "Good to see you, sweetheart." },
            returning = { "Hey again, love.", "You came back. Good." },
        },
        family = {
            first = { "Hey. You alright?", "Good to see you again." },
            returning = { "Hey again. You okay?", "Already back?" },
        },
    },
    reserved = {
        neutral = {
            first = { "Hello.", "Morning." },
            returning = { "Hey again.", "There you are again." },
        },
        colonist = {
            first = { "Morning.", "Hey. Stay safe out there." },
            returning = { "Hey again.", "Back already?" },
        },
        lover = {
            first = { "Hey, love.", "Morning, sweetheart." },
            returning = { "Hey again, love.", "There you are." },
        },
        family = {
            first = { "Morning.", "Hey. Take care of yourself." },
            returning = { "Hey again.", "Back already?" },
        },
    },
}

local socialGreetingTypes = { "neutral", "colonist", "lover", "family" }
local socialGreetingTiers = { "warm", "familiar", "reserved" }
local socialGreetingStates = { "first", "returning" }
local socialGreetingTypeIndex
local socialGreetingTierIndex
local socialGreetingStateIndex
local socialGreetingType
local socialGreetingTier
local socialGreetingState
local socialGreetingLines
for socialGreetingTypeIndex = 1, #socialGreetingTypes do
    socialGreetingType = socialGreetingTypes[socialGreetingTypeIndex]
    for socialGreetingTierIndex = 1, #socialGreetingTiers do
        socialGreetingTier = socialGreetingTiers[socialGreetingTierIndex]
        for socialGreetingStateIndex = 1, #socialGreetingStates do
            socialGreetingState = socialGreetingStates[socialGreetingStateIndex]
            socialGreetingLines = SOCIAL_GREETING_LINES[socialGreetingTier]
                [socialGreetingType][socialGreetingState]
            registerSocialGreeting(
                socialGreetingType,
                socialGreetingTier,
                socialGreetingState,
                socialGreetingLines
            )
        end
    end
end

registerTypedReplies("wavebye", "WaveBye", {
    hostile = { "Keep walking.", "Don't make this a conversation." },
    neutral = { "Take care.", "Goodbye." },
    colonist = { "Stay safe out there.", "See you at camp." },
    lover = { "Come back safe, love.", "I'll see you soon." },
    family = { "Take care of yourself.", "See you soon." },
})
registerTypedReplies("thankyou", "ThankYou", {
    hostile = { "Don't mistake this for friendship.", "Fine. It was nothing." },
    neutral = { "You're welcome.", "No trouble." },
    colonist = { "Anytime. We look after our own.", "That's what we're here for." },
    lover = { "Always, love.", "Anything for you." },
    family = { "Of course.", "You don't have to thank me." },
})
registerTypedReplies("thumbsup", "ThumbsUp", {
    hostile = { "Don't get comfortable.", "We'll see." },
    neutral = { "Good.", "Let's hope it holds." },
    colonist = { "Good work.", "That's how we get through this." },
    lover = { "That's my survivor.", "I knew you could do it." },
    family = { "That's the spirit.", "Proud of you." },
})
registerTypedReplies("clap", "Clap", {
    hostile = { "Save the celebration.", "Keep your hands to yourself." },
    neutral = { "Thanks, I guess.", "It was a small win." },
    colonist = { "Glad you were there.", "We did it together." },
    lover = { "You make a good audience.", "That means a lot, love." },
    family = { "You're too kind.", "Nice to hear that from you." },
})
registerTypedReplies("salute", "Salute", {
    hostile = { "Don't salute me.", "Stay sharp and stay away." },
    neutral = { "Stay sharp.", "Acknowledged." },
    colonist = { "Stay sharp, survivor.", "Right back at you." },
    lover = { "Always, love.", "Stay safe for me." },
    family = { "Stay sharp.", "Take care." },
})


return Flavor
