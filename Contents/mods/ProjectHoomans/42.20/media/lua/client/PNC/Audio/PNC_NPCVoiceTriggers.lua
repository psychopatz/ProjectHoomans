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
    local identity = snapshot and snapshot.identity or nil
    local seed = snapshot and snapshot.identitySeed or nil
    local fallback
    if seed == nil and identity then
        seed = identity.seed
    end
    fallback = snapshot and snapshot.id or nil
    if fallback == nil and body and body.getModData then
        local ok, modData = pcall(body.getModData, body)
        if ok and modData then
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

local function playEvent(snapshot, body, eventID, now)
    local policy = Catalog and Catalog.Get and Catalog.Get(eventID) or nil
    local options
    local handle
    if not policy or isServerRuntime() then
        return false
    end
    now = nowMillis(now)
    options = {
        snapshot = snapshot,
        radius = policy.radius,
        volume = policy.volume,
        stressHumans = policy.stressHumans,
    }
    if policy.mode == Voice.MODE_WORLD then
        if body then
            handle = Voice.PlayWorld(body, policy.suffix, options)
        elseif Voice.PlayWorldAt then
            handle = Voice.PlayWorldAt(snapshot, policy.suffix, options)
        end
    elseif body then
        handle = Voice.PlayLocal(body, policy.suffix, options)
    end
    return handle ~= nil and handle ~= 0
end

local function readyFor(state, field, now, cooldown)
    local last = tonumber(state[field]) or -math.huge
    return now - last >= cooldown
end

local function triggerRuleState(state, ruleID)
    state.triggerRules = state.triggerRules or {}
    state.triggerRules[ruleID] = state.triggerRules[ruleID] or {
        lastAt = -math.huge,
        lastKey = nil,
    }
    return state.triggerRules[ruleID]
end

local function clearInactiveTriggerRules(state, activeRuleID)
    local rules = state.triggerRules or {}
    local ruleID
    local ruleState
    for ruleID, ruleState in pairs(rules) do
        if ruleID ~= activeRuleID then
            ruleState.lastKey = nil
        end
    end
end

local function triggerCooldownMillis(rule, policy)
    local cooldown = rule and (
        rule.cooldownSeconds
        or rule.cooldown
    ) or nil
    if cooldown == nil then
        cooldown = policy and policy.cooldown or 0
    end
    return secondsToMillis(cooldown, 0)
end

local function observeTriggerRule(
    state,
    snapshot,
    body,
    now,
    isInitial
)
    local rule
    local ruleID
    local occurrenceKey
    local eventID
    local policy
    local ruleState
    rule, ruleID, occurrenceKey = resolveTriggerRule(snapshot)
    if not rule then
        clearInactiveTriggerRules(state, nil)
        return
    end
    clearInactiveTriggerRules(state, ruleID)
    ruleState = triggerRuleState(state, ruleID)
    if ruleState.lastKey == occurrenceKey then return end
    ruleState.lastKey = occurrenceKey
    if isInitial and rule.fireOnInitial == false then return end
    eventID = rule.eventID or rule.event
    policy = Catalog.Get(eventID)
    if not policy
        or not readyFor(
            ruleState,
            "lastAt",
            now,
            triggerCooldownMillis(rule, policy)
        )
        or not passesChance(
            snapshot,
            body,
            occurrenceKey,
            rule
        )
    then
        return
    end
    if playEvent(snapshot, body, eventID, now) then
        ruleState.lastAt = now
    end
end

local function updateState(state, snapshot)
    state.lastAlive = snapshot.alive ~= false
    state.lastHealthState = snapshot.healthState
    state.lastRecentDamageUntil = snapshot.recentDamageUntil
    state.lastBodyHealthSignature = healthSignature(snapshot)
    state.lastStaminaState = snapshot.staminaState
    state.lastMoving = isMoving(snapshot)
    state.initialized = true
end

local function observeInitialized(state, snapshot, body, now)
    local healthState = snapshot.healthState
    local previousHealthState = state.lastHealthState
    local staminaState = tostring(snapshot.staminaState or "")
    local previousStaminaState = tostring(state.lastStaminaState or "")
    local damageUntil = tonumber(snapshot.recentDamageUntil) or 0
    local previousDamageUntil = tonumber(state.lastRecentDamageUntil) or 0
    local bodySignature = healthSignature(snapshot)
    local damageChanged = damageUntil > 0
        and damageUntil ~= previousDamageUntil
    local nowMoving = isMoving(snapshot)
    local policy

    if damageChanged
        and healthState ~= "incapacitated"
    then
        policy = Catalog.Get(resolveDamageEvent(snapshot))
        if policy and readyFor(
            state,
            "lastDamageAt",
            now,
            secondsToMillis(policy.cooldown, 0.75)
        ) then
            if playEvent(snapshot, body, resolveDamageEvent(snapshot), now) then
                state.lastDamageAt = now
            end
        end
    end

    if healthState == "incapacitated"
        and previousHealthState ~= "incapacitated"
        and readyFor(state, "lastDownedAt", now, 1000)
    then
        if playEvent(snapshot, body, "incapacitated.impact", now) then
            state.lastDownedAt = now
        end
    end

    if staminaState == "exhausted"
        and previousStaminaState ~= "exhausted"
        and nowMoving
        and readyFor(state, "lastEffortAt", now, 3000)
    then
        if playEvent(snapshot, body, "effort.exhausted", now) then
            state.lastEffortAt = now
        end
    end

    observeTriggerRule(state, snapshot, body, now, false)

    state.lastAlive = snapshot.alive ~= false
    state.lastHealthState = healthState
    state.lastRecentDamageUntil = snapshot.recentDamageUntil
    state.lastBodyHealthSignature = bodySignature
    state.lastStaminaState = snapshot.staminaState
    state.lastMoving = nowMoving
end

function Triggers.Observe(snapshot, body, _, now)
    local state
    if isServerRuntime()
        or type(snapshot) ~= "table"
        or not body
        or snapshot.interestDetailed == false
        or snapshot.presenceState ~= PRESENCE_LIVE
        or snapshot.alive == false
    then
        return false
    end
    state = stateFor(snapshot, body)
    if not state then return false end
    now = nowMillis(now)
    if not state.initialized then
        updateState(state, snapshot)
        if snapshot.healthState == "incapacitated"
            and playEvent(snapshot, body, "incapacitated.impact", now)
        then
            state.lastDownedAt = now
        end
        observeTriggerRule(state, snapshot, body, now, true)
        return false
    end
    observeInitialized(state, snapshot, body, now)
    return true
end

local function resolveBodyForID(id)
    local sync = PNC.ClientPresenceSync
    local body
    local cell
    local zombieList
    local i
    local candidate
    local modData
    if sync and sync.BodyByID then
        body = sync.BodyByID[tostring(id)]
        if body and body ~= false then return body end
    end
    if not getCell then return nil end
    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then return nil end
    for i = 0, zombieList:size() - 1 do
        candidate = zombieList:get(i)
        modData = candidate and candidate.getModData
            and candidate:getModData() or nil
        if modData and modData.PNC_NPC == true
            and tostring(modData.PNC_UUID or "") == tostring(id)
        then
            return candidate
        end
    end
    return nil
end

function Triggers.ObserveDeath(snapshot, body, now)
    local state
    local previous
    local clientState
    local previousSnapshot
    if isServerRuntime() or type(snapshot) ~= "table" then
        return false
    end
    body = body or resolveBodyForID(snapshot.id)
    clientState = PNC.Network and PNC.Network.ClientState or nil
    previousSnapshot = clientState and clientState.snapshots
        and clientState.snapshots[tostring(snapshot.id or "")] or nil
    previous = previousSnapshot
    if previous then
        -- Death-marker snapshots are intentionally compact. Reuse identity
        -- fields from the last live snapshot so position-only playback still
        -- selects the NPC's established voice profile.
        if snapshot.identitySeed == nil then
            snapshot.identitySeed = previous.identitySeed
        end
        if snapshot.isFemale == nil then
            snapshot.isFemale = previous.isFemale
        end
        if snapshot.identity == nil then
            snapshot.identity = previous.identity
        end
    end
    state = stateFor(snapshot, body)
    if state and state.terminalPlayed then
        return false
    end
    if playEvent(snapshot, body, "death.alone", nowMillis(now)) then
        if state then
            state.terminalPlayed = true
            state.lastAlive = false
            state.lastDeathAt = nowMillis(now)
        end
        return true
    end
    return false
end

function Triggers.Emit(body, eventID, snapshot, options)
    local policy
    local now
    local occurrenceKey
    if isServerRuntime() or not body then return false end
    policy = Catalog and Catalog.Get and Catalog.Get(eventID) or nil
    if not policy then return false end
    options = options or {}
    now = nowMillis(options.now)
    occurrenceKey = options.occurrenceKey
        or tostring(eventID) .. ":" .. tostring(now)
    if not passesChance(snapshot, body, occurrenceKey, policy) then
        return false
    end
    return playEvent(snapshot, body, eventID, now)
end

function Triggers.Reset()
    STATE_BY_ID = {}
    BODY_ID_BY_OBJECT = setmetatable({}, { __mode = "k" })
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Triggers.Reset)
end

return Triggers
