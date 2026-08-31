local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local npcProfile = {
    romanceStyle = "flirty",
    orientation = "bisexual",
}
local playerProfile = { orientation = "bisexual" }
local orientationAllowed = true
local record = {
    id = "npc-policy",
    isFemale = false,
    social = { personality = npcProfile },
}
local player = {
    isFemale = function() return false end,
    socialProfile = playerProfile,
}

PNC = {
    Conversation = {},
    SocialProfiles = {
        GetNPCProfile = function() return npcProfile end,
        GetPlayerProfileForPlayer = function() return playerProfile end,
        AreMutuallyOrientationCompatible = function()
            return orientationAllowed
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationLLMTools.lua")
T.load("ProjectHoomans", "server", "PNC/Networking/PNC_LLMSocialReactionPolicy.lua")

local Policy = PNC.Conversation.LLMSocialReactionPolicy
local relationship = {
    state = "friend",
    approval = 75,
    respect = 70,
    familiarity = 70,
    cooldowns = {},
}

local allowed, reason = Policy.Evaluate(
    "admire", record, player, relationship, 10
)
T.truthy(allowed, "admire is an exposed positive social intent")
T.equal(reason, "available", "admire has a normal policy result")

local cooldownType, cooldownUntil = Policy.CooldownMutation("admire", 10)
T.equal(cooldownType, "llm_positive_social",
    "positive reactions share one cooldown bucket")
T.equal(cooldownUntil, 34, "positive cooldown lasts one in-game day")
relationship.cooldowns[cooldownType] = cooldownUntil

local blocked, blockedReason, blockedDetails = Policy.Evaluate(
    "praise", record, player, relationship, 10
)
T.falsy(blocked, "praise cannot farm a second positive action that day")
T.equal(blockedReason, "positive_cooldown_active",
    "positive cooldown has a stable rejection reason")
T.equal(blockedDetails.retryAfterWorldHours, 24,
    "positive cooldown exposes remaining time")

local insultAllowed, insultReason = Policy.Evaluate(
    "insult", record, player, relationship, 10
)
T.truthy(insultAllowed, "insults remain unlimited during positive cooldown")
T.equal(insultReason, "available", "insult is not in the positive bucket")

local capabilities = Policy.BuildCapabilities(record, player, relationship, 10)
T.equal(#capabilities.available_reactions, 1,
    "cooldown capability list contains only the available insult")
T.equal(capabilities.available_reactions[1], "insult",
    "capability list keeps insult available")
T.equal(capabilities.flirt_reason, "positive_cooldown_active",
    "capabilities explain flirt cooldown state")

relationship.cooldowns[cooldownType] = nil
npcProfile.romanceStyle = "reserved"
local reserved, reservedReason = Policy.Evaluate(
    "flirt", record, player, relationship, 40
)
T.falsy(reserved, "reserved NPCs reject flirt")
T.equal(reservedReason, "personality_gate",
    "reserved personality is a deterministic flirt gate")

npcProfile.romanceStyle = "neutral"
relationship.approval = 65
relationship.familiarity = 50
local neutral, neutralReason = Policy.Evaluate(
    "flirt", record, player, relationship, 40
)
T.falsy(neutral, "neutral NPCs require a stronger romantic relationship")
T.equal(neutralReason, "personality_gate",
    "neutral personality uses the stronger relationship threshold")

npcProfile.romanceStyle = "flirty"
relationship.approval = 75
relationship.familiarity = 70
orientationAllowed = false
local incompatible, incompatibleReason = Policy.Evaluate(
    "flirt", record, player, relationship, 40
)
T.falsy(incompatible, "orientation-incompatible NPCs reject flirt")
T.equal(incompatibleReason, "orientation_gate",
    "flirt reports an orientation rejection")

orientationAllowed = true
local flirt, flirtReason = Policy.Evaluate(
    "flirt", record, player, relationship, 40
)
T.truthy(flirt, "flirty compatible NPCs accept a qualified flirt")
T.equal(flirtReason, "available", "qualified flirt is available")

local lowRelation = {
    approval = 20,
    familiarity = 10,
    cooldowns = {},
}
local lowFlirt, lowFlirtReason = Policy.Evaluate(
    "flirt", record, player, lowRelation, 40
)
T.falsy(lowFlirt, "flirt remains relationship-gated")
T.equal(lowFlirtReason, "relationship_gate",
    "flirt checks live directed relationship scores")

T.finish("pnc_llm_social_policy_smoke")
