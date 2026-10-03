local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Path"

local Internal = ZombieAggro.Internal
local Core = Internal.Core
local Const = Internal.Const
local Diagnostics = Internal.Diagnostics
local Multiplayer = Internal.Multiplayer
local isMultiplayerServer = Internal.isMultiplayerServer
local setNoLungeAttack = Internal.setNoLungeAttack
local logPursuitDiagnostic = Internal.logPursuitDiagnostic
local actionStateName = Internal.actionStateName
local refreshPursuitPath = Internal.refreshPursuitPath

local function clearMPTargetDirective(zombie, now)
    return Multiplayer.clear(zombie, now)
end

local function publishMPTargetDirective(
    zombie, record, npcBody, now, approach
)
    return Multiplayer.publish(zombie, record, npcBody, now, approach)
end
local function pursueForcedTarget(zombie, npcBody, record, now, hitSettling)
    local distSq
    local dist
    local zDistance
    local zombieSquare
    local npcSquare
    local blocked
    local approach = true
    local repathClose = false
    local biteStarted
    if not Internal.AcquirePursuitLease(
        zombie,
        "ProjectHoomans",
        "Hoomans",
        record and record.id or nil,
        now,
        Const.ZOMBIE_NPC_AGGRO_LEASE_MS,
        100,
        "hoomans_npc"
    ) then
        logPursuitDiagnostic(
            zombie,
            record and record.id or nil,
            "server_target",
            "pursuit_lease_denied",
            "owner=" .. tostring(
                Internal.GetPursuitLease
                    and Internal.GetPursuitLease(zombie, now)
                    and Internal.GetPursuitLease(zombie, now).owner
                    or "unknown"
            ),
            now
        )
        return
    end
    if npcBody.setZombiesDontAttack then
        -- This flag protects the IsoZombie shell from vanilla zombie attack
        -- acquisition. PNC's abstract bite lane does not use the native
        -- target slot, so it remains independently targetable by PNC.
        npcBody:setZombiesDontAttack(true)
    end
    distSq = Core.DistanceSq(zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY())
    dist = math.sqrt(distSq)
    zDistance = math.abs(zombie:getZ() - npcBody:getZ())
    if Internal.rememberZombieAttacker then
        Internal.rememberZombieAttacker(
            record,
            zombie,
            dist < Const.ZOMBIE_BITE_DISTANCE
                and "bite_range" or "pursuit",
            now,
            distSq
        )
    end
    if isMultiplayerServer() or not (isClient and isClient() == true) then
        -- The server selects the target in MP. The owning client follows this
        -- bounded coordinate directive; a location-only WorldSound can send
        -- the same zombie down a conflicting path and carries no NPC identity.
        setNoLungeAttack(zombie, true)
    else
        -- The client-side SP controller owns the abstract NPC damage gate.
        -- Keep native lunge disabled because the shell is not an IsoPlayer.
        setNoLungeAttack(zombie, true)
    end
    if (isMultiplayerServer() or not (isClient and isClient() == true))
        and not hitSettling
    then
        if zombie.setTarget then zombie:setTarget(nil) end
        if zombie.setAttackedBy then zombie:setAttackedBy(nil) end
        if zombie.setTargetSeenTime then zombie:setTargetSeenTime(0) end
        if zombie.clearAggroList then zombie:clearAggroList() end
    end
    if dist < Const.ZOMBIE_BITE_DISTANCE and zDistance < 0.3 then
        zombieSquare = zombie.getSquare and zombie:getSquare() or nil
        npcSquare = npcBody.getSquare and npcBody:getSquare() or nil
        if not zombieSquare or not npcSquare then
            repathClose = true
            logPursuitDiagnostic(
                zombie, record.id, "server_combat", "close_square_missing",
                "distance=" .. tostring(dist)
                    .. " zombieSquare=" .. tostring(zombieSquare ~= nil)
                    .. " npcSquare=" .. tostring(npcSquare ~= nil), now
            )
        else
            blocked = zombieSquare:isSomethingTo(npcSquare)
        end
        if zombieSquare and npcSquare and not blocked then
            if zombie.isFacingObject and zombie:isFacingObject(npcBody, 0.3) then
                if not hitSettling then
                    biteStarted = ZombieAggro.TryStartBite(
                        zombie, npcBody, record
                    )
                    approach = biteStarted ~= true
                    repathClose = approach
                    logPursuitDiagnostic(
                        zombie, record.id, "server_combat",
                        biteStarted and "bite_started_or_active"
                            or "bite_start_rejected",
                        "distance=" .. tostring(dist)
                            .. " action=" .. actionStateName(zombie), now
                    )
                else
                    approach = true
                    repathClose = true
                    logPursuitDiagnostic(
                        zombie, record.id, "server_combat", "hit_settling",
                        "distance=" .. tostring(dist)
                            .. " action=" .. actionStateName(zombie), now
                    )
                end
            elseif zombie.faceThisObject then
                approach = hitSettling == true
                repathClose = approach
                zombie:faceThisObject(npcBody)
                logPursuitDiagnostic(
                    zombie, record.id, "server_combat", "turning_to_npc",
                    "distance=" .. tostring(dist)
                        .. " action=" .. actionStateName(zombie), now
                )
            else
                approach = true
                repathClose = true
                logPursuitDiagnostic(
                    zombie, record.id, "server_combat", "cannot_face_npc",
                    "distance=" .. tostring(dist)
                        .. " hasFacingApi="
                        .. tostring(zombie.isFacingObject ~= nil), now
                )
            end
        elseif zombieSquare and npcSquare and blocked then
            approach = true
            repathClose = true
            logPursuitDiagnostic(
                zombie, record.id, "server_combat", "close_path_blocked",
                "distance=" .. tostring(dist)
                    .. " action=" .. actionStateName(zombie), now
            )
        end
        if repathClose and not isMultiplayerServer() then
            refreshPursuitPath(zombie, npcBody, now, record.id)
        end
    elseif not isMultiplayerServer() then
        -- SP/local authority owns the native zombie path. In MP the owning
        -- client performs native pursuit while this server code owns only the
        -- forced-target lease, coordinate directive, bite validation, and
        -- damage.
        if zombie.isUseless and zombie.setUseless
            and zombie:isUseless()
        then
            -- Match Bandits for the active ordinary-zombie lane. Do this only
            -- while a pursuit is active; distant zombies retain engine tiering.
            zombie:setUseless(false)
        end
        refreshPursuitPath(zombie, npcBody, now, record.id)
    end
    if isMultiplayerServer() then
        publishMPTargetDirective(
            zombie, record, npcBody, now, approach
        )
    end
    -- The pursuit lane already has the authoritative zombie/NPC pair. Publish
    -- the group stimulus here once per zombie cadence so NPC behavior ticks do
    -- not repeat the fan-out work. The helper remains authority-gated for
    -- singleplayer and multiplayer safety.
    if PNC.Perception and PNC.Perception.PublishZombieGroupAlert then
        PNC.Perception.PublishZombieGroupAlert(record, zombie, now)
    end
end


Internal.clearMPTargetDirective = clearMPTargetDirective
Internal.publishMPTargetDirective = publishMPTargetDirective
Internal.pursueForcedTarget = pursueForcedTarget
return ZombieAggro
