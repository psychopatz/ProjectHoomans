-- Bounded semantic profile for routine zombie-kill reactions.
--
-- This module derives presentation meaning from existing personality, traits,
-- condition, relationship, and zombie-pressure owners. It persists nothing
-- and does not authorize gameplay effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Profile = PNC.Semantics.CombatReactionProfile or {}
PNC.Semantics.CombatReactionProfile = Profile

Profile.VERSION = 1
Profile.SCHEMA = "semantic.combat.reaction_profile.v1"

local TraitContext = PNC.NPCTraitContext
    or require "PNC/Core/Traits/PNC_NPCTraitContext"
local Style = PNC.Semantics.SpeechStyleContext
    or require "PNC/Semantics/PNC_SpeechStyleContext"

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return tonumber(fallback) or 0 end
    return value
end

local function unit(value, fallback)
    return math.max(0, math.min(1, number(value, fallback)))
end

local function relationshipFor(record, playerKey)
    local social = type(record) == "table" and record.social or nil
    local relationships = social and social.relationships or nil
    return type(relationships) == "table"
        and type(relationships[playerKey]) == "table"
        and relationships[playerKey] or {}
end

local function personalityFor(record)
    if type(record) ~= "table" then return {} end
    local social = type(record.social) == "table" and record.social or {}
    return type(social.personality) == "table" and social.personality
        or type(record.personality) == "table" and record.personality
        or type(record.socialProfile) == "table" and record.socialProfile
        or {}
end

local function conditionFor(record)
    return type(record) == "table"
        and type(record.conditionStats) == "table"
        and record.conditionStats or {}
end

local function healthState(record)
    local health = type(record) == "table" and record.health or nil
    local state = tostring(health and health.state or "")
    if state == "incapacitated" or state == "critical"
        or state == "wounded" or state == "injured"
    then return "injured" end
    local current = tonumber(health and health.current)
    local maximum = tonumber(health and health.max)
    if current and maximum and maximum > 0 and current < maximum then
        return "injured"
    end
    return "okay"
end

local function pressureFor(record, options)
    local observation = type(options.zombieObservation) == "table"
        and options.zombieObservation
        or type(record) == "table"
            and type(record.runtime) == "table"
            and type(record.runtime.zombieObservation) == "table"
            and record.runtime.zombieObservation
        or {}
    return tostring(observation.band or options.combatPressure or "none"),
        math.max(0, math.floor(number(
            observation.nearbyCount or observation.hordeCount, 0
        )))
end

local function relationshipTier(relationship)
    local state = tostring(relationship.state or relationship.category or "")
    local approval = number(relationship.approval, 0)
    local familiarity = number(relationship.familiarity, 0)
    if state == "enemy" or state == "rival" then return "reserved" end
    if state == "friend" or approval >= 30 then return "warm" end
    if approval >= 10 or familiarity >= 5 then return "familiar" end
    return "reserved"
end

local function quantityText(band, count)
    if count > 0 then
        return tostring(count) .. " zombies are still close enough to matter."
    end
    if band == "massive_horde" then return "There is a massive horde nearby." end
    if band == "horde" then return "There is a horde nearby." end
    if band == "several" then return "There are several zombies nearby." end
    if band == "few" then return "There are only a few zombies nearby." end
    return "I don't see another immediate group nearby."
end

local function nextAction(band)
    if band == "massive_horde" or band == "horde" then
        return "Keep moving and avoid getting surrounded."
    end
    if band == "several" then
        return "Clear the nearby zombies before we relax."
    end
    return "Check the area, then keep moving."
end

function Profile.Build(record, playerKey, options)
    options = type(options) == "table" and options or {}
    local relationship = relationshipFor(record, tostring(playerKey or ""))
    local personality = personalityFor(record)
    local traits = TraitContext and TraitContext.Collect
        and TraitContext.Collect(record) or {}
    local condition = conditionFor(record)
    local pressure, nearbyCount = pressureFor(record, options)
    local panic = number(condition.panic, 0)
    local stress = number(condition.stress, 0)
    local bravery = unit(personality.bravery, 0.5)
    local aggression = unit(personality.aggression, 0.5)
    local compassion = unit(personality.compassion, 0.5)
    local socialStyle = tostring(personality.socialStyle or "neutral")
    local state = tostring(
        relationship.state or relationship.category or "unknown"
    )
    local styleProjection = Style.Resolve({
        npcID = record and record.id,
        npcRecord = record,
        npcTraits = traits,
        npcPersonality = personality,
        relationship = relationship,
        relationshipState = state,
        dialogueSituation = {
            npc = {
                inCombat = options.inCombat == true,
                healthState = healthState(record),
            },
        },
    })
    local speechVariant = tostring(
        styleProjection and styleProjection.variant or "neutral"
    )

    local mood = "steady"
    if panic >= 70 then mood = "panicked"
    elseif stress >= 0.75 or panic >= 45 then mood = "tense" end

    local dangerousPressure = pressure == "several"
        or pressure == "horde" or pressure == "massive_horde"
    local aggressiveTrait = traits.pnc_berserker == true
        or traits.pnc_reckless == true
        or traits.pnc_trigger_happy == true
        or traits.pnc_brawler == true
    local shakenTrait = traits.pnc_cowardly == true
        or traits.pnc_nervous_fighter == true
        or traits.pnc_frayednerves == true
    local braveTrait = traits.pnc_veteran == true
        or traits.pnc_ironnerves == true
        or traits.pnc_disciplined_fighter == true
    local supportiveTrait = traits.pnc_friendly == true
        or traits.pnc_peacemaker == true
    local reservedTrait = traits.pnc_reserved == true
        or traits.pnc_withdrawn == true

    local reactionStyle
    if state == "enemy" or state == "rival" then
        reactionStyle = "cold"
    elseif (mood == "panicked" or mood == "tense"
            or (shakenTrait and dangerousPressure))
        and not braveTrait
    then
        reactionStyle = "shaken"
    elseif aggressiveTrait or aggression >= 0.72 then
        reactionStyle = "aggressive"
    elseif supportiveTrait
        or compassion >= 0.66
            and (state == "friend"
                or relationshipTier(relationship) ~= "reserved")
    then
        reactionStyle = "supportive"
    elseif braveTrait or bravery >= 0.72 then
        reactionStyle = "brave"
    elseif speechVariant == "terse" or socialStyle == "withdrawn"
        or reservedTrait
    then
        reactionStyle = "reserved"
    else
        reactionStyle = "practical"
    end

    local health = healthState(record)
    local healthText = health == "injured"
        and "I'm hurt, but I'm still moving."
        or mood == "panicked"
            and "I'm not hurt, but I need a second."
            or "I'm okay."

    return {
        schemaVersion = Profile.VERSION,
        schema = Profile.SCHEMA,
        combatReactionRole = tostring(options.role or "witness"),
        combatReactionStyle = reactionStyle,
        combatReactionMood = mood,
        combatPressure = pressure,
        killerActorKind = tostring(options.actorKind or "player"),
        relationshipState = state,
        relationshipTier = relationshipTier(relationship),
        socialStyle = socialStyle,
        healthState = health,
        health = healthText,
        nextAction = nextAction(pressure),
        quantity = quantityText(pressure, nearbyCount),
        nearbyZombieCount = nearbyCount,
        speechVariant = speechVariant,
        traits = traits,
        provenance = {
            personality = "social.personality",
            traits = "NPCTraitContext",
            condition = "conditionStats",
            relationship = "directed_relationship",
            pressure = "ZombieObservation",
            speechStyle = "SpeechStyleContext",
        },
    }
end

return Profile
