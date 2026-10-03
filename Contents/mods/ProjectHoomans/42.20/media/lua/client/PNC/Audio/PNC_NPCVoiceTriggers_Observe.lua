-- Client voice state observation provider.

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
local stateFor = Internal.StateFor
local healthSignature = Internal.HealthSignature
local resolveDamageEvent = Internal.ResolveDamageEvent
local isMoving = Internal.IsMoving
local observeTriggerRule = Internal.ObserveTriggerRule
local playEvent = Internal.PlayEvent
local readyFor = Internal.ReadyFor
local PRESENCE_LIVE = Internal.PresenceLive

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
    local damageType = string.lower(tostring(snapshot.recentDamageType or ""))
    local bodySignature = healthSignature(snapshot)
    local damageChanged = damageUntil > 0
        and damageUntil ~= previousDamageUntil
    local nowMoving = isMoving(snapshot)
    local policy

    -- Bleeding damage repeats on a timer; it is not a new impact that needs
    -- another pain vocalization.
    if damageChanged
        and healthState ~= "incapacitated"
        and damageType ~= "blood_loss"
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


return Triggers
