local ZombieAggro = PNC and PNC.ZombieAggro
if not ZombieAggro then
    return
end

local Internal = ZombieAggro.Internal
local Providers = Internal and Internal.UpdateProviders
local Multiplayer = Providers and Providers.Multiplayer
if not Providers or not Multiplayer then
    return
end

local Const = PNC.Const
local Core = PNC.Core
local incrementDiagnostic = Providers.incrementDiagnostic
local isMultiplayerServer = Providers.isMultiplayerServer
local logPursuitDiagnostic = Providers.logPursuitDiagnostic

-- The shared composition loads the zombie subsystem before PNC_Network. Keep
-- this lookup lazy so a fresh dedicated-server load sees the transport after
-- the networking facade has finished registering its functions.
local function getMPNetwork()
    local network = PNC.Network
    if not network
        or not network.GetZombieOnlineID
        or not network.Internal
        or not network.Internal.SendToNearbyPlayers
    then
        return nil
    end
    return network
end

local function isMPDirectiveServer()
    return isMultiplayerServer()
        and getMPNetwork() ~= nil
end

local function clearMPTargetDirective(zombie, now)
    local modData
    local zombieOnlineID
    local revision
    local payload
    local sent
    local network
    if not isMPDirectiveServer() or not zombie then
        return 0
    end
    network = getMPNetwork()
    modData = Internal.getZombieModData(zombie)
    if not modData or modData.PNC_MPAggroDirectiveNPCId == nil then
        return 0
    end
    zombieOnlineID = network.GetZombieOnlineID(zombie)
    revision = (tonumber(modData.PNC_MPAggroDirectiveRevision) or 0) + 1
    payload = {
        active = false,
        owner = "ProjectHoomans",
        provider = "Hoomans",
        priority = 100,
        reason = "hoomans_npc",
        zombieOnlineID = zombieOnlineID,
        npcId = modData.PNC_MPAggroDirectiveNPCId,
        x = tonumber(modData.PNC_MPAggroDirectiveX),
        y = tonumber(modData.PNC_MPAggroDirectiveY),
        z = tonumber(modData.PNC_MPAggroDirectiveZ),
        expiresAt = tonumber(now) or Core.Now(),
        revision = revision,
    }
    sent = 0
    if zombieOnlineID ~= nil then
        sent = network.Internal.SendToNearbyPlayers(
            zombie,
            nil,
            Const.CMD_ZOMBIE_PURSUIT,
            payload
        )
    end
    modData.PNC_MPAggroDirectiveRevision = revision
    modData.PNC_MPAggroDirectiveNPCId = nil
    modData.PNC_MPAggroDirectiveLastSentAt = nil
    modData.PNC_MPAggroDirectiveX = nil
    modData.PNC_MPAggroDirectiveY = nil
    modData.PNC_MPAggroDirectiveZ = nil
    modData.PNC_MPAggroDirectiveApproach = nil
    if sent > 0 then
        incrementDiagnostic("ZombieAggro.MPDirectiveCleared", sent)
    end
    return sent
end

local function publishMPTargetDirective(
    zombie, record, npcBody, now, approach
)
    local modData
    local zombieOnlineID
    local npcId
    local targetX
    local targetY
    local targetZ
    local previousId
    local previousX
    local previousY
    local previousApproach
    local targetChanged
    local approachChanged
    local movedSq
    local sendAt
    local sent
    local payload
    local network
    network = getMPNetwork()
    if isMultiplayerServer() and not network then
        logPursuitDiagnostic(
            zombie,
            record and record.id or nil,
            "server_mp",
            "network_unavailable",
            "networkFacade=" .. tostring(PNC.Network ~= nil),
            now
        )
        return 0
    end
    if not isMultiplayerServer()
        or not network
        or not zombie
        or not record
        or not npcBody
    then
        return 0
    end
    modData = Internal.getZombieModData(zombie)
    zombieOnlineID = network.GetZombieOnlineID(zombie)
    npcId = record.id ~= nil and tostring(record.id) or nil
    targetX = tonumber(npcBody:getX())
    targetY = tonumber(npcBody:getY())
    targetZ = tonumber(npcBody:getZ())
    if not modData or zombieOnlineID == nil or not npcId
        or targetX == nil or targetY == nil or targetZ == nil
    then
        return 0
    end
    previousId = modData.PNC_MPAggroDirectiveNPCId
    previousX = tonumber(modData.PNC_MPAggroDirectiveX)
    previousY = tonumber(modData.PNC_MPAggroDirectiveY)
    previousApproach = modData.PNC_MPAggroDirectiveApproach == true
    targetChanged = tostring(previousId or "") ~= npcId
    approachChanged = previousApproach ~= (approach == true)
    movedSq = previousX and previousY
        and Core.DistanceSq(previousX, previousY, targetX, targetY)
        or math.huge
    now = tonumber(now) or Core.Now()
    sendAt = tonumber(modData.PNC_MPAggroDirectiveLastSentAt) or 0
    if not targetChanged and not approachChanged
        and now - sendAt < (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_SEND_MS) or 400)
        and movedSq < ((tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6) ^ 2)
    then
        return 0
    end
    if targetChanged or approachChanged then
        modData.PNC_MPAggroDirectiveRevision =
            (tonumber(modData.PNC_MPAggroDirectiveRevision) or 0) + 1
    end
    payload = {
        active = true,
        owner = "ProjectHoomans",
        provider = "Hoomans",
        priority = 100,
        reason = "hoomans_npc",
        zombieOnlineID = zombieOnlineID,
        npcId = npcId,
        x = targetX,
        y = targetY,
        z = targetZ,
        approach = approach == true,
        expiresAt = now + (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_TTL_MS) or 1100),
        revision = tonumber(modData.PNC_MPAggroDirectiveRevision) or 1,
    }
    sent = network.Internal.SendToNearbyPlayers(
        zombie,
        npcBody,
        Const.CMD_ZOMBIE_PURSUIT,
        payload
    )
    logPursuitDiagnostic(
        zombie,
        npcId,
        "server_mp",
        sent > 0 and "directive_sent" or "directive_no_recipients",
        "recipients=" .. tostring(sent)
            .. " revision=" .. tostring(payload.revision)
            .. " x=" .. tostring(targetX)
            .. " y=" .. tostring(targetY)
            .. " z=" .. tostring(targetZ)
            .. " approach=" .. tostring(approach == true),
        now
    )
    modData.PNC_MPAggroDirectiveNPCId = npcId
    modData.PNC_MPAggroDirectiveX = targetX
    modData.PNC_MPAggroDirectiveY = targetY
    modData.PNC_MPAggroDirectiveZ = targetZ
    modData.PNC_MPAggroDirectiveApproach = approach == true
    if sent > 0 then
        modData.PNC_MPAggroDirectiveLastSentAt = now
        incrementDiagnostic("ZombieAggro.MPDirectiveSent", sent)
    end
    return sent
end


Multiplayer.clear = clearMPTargetDirective
Multiplayer.publish = publishMPTargetDirective
