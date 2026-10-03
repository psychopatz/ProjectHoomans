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

local isMultiplayerMode = Internal.IsMultiplayerMode
local isManagedBody = Internal.IsManagedBody
local logPursuitDiagnostic = Internal.LogPursuitDiagnostic
local hasActivePNCBite = Internal.HasActivePNCBite
local PATH_REFRESH_MS = Internal.PathRefreshMS
local PATH_REFRESH_DISTANCE = Internal.PathRefreshDistance
local PATH_STABLE_RETRY_MS = Internal.PathStableRetryMS
local BITE_DISTANCE = Internal.BiteDistance

function Effects.ShouldRefreshPath(zombie, targetX, targetY, now)
    local modData = zombie.getModData
        and zombie:getModData() or nil
    local pathAtKey = "PNC_ClientAggroPathAt"
    local pathXKey = "PNC_ClientAggroPathX"
    local pathYKey = "PNC_ClientAggroPathY"
    local x = tonumber(targetX) or zombie:getX()
    local y = tonumber(targetY) or zombie:getY()
    if not isMultiplayerMode() then
        -- Singleplayer shared pursuit and this client hook control the same
        -- zombie. Share their path timestamp so they cannot reset one route
        -- twice through independent throttles.
        pathAtKey = "PNC_AggroPathAt"
        pathXKey = "PNC_AggroPathX"
        pathYKey = "PNC_AggroPathY"
    end
    local lastX = modData
        and tonumber(modData[pathXKey]) or nil
    local lastY = modData
        and tonumber(modData[pathYKey]) or nil
    local dx = lastX and x - lastX or math.huge
    local dy = lastY and y - lastY or math.huge
    local lastAt = modData
        and tonumber(modData[pathAtKey]) or nil
    local elapsed = lastAt and now - lastAt or math.huge
    local movedSq = (dx * dx) + (dy * dy)
    if modData and lastAt and (
        elapsed < PATH_REFRESH_MS
        or (movedSq < PATH_REFRESH_DISTANCE * PATH_REFRESH_DISTANCE
            and elapsed < PATH_STABLE_RETRY_MS)
    ) then
        return false
    end
    if modData then
        modData[pathAtKey] = now
        modData[pathXKey] = x
        modData[pathYKey] = y
    end
    return true
end

function Effects.RequestCoordinatePath(zombie, targetX, targetY, targetZ)
    local aggro = PNC.ZombieAggro
    if aggro and aggro.RequestCoordinatePath then
        return aggro.RequestCoordinatePath(
            zombie,
            targetX,
            targetY,
            targetZ
        )
    end
    if zombie.pathToLocationF then
        zombie:pathToLocationF(targetX, targetY, targetZ)
        return true
    end
    return false
end

function Effects.ApplySingleplayerAggro(
    zombie, body, distanceSq, now, npcId
)
    local refreshed
    local requested
    local requestReason
    local biteActive
    Effects.ClearHeldItems(zombie)
    -- PNC bodies are IsoZombie shells. Build 42's native attack and window
    -- traversal events assume their target is an IsoPlayer and can dereference
    -- player-only state such as Moodles. Keep the shell out of those slots in
    -- both fresh and stale-target cases.
    Effects.ClearNativeCombatTarget(zombie)
    if body.setZombiesDontAttack then
        -- Native zombies must not acquire the IsoZombie shell as a combat
        -- target. PNC's abstract bite lane remains independently targetable.
        body:setZombiesDontAttack(true)
    end
    if zombie.isUseless and zombie.setUseless
        and zombie:isUseless()
    then
        zombie:setUseless(false)
    end
    -- Coordinate pursuit is safe for the IsoZombie shell representation. Do
    -- not call pathToCharacter here: Build 42 may promote that character goal
    -- into the same native combat state we are explicitly avoiding.
    if distanceSq > BITE_DISTANCE * BITE_DISTANCE then
        refreshed = Effects.ShouldRefreshPath(
            zombie,
            body:getX(),
            body:getY(),
            now
        )
        if refreshed then
            requested, requestReason = Effects.RequestCoordinatePath(
                zombie,
                body:getX(),
                body:getY(),
                body:getZ()
            )
            logPursuitDiagnostic(
                zombie, npcId,
                requested and "sp_path_requested"
                    or "sp_path_request_failed",
                "api=" .. tostring(requestReason or "pathToLocationF")
                    .. " distance=" .. tostring(math.sqrt(distanceSq))
                    .. " action=" .. tostring(
                        zombie.getActionStateName
                            and zombie:getActionStateName() or "unknown"
                    ),
                now
            )
        else
            logPursuitDiagnostic(
                zombie, npcId, "sp_path_refresh_suppressed",
                "distance=" .. tostring(math.sqrt(distanceSq)), now
            )
        end
    else
        biteActive = hasActivePNCBite(zombie)
        if not biteActive then
            refreshed = Effects.ShouldRefreshPath(
                zombie,
                body:getX(),
                body:getY(),
                now
            )
            if refreshed then
                requested, requestReason = Effects.RequestCoordinatePath(
                    zombie,
                    body:getX(),
                    body:getY(),
                    body:getZ()
                )
            end
            logPursuitDiagnostic(
                zombie, npcId,
                requested and "sp_close_path_requested"
                    or refreshed and "sp_close_path_request_failed"
                    or "sp_close_goal_kept",
                "distance=" .. tostring(math.sqrt(distanceSq))
                    .. " api=" .. tostring(requestReason or "pathToLocationF")
                    .. " action=" .. tostring(
                        zombie.getActionStateName
                            and zombie:getActionStateName() or "unknown"
                    ),
                now
            )
            if zombie.faceLocation then
                zombie:faceLocation(body:getX(), body:getY())
            elseif zombie.faceThisObject then
                zombie:faceThisObject(body)
            end
        else
            if zombie.faceLocation then
                zombie:faceLocation(body:getX(), body:getY())
            elseif zombie.faceThisObject then
                zombie:faceThisObject(body)
            end
            logPursuitDiagnostic(
                zombie, npcId, "sp_close_range_hold",
                "distance=" .. tostring(math.sqrt(distanceSq))
                    .. " biteDistance=" .. tostring(BITE_DISTANCE)
                    .. " action=" .. tostring(
                        zombie.getActionStateName
                            and zombie:getActionStateName() or "unknown"
                    ),
                now
            )
        end
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", true)
    end
end

function Effects.ApplyCoordinateDirective(
    zombie, targetX, targetY, targetZ, now, npcId, approach,
    owner, provider, leaseUntil, priority, reason
)
    local x = tonumber(targetX)
    local y = tonumber(targetY)
    local z = tonumber(targetZ)
    local dx
    local dy
    local distanceSq
    local zDistance
    local actionState
    local refreshed
    local requested
    local requestReason
    if not zombie or x == nil or y == nil or z == nil then
        return false
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if zombie.getModData then
        local modData = zombie:getModData()
        if modData then
            modData.PNC_ZombiePursuitOwner = owner or "ProjectHoomans"
            modData.PNC_ZombiePursuitProvider = provider or "Hoomans"
            modData.PNC_ZombiePursuitTarget = npcId
            modData.PNC_ZombiePursuitRevision = tonumber(
                modData.PNC_ZombiePursuitRevision
            ) or 0
            modData.PNC_ZombiePursuitUntil = tonumber(leaseUntil)
                or (now + 1100)
            modData.PNC_ZombiePursuitPriority = tonumber(priority) or 100
            modData.PNC_ZombiePursuitReason = reason or "hoomans_npc"
        end
    end
    Effects.ClearHeldItems(zombie)
    Effects.ClearNativeCombatTarget(zombie)
    if zombie.isUseless and zombie.setUseless
        and zombie:isUseless()
    then
        zombie:setUseless(false)
    end
    dx = x - zombie:getX()
    dy = y - zombie:getY()
    distanceSq = (dx * dx) + (dy * dy)
    zDistance = math.abs(z - zombie:getZ())
    actionState = zombie.getActionStateName
        and string.lower(tostring(zombie:getActionStateName() or ""))
        or ""
    if distanceSq > BITE_DISTANCE * BITE_DISTANCE
        or zDistance >= 0.3
        or ((approach == true or actionState == "staggerback")
            and actionState ~= "bumped")
    then
        refreshed = Effects.ShouldRefreshPath(zombie, x, y, now)
        if refreshed then
            requested, requestReason = Effects.RequestCoordinatePath(
                zombie, x, y, z
            )
            logPursuitDiagnostic(
                zombie, npcId,
                requested and "mp_path_requested"
                    or "mp_path_request_failed",
                "api=" .. tostring(requestReason or "pathToLocationF")
                    .. " distance=" .. tostring(math.sqrt(distanceSq))
                    .. " zDistance=" .. tostring(zDistance)
                    .. " approach=" .. tostring(approach == true)
                    .. " action=" .. actionState
                    .. " targetX=" .. tostring(x)
                    .. " targetY=" .. tostring(y),
                now
            )
        else
            logPursuitDiagnostic(
                zombie, npcId, "mp_path_refresh_suppressed",
                "distance=" .. tostring(math.sqrt(distanceSq))
                    .. " approach=" .. tostring(approach == true)
                    .. " targetX=" .. tostring(x)
                    .. " targetY=" .. tostring(y),
                now
            )
        end
    elseif zombie.faceLocation then
        zombie:faceLocation(x, y)
        logPursuitDiagnostic(
            zombie, npcId, "mp_close_range_hold",
            "distance=" .. tostring(math.sqrt(distanceSq))
                .. " zDistance=" .. tostring(zDistance)
                .. " approach=" .. tostring(approach == true)
                .. " biteDistance=" .. tostring(BITE_DISTANCE),
            now
        )
    else
        logPursuitDiagnostic(
            zombie, npcId, "mp_close_range_no_face_api",
            "distance=" .. tostring(math.sqrt(distanceSq))
                .. " zDistance=" .. tostring(math.abs(z - zombie:getZ())),
            now
        )
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", true)
    end
    return true
end

function Effects.ReleaseCoordinateDirective(zombie)
    local modData
    if not zombie then
        return false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        modData.PNC_ClientAggroPathAt = nil
        modData.PNC_ClientAggroPathX = nil
        modData.PNC_ClientAggroPathY = nil
    end
    if PNC.ZombieAggro
        and PNC.ZombieAggro.Internal
        and PNC.ZombieAggro.Internal.ReleasePursuitLease
    then
        PNC.ZombieAggro.Internal.ReleasePursuitLease(
            zombie,
            "ProjectHoomans"
        )
    end
    -- Cancel the old coordinate goal without creating a native NPC target.
    -- Vanilla may reacquire a player on its next state update.
    local behavior = zombie.getPathFindBehavior2
        and zombie:getPathFindBehavior2() or nil
    if behavior and behavior.cancel then behavior:cancel() end
    if zombie.setPath2 then zombie:setPath2(nil) end
    if zombie.setVariable then
        zombie:setVariable("bPathfind", false)
        zombie:setVariable("bMoving", false)
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
    end
    return true
end

function Effects.ApplyPlayerTarget(zombie, player)
    local currentTarget = zombie.getTarget and zombie:getTarget() or nil
    if isManagedBody(currentTarget) then
        Effects.ReleaseManagedTarget(zombie)
        currentTarget = zombie.getTarget and zombie:getTarget() or nil
    end
    if player and currentTarget ~= player and zombie.setTarget then
        zombie:setTarget(player)
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
    end
end

function Effects.ReleaseManagedTarget(zombie)
    local target = zombie.getTarget and zombie:getTarget() or nil
    local attackedBy = zombie.getAttackedBy
        and zombie:getAttackedBy() or nil
    if isManagedBody(target) and zombie.setTarget then
        zombie:setTarget(nil)
    end
    if isManagedBody(attackedBy) and zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    if zombie.setTargetSeenTime then
        zombie:setTargetSeenTime(0)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
        zombie:setVariable("ZombieBiteDone", false)
    end
    if zombie.setNoTeeth then
        zombie:setNoTeeth(false)
    end
end


return Effects
