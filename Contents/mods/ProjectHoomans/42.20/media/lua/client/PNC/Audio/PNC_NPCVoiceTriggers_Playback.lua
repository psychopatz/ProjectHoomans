-- Client voice playback and trigger-rule provider.

PNC = PNC or {}
PNC.NPCVoice = PNC.NPCVoice or {}
PNC.NPCVoice.Triggers = PNC.NPCVoice.Triggers or {}
local Voice = PNC.NPCVoice
local Catalog = Voice.Catalog
local Triggers = Voice.Triggers
local Internal = Triggers.Internal or {}
Triggers.Internal = Internal
local isServerRuntime = Internal.IsServerRuntime
local nowMillis = Internal.NowMillis
local secondsToMillis = Internal.SecondsToMillis
local resolveTriggerRule = Internal.ResolveTriggerRule
local passesChance = Internal.PassesChance

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


Internal.PlayEvent = playEvent
Internal.ReadyFor = readyFor
Internal.ObserveTriggerRule = observeTriggerRule

return Triggers
