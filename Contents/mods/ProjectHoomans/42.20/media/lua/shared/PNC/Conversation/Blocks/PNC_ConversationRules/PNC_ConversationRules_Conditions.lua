local Rules = PNC.Conversation.Rules
local Internal = Rules.Internal
local Registry = PsychopatzCore.Conversation.Registry
local EngineFacts = PNC.Semantics and PNC.Semantics.EngineFacts
if type(EngineFacts) ~= "table" then
    EngineFacts = require "PNC/Semantics/PNC_SemanticEngineFacts"
end

function Internal.Compare(actual, operator, expected)
    operator = operator or ">="
    if operator == "==" then return actual == expected end
    if operator == "~=" then return actual ~= expected end
    actual = tonumber(actual)
    expected = tonumber(expected)
    if actual == nil or expected == nil then return false end
    if operator == ">=" then return actual >= expected end
    if operator == "<=" then return actual <= expected end
    if operator == ">" then return actual > expected end
    if operator == "<" then return actual < expected end
    return false
end

local function tableValue(root, key)
    return type(root) == "table" and root[key] or nil
end

local function skillLevel(context, gate)
    local actor = gate.actor == "npc" and "npc" or "player"
    local values = context[actor .. "Skills"]
    local level = tableValue(values, gate.skill)
    local player
    local perk
    if level ~= nil then return tonumber(level) or 0 end
    if actor == "npc" and PNC.Skills and PNC.Skills.GetLevel
        and context.npcRecord
    then
        return tonumber(
            PNC.Skills.GetLevel(context.npcRecord, gate.skill)
        ) or 0
    end
    player = context.player
    if actor == "player" and player and player.getPerkLevel then
        perk = gate.perk
        if not perk and Perks and Perks.FromString then
            perk = Perks.FromString(tostring(gate.skill or ""))
        end
        if perk then return tonumber(player:getPerkLevel(perk)) or 0 end
    end
    return 0
end

local function resolveDispositionProjection()
    local dp = PNC and PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if type(dp) == "table" and type(dp.Resolve) == "function" then
        return dp
    end
    return nil
end

-- Generic temperament traits route through resolved numeric disposition so
-- literal trait tags cannot override seeded personality, temporary demeanor,
-- or situational condition pressure. Unique capability/identity traits (e.g.
-- pnc_veteran, pnc_disciplined_fighter, pnc_heavysleeper, pnc_hasbrother,
-- Doctor, Burglar) fall through to direct trait lookup in hasTrait().
local TEMPERAMENT_TRAIT_GATES = {
    brave = { axis = "bravery", operator = ">=", value = 0.65 },
    desensitized = { axis = "bravery", operator = ">=", value = 0.65 },
    pnc_brave = { axis = "bravery", operator = ">=", value = 0.65 },
    pnc_ironnerves = { axis = "bravery", operator = ">=", value = 0.65 },
    cowardly = { axis = "bravery", operator = "<=", value = 0.35 },
    pnc_cowardly = { axis = "bravery", operator = "<=", value = 0.35 },
    pnc_nervous_fighter = { axis = "bravery", operator = "<=", value = 0.35 },
    pnc_frayednerves = { axis = "bravery", operator = "<=", value = 0.35 },
    aggressive = { axis = "aggression", operator = ">=", value = 0.65 },
    pnc_berserker = { axis = "aggression", operator = ">=", value = 0.65 },
    pnc_reckless = { axis = "aggression", operator = ">=", value = 0.65 },
    pnc_trigger_happy = { axis = "aggression", operator = ">=", value = 0.65 },
    pnc_brawler = { axis = "aggression", operator = ">=", value = 0.65 },
    pnc_cautious_fighter = { axis = "aggression", operator = "<=", value = 0.38 },
    empathetic = { axis = "compassion", operator = ">=", value = 0.62 },
    kind = { axis = "compassion", operator = ">=", value = 0.62 },
    kindhearted = { axis = "compassion", operator = ">=", value = 0.62 },
    pacifist = { axis = "compassion", operator = ">=", value = 0.62 },
    pnc_peacemaker = { axis = "compassion", operator = ">=", value = 0.62 },
    cold = { axis = "compassion", operator = "<=", value = 0.35 },
    friendly = { axis = "sociability", operator = ">=", value = 0.62 },
    pnc_friendly = { axis = "sociability", operator = ">=", value = 0.62 },
    reserved = { axis = "sociability", operator = "<=", value = 0.38 },
    withdrawn = { axis = "sociability", operator = "<=", value = 0.38 },
    pnc_reserved = { axis = "sociability", operator = "<=", value = 0.38 },
    pnc_withdrawn = { axis = "sociability", operator = "<=", value = 0.38 },
    loyal = { axis = "loyalty", operator = ">=", value = 0.65 },
    greedy = { axis = "materialism", operator = ">=", value = 0.65 },
    generous = { axis = "materialism", operator = "<=", value = 0.35 },
}

local function rawPersonalityTable(context, actor)
    if actor == "npc" then
        return context.npcPersonality
            or (type(context.npcRecord) == "table"
                and (context.npcRecord.personality
                    or (type(context.npcRecord.social) == "table"
                        and context.npcRecord.social.personality)))
            or nil
    end
    return context.playerPersonality
        or (type(context.playerSocialProfile) == "table"
            and (context.playerSocialProfile.personality
                or context.playerSocialProfile))
        or nil
end

local function resolvedDisposition(context, actor, traitName)
    local DP = resolveDispositionProjection()
    if not DP then return nil end
    local rawValues = rawPersonalityTable(context, actor)
    if actor == "npc" then
        local record = type(context.npcRecord) == "table" and context.npcRecord or nil
        local proj = DP.Resolve(record, {
            personality = rawValues,
            traits = context.npcTraits,
            condition = context.npcCondition or context.condition
                or (record and record.conditionStats),
            temporaryDemeanor = context.temporaryDemeanor,
            relationshipState = context.relationshipState,
        })
        if proj and type(proj.effectiveDisposition) == "table" then
            if type(DP.ToUnitDisposition) == "function" then
                return DP.ToUnitDisposition(proj.effectiveDisposition)
            end
            return proj.effectiveDisposition
        end
        return nil
    end
    local playerTraits = context.playerTraits
        or (type(context.playerSocialProfile) == "table"
            and context.playerSocialProfile.sourceTraits)
        or nil
    if type(playerTraits) ~= "table" and type(traitName) == "string"
        and traitName ~= "" and context.player and context.player.HasTrait
    then
        if context.player:HasTrait(traitName) == true then
            playerTraits = { [traitName] = true }
        end
    end
    local proj = DP.Resolve(type(context.player) == "table" and context.player or nil, {
        personality = rawValues,
        playerTraits = playerTraits,
        condition = context.playerCondition or context.condition,
        temporaryDemeanor = context.playerTemporaryDemeanor
            or context.temporaryDemeanor,
    })
    if proj and type(proj.effectiveDisposition) == "table" then
        if type(DP.ToUnitDisposition) == "function" then
            return DP.ToUnitDisposition(proj.effectiveDisposition)
        end
        return proj.effectiveDisposition
    end
    return nil
end

local function personalityValue(context, gate)
    local actor = gate.actor == "player" and "player" or "npc"
    local key = gate.key or gate.dimension
    local disp = resolvedDisposition(context, actor)
    local resolved = tableValue(disp, key)
    if resolved ~= nil then return resolved end
    return tableValue(rawPersonalityTable(context, actor), key)
end

local function hasTrait(context, gate)
    local traits
    local value
    local player
    if gate.actor == "npc" then
        traits = context.npcTraits
    else
        traits = context.playerTraits
            or context.playerSocialProfile
                and context.playerSocialProfile.sourceTraits
    end
    if type(traits) == "table" then
        if traits[gate.trait] == true then return true end
        for _, value in ipairs(traits) do
            if value == gate.trait then return true end
        end
    end
    player = context.player
    return gate.actor ~= "npc" and player and player.HasTrait
        and player:HasTrait(gate.trait) == true or false
end

local function traitMatches(context, gate)
    local traitID = tostring(gate.trait or "")
    local mapped = TEMPERAMENT_TRAIT_GATES[string.lower(traitID)]
    if mapped then
        local actor = gate.actor == "player" and "player" or "npc"
        local disp = resolvedDisposition(context, actor, traitID)
        local actual = tableValue(disp, mapped.axis)
        if actual ~= nil then
            return Internal.Compare(actual, mapped.operator, mapped.value)
        end
    end
    -- Direct trait lookup preserved for unique capability/identity traits
    -- (and as a safe fallback if DispositionProjection is unavailable).
    return hasTrait(context, gate)
end

local function timeMatches(context, gate)
    local hour = tonumber(context.hour)
    local first = tonumber(gate.startHour) or 0
    local last = tonumber(gate.endHour) or 24
    if hour == nil then
        hour = (tonumber(context.worldAgeHours) or 0) % 24
    end
    if first <= last then return hour >= first and hour < last end
    return hour >= first or hour < last
end

local function historyMatches(context, gate)
    local entry = context.historyEntry
    if type(context.historyLookup) == "function" then
        entry = context.historyLookup(gate.subjectID, gate.scope)
    end
    entry = type(entry) == "table" and entry or {}
    if gate.maxUses ~= nil
        and (tonumber(entry.useCount) or 0) >= tonumber(gate.maxUses)
    then
        return false
    end
    if gate.cooldownHours ~= nil and entry.lastUsedWorldHour ~= nil
        and (tonumber(context.worldAgeHours) or 0)
            < tonumber(entry.lastUsedWorldHour)
                + tonumber(gate.cooldownHours)
    then
        return false
    end
    return true
end

local function weatherMatches(context, gate)
    context = type(context) == "table" and context or {}
    local world = type(context.worldContext) == "table"
        and context.worldContext or {}
    local weather = type(world.weather) == "table"
        and world.weather or {}
    local field = tostring(gate.field or "raining")
    local actual = weather[field]
    if actual == nil then
        return nil, gate.unknownReasonKey or "weather_unknown"
    end
    local matches = Internal.Compare(
        actual, gate.operator or "==", gate.value
    )
    if matches then
        return true, gate.passReasonKey or "weather_matches"
    end
    return false, gate.failReasonKey or "weather_mismatch"
end

local function engineFactMatches(context, gate)
    local factID = gate.fact or gate.subject
    local fact = EngineFacts.Resolve(factID, context)
    local matches
    if type(fact) ~= "table" or fact.status ~= "known" then
        if gate.unknownPolicy == "pass" then
            return true, gate.unknownReasonKey or "engine_fact_unknown_allowed"
        end
        if gate.unknownPolicy == "fail" then
            return false, gate.unknownReasonKey or "engine_fact_unknown_failed"
        end
        return nil, gate.unknownReasonKey or fact.reason
            or "engine_fact_unknown"
    end
    matches = EngineFacts.Compare(fact, gate.operator or "==", gate.value)
    if matches then
        return true, gate.passReasonKey or "engine_fact_matches"
    end
    return false, gate.failReasonKey or "engine_fact_mismatch"
end

local BUILTINS = {
    ["pnc:skill"] = function(context, gate)
        return Internal.Compare(
            skillLevel(context, gate), gate.operator, gate.value
        )
    end,
    ["pnc:trait"] = function(context, gate)
        return traitMatches(context, gate) == (gate.present ~= false)
    end,
    ["pnc:personality"] = function(context, gate)
        return Internal.Compare(
            personalityValue(context, gate), gate.operator, gate.value
        )
    end,
    ["pnc:relationship"] = function(context, gate)
        local relationship = context.relationship or {}
        return Internal.Compare(
            relationship[gate.axis or gate.key],
            gate.operator,
            gate.value
        )
    end,
    ["pnc:relationship_state"] = function(context, gate)
        return tostring(context.relationshipState or "")
            == tostring(gate.value or "")
    end,
    ["pnc:audience"] = function(context, gate)
        return context.audiences
            and context.audiences[
                tostring(gate.value or gate.audience)
            ] == true or false
    end,
    -- Generated simple-command flows use the existing condition evaluator for
    -- a bounded conversation/target authorization gate. The final command
    -- adapter and authoritative server still make the gameplay decision; this
    -- gate only prevents a malformed or unauthorised local context from
    -- reaching that adapter.
    ["pnc:semantic_context"] = function(context, gate)
        context = type(context) == "table" and context or {}
        local explicit = context.semanticAuthorization
        if type(explicit) == "table" then
            local capabilityID = tostring(gate.capabilityID or "")
            if explicit[capabilityID] ~= nil then
                return explicit[capabilityID] == true
            end
            if explicit.authorized ~= nil then
                return explicit.authorized == true
            end
        elseif explicit ~= nil then
            return explicit == true
        end
        if gate.requiresTarget == true
            and (context.npcID == nil or tostring(context.npcID) == "")
        then
            return false
        end
        if gate.requiresAuthority == true then
            local lifecycle = context.conversationLifecycleState
            if type(lifecycle) ~= "table"
                or lifecycle.token == nil
                or tostring(lifecycle.token) == ""
            then
                return false
            end
        end
        return true
    end,
    ["pnc:time"] = timeMatches,
    ["pnc:history"] = historyMatches,
    ["pnc:weather"] = weatherMatches,
    ["pnc:fact"] = engineFactMatches,
    ["pnc:base_not_established"] = function(context)
        return context.baseEstablished ~= true
    end,
    ["pnc:settlement_visit"] = function(context)
        local visit = context.settlementVisit
        return type(visit) == "table"
            and visit.active == true
            and (tonumber(visit.expiresAt) or 0)
                > (tonumber(context.worldAgeHours) or 0)
    end,
}

local id
local evaluate
for id, evaluate in pairs(BUILTINS) do
    if not Registry.conditionHandlers[id] then
        Registry.RegisterConditionHandler(id, {
            evaluate = evaluate,
            builtin = true,
        })
    end
end
