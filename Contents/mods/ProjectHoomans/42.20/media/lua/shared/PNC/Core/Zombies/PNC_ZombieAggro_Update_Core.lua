PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local ZombieReaction = PNC.CombatZombieReaction
local Settings = PNC.Sandbox
local Diagnostics = PNC.PerformanceScalingDiagnostics

ZombieAggro.Internal = ZombieAggro.Internal or {}
local Internal = ZombieAggro.Internal
local Multiplayer = {}
local pursuitLogThrottle = {}
local pursuitLogCalls = 0

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end

local function isMultiplayerServer()
    return isServer and isServer() == true or false
end

function ZombieAggro.ClearForNPCBody(npcBody)
    local target
    local forcedRecord
    local forcedBody
    if not npcBody or not getCell then
        return
    end
    ZombieAggro.ClearBiteEntriesForNPCBody(npcBody)
    if ZombieAggro.ForEachActive then
        ZombieAggro.ForEachActive(function(zombie)
        if zombie and (not zombie:isDead())
            and (not Internal.isManagedNPCBody(zombie))
            and not isForeignOwnedBody(zombie)
        then
            target = zombie.getTarget and zombie:getTarget() or nil
            forcedRecord, forcedBody = Internal.getForcedNPCBodyTarget(zombie)
            if target == npcBody or forcedBody == npcBody then
                Internal.clearZombieTarget(zombie)
                ZombieAggro.ClearBiteEntryForZombie(zombie)
            end
        end
        end)
    end
end

function ZombieAggro.OnZombieProvoked(zombie, npcBody)
    if not zombie or not npcBody or zombie:isDead()
        or Internal.isManagedNPCBody(zombie)
        or isForeignOwnedBody(zombie)
    then
        return
    end
    if ZombieAggro.Activate then
        ZombieAggro.Activate(zombie, Core.Now(), "provoked")
    end
    Internal.forceAggro(zombie, npcBody)
end

local function setNoLungeAttack(zombie, disabled)
    if zombie and zombie.setVariable then
        zombie:setVariable("NoLungeAttack", disabled == true)
    end
end

local function incrementDiagnostic(name, amount)
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment(name, amount)
    end
end

local function logPursuitDiagnostic(
    zombie, npcId, channel, state, detail, now
)
    local perZombie
    local previous
    local zombieId
    local throttleKey
    local lastAt
    local fields
    local auditEnabled
    auditEnabled = not Diagnostics
        or type(Diagnostics.IsZombieAggroAuditEnabled) ~= "function"
        or Diagnostics.IsZombieAggroAuditEnabled() == true
    if not auditEnabled then
        return false
    end
    if not zombie or not Core or not Core.LogInfo then
        return false
    end
    now = tonumber(now) or Core.Now()
    channel = tostring(channel or "pursuit")
    state = tostring(state or "unknown")
    zombieId = zombie.getOnlineID and zombie:getOnlineID() or nil
    if (tonumber(zombieId) or -1) < 0
        and Internal.ensureZombieID
    then
        zombieId = Internal.ensureZombieID(zombie)
    end
    throttleKey = tostring(zombieId or zombie)
    perZombie = pursuitLogThrottle[throttleKey]
    if not perZombie then
        perZombie = {}
        pursuitLogThrottle[throttleKey] = perZombie
    end
    previous = perZombie[channel]
    if previous
        and previous.state == state
        and now - (tonumber(previous.at) or 0) < 2500
    then
        return false
    end
    if previous
        and previous.state ~= state
        and now - (tonumber(previous.at) or 0) < 500
    then
        return false
    end
    perZombie[channel] = { state = state, at = now }
    pursuitLogCalls = pursuitLogCalls + 1
    if pursuitLogCalls % 128 == 0 then
        for cachedZombie, channels in pairs(pursuitLogThrottle) do
            lastAt = 0
            for _, entry in pairs(channels) do
                if (tonumber(entry.at) or 0) > lastAt then
                    lastAt = tonumber(entry.at) or 0
                end
            end
            if now - lastAt > 30000 then
                pursuitLogThrottle[cachedZombie] = nil
            end
        end
    end
    fields = {
        "zombie=" .. tostring(zombieId or ("local@" .. throttleKey)),
        "npc=" .. tostring(npcId or "unknown"),
        "state=" .. state,
        tostring(detail or ""),
    }
    if Diagnostics and type(Diagnostics.LogZombieAggroAudit) == "function" then
        return Diagnostics.LogZombieAggroAudit(channel, fields)
    end
    Core.LogInfo(
        "ZombieAggro." .. channel .. " " .. table.concat(fields, " ")
    )
    return true
end

-- Shared and client-side controllers use the same bounded logger so a single
-- console capture can show target selection, movement, and MP handoff.
ZombieAggro.LogPursuitDiagnostic = logPursuitDiagnostic

local function actionStateName(zombie)
    return zombie
        and zombie.getActionStateName
        and string.lower(tostring(zombie:getActionStateName() or ""))
        or ""
end

local PURSUIT_ACTION_LOCKS = {
    ["attack"] = true,
    ["attack-network"] = true,
    bumped = true,
    climbfence = true,
    climbwindow = true,
    getup = true,
    lunge = true,
    onground = true,
    staggerback = true,
    turnalerted = true,
}

local function isPursuitActionLocked(zombie)
    return PURSUIT_ACTION_LOCKS[actionStateName(zombie)] == true
end

-- Use the vanilla coordinate-goal API without ever creating an NPC character
-- goal. When a zombie is already in PathFindState, calling the character
-- wrapper can be ignored by IsoZombie's allowRepathDelay guard. PathFindState
-- already owns Behavior2:update(), so update its location goal directly in
-- that state. In all other states the public wrapper remains responsible for
-- entering the normal pathfind/movement animation contract.
function ZombieAggro.RequestCoordinatePath(zombie, targetX, targetY, targetZ)
    local behavior
    local state
    local pathState
    local currentState
    if not zombie then
        return false, "missing_zombie"
    end
    behavior = zombie.getPathFindBehavior2
        and zombie:getPathFindBehavior2() or nil
    state = actionStateName(zombie)
    if isPursuitActionLocked(zombie) then
        incrementDiagnostic("ZombieAggro.PathRequestsDeferred")
        return false, "action_state_locked:" .. state
    end
    if not behavior or not behavior.pathToLocationF then
        return false, "behavior2_unavailable"
    end

    pathState = PathFindState and PathFindState.instance
        and PathFindState.instance() or nil
    currentState = zombie.getCurrentState and zombie:getCurrentState() or nil
    -- IsoZombie:pathToLocationF() is guarded by allowRepathDelay while it is
    -- in PathFind/WalkToward states. Use the same direct Behavior2 + state
    -- transition sequence that Project A-Life uses for its owned shells in
    -- every state, so the goal update cannot be silently discarded.
    if pathState and currentState ~= pathState then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
        if zombie.setPath2 then zombie:setPath2(nil) end
    end
    behavior:pathToLocationF(targetX, targetY, targetZ)
    if zombie.setVariable then
        zombie:setVariable("bPathfind", true)
        zombie:setVariable("bMoving", false)
    end
    if pathState and currentState ~= pathState and zombie.changeState then
        zombie:changeState(pathState)
    end
    incrementDiagnostic("ZombieAggro.Behavior2PathRequests")
    return true, "behavior2_pathfind_state"
end

local function suppressForStealth(zombie, record)
    Internal.clearZombieTarget(zombie)
    ZombieAggro.ClearBiteEntryForZombie(zombie)
    -- clearZombieTarget intentionally restores the ordinary zombie default.
    -- Stealth suppression must override that default on the same frame or a
    -- stale native target can still lunge before the next aggro tick.
    setNoLungeAttack(zombie, true)
    record.runtime = record.runtime or {}
    record.runtime.combatBlockReason = Stealth
        and Stealth.IsTravelStealthActive
        and Stealth.IsTravelStealthActive(record)
        and "travel_stealth_hidden"
        or "follow_stealth_hidden"
end


Internal.UpdateProviders = Internal.UpdateProviders or {}
Internal.UpdateProviders.Multiplayer = Multiplayer
Internal.UpdateProviders.isMultiplayerServer = isMultiplayerServer
Internal.UpdateProviders.incrementDiagnostic = incrementDiagnostic
Internal.UpdateProviders.logPursuitDiagnostic = logPursuitDiagnostic
Internal.Core = Core
Internal.Const = Const
Internal.Registry = Registry
Internal.Stealth = Stealth
Internal.ZombieReaction = ZombieReaction
Internal.Settings = Settings
Internal.Diagnostics = Diagnostics
Internal.Multiplayer = Multiplayer
Internal.isForeignOwnedBody = isForeignOwnedBody
Internal.isMultiplayerServer = isMultiplayerServer
Internal.setNoLungeAttack = setNoLungeAttack
Internal.incrementDiagnostic = incrementDiagnostic
Internal.logPursuitDiagnostic = logPursuitDiagnostic
Internal.actionStateName = actionStateName
Internal.isPursuitActionLocked = isPursuitActionLocked
Internal.suppressForStealth = suppressForStealth

return ZombieAggro
