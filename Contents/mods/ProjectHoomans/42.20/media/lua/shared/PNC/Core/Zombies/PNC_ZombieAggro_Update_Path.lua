local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"
local Internal = ZombieAggro.Internal
local Core = Internal.Core
local Const = Internal.Const
local Diagnostics = Internal.Diagnostics
local Multiplayer = Internal.Multiplayer
local incrementDiagnostic = Internal.incrementDiagnostic
local logPursuitDiagnostic = Internal.logPursuitDiagnostic
local actionStateName = Internal.actionStateName
local isPursuitActionLocked = Internal.isPursuitActionLocked

local function refreshPursuitPath(zombie, npcBody, now, npcId)
    local modData = Internal.getZombieModData(zombie)
    local targetX = npcBody:getX()
    local targetY = npcBody:getY()
    local dx = targetX - zombie:getX()
    local dy = targetY - zombie:getY()
    local distanceSq = (dx * dx) + (dy * dy)
    local lastX = modData and tonumber(modData.PNC_AggroPathX) or nil
    local lastY = modData and tonumber(modData.PNC_AggroPathY) or nil
    local movedSq = lastX and lastY and Core.DistanceSq(lastX, lastY, targetX, targetY) or math.huge
    local refreshDistance = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6
    local lastAt = modData
        and tonumber(modData.PNC_AggroPathAt) or nil
    local elapsed
    local refreshMs = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_MS) or 350
    local stableRetryMs = tonumber(
        Const.ZOMBIE_NPC_PATH_STABLE_RETRY_MS
    ) or 1500
    now = tonumber(now) or Core.Now()
    if isPursuitActionLocked(zombie) then
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            "action_state_locked",
            "action=" .. actionStateName(zombie),
            now
        )
        return false
    end
    elapsed = lastAt and (now - lastAt) or math.huge
    if modData and lastAt and (
        elapsed < refreshMs
        or (movedSq < (refreshDistance * refreshDistance)
            and elapsed < stableRetryMs)
    ) then
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            elapsed < refreshMs and "request_cooldown"
                or "stable_goal_kept",
            "targetMovedSq=" .. tostring(movedSq)
                .. " elapsedMs=" .. tostring(elapsed)
                .. " minIntervalMs=" .. tostring(refreshMs)
                .. " stableRetryMs=" .. tostring(stableRetryMs),
            now
        )
        return false
    end
    if ZombieAggro.ConsumePathRequestBudget
        and not ZombieAggro.ConsumePathRequestBudget()
    then
        if Diagnostics then
            Diagnostics.Increment(
                "ZombieAggro.PathRequestsDeferred"
            )
        end
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            "budget_deferred",
            "targetX=" .. tostring(targetX)
                .. " targetY=" .. tostring(targetY),
            now
        )
        return false
    end
    if modData then
        modData.PNC_AggroPathAt = now
        modData.PNC_AggroPathX = targetX
        modData.PNC_AggroPathY = targetY
    end
    -- PNC bodies are IsoZombie shells, not IsoPlayer targets. A native
    -- character goal can enter Build 42's lunge/fence attack path, whose
    -- animation event dereferences player-only state such as Moodles and
    -- BodyDamage. Keep SP pursuit coordinate-only; the abstract bite lane
    -- owns NPC damage separately.
    local requested
    local requestReason
    if ZombieAggro.RequestCoordinatePath then
        requested, requestReason = ZombieAggro.RequestCoordinatePath(
            zombie,
            targetX,
            targetY,
            npcBody:getZ()
        )
    elseif zombie.pathToLocationF then
        zombie:pathToLocationF(targetX, targetY, npcBody:getZ())
        requested = true
    end
    if requested then
        if Diagnostics then
            Diagnostics.Increment("ZombieAggro.PathRequests")
        end
    end
    logPursuitDiagnostic(
        zombie,
        npcId,
        "server_path",
        requested and "path_requested" or "path_request_failed",
        "api=" .. tostring(requestReason or "pathToLocationF")
            .. " action=" .. actionStateName(zombie)
            .. " distance=" .. tostring(math.sqrt(distanceSq))
            .. " targetX=" .. tostring(targetX)
            .. " targetY=" .. tostring(targetY),
        now
    )
    return true
end

-- Multiplayer directive state is implemented by the provider loaded below.
-- These wrappers keep the update loop ownership and call sites stable.

Internal.refreshPursuitPath = refreshPursuitPath
return ZombieAggro
