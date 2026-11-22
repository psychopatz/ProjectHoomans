-- Bounded semantic profile for routine zombie-kill reactions.
--
-- This module derives presentation meaning from existing personality, traits,
-- condition, relationship, and zombie-pressure owners. It persists nothing
-- and does not authorize gameplay effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Profile = PNC.Semantics.CombatReactionProfile or {}
PNC.Semantics.CombatReactionProfile = Profile

Profile.VERSION = 1
Profile.SCHEMA = "semantic.combat.reaction_profile.v1"

local TraitContext = PNC.NPCTraitContext
    or require "PNC/Core/Traits/PNC_NPCTraitContext"
local Style = PNC.ConvoEngine.SpeechStyleContext
    or require "PNC/ConvoEngine/SpeechStyleContext"

local function resolveDispositionProjection()
    local dp = PNC and PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if type(dp) == "table" and type(dp.Resolve) == "function" then
        return dp
    end
    if type(require) == "function" then
        local ok, loaded = pcall(require, "PNC/ConvoEngine/DispositionProjection")
        if ok and type(loaded) == "table" and type(loaded.Resolve) == "function" then
            return loaded
        end
    end
    return nil
end

local function hasEntries(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do return true end
    return false
end

local function demeanorSignature(record, options)
    local d = type(options) == "table" and type(options.temporaryDemeanor) == "table"
        and options.temporaryDemeanor
        or (type(record) == "table" and type(record.temporaryDemeanor) == "table" and record.temporaryDemeanor)
        or (type(record) == "table" and type(record.runtime) == "table"
            and type(record.runtime.temporaryDemeanor) == "table"
            and record.runtime.temporaryDemeanor)
        or nil
    if type(d) ~= "table" then return "" end
    return table.concat({
        tostring(tonumber(d.moraleHope) or 0),
        tostring(tonumber(d.scarcityAnxiety) or 0),
        tostring(tonumber(d.vigilanceFear) or 0),
        tostring(tonumber(d.hostilityIrritability) or 0),
        tostring(tonumber(d.griefStress) or 0),
        tostring(tonumber(d.confidencePressure) or 0),
    }, ",")
end

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
    local playerId = tostring(playerKey or "")
    local role = tostring(options.role or "witness")
    local actorKind = tostring(options.actorKind or "player")
    local inCombat = options.inCombat == true
    local relationship = relationshipFor(record, playerId)
    local state = tostring(
        relationship.state or relationship.category or "unknown"
    )
    local condition = conditionFor(record)
    local pressure, nearbyCount = pressureFor(record, options)
    local panic = number(condition.panic, 0)
    local stress = number(condition.stress, 0)
    local fatigue = number(
        condition.fatigue ~= nil and condition.fatigue
            or (type(record) == "table" and type(record.needs) == "table" and record.needs.fatigue),
        0
    )
    local pain = number(condition.pain, 0)
    local health = healthState(record)
    local h = type(record) == "table" and type(record.health) == "table" and record.health or nil
    local body = h and type(h.body) == "table" and h.body or nil
    local bleeding = (h and h.bleeding == true)
        or number(body and body.bleedingRate, 0) > 0
        or number(body and body.openWoundCount, 0) > 0
        or number(h and h.bleedingRate, 0) > 0
        or number(h and h.openWoundCount, 0) > 0
        or false
    local tRole = tostring(type(record) == "table" and (record.tacticalRole or record.role) or "")
    local isTactical = (type(record) == "table" and record.tactical == true)
        or tRole == "guard" or tRole == "soldier" or tRole == "scout"
    local isHostile = (type(record) == "table"
        and (record.activeBehavior == "hostile"
            or record.behavior == "hostile"
            or record.isHostile == true))
        or state == "enemy"
    local stState = string.lower(tostring(
        type(record) == "table" and type(record.stamina) == "table"
            and record.stamina.state or ""
    ))
    local passiveCombat = tostring(type(record) == "table" and record.combatPolicy or "") == "passive"
        or tostring(type(record) == "table" and record.attackType or "") == "none"

    local rt = type(record) == "table" and type(record.runtime) == "table" and record.runtime or nil
    local now = PNC and PNC.Core and type(PNC.Core.Now) == "function"
        and tonumber(PNC.Core.Now()) or nil
    local cacheSig = nil
    if rt and options.noCache ~= true and type(options.temporaryDemeanor) ~= "table"
        and now ~= nil and now > 0
    then
        cacheSig = table.concat({
            playerId, role, actorKind, tostring(inCombat), health, pressure,
            tostring(nearbyCount), tostring(math.floor(panic / 15)),
            tostring(math.floor(stress * 4)), tostring(math.floor(fatigue * 4)),
            tostring(math.floor(pain / 20)), tostring(bleeding), state,
            tostring(isHostile), tostring(isTactical), tostring(passiveCombat),
            stState, demeanorSignature(record, options),
        }, "|")
        local c = rt._combatProfileCache
        if type(c) == "table" and c.sig == cacheSig and now < (tonumber(c.expiresAt) or 0) then
            return c.profile
        end
    end

    local personality = personalityFor(record)
    local traits = TraitContext and TraitContext.Collect
        and TraitContext.Collect(record) or {}
    local socialStyle = tostring(personality.socialStyle or "neutral")
    local DP = resolveDispositionProjection()
    local proj = DP and DP.Resolve(record, {
        personality = hasEntries(personality) and personality or nil,
        traits = traits,
        condition = condition,
        temporaryDemeanor = options.temporaryDemeanor,
        relationshipState = state,
        isHostile = isHostile,
        tactical = isTactical,
    }) or nil

    local eff = proj and proj.effectiveDisposition or nil
    local unitDisp = (proj and DP and DP.ToUnitDisposition)
        and DP.ToUnitDisposition(eff) or nil
    local bravery = unitDisp and unitDisp.bravery
        or (eff and unit(eff.bravery / 100, 0.5))
        or unit(personality.bravery, 0.5)
    local aggression = unitDisp and unitDisp.aggression
        or (eff and unit(eff.aggression / 100, 0.5))
        or unit(personality.aggression, 0.5)
    local compassion = unitDisp and unitDisp.compassion
        or (eff and unit(eff.compassion / 100, 0.5))
        or unit(personality.compassion, 0.5)

    local styleProjection = Style.Resolve({
        npcID = record and record.id,
        npcRecord = record,
        npcTraits = traits,
        npcPersonality = personality,
        temporaryDemeanor = options.temporaryDemeanor,
        dispositionProjection = proj,
        relationship = relationship,
        relationshipState = state,
        dialogueSituation = {
            npc = {
                inCombat = inCombat,
                healthState = health,
            },
        },
    })
    local speechVariant = tostring(
        styleProjection and styleProjection.variant or "neutral"
    )

    local mood = "steady"
    if panic >= 70 then mood = "panicked"
    elseif stress >= 0.75 or panic >= 45 then mood = "tense" end

    local reactionStyle
    local allyWarnStyle
    if proj then
        local unifiedStyle = tostring(proj.styleProfile or "default")
        reactionStyle = unifiedStyle == "default" and "practical" or unifiedStyle
        if isHostile then
            allyWarnStyle = "hostile"
        elseif unifiedStyle == "shaken" or passiveCombat then
            allyWarnStyle = "shaken"
        elseif bleeding == true or pain >= 55 or fatigue >= 0.80 or stState == "exhausted" then
            allyWarnStyle = "exhausted"
        elseif unifiedStyle == "aggressive" or unifiedStyle == "brave" or unifiedStyle == "supportive" then
            allyWarnStyle = unifiedStyle
        elseif isTactical then
            allyWarnStyle = "tactical"
        else
            allyWarnStyle = "neutral"
        end
    else
        -- Safe fallback when DispositionProjection is not yet loaded:
        -- use resolved numeric disposition only (no trait double-counting).
        if state == "enemy" or state == "rival" then
            reactionStyle = "cold"
        elseif mood == "panicked" or mood == "tense" or bravery <= 0.32 then
            reactionStyle = "shaken"
        elseif aggression >= 0.70 then
            reactionStyle = "aggressive"
        elseif (compassion >= 0.66)
            and (state == "friend"
                or relationshipTier(relationship) ~= "reserved")
        then
            reactionStyle = "supportive"
        elseif bravery >= 0.68 then
            reactionStyle = "brave"
        elseif speechVariant == "terse" or socialStyle == "withdrawn" then
            reactionStyle = "reserved"
        else
            reactionStyle = "practical"
        end

        if isHostile then
            allyWarnStyle = "hostile"
        elseif reactionStyle == "shaken" or passiveCombat then
            allyWarnStyle = "shaken"
        elseif bleeding == true or pain >= 55 or fatigue >= 0.80 or stState == "exhausted" then
            allyWarnStyle = "exhausted"
        elseif reactionStyle == "aggressive" or reactionStyle == "brave" or reactionStyle == "supportive" then
            allyWarnStyle = reactionStyle
        elseif isTactical then
            allyWarnStyle = "tactical"
        else
            allyWarnStyle = "neutral"
        end
    end

    local isCowardly = eff
        and ((proj.styleProfile == "shaken") or eff.bravery <= 32 or eff.confidence <= 32 or panic >= 55)
        or (bravery <= 0.32 or panic >= 55)
    local isBrave = eff
        and ((proj.styleProfile == "brave") or (eff.bravery >= 68 and eff.confidence >= 65))
        or (bravery >= 0.68)
    local isExhausted = fatigue >= 0.75 or pain >= 50 or health == "injured"
        or bleeding == true or stState == "exhausted"

    local curHp, maxHp = tonumber(h and h.current), tonumber(h and h.max)
    local hpRatio = (curHp and maxHp and maxHp > 0) and unit(curHp / maxHp, 1)
        or (health == "injured" and 0.6 or 1)

    local healthText = health == "injured"
        and "I'm hurt, but I'm still moving."
        or mood == "panicked"
            and "I'm not hurt, but I need a second."
            or "I'm okay."

    local out = {
        schemaVersion = Profile.VERSION,
        schema = Profile.SCHEMA,
        combatReactionRole = role,
        combatReactionStyle = reactionStyle,
        combatReactionMood = mood,
        styleProfile = proj and proj.styleProfile or reactionStyle,
        baseDisposition = proj and proj.baseDisposition or nil,
        temporaryDemeanor = proj and proj.temporaryDemeanor or nil,
        effectiveDisposition = eff,
        combatPressure = pressure,
        killerActorKind = actorKind,
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
        bravery = bravery,
        aggression = aggression,
        compassion = compassion,
        panic = panic,
        stress = stress,
        fatigue = fatigue,
        pain = pain,
        bleeding = bleeding == true,
        hpRatio = hpRatio,
        isCowardly = isCowardly == true,
        isBrave = isBrave == true,
        isExhausted = isExhausted == true,
        allyWarnStyle = allyWarnStyle,
        provenance = {
            personality = proj and "DispositionProjection" or "social.personality",
            disposition = proj and "DispositionProjection" or "fallback",
            traits = "NPCTraitContext",
            condition = "conditionStats",
            relationship = "directed_relationship",
            pressure = "ZombieObservation",
            speechStyle = "SpeechStyleContext",
        },
    }
    if rt and cacheSig then
        rt._combatProfileCache = { expiresAt = now + 1500, sig = cacheSig, profile = out }
    end
    return out
end

return Profile
