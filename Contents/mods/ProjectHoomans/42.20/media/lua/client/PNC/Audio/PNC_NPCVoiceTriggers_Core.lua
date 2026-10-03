--[[
    PNC NPC Voice Triggers
    Client-only snapshot observer for one-shot NPC voice events.

    This module observes state owned by shared/server systems. It must not be
    required by behavior, health, stamina, or movement code.
]]

PNC = PNC or {}
PNC.NPCVoice = PNC.NPCVoice or {}
PNC.NPCVoice.Triggers = PNC.NPCVoice.Triggers or {}

local Voice = PNC.NPCVoice
local Catalog = Voice.Catalog
local Triggers = Voice.Triggers
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local PRESENCE_LIVE = Const and Const.PRESENCE_LIVE or "live"

local STATE_BY_ID = {}
local BODY_ID_BY_OBJECT = setmetatable({}, { __mode = "k" })

local DAMAGE_EVENT_BY_WOUND = {
    bite = "injury.bite",
    glass_cut = "injury.glass_cut",
    fall_low = "injury.fall_low",
    fall_high = "injury.fall_high",
    laceration = "injury.lacerate",
    lacerate = "injury.lacerate",
    scratch = "injury.scratch",
    wall = "injury.wall",
    blunt = "injury.blunt",
}

local function isServerRuntime()
    return isServer and isServer() == true
end

local function nowMillis(value)
    if value ~= nil then
        return tonumber(value) or 0
    end
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    return 0
end

local function secondsToMillis(value, fallback)
    return math.max(0, (tonumber(value) or fallback) * 1000)
end

local function npcKey(snapshot, body)
    local id = snapshot and snapshot.id or nil
    if id ~= nil then
        return tostring(id)
    end
    if body then
        return BODY_ID_BY_OBJECT[body]
    end
    return nil
end

local function newState()
    return {
        initialized = false,
        lastAlive = nil,
        lastHealthState = nil,
        lastRecentDamageUntil = nil,
        lastBodyHealthSignature = nil,
        lastStaminaState = nil,
        lastMoving = nil,
        lastDamageAt = -math.huge,
        lastEffortAt = -math.huge,
        lastDownedAt = -math.huge,
        lastDeathAt = -math.huge,
        triggerRules = {},
        terminalPlayed = false,
    }
end

local function stateFor(snapshot, body)
    local key = npcKey(snapshot, body)
    local state
    if not key then return nil end
    if body then
        BODY_ID_BY_OBJECT[body] = key
    end
    state = STATE_BY_ID[key]
    if not state then
        state = newState()
        STATE_BY_ID[key] = state
    end
    return state
end

local function healthSignature(snapshot)
    local bodyHealth = snapshot and snapshot.bodyHealth or nil
    local wounds = bodyHealth and bodyHealth.wounds or nil
    local woundCount = 0
    local woundTypes = {}
    local partID
    local wound
    if type(wounds) == "table" then
        for partID, wound in pairs(wounds) do
            if type(wound) == "table" then
                woundCount = woundCount + 1
                woundTypes[#woundTypes + 1] = tostring(partID)
                    .. ":" .. tostring(wound.type or "")
                    .. ":" .. tostring(wound.createdAt or 0)
                    .. ":" .. tostring(wound.damage or wound.severity or 0)
            end
        end
    end
    table.sort(woundTypes)
    return table.concat({
        tostring(snapshot and snapshot.hpCurrent or 0),
        tostring(bodyHealth and bodyHealth.overallPercent or 0),
        tostring(bodyHealth and bodyHealth.bleedingRate or 0),
        tostring(bodyHealth and bodyHealth.openWoundCount or 0),
        tostring(bodyHealth and bodyHealth.bandagedWoundCount or 0),
        tostring(woundCount),
        table.concat(woundTypes, ";"),
    }, "|")
end

local function newestWoundType(snapshot)
    local wounds = snapshot
        and snapshot.bodyHealth
        and snapshot.bodyHealth.wounds
        or nil
    local newestAt = -math.huge
    local newestType
    local wound
    if type(wounds) ~= "table" then return nil end
    for _, candidate in pairs(wounds) do
        if type(candidate) == "table" then
            wound = candidate
            if (tonumber(wound.createdAt) or 0) >= newestAt then
                newestAt = tonumber(wound.createdAt) or 0
                newestType = tostring(wound.type or "")
            end
        end
    end
    return newestType
end

local function resolveDamageEvent(snapshot)
    local woundType = newestWoundType(snapshot)
    return DAMAGE_EVENT_BY_WOUND[woundType] or "injury.generic"
end

local function isMoving(snapshot)
    local visual = snapshot and snapshot.visualState or {}
    local profile = tostring(visual.profileKey or "")
    return visual.moving == true
        or visual.isRunning == true
        or visual.isCrawling == true
        or profile == "run"
        or profile == "walk"
        or profile == "sneak"
        or profile == "crawl"
        or profile == "recovery_walk"
        or profile == "recovery_sneak"
end

local function matchesTriggerValue(value, target, mode, caseSensitive)
    local observed = tostring(value or "")
    local wanted = tostring(target or "")
    if wanted == "" then return false end
    if not caseSensitive then
        observed = string.lower(observed)
        wanted = string.lower(wanted)
    end
    if mode == "equals" then
        return observed == wanted
    end
    return string.find(observed, wanted, 1, true) ~= nil
end

local function readMatchField(snapshot, field)
    local value = snapshot
    local firstSegment = true
    local segment
    if type(field) ~= "string" or field == "" then return nil end
    for segment in string.gmatch(field, "[^%.]+") do
        if firstSegment and (
            segment == "anim"
            or segment == "sceneBump"
            or segment == "specialAnim"
        ) then
            value = snapshot and snapshot.visualState or nil
        end
        if type(value) ~= "table" then return nil end
        value = value[segment]
        firstSegment = false
    end
    return value
end

local function matchesTriggerRule(snapshot, rule)
    local match = rule and rule.match or nil
    local fields = match and match.fields or nil
    local values = match and match.values or nil
    local mode = match and match.mode or "contains"
    local caseSensitive = match and match.caseSensitive == true
    local field
    local value
    local target
    if type(snapshot) ~= "table"
        or type(match) ~= "table"
        or type(fields) ~= "table"
        or type(values) ~= "table"
    then
        return false
    end
    for _, field in ipairs(fields) do
        value = readMatchField(snapshot, field)
        if value ~= nil then
            for _, target in ipairs(values) do
                if matchesTriggerValue(
                    value,
                    target,
                    mode,
                    caseSensitive
                ) then
                    return true
                end
            end
        end
    end
    return false
end

local DEFAULT_OCCURRENCE_FIELDS = {
    "visualState.sceneId",
    "visualState.sceneRevision",
    "visualState.scenePlaybackRevision",
    "visualState.sceneStepId",
    "visualState.sceneStepStartedAt",
    "visualState.anim",
    "visualState.sceneBump",
    "visualState.specialAnim",
}

local function triggerOccurrenceKey(snapshot, ruleID, rule)
    local fields = rule and rule.keyFields or DEFAULT_OCCURRENCE_FIELDS
    local values = { tostring(ruleID or "") }
    for _, field in ipairs(fields) do
        values[#values + 1] = tostring(readMatchField(snapshot, field) or "")
    end
    return table.concat(values, "|")
end

local function resolveTriggerRule(snapshot)
    local rules = Catalog
        and Catalog.GetTriggerRules
        and Catalog.GetTriggerRules()
        or nil
    local ruleID
    if type(rules) ~= "table" then return nil, nil, nil end
    for index, rule in ipairs(rules) do
        if matchesTriggerRule(snapshot, rule) then
            ruleID = tostring(rule.id or rule.eventID or index)
            return rule, ruleID, triggerOccurrenceKey(snapshot, ruleID, rule)
        end
    end
    return nil, nil, nil
end

local function identityVoiceSeed(snapshot, body)
    local seed = snapshot and snapshot.identitySeed or nil
    local fallback
    fallback = snapshot and snapshot.id or nil
    if fallback == nil and body and body.getModData then
        local modData = body:getModData()
        if modData then
            fallback = modData.PNC_UUID
        end
    end
    if Identity and Identity.NormalizeSeed then
        return Identity.NormalizeSeed(seed, fallback or "npc_voice")
    end
    return seed or fallback or "npc_voice"
end

local function fallbackChance(seed, salt)
    local value = 5381
    local source = tostring(seed or "") .. ":" .. tostring(salt or "")
    local i
    for i = 1, #source do
        value = ((value * 33) + string.byte(source, i)) % 2147483647
    end
    return (value % 100) + 1
end

local function passesChance(snapshot, body, occurrenceKey, rule)
    local configuredChance = rule and rule.chancePercent
    local chance
    local roll
    if configuredChance == nil then return true end
    chance = math.max(0, math.min(100, math.floor(
        tonumber(configuredChance) or 0
    )))
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    if Identity and Identity.Index then
        roll = Identity.Index(
            identityVoiceSeed(snapshot, body),
            "voice:trigger:" .. tostring(occurrenceKey),
            100
        )
    else
        roll = fallbackChance(
            identityVoiceSeed(snapshot, body),
            occurrenceKey
        )
    end
    return tonumber(roll) <= chance
end


Triggers.Internal = Triggers.Internal or {}
local Internal = Triggers.Internal
Internal.IsServerRuntime = isServerRuntime
Internal.NowMillis = nowMillis
Internal.SecondsToMillis = secondsToMillis
Internal.StateFor = stateFor
Internal.HealthSignature = healthSignature
Internal.ResolveDamageEvent = resolveDamageEvent
Internal.IsMoving = isMoving
Internal.ReadMatchField = readMatchField
Internal.ResolveTriggerRule = resolveTriggerRule
Internal.IdentityVoiceSeed = identityVoiceSeed
Internal.PassesChance = passesChance
Internal.Catalog = Catalog
Internal.PresenceLive = PRESENCE_LIVE
Internal.ResetState = function()
    STATE_BY_ID = {}
    BODY_ID_BY_OBJECT = setmetatable({}, { __mode = "k" })
end

return Triggers
