--[[
    PNC Client Combat Commands
    Applies transient replicated combat events and maintains bite replicas.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Client.BiteReplicas = Client.BiteReplicas or {}
Client.ZombieReactionReplicas = Client.ZombieReactionReplicas or {}

local function applyPlayerReaction(args)
    local player
    if not args or not PNC.PlayerReaction
        or not PNC.PlayerReaction.ApplyLocalCounterStagger
    then
        return false
    end
    player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if not player then return false end
    if args.targetOnlineID ~= nil and player.getOnlineID
        and tonumber(player:getOnlineID()) ~= tonumber(args.targetOnlineID)
    then
        return false
    end
    return PNC.PlayerReaction.ApplyLocalCounterStagger(player, args) == true
end

local function applyZombieReaction(args)
    local targetZombie
    local attackerZombie
    local reaction
    if not args then
        return false
    end
    targetZombie = PNC.Network and PNC.Network.FindZombieByOnlineID
        and PNC.Network.FindZombieByOnlineID(args.targetOnlineID) or nil
    if not targetZombie then
        return false
    end
    attackerZombie = PNC.Network and PNC.Network.FindZombieByOnlineID
        and PNC.Network.FindZombieByOnlineID(args.attackerOnlineID) or nil
    reaction = PNC.CombatZombieReaction
    if not reaction or not reaction.ApplyReplicatedHit then
        return false
    end
    local applied = reaction.ApplyReplicatedHit(
        attackerZombie,
        targetZombie,
        args
    )
    if applied then
        Client.ZombieReactionReplicas[
            tostring(args.targetOnlineID)
        ] = {
            targetOnlineID = args.targetOnlineID,
            deadline = Core.Now() + 1500,
        }
    end
    return applied
end

local function signalBiteRelease(attackerZombie)
    if not attackerZombie then
        return
    end
    if attackerZombie.setBumpDone then
        attackerZombie:setBumpDone(true)
    end
    if attackerZombie.setVariable then
        attackerZombie:setVariable("BumpDone", true)
        attackerZombie:setVariable("BumpAnimFinished", true)
    end
end

local function finishBiteReplica(attackerZombie)
    signalBiteRelease(attackerZombie)
    if attackerZombie and attackerZombie.setBumpType then
        attackerZombie:setBumpType("")
    end
    if attackerZombie and attackerZombie.setBumpedChr then
        attackerZombie:setBumpedChr(nil)
    end
    if attackerZombie and attackerZombie.setVariable then
        attackerZombie:setVariable("PNCZombieBitingNPC", false)
    end
end

local function applyZombieBite(args)
    local attackerZombie
    local targetNPCBody
    local key
    local state
    local now
    if not args or not PNC.Network or not PNC.Network.FindZombieByOnlineID then
        return false
    end
    key = tostring(args.attackerOnlineID or "")
    if key == "" then
        return false
    end
    now = Core.Now()
    attackerZombie = PNC.Network.FindZombieByOnlineID(args.attackerOnlineID)
    state = Client.BiteReplicas[key] or {
        attackerOnlineID = args.attackerOnlineID,
        startedAt = now,
    }
    Client.BiteReplicas[key] = state
    if args.phase == "clear" then
        state.phase = "release"
        state.releaseAt = now
        state.releaseDeadline = now + (tonumber(Const.BITE_RELEASE_TIMEOUT_MS) or 650)
        signalBiteRelease(attackerZombie)
        return true
    end
    state.phase = "windup"
    state.targetOnlineID = args.targetOnlineID
    state.npcId = args.npcId
    state.bumpType = tostring(args.bumpType or "Bite")
    state.startedAt = now
    state.localReleaseAt = now + (tonumber(Const.ZOMBIE_BITE_CLEAR_DELAY_MS) or 700) + 350
    if not attackerZombie then
        return true
    end
    targetNPCBody = PNC.Network.FindZombieByOnlineID(args.targetOnlineID)
    if not targetNPCBody and PNC.ClientPresenceSync then
        local npcKey = tostring(args.npcId or "")
        local snapshot = ClientState.snapshots and ClientState.snapshots[npcKey] or nil
        if snapshot and snapshot.liveBodyLease and PNC.ClientPresenceSync.BodyByLease then
            targetNPCBody = PNC.ClientPresenceSync.BodyByLease[
                npcKey .. ":" .. tostring(snapshot.liveBodyLease)
            ]
        elseif not snapshot or not snapshot.liveBodyLease then
            targetNPCBody = PNC.ClientPresenceSync.BodyByID
                and PNC.ClientPresenceSync.BodyByID[npcKey] or nil
        end
    end
    if targetNPCBody and attackerZombie.faceThisObject then
        attackerZombie:faceThisObject(targetNPCBody)
    end
    if targetNPCBody and attackerZombie.setBumpedChr then
        attackerZombie:setBumpedChr(targetNPCBody)
    end
    if attackerZombie.setBumpDone then
        attackerZombie:setBumpDone(false)
    end
    if attackerZombie.setVariable then
        attackerZombie:setVariable("PNCZombieBitingNPC", true)
        attackerZombie:setVariable("BumpDone", false)
        attackerZombie:setVariable("BumpAnimFinished", false)
    end
    if attackerZombie.setBumpType then
        attackerZombie:setBumpType(state.bumpType)
    end
    state.applied = true
    return true
end

local function pumpCombatReplicas()
    local now = Core.Now()
    local key
    local state
    local zombie
    local asn
    local reaction
    if PNC.PlayerReaction and PNC.PlayerReaction.Pump then
        PNC.PlayerReaction.Pump(now)
    end
    for key, state in pairs(Client.BiteReplicas) do
        zombie = PNC.Network and PNC.Network.FindZombieByOnlineID
            and PNC.Network.FindZombieByOnlineID(state.attackerOnlineID) or nil
        if state.phase ~= "release" and now >= (tonumber(state.localReleaseAt) or math.huge) then
            state.phase = "release"
            state.releaseAt = now
            state.releaseDeadline = now + (tonumber(Const.BITE_RELEASE_TIMEOUT_MS) or 650)
        end
        if state.phase == "release" then
            signalBiteRelease(zombie)
            asn = zombie and zombie.getActionStateName and tostring(zombie:getActionStateName() or "") or ""
            if (zombie and asn ~= "bumped" and (now - (tonumber(state.releaseAt) or now)) >= 35)
                or now >= (tonumber(state.releaseDeadline) or now)
            then
                finishBiteReplica(zombie)
                Client.BiteReplicas[key] = nil
            end
        elseif zombie and state.applied ~= true then
            applyZombieBite({
                attackerOnlineID = state.attackerOnlineID,
                targetOnlineID = state.targetOnlineID,
                npcId = state.npcId,
                bumpType = state.bumpType,
                phase = "start",
            })
        end
    end
    reaction = PNC.CombatZombieReaction
    for key, state in pairs(Client.ZombieReactionReplicas) do
        zombie = PNC.Network and PNC.Network.FindZombieByOnlineID
            and PNC.Network.FindZombieByOnlineID(
                state.targetOnlineID
            )
            or nil
        if zombie and reaction and reaction.Pump then
            if not reaction.Pump(zombie, now) then
                Client.ZombieReactionReplicas[key] = nil
            end
        elseif now >= (tonumber(state.deadline) or 0) then
            Client.ZombieReactionReplicas[key] = nil
        end
    end
end

Internal.PumpCombatReplicas = pumpCombatReplicas
-- Compatibility alias for older client bootstrap code and external tooling.
Internal.PumpBiteReplicas = pumpCombatReplicas

Internal.RegisterServerCommand(Const.CMD_ZOMBIE_REACTION, function(args)
    applyZombieReaction(args)
end)

if Const.CMD_PLAYER_REACTION then
    Internal.RegisterServerCommand(Const.CMD_PLAYER_REACTION, function(args)
        applyPlayerReaction(args)
    end)
end

Internal.RegisterServerCommand(Const.CMD_ZOMBIE_BITE, function(args)
    applyZombieBite(args)
end)

Internal.RegisterServerCommand(Const.CMD_FIREARM_SHOT, function(args)
    if PNC.ClientFirearmEffects and PNC.ClientFirearmEffects.Play then
        PNC.ClientFirearmEffects.Play(args)
    end
end)
