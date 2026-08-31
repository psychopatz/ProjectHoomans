-- Server-authoritative policy for LLM-authored social reactions.
-- The LLM may suggest an intent, but this module decides whether the intent
-- is currently legal for the live NPC/player relationship.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.LLMSocialReactionPolicy =
    PNC.Conversation.LLMSocialReactionPolicy or {}

local Policy = PNC.Conversation.LLMSocialReactionPolicy
local Tools = PNC.ConversationLLMTools
local Profiles = PNC.SocialProfiles
local ProfileMath = PNC.SocialProfileMath
local ProfileTypes = PNC.SocialProfileTypes

Policy.VERSION = 1
Policy.POSITIVE_COOLDOWN_TYPE = "llm_positive_social"
Policy.POSITIVE_COOLDOWN_HOURS = 24

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function normalized(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s%-]", "_")
    return value
end

local function methodValue(target, methodName)
    local method = target and target[methodName]
    local ok
    local value
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target)
    if not ok then return nil end
    return value
end

local function relationshipGate(relationship)
    relationship = type(relationship) == "table" and relationship or {}
    local state = normalized(
        relationship.state
            or relationship.category
            or relationship.relationshipState
            or ""
    )
    local approval = finite(relationship.approval, 0)
    local familiarity = finite(relationship.familiarity, 0)
    return state == "lover"
        or state == "partner"
        or state == "spouse"
        or (approval >= 60 and familiarity >= 40)
end

local function npcProfile(record)
    local profile
    if Profiles and Profiles.GetNPCProfile then
        profile = Profiles.GetNPCProfile(record and record.id)
        if profile then return profile end
    end
    if not ProfileTypes then return nil end
    return ProfileTypes.NormalizeNPCPersonality(
        record and record.social and record.social.personality,
        record and record.identitySeed,
        record and record.archetypeID
    )
end

local function playerProfile(player)
    local profile
    if Profiles and Profiles.GetPlayerProfileForPlayer then
        profile = Profiles.GetPlayerProfileForPlayer(player)
        return profile
    end
    if not ProfileTypes or type(player) ~= "table" then return nil end
    if type(player.socialProfile) ~= "table" then return nil end
    return ProfileTypes.NormalizePlayerSocialProfile(player.socialProfile)
end

local function npcGender(record)
    if type(record) ~= "table" then return nil end
    if record.isFemale ~= nil then return record.isFemale == true end
    if record.identity and record.identity.isFemale ~= nil then
        return record.identity.isFemale == true
    end
    return nil
end

local function playerGender(player)
    local value
    if type(player) ~= "table" then return nil end
    value = player.isFemale
    if type(value) == "function" then
        value = methodValue(player, "isFemale")
    end
    if type(value) == "boolean" then return value end
    return nil
end

local function orientationCompatible(
    npcPersonality,
    npcIsFemale,
    playerPersonality,
    playerIsFemale
)
    if Profiles and Profiles.AreMutuallyOrientationCompatible then
        return Profiles.AreMutuallyOrientationCompatible(
            npcPersonality,
            npcIsFemale,
            playerPersonality,
            playerIsFemale
        )
    end
    if ProfileMath and ProfileMath.AreMutuallyOrientationCompatible then
        return ProfileMath.AreMutuallyOrientationCompatible(
            npcPersonality,
            npcIsFemale,
            playerPersonality,
            playerIsFemale
        )
    end
    return false
end

local function evaluateFlirt(record, player, relationship)
    local personality
    local playerSocialProfile
    local npcIsFemale
    local playerIsFemale
    if not relationshipGate(relationship) then
        return false, "relationship_gate"
    end
    personality = npcProfile(record)
    if not personality then return false, "personality_unavailable" end
    if personality.romanceStyle == "reserved" then
        return false, "personality_gate"
    end
    if personality.romanceStyle == "neutral"
        and (finite(relationship.approval, 0) < 70
            or finite(relationship.familiarity, 0) < 60)
    then
        return false, "personality_gate"
    end
    npcIsFemale = npcGender(record)
    playerIsFemale = playerGender(player)
    playerSocialProfile = playerProfile(player)
    if npcIsFemale == nil or playerIsFemale == nil
        or not playerSocialProfile
    then
        return false, "compatibility_data_unavailable"
    end
    if not orientationCompatible(
        personality,
        npcIsFemale,
        playerSocialProfile,
        playerIsFemale
    ) then
        return false, "orientation_gate"
    end
    return true, "available"
end

local function positiveCooldown(relationship, at)
    local cooldownUntil = relationship
        and relationship.cooldowns
        and tonumber(relationship.cooldowns[Policy.POSITIVE_COOLDOWN_TYPE])
        or nil
    if cooldownUntil ~= nil
        and (cooldownUntil ~= cooldownUntil
            or cooldownUntil == math.huge
            or cooldownUntil == -math.huge)
    then
        cooldownUntil = nil
    end
    if cooldownUntil and at < cooldownUntil then
        return false, cooldownUntil - at, cooldownUntil
    end
    return true, 0, cooldownUntil
end

function Policy.IsPositive(reaction)
    return normalized(reaction) ~= ""
        and normalized(reaction) ~= "insult"
end

function Policy.Evaluate(reaction, record, player, relationship, at)
    reaction = Tools and Tools.NormalizeReaction
        and Tools.NormalizeReaction(reaction) or nil
    at = math.max(0, finite(at, 0))
    if not reaction then return false, "unknown_reaction" end
    relationship = type(relationship) == "table" and relationship or {}
    if reaction == "flirt" then
        local allowed, reason = evaluateFlirt(record, player, relationship)
        if not allowed then return false, reason end
    end
    if Policy.IsPositive(reaction) then
        local available, remaining, cooldownUntil =
            positiveCooldown(relationship, at)
        if not available then
            return false, "positive_cooldown_active", {
                retryAfterWorldHours = remaining,
                cooldownUntil = cooldownUntil,
            }
        end
    end
    return true, "available"
end

function Policy.CooldownMutation(reaction, at)
    if not Policy.IsPositive(reaction) then return nil, nil end
    at = math.max(0, finite(at, 0))
    return Policy.POSITIVE_COOLDOWN_TYPE,
        at + Policy.POSITIVE_COOLDOWN_HOURS
end

require "PNC/Networking/PNC_LLMSocialReactionPolicy_Capabilities"

return Policy
