PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
-- Shared bounds, normalization, and condition matching helpers.

local ResponsePlan = require
    "PNC/ConvoEngine/Dialogue/ResponsePlan"

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
}

function Core.copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = Core.copy(item, depth + 1)
        end
    end
    return output
end

function Core.validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= 96
        and string.find(value, "[^%w_%.%-]") == nil
end

function Core.boundedText(value)
    value = tostring(value or "")
    if #value > 256 then return string.sub(value, 1, 256) end
    return value
end

function Core.registerTextFallback(templateID, fallback)
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.RegisterFallback) == "function" then
        text.RegisterFallback(templateID, fallback)
    end
end

local function contentFallback(templateID)
    local registry = PNC.ConvoEngine and PNC.ConvoEngine.Registry or nil
    if type(registry) ~= "table" then
        local ok, loaded = pcall(
            require,
            "PNC/ConvoEngine/Registry"
        )
        registry = ok and loaded or nil
    end
    if type(registry) ~= "table"
        or type(registry.FamilyFor) ~= "function"
    then
        return nil
    end
    local _, phrases = registry.FamilyFor(templateID, "neutral")
    local phrase = type(phrases) == "table" and phrases[1] or nil
    if not (phrase and phrase.fallback and phrase.fallback ~= "") then
        local ConvoPlanFamily = PNC.ConvoEngine
            and PNC.ConvoEngine.ConvoPlanFamily or nil
        if type(ConvoPlanFamily) ~= "table" then
            local ok, loaded = pcall(
                require,
                "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"
            )
            ConvoPlanFamily = ok and loaded or nil
        end
        if type(ConvoPlanFamily) == "table"
            and type(ConvoPlanFamily.install) == "function"
        then
            ConvoPlanFamily.install(templateID)
            _, phrases = registry.FamilyFor(templateID, "neutral")
            phrase = type(phrases) == "table" and phrases[1] or nil
        end
    end
    local fallback = phrase and phrase.fallback or nil
    return Core.boundedText(fallback)
end

local function contentOwnerForPool(poolID)
    poolID = tostring(poolID or "")
    if string.find(poolID, "semantic.compat.", 1, true) == 1 then
        return "projecthoomans.dialogue_content.compatibility"
    end
    if string.find(poolID, "semantic.tool_reply.", 1, true) == 1 then
        return "projecthoomans.dialogue_content.tool_replies"
    end
    if string.find(poolID, "semantic.command.", 1, true) == 1
        or string.find(poolID, "semantic.emote.", 1, true) == 1
        or string.find(poolID, "semantic.flow.greeting.", 1, true) == 1
    then
        return "projecthoomans.dialogue_content.commands_emotes"
    end
    if string.find(poolID, "semantic.medical.", 1, true) == 1
        or string.find(poolID, "semantic.combat.", 1, true) == 1
        or string.find(poolID, "semantic.leader_loss.", 1, true) == 1
        or string.find(poolID, "semantic.companion.", 1, true) == 1
        or string.find(poolID, "semantic.conversation.safety", 1, true) == 1
        or string.find(poolID, "semantic.corpse.", 1, true) == 1
        or string.find(poolID, "semantic.flow.farewell", 1, true) == 1
        or string.find(poolID, "semantic.social.reaction", 1, true) == 1
    then
        return "projecthoomans.dialogue_content.events"
    end
    return nil
end

local function normalizePlanContent(plan, templateID)
    if type(plan) ~= "table" or type(plan.turns) ~= "table" then
        return plan
    end
    for _, turn in ipairs(plan.turns) do
        for _, segment in ipairs(turn.segments or {}) do
            if type(segment) == "table" and segment.kind == "literal" then
                local text = Core.boundedText(segment.text)
                if text ~= "" then
                    -- ResponsePlan remains the semantic plan owner. A literal
                    -- event segment is promoted to the same translation seam
                    -- as the selected response so Dialogue Content can own
                    -- wording without creating another selector.
                    segment.kind = "translation"
                    segment.templateID = templateID
                    segment.fallback = text
                    segment.args = {}
                    segment.text = nil
                end
            end
        end
    end
    return plan
end

function Core.hash(value)
    local output = 0
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 31 + string.byte(value, index)) % 2147483647
    end
    return output
end

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
    local pendingRequest = context.pendingRequest
        or state.pendingRequest
    local situation = context.dialogueSituation or {}
    local npc = situation.npc or {}
    local activity = npc.activity or {}
    local needs = npc.needs or {}
    local emotion = npc.emotion or {}
    local social = situation.social or {}
    local gossip = context.npcGossip
    local healthState = context.healthState or npc.healthState
    -- Keep missing health evidence distinct from a known healthy state for
    -- response selection. The routed situation remains source-faithful and
    -- continues to omit the field when the NPC health fact is unavailable.
    if type(healthState) ~= "string" or healthState == "" then
        healthState = "unknown"
    end
    return {
        topic = context.currentTopic or context.topic,
        previousTopic = context.previousTopic,
        previousAction = context.previousAction,
        lastIntent = context.lastIntent,
        lastAction = context.lastAction,
        lastSpeaker = context.lastSpeaker,
        intent = context.intent,
        action = context.action,
        subject = context.subject,
        pattern = context.pattern,
        eventType = context.eventType,
        commandID = context.commandID,
        commandReason = context.commandReason,
        commandOutcome = context.commandOutcome,
        toolStatus = context.toolStatus,
        toolReason = context.toolReason,
        toolReaction = context.toolReaction,
        toolSubtype = context.toolSubtype,
        toolOutcome = context.toolOutcome,
        relationshipState = context.relationshipState,
        identityTrust = context.identityTrust,
        timeBand = world.timeBand or time.band or context.timeBand,
        raining = weather.raining,
        foggy = weather.foggy,
        snowing = weather.snowing,
        indoors = environment.indoors,
        hasPendingRequest = pendingRequest ~= nil,
        npcID = context.npcID,
        activity = context.activity or activity.id,
        busy = context.busy ~= nil and context.busy or activity.busy,
        memoryAvailable = type(gossip) == "table"
            and type(gossip.statements) == "table"
            and #gossip.statements > 0 or false,
        needType = context.needType or needs.highest,
        needUrgency = context.needUrgency or needs.urgency,
        emotionType = context.emotionType or emotion.highest,
        emotionUrgency = context.emotionUrgency or emotion.urgency,
        relationshipAttitude = context.relationshipAttitude
            or social.attitude,
        healthState = healthState,
        socialStyle = context.socialStyle or social.style,
        hostilityCount = context.hostilityCount
            or state.socialContext and state.socialContext.hostilityCount,
        insultCount = context.insultCount
            or state.socialContext and state.socialContext.insultCount,
        lastSpeechAct = context.lastSpeechAct
            or state.socialContext and state.socialContext.lastSpeechAct,
        medicalBandageRequired = context.medicalBandageRequired,
        medicalBandageStatus = context.medicalBandageStatus,
        medicalSupplyRequestStatus = context.medicalSupplyRequestStatus,
        downedAudience = context.downedAudience,
        downedNeed = context.downedNeed,
        downedThreat = context.downedThreat,
        leaderGrief = context.leaderGrief,
        leaderSuccession = context.leaderSuccession,
        corpseRevenge = context.corpseRevenge,
        projectALifeKind = context.projectALifeKind,
        projectALifeStance = context.projectALifeStance,
        projectALifeConflictDirection =
            context.projectALifeConflictDirection,
        projectALifeConflictDamage = context.projectALifeConflictDamage,
        companionDogSex = context.companionDogSex,
        companionDogFed = context.companionDogFed,
        npcType = context.npcType,
        relationshipTier = context.relationshipTier,
        greetingState = context.greetingState,
        combatReactionRole = context.combatReactionRole,
        combatReactionStyle = context.combatReactionStyle,
        combatReactionMood = context.combatReactionMood,
        combatPressure = context.combatPressure,
        killerActorKind = context.killerActorKind,
        combatAttackType = context.combatAttackType,
        combatWeaponFamily = context.combatWeaponFamily,
        combatWeaponSkill = context.combatWeaponSkill,
        combatSkillBand = context.combatSkillBand,
        combatHitZone = context.combatHitZone,
        combatWoundType = context.combatWoundType,
        combatWeaponNamed = context.combatWeaponNamed,
        assaultKind = context.assaultKind,
        friendlyPushTier = context.friendlyPushTier,
        lootCategory = context.lootCategory,
        hordePhase = context.hordePhase,
        socialRole = context.socialRole or social.role,
        farewellSpeaker = context.farewellSpeaker,
    }
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

function Core.matchesNormalized(variant, condCtx, withTrace)
    local when = variant.when
    local whenKeys = variant._whenKeys
    local actual
    local field
    local index
    if type(when) ~= "table" or (variant._whenCompiled == true and whenKeys == nil) then
        return true, 0, withTrace and {} or nil
    end
    local keys = whenKeys or Core.CONDITION_FIELDS
    local specificity = 0
    local checks = withTrace and {} or nil
    for index = 1, #keys do
        field = keys[index]
        actual = condCtx[field]
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

local function prepareVariant(poolID, index, value)
    if type(value) == "string" then
        value = { fallback = value }
    end
    if type(value) ~= "table" then
        return nil, "invalid_variant_definition", {
            poolID = tostring(poolID or ""),
            variantIndex = index,
        }
    end
    local templateID = tostring(value.templateID or value.id or "")
    local id = tostring(value.id or (poolID .. "." .. tostring(index)))
    local detail = {
        poolID = tostring(poolID or ""),
        variantIndex = index,
        templateID = templateID ~= "" and templateID or id,
        realizationID = id,
    }
    local fallback = Core.boundedText(value.fallback or value.text)
    if fallback == "" then fallback = contentFallback(templateID) end
    if fallback == "" then
        return nil, "unresolved_template_fallback", detail
    end
    if not Core.validID(id) then
        return nil, "invalid_variant_id", detail
    end
    local plan
    if value.plan ~= nil then
        local valid, normalized, planReason = ResponsePlan.Build(value.plan)
        if not valid then
            return nil, tostring(planReason or "invalid_response_plan"), detail
        end
        plan = normalizePlanContent(normalized, tostring(
            value.templateID or id
        ))
    end
    local contentOwner = value.contentOwner or contentOwnerForPool(poolID)
    local when = Core.copy(value.when)
    return {
        id = id,
        templateID = templateID ~= "" and templateID or id,
        fallback = fallback,
        plan = plan,
        dialogueAct = value.dialogueAct,
        topic = value.topic,
        groundedFactRefs = Core.copy(
            value.groundedFactRefs or value.sourceFactRefs
        ),
        uncertainty = value.uncertainty,
        tone = value.tone,
        personalityStyle = value.personalityStyle,
        contentOwner = contentOwner,
        translationArgs = Core.copy(value.translationArgs),
        when = when,
        _whenKeys = compileWhenKeys(when),
        _whenCompiled = true,
        priority = tonumber(value.priority) or 0,
    }, nil, detail
end

function Core.validateVariant(poolID, index, value)
    return prepareVariant(poolID, index, value)
end

function Core.normalizedVariant(poolID, index, value)
    local normalized, reason, detail = prepareVariant(poolID, index, value)
    if not normalized then return nil, reason, detail end
    Core.registerTextFallback(normalized.templateID, normalized.fallback)
    return normalized, nil, detail
end

function Core.install(Catalog)
    Catalog.VERSION = 1
    Catalog.MAX_POOLS = 256
    Catalog.MAX_VARIANTS = 16
    Catalog.MAX_LAST_VARIANTS = 256
    Catalog.POOLS = Catalog.POOLS or {}
    Catalog.REVISION = Catalog.REVISION or 0
    Catalog.REGISTRATION_ORIGINS = Catalog.REGISTRATION_ORIGINS or {}
    Catalog.LAST_VARIANTS = Catalog.LAST_VARIANTS or {}
    Catalog.LAST_VARIANT_ORDER = Catalog.LAST_VARIANT_ORDER or {}
end

return Core
