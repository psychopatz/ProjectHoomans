-- Engine-facing effects for ordinary zombie pursuit and managed shell safety.
-- Target selection and update scheduling stay in the controller.

PNC = PNC or {}

local Effects = {}
local Core = PNC.Core
local Const = PNC.Const or {}

local PATH_REFRESH_MS = tonumber(
    Const.ZOMBIE_NPC_PATH_REFRESH_MS
) or 350
local PATH_REFRESH_DISTANCE = tonumber(
    Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE
) or 0.6
local BITE_DISTANCE = tonumber(Const.ZOMBIE_BITE_DISTANCE) or 1.2

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

function Effects.ShouldRefreshPath(zombie, targetX, targetY, now)
    local modData = zombie.getModData
        and zombie:getModData() or nil
    local x = tonumber(targetX) or zombie:getX()
    local y = tonumber(targetY) or zombie:getY()
    local lastX = modData
        and tonumber(modData.PNC_ClientAggroPathX) or nil
    local lastY = modData
        and tonumber(modData.PNC_ClientAggroPathY) or nil
    local dx = lastX and x - lastX or math.huge
    local dy = lastY and y - lastY or math.huge
    if modData
        and now - (
            tonumber(modData.PNC_ClientAggroPathAt) or 0
        ) < PATH_REFRESH_MS
        and (dx * dx) + (dy * dy)
            < PATH_REFRESH_DISTANCE * PATH_REFRESH_DISTANCE
    then
        return false
    end
    if modData then
        modData.PNC_ClientAggroPathAt = now
        modData.PNC_ClientAggroPathX = x
        modData.PNC_ClientAggroPathY = y
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

function Effects.ApplySingleplayerAggro(zombie, body, distanceSq, now)
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
        if Effects.ShouldRefreshPath(
            zombie,
            body:getX(),
            body:getY(),
            now
        )
        then
            Effects.RequestCoordinatePath(
                zombie,
                body:getX(),
                body:getY(),
                body:getZ()
            )
        end
    else
        if zombie.faceLocation then
            zombie:faceLocation(body:getX(), body:getY())
        elseif zombie.faceThisObject then
            zombie:faceThisObject(body)
        end
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", true)
    end
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
