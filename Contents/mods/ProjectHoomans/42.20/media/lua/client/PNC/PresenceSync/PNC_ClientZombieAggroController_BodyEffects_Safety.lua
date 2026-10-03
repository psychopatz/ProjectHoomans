PNC = PNC or {}
PNC.ZombieAggroEffects = PNC.ZombieAggroEffects or {}

local Effects = PNC.ZombieAggroEffects
Effects.Internal = Effects.Internal or {}
local Internal = Effects.Internal
local Core = PNC.Core
local Const = PNC.Const or {}

local PATH_REFRESH_MS = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_MS) or 350
local PATH_REFRESH_DISTANCE = tonumber(
    Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6
local PATH_STABLE_RETRY_MS = tonumber(Const.ZOMBIE_NPC_PATH_STABLE_RETRY_MS) or 1500
local BITE_DISTANCE = tonumber(Const.ZOMBIE_BITE_DISTANCE) or 1.2

Internal.Core = Core
Internal.PathRefreshMS = PATH_REFRESH_MS
Internal.PathRefreshDistance = PATH_REFRESH_DISTANCE
Internal.PathStableRetryMS = PATH_STABLE_RETRY_MS
Internal.BiteDistance = BITE_DISTANCE

local function isMultiplayerMode()
    return (isServer and isServer() == true)
        or (isClient and isClient() == true)
end

local function isManagedBody(body)
    return Core
        and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(body)
        or false
end

local function logPursuitDiagnostic(
    zombie, npcId, state, detail, now
)
    local aggro = PNC.ZombieAggro
    if aggro and aggro.LogPursuitDiagnostic then
        aggro.LogPursuitDiagnostic(
            zombie, npcId, "client_move", state, detail, now
        )
    end
end

local function hasActivePNCBite(zombie)
    local aggro = PNC.ZombieAggro
    local internal = aggro and aggro.Internal
    local biteInternal = aggro and aggro.BiteInternal
    local zombieId = internal and internal.ensureZombieID
        and internal.ensureZombieID(zombie) or nil
    return zombieId ~= nil
        and biteInternal
        and biteInternal.GetBiteEntry
        and biteInternal.GetBiteEntry(zombieId) ~= nil
        or false
end

function Effects.EnforceManagedSafetyGuard(zombie)
    if not isManagedBody(zombie) then return false end
    -- This handler runs late in the client OnZombieUpdate chain. Keep the
    -- managed shell in the same final safety gate even though it is not
    -- eligible for ordinary-zombie target selection; this closes the window
    -- where vanilla alert/path state can be restored after shared safety.
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.EnforceManagedSafety
    then
        PNC.LiveBodyControl.EnforceManagedSafety(
            zombie,
            "client_zombie_aggro_guard"
        )
    end
    return true
end

function Effects.ClearHeldItems(zombie)
    -- Build 42's multiplayer dropHeavyItems path sends a player-only packet.
    -- Ordinary zombies can reach that path while pursuing a managed NPC, so
    -- mirror Bandits and remove carried items before native pursuit continues.
    if zombie.getPrimaryHandItem and zombie:getPrimaryHandItem()
        and zombie.setPrimaryHandItem
    then
        zombie:setPrimaryHandItem(nil)
    end
    if zombie.getSecondaryHandItem and zombie:getSecondaryHandItem()
        and zombie.setSecondaryHandItem
    then
        zombie:setSecondaryHandItem(nil)
    end
    -- Bandits also clear the equipped/attached visual state in MP. Keep this
    -- traversal safeguard out of the restored singleplayer lane.
    if isMultiplayerMode() then
        if zombie.resetEquippedHandsModels then
            zombie:resetEquippedHandsModels()
        end
        if zombie.clearAttachedItems then
            zombie:clearAttachedItems()
        end
    end
end

function Effects.ClearNativeCombatTarget(zombie)
    -- NPCs are IsoZombie shells. Never place one in IsoZombie.target or
    -- attackedBy: Build 42 AttackState casts those native combat slots to
    -- IsoPlayer during animation events. Movement uses coordinate goals while
    -- damage is handled by the abstract server lane.
    if zombie.setTarget then zombie:setTarget(nil) end
    if zombie.setAttackedBy then zombie:setAttackedBy(nil) end
    if zombie.setTargetSeenTime then zombie:setTargetSeenTime(0) end
    if zombie.clearAggroList then zombie:clearAggroList() end
end

Internal.IsMultiplayerMode = isMultiplayerMode
Internal.IsManagedBody = isManagedBody
Internal.LogPursuitDiagnostic = logPursuitDiagnostic
Internal.HasActivePNCBite = hasActivePNCBite

return Effects
