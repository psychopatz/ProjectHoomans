PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
-- Shared bounds, normalization, and condition matching helpers.

local Core = {}

Core.CONDITION_FIELDS = {
    "topic", "previousTopic", "previousAction", "lastIntent", "lastAction", "lastSpeaker",
    "intent", "action", "subject", "pattern",
    "relationshipState", "identityTrust", "timeBand", "raining", "foggy", "snowing",
    "indoors", "hasPendingRequest", "npcID", "activity", "busy",
    "memoryAvailable",
    "needType", "needUrgency", "relationshipAttitude", "healthState",
    "socialStyle", "emotionType", "emotionUrgency", "hostilityCount",
    "insultCount", "lastSpeechAct",
    "eventType", "commandID", "commandReason", "commandOutcome",
    "toolStatus", "toolReason", "toolReaction", "toolSubtype",
    "toolOutcome",
    "medicalBandageRequired", "medicalBandageStatus",
    "medicalSupplyRequestStatus",
    "downedAudience", "downedNeed", "downedThreat",
    "leaderGrief", "leaderSuccession", "corpseRevenge",
    "projectALifeKind", "projectALifeStance",
    "projectALifeConflictDirection", "projectALifeConflictDamage",
    "companionDogSex", "companionDogFed", "npcType", "relationshipTier",
    "greetingState", "combatReactionRole", "combatReactionStyle",
    "combatReactionMood", "combatPressure", "killerActorKind",
    "combatAttackType", "combatWeaponFamily", "combatWeaponSkill",
    "combatSkillBand", "combatHitZone", "combatWoundType",
    "combatWeaponNamed", "assaultKind", "friendlyPushTier", "lootCategory",
    "hordePhase", "socialRole", "farewellSpeaker",
    "milestoneStage", "worldEventType", "epistemicProvenance",
    "stateValue", "knoxExposure", "salivaTransmissible", "isBitten", "hasOpenWounds",
}

local PASSTHROUGH_FIELDS = {
    "previousTopic", "previousAction", "lastIntent", "lastAction", "lastSpeaker",
    "intent", "action", "subject", "pattern", "eventType",
    "commandID", "commandReason", "commandOutcome",
    "toolStatus", "toolReason", "toolReaction", "toolSubtype", "toolOutcome",
    "relationshipState", "identityTrust", "npcID",
    "medicalBandageRequired", "medicalBandageStatus", "medicalSupplyRequestStatus",
    "downedAudience", "downedNeed", "downedThreat",
    "leaderGrief", "leaderSuccession", "corpseRevenge",
    "projectALifeKind", "projectALifeStance", "projectALifeConflictDirection", "projectALifeConflictDamage",
    "companionDogSex", "companionDogFed", "npcType", "relationshipTier",
    "greetingState", "combatReactionRole", "combatReactionStyle", "combatReactionMood",
    "combatPressure", "killerActorKind", "combatAttackType", "combatWeaponFamily",
    "combatWeaponSkill", "combatSkillBand", "combatHitZone", "combatWoundType",
    "combatWeaponNamed", "assaultKind", "friendlyPushTier", "lootCategory",
    "hordePhase", "farewellSpeaker", "milestoneStage", "worldEventType",
    "stateValue", "knoxExposure", "salivaTransmissible", "isBitten", "hasOpenWounds",
}

local function scalarMatches(expected, actual)
    if expected == nil then return true end
    if type(expected) == "table" then
        for index = 1, #expected do
            if scalarMatches(expected[index], actual) then return true end
        end
        return false
    end
    if type(expected) == "boolean" then return expected == (actual == true) end
    return tostring(expected) == tostring(actual)
end

function Core.conditionContext(context)
    context = type(context) == "table" and context or {}
    local world = context.worldContext or {}
    local time = world.time or {}
    local weather = world.weather or {}
    local environment = world.environment or {}
    local state = context.semanticDialogueState or {}
    local pendingRequest = context.pendingRequest or state.pendingRequest
    local situation = context.dialogueSituation or {}
    local npc = situation.npc or {}
    local activity = npc.activity or {}
    local needs = npc.needs or {}
    local emotion = npc.emotion or {}
    local social = situation.social or {}
    local gossip = context.npcGossip
    local healthState = context.healthState or npc.healthState
    if type(healthState) ~= "string" or healthState == "" then
        healthState = "unknown"
    end
    local out = {
        topic = context.currentTopic or context.topic,
        timeBand = world.timeBand or time.band or context.timeBand,
        raining = weather.raining,
        foggy = weather.foggy,
        snowing = weather.snowing,
        indoors = environment.indoors,
        hasPendingRequest = pendingRequest ~= nil,
        activity = context.activity or activity.id,
        busy = context.busy ~= nil and context.busy or activity.busy,
        memoryAvailable = type(gossip) == "table"
            and type(gossip.statements) == "table"
            and #gossip.statements > 0 or false,
        needType = context.needType or needs.highest,
        needUrgency = context.needUrgency or needs.urgency,
        emotionType = context.emotionType or emotion.highest,
        emotionUrgency = context.emotionUrgency or emotion.urgency,
        relationshipAttitude = context.relationshipAttitude or social.attitude,
        healthState = healthState,
        socialStyle = context.socialStyle or social.style,
        hostilityCount = context.hostilityCount
            or state.socialContext and state.socialContext.hostilityCount,
        insultCount = context.insultCount
            or state.socialContext and state.socialContext.insultCount,
        lastSpeechAct = context.lastSpeechAct
            or state.socialContext and state.socialContext.lastSpeechAct,
        socialRole = context.socialRole or social.role,
        epistemicProvenance = context.epistemicProvenance or context.provenance,
    }
    for i = 1, #PASSTHROUGH_FIELDS do
        local f = PASSTHROUGH_FIELDS[i]
        out[f] = context[f]
    end
    return out
end

local function compileWhenKeys(when)
    if type(when) ~= "table" then return nil end
    local keys = {}
    for index = 1, #Core.CONDITION_FIELDS do
        local field = Core.CONDITION_FIELDS[index]
        if when[field] ~= nil then keys[#keys + 1] = field end
    end
    return #keys > 0 and keys or nil
end
Core.compileWhenKeys = compileWhenKeys

function Core.matchesNormalized(variant, condCtx, withTrace)
    local when = variant.when
    local whenKeys = variant._whenKeys
    if type(when) ~= "table" or (variant._whenCompiled == true and whenKeys == nil) then
        return true, 0, withTrace and {} or nil
    end
    local keys = whenKeys or Core.CONDITION_FIELDS
    local specificity = 0
    local checks = withTrace and {} or nil
    for index = 1, #keys do
        local field = keys[index]
        local actual = condCtx[field]
        if when[field] ~= nil then
            local passed = scalarMatches(when[field], actual)
            if checks then
                checks[#checks + 1] = {
                    field = field,
                    expected = Core.copy(when[field]),
                    actual = Core.copy(actual),
                    actualKnown = actual ~= nil,
                    matched = passed,
                }
            end
            if not passed and not withTrace then return false, 0 end
            if passed then specificity = specificity + 1 end
        end
    end
    if checks then
        for i = 1, #checks do
            if not checks[i].matched then return false, 0, checks end
        end
    end
    return true, specificity, checks
end

function Core.matches(variant, context, withTrace)
    local when = variant.when
    if type(when) ~= "table" or (variant._whenCompiled == true and variant._whenKeys == nil) then
        return true, 0, withTrace and {} or nil
    end
    return Core.matchesNormalized(variant, Core.conditionContext(context), withTrace)
end

local attachNormalization = require
    "PNC/ConvoEngine/Dialogue/ResponseCatalog_Core_Normalization"
attachNormalization(Core)

return Core
