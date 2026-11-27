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
local isPursuitAuditEnabled = Internal.isPursuitAuditEnabled
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
local function pursueForcedTarget(zombie, npcBody, record, now, hitSettling, modData)
    local distSq
    local dist
    local zDistance
    local zombieSquare
    local npcSquare
    local blocked
    local closeBlocked = false
    local approach = true
    local repathClose = false
    local biteStarted
    local canWriteNative
    local nativeOwner
    modData = modData or Internal.getZombieModData(zombie)
    canWriteNative, nativeOwner = Internal.CanWriteNativeControl(
        zombie, "ProjectHoomans", now, 100, nil, modData
    )
    if not canWriteNative then
        if isPursuitAuditEnabled and isPursuitAuditEnabled() then
            logPursuitDiagnostic(
                zombie,
                record and record.id or nil,
                "server_target",
                "native_control_denied",
                "owner=" .. tostring(nativeOwner),
                now
            )
        end
        return false, false
    end
    if not Internal.AcquirePursuitLease(
        zombie,
        "ProjectHoomans",
        "Hoomans",
        record and record.id or nil,
        now,
        Const.ZOMBIE_NPC_AGGRO_LEASE_MS,
        100,
        "hoomans_npc",
        modData
    ) then
        if isPursuitAuditEnabled and isPursuitAuditEnabled() then
            local leaseOwner = Internal.GetPursuitLeaseFields
                and Internal.GetPursuitLeaseFields(zombie, now, modData)
                or nil
            logPursuitDiagnostic(
                zombie,
                record and record.id or nil,
                "server_target",
                "pursuit_lease_denied",
                "owner=" .. tostring(leaseOwner or "unknown"),
                now
            )
        end
        return nil, false
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
    local callouts = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    if callouts and record and record.runtime
        and now >= (tonumber(record.runtime.nextSwarmBeatCheckAt) or 0)
    then
        record.runtime.nextSwarmBeatCheckAt = now + 1500
        if record.runtime.swarmHelpRequest and callouts.CheckSwarmHelpResolution then
            callouts.CheckSwarmHelpResolution(record, now)
        elseif callouts.TryEmitSwarmHelpCall then
            callouts.TryEmitSwarmHelpCall(record, nil, now)
        end
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
    -- Use the same inclusive contact boundary as the coordinate pursuit lane.
    -- A zombie commonly settles exactly on the engine's collision distance;
    -- using a strict comparison here leaves it facing the NPC forever while
    -- the bite lane never receives ownership.
    if dist <= Const.ZOMBIE_BITE_DISTANCE and zDistance < 0.3 then
        zombieSquare = zombie.getSquare and zombie:getSquare() or nil
        npcSquare = npcBody.getSquare and npcBody:getSquare() or nil
        if not zombieSquare or not npcSquare then
            repathClose = true
            if isPursuitAuditEnabled and isPursuitAuditEnabled() then
                logPursuitDiagnostic(
                    zombie, record.id, "server_combat", "close_square_missing",
                    "distance=" .. tostring(dist)
                        .. " zombieSquare=" .. tostring(zombieSquare ~= nil)
                        .. " npcSquare=" .. tostring(npcSquare ~= nil), now
                )
            end
        else
            blocked = zombieSquare:isSomethingTo(npcSquare)
            if blocked == true then
                closeBlocked = true
            end
        end
        if zombieSquare and npcSquare and not blocked then
            if zombie.isFacingObject and zombie:isFacingObject(npcBody, 0.3) then
                if not hitSettling then
                    biteStarted = ZombieAggro.TryStartBite(
                        zombie, npcBody, record
                    )
                    approach = biteStarted ~= true
                    repathClose = approach
                    if isPursuitAuditEnabled and isPursuitAuditEnabled() then
                        logPursuitDiagnostic(
                            zombie, record.id, "server_combat",
                            biteStarted and "bite_started_or_active"
                                or "bite_start_rejected",
                            "distance=" .. tostring(dist)
                                .. " action=" .. actionStateName(zombie), now
                        )
                    end
                else
                    approach = true
                    repathClose = true
                    if isPursuitAuditEnabled and isPursuitAuditEnabled() then
                        logPursuitDiagnostic(
                            zombie, record.id, "server_combat", "hit_settling",
                            "distance=" .. tostring(dist)
                                .. " action=" .. actionStateName(zombie), now
                        )
                    end
                end
            elseif zombie.faceThisObject then
                -- Keep facing the NPC to trigger the bite cleanly. Only
                -- repath if still more than 0.75 tiles away; repathing when
                -- already touching can spin the zombie away from the NPC.
                approach = true
                repathClose = dist > 0.75
                zombie:faceThisObject(npcBody)
                if isPursuitAuditEnabled and isPursuitAuditEnabled() then
                    logPursuitDiagnostic(
                        zombie, record.id, "server_combat", "turning_to_npc",
                        "distance=" .. tostring(dist)
                            .. " action=" .. actionStateName(zombie), now
                    )
                end
            else
                approach = true
                repathClose = true
                if isPursuitAuditEnabled and isPursuitAuditEnabled() then
                    logPursuitDiagnostic(
                        zombie, record.id, "server_combat", "cannot_face_npc",
                        "distance=" .. tostring(dist)
                            .. " hasFacingApi="
                            .. tostring(zombie.isFacingObject ~= nil), now
                    )
                end
            end
        elseif zombieSquare and npcSquare and blocked then
            approach = true
            repathClose = true
            if isPursuitAuditEnabled and isPursuitAuditEnabled() then
                logPursuitDiagnostic(
                    zombie, record.id, "server_combat", "close_path_blocked",
                    "distance=" .. tostring(dist)
                        .. " action=" .. actionStateName(zombie), now
                )
            end
        end
        if repathClose and not isMultiplayerServer() then
            refreshPursuitPath(zombie, npcBody, now, record.id, closeBlocked, modData)
        end
    else
        local closeRange = (tonumber(Const.ZOMBIE_BITE_DISTANCE) or 1.2) + 1.5
        if dist <= closeRange and zDistance < 1 then
            zombieSquare = zombie.getSquare and zombie:getSquare() or nil
            npcSquare = npcBody.getSquare and npcBody:getSquare() or nil
            if zombieSquare and npcSquare and zombieSquare ~= npcSquare
                and zombieSquare.isSomethingTo
                and zombieSquare:isSomethingTo(npcSquare) == true
            then
                closeBlocked = true
            end
        end
        if not isMultiplayerServer() then
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
            refreshPursuitPath(zombie, npcBody, now, record.id, closeBlocked, modData)
        end
    end
    local policy = ZombieAggro.PathPolicy
    if policy and policy.UpdateLungeVisual and not isMultiplayerServer() then
        local wantsLunge = zDistance < 0.35
            and distSq <= 12.25
            and closeBlocked ~= true
            and not hitSettling
        policy.UpdateLungeVisual(zombie, wantsLunge)
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
    local callouts = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    if callouts and record and record.runtime then
        local lastSwarmCheck = tonumber(record.runtime.lastPursuitSwarmCheckAt) or 0
        if (now - lastSwarmCheck) >= 1500 then
            record.runtime.lastPursuitSwarmCheckAt = now
            if callouts.CheckSwarmHelpResolution then
                callouts.CheckSwarmHelpResolution(record, now)
            end
            local spokeSwarm = callouts.TryEmitSwarmHelpCall
                and callouts.TryEmitSwarmHelpCall(record, nil, now, nil)
            if not spokeSwarm and callouts.TryEmitBystanderHelpCall then
                callouts.TryEmitBystanderHelpCall(record, nil, now, nil)
            end
        end
    end
    return true, closeBlocked
end


Internal.clearMPTargetDirective = clearMPTargetDirective
Internal.publishMPTargetDirective = publishMPTargetDirective
Internal.pursueForcedTarget = pursueForcedTarget
return ZombieAggro
