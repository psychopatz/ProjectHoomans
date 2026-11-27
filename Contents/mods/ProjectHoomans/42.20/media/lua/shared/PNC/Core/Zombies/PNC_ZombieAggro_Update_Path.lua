local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"
local Internal = ZombieAggro.Internal
local Core = Internal.Core
local Const = Internal.Const
local Diagnostics = Internal.Diagnostics
local Multiplayer = Internal.Multiplayer
local incrementDiagnostic = Internal.incrementDiagnostic
local logPursuitDiagnostic = Internal.logPursuitDiagnostic
local isPursuitAuditEnabled = Internal.isPursuitAuditEnabled
local actionStateName = Internal.actionStateName
local isPursuitActionLocked = Internal.isPursuitActionLocked

local function refreshPursuitPath(zombie, npcBody, now, npcId, closeBlocked, modData)
    modData = modData or Internal.getZombieModData(zombie)
    local policy = ZombieAggro.PathPolicy
    local zx = zombie:getX()
    local zy = zombie:getY()
    local zz = zombie:getZ()
    local targetX = npcBody:getX()
    local targetY = npcBody:getY()
    local targetZ = npcBody:getZ()
    local dx = targetX - zx
    local dy = targetY - zy
    local distanceSq = (dx * dx) + (dy * dy)
    local sameFloor = math.floor(zz) == math.floor(targetZ)
    local lastX = modData and tonumber(modData.PNC_AggroPathX) or nil
    local lastY = modData and tonumber(modData.PNC_AggroPathY) or nil
    local lastZ = modData and tonumber(modData.PNC_AggroPathZ) or nil
    local prevNpcId = modData and modData.PNC_AggroPathNpcId or nil
    local targetChanged = npcId ~= nil and tostring(prevNpcId or "") ~= tostring(npcId)
    local movedSq = lastX and lastY and Core.DistanceSq(lastX, lastY, targetX, targetY) or math.huge
    local levelChanged = lastZ ~= nil and math.floor(lastZ) ~= math.floor(targetZ)
    local refreshDistance = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.85
    local lastAt = modData and tonumber(modData.PNC_AggroPathAt) or nil
    local elapsed
    local refreshMs = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_MS) or 350
    local stableRetryMs = tonumber(Const.ZOMBIE_NPC_PATH_STABLE_RETRY_MS) or 1500
    now = tonumber(now) or Core.Now()
    if isPursuitActionLocked(zombie) then
        if isPursuitAuditEnabled and isPursuitAuditEnabled() then
            logPursuitDiagnostic(
                zombie,
                npcId,
                "server_path",
                "action_state_locked",
                "action=" .. actionStateName(zombie),
                now
            )
        end
        return false
    end
    local stalled = policy and policy.UpdateProgress
        and policy.UpdateProgress(zombie, modData, now) or false
    local action = actionStateName(zombie)
    local pursuingState = action == "pathfind"
        or action == "walktoward"
        or action == "walktoward-network"
    local stateLost = action == "turnalerted"
        or action == "lunge"
        or action == "lunge-network"
    local closeWalkFast = sameFloor and closeBlocked ~= true
        and distanceSq <= 36 and action == "walktoward"
    if not stalled and not targetChanged and not levelChanged and pursuingState
        and policy and policy.IsFinderNearGoal
        and policy.IsFinderNearGoal(zombie, targetX, targetY, targetZ)
    then
        return false
    end
    elapsed = lastAt and (now - lastAt) or math.huge
    local hasPath2 = zombie.getPath2 and zombie:getPath2() ~= nil or false
    local backoffMs = modData and tonumber(modData.PNC_AggroBackoffMs) or 0
    local effectiveRefreshMs = stateLost and 150 or math.max(refreshMs, backoffMs)
    local effectiveStableMs = (closeBlocked == true and hasPath2)
        and math.max(stableRetryMs, 1500, backoffMs)
        or math.max(stableRetryMs, backoffMs)
    if modData and lastAt and not targetChanged and not levelChanged and (
        elapsed < effectiveRefreshMs
        or (not stateLost
            and movedSq < (refreshDistance * refreshDistance)
            and elapsed < effectiveStableMs)
    ) then
        if isPursuitAuditEnabled and isPursuitAuditEnabled() then
            logPursuitDiagnostic(
                zombie,
                npcId,
                "server_path",
                elapsed < effectiveRefreshMs and "request_cooldown"
                    or "stable_goal_kept",
                "targetMovedSq=" .. tostring(movedSq)
                    .. " elapsedMs=" .. tostring(elapsed)
                    .. " minIntervalMs=" .. tostring(effectiveRefreshMs)
                    .. " stableRetryMs=" .. tostring(effectiveStableMs),
                now
            )
        end
        return false
    end
    if not closeWalkFast then
        if ZombieAggro.ConsumePathRequestBudget
            and not ZombieAggro.ConsumePathRequestBudget()
        then
            if Diagnostics then
                Diagnostics.Increment("ZombieAggro.PathRequestsDeferred")
            end
            return false
        end
        if policy and policy.CanAdmitAStar
            and not policy.CanAdmitAStar(
                zombie, now, targetChanged or levelChanged,
                sameFloor and distanceSq <= 36
            )
        then
            if Diagnostics then
                Diagnostics.Increment("ZombieAggro.PathRequestsDeferred")
            end
            return false
        end
    end
    local goalX, goalY = targetX, targetY
    if policy and policy.ComputeLeadGoal and not stalled then
        goalX, goalY = policy.ComputeLeadGoal(
            modData, zx, zy, zz, targetX, targetY, targetZ, now
        )
    end
    if modData then
        modData.PNC_AggroPathAt = now
        modData.PNC_AggroPathX = targetX
        modData.PNC_AggroPathY = targetY
        modData.PNC_AggroPathZ = targetZ
        modData.PNC_AggroPathNpcId = npcId
        if policy and policy.ComputeRepathCooldown then
            policy.ComputeRepathCooldown(modData, stalled, targetChanged)
        end
    end
    -- PNC bodies are IsoZombie shells, not IsoPlayer targets. Keep pursuit
    -- unified on Behavior2 + PathFindState across SP and MP; the abstract
    -- bite lane owns NPC damage separately.
    local requested
    local requestReason
    if ZombieAggro.RequestCoordinatePath then
        requested, requestReason = ZombieAggro.RequestCoordinatePath(
            zombie,
            goalX,
            goalY,
            targetZ
        )
    elseif zombie.pathToLocationF then
        zombie:pathToLocationF(goalX, goalY, targetZ)
        requested = true
    end
    if requested then
        if Diagnostics then
            Diagnostics.Increment("ZombieAggro.PathRequests")
        end
    end
    if isPursuitAuditEnabled and isPursuitAuditEnabled() then
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            requested and "path_requested" or "path_request_failed",
            "api=" .. tostring(requestReason or "pathToSound")
                .. " action=" .. actionStateName(zombie)
                .. " distance=" .. tostring(math.sqrt(distanceSq))
                .. " targetX=" .. tostring(goalX)
                .. " targetY=" .. tostring(goalY),
            now
        )
    end
    return true
end

-- Multiplayer directive state is implemented by the provider loaded below.
-- These wrappers keep the update loop ownership and call sites stable.

Internal.refreshPursuitPath = refreshPursuitPath
return ZombieAggro
