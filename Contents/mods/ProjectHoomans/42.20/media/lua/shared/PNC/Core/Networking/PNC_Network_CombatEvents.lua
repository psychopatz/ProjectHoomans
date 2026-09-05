--[[
    PNC Networking - Combat Events
    Replicates transient zombie reactions, bites, and firearm-shot effects.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local sendToInterestedNPC = Internal.SendToInterestedNPC
local sendToPlayer = Internal.SendToPlayer

function Network.GetZombieOnlineID(zombie)
    local onlineID
    if not zombie or not zombie.getOnlineID then
        return nil
    end
    onlineID = tonumber(zombie:getOnlineID())
    if not onlineID or onlineID < 0 then
        return nil
    end
    return onlineID
end

function Network.FindZombieByOnlineID(onlineID)
    local cell
    local zombieList
    local zombie
    local match
    local i
    onlineID = tonumber(onlineID)
    if onlineID == nil or not getCell then
        return nil
    end
    if PNC.WorldCensus and PNC.WorldCensus.FindByOnlineID then
        return PNC.WorldCensus.FindByOnlineID(onlineID, Core.Now())
    end
    cell = getCell()
    if not cell or not cell.getZombieList then
        return nil
    end
    zombieList = cell:getZombieList()
    if not zombieList then
        return nil
    end
    for i = zombieList:size() - 1, 0, -1 do
        zombie = zombieList:get(i)
        if Network.GetZombieOnlineID(zombie) == onlineID then
            if match and match ~= zombie then
                return nil
            end
            match = zombie
        end
    end
    return match
end

function Network.BroadcastZombieReaction(targetZombie, attackerZombie, options)
    local targetOnlineID
    local attackerOnlineID
    local health
    local payload
    local attackerModData
    local npcId
    if not Core.IsAuthority()
        or not isServer
        or not isServer()
        or not sendServerCommand
        or not targetZombie
        or (targetZombie.isDead and targetZombie:isDead())
    then
        return false
    end
    targetOnlineID = Network.GetZombieOnlineID(targetZombie)
    if not targetOnlineID then
        return false
    end
    attackerOnlineID = Network.GetZombieOnlineID(attackerZombie)
    health = targetZombie.getHealth and tonumber(targetZombie:getHealth()) or nil
    options = options or {}
    payload = {
        targetOnlineID = targetOnlineID,
        attackerOnlineID = attackerOnlineID,
        kind = tostring(options.kind or "weapon_hit"),
        hitReaction = options.hitReaction and tostring(options.hitReaction) or nil,
        hitForce = tonumber(options.hitForce) or 0.92,
        stagger = options.stagger ~= false,
        health = health and health > 0 and health or nil,
        partId = options.partId and tostring(options.partId) or nil,
        woundType = options.woundType and tostring(options.woundType) or nil,
    }
    attackerModData = attackerZombie and attackerZombie.getModData and attackerZombie:getModData() or nil
    npcId = attackerModData and attackerModData.PNC_UUID or nil
    return sendToInterestedNPC(npcId, Const.CMD_ZOMBIE_REACTION, payload) > 0
end

function Network.BroadcastZombieBite(attackerZombie, targetNPCBody, npcId, phase, bumpType)
    local attackerOnlineID
    local targetOnlineID
    if not Core.IsAuthority()
        or not isServer
        or not isServer()
        or not sendServerCommand
    then
        return false
    end
    attackerOnlineID = Network.GetZombieOnlineID(attackerZombie)
    if not attackerOnlineID then
        return false
    end
    targetOnlineID = Network.GetZombieOnlineID(targetNPCBody)
    local payload = {
        attackerOnlineID = attackerOnlineID,
        targetOnlineID = targetOnlineID,
        npcId = npcId and tostring(npcId) or nil,
        phase = phase == "clear" and "clear" or "start",
        bumpType = bumpType and tostring(bumpType) or "Bite",
    }
    return sendToInterestedNPC(npcId, Const.CMD_ZOMBIE_BITE, payload) > 0
end

function Network.BroadcastFirearmShot(payload)
    local deliveryRadius
    local sent = 0
    if not Core.IsAuthority() or type(payload) ~= "table" then
        return false
    end
    if isServer and isServer() then
        if not sendServerCommand then return false end
        -- A gunshot can be heard beyond an NPC's normal detailed-interest
        -- bubble. Deliver this transient event by the weapon's own noise
        -- radius, with the interest distance as the minimum visual range.
        deliveryRadius = math.max(
            tonumber(payload.soundRadius) or 0,
            tonumber(Const.INTEREST_LEAVE_DISTANCE) or 56
        )
        Core.ForEachPlayer(function(player)
            local dx
            local dy
            local dz
            if not player then return end
            dx = (tonumber(player:getX()) or 0) - (tonumber(payload.sx) or 0)
            dy = (tonumber(player:getY()) or 0) - (tonumber(payload.sy) or 0)
            dz = math.abs((tonumber(player:getZ()) or 0) - (tonumber(payload.sz) or 0))
            if dz <= 2 and ((dx * dx) + (dy * dy)) <= (deliveryRadius * deliveryRadius) then
                sendToPlayer(player, Const.CMD_FIREARM_SHOT, payload)
                sent = sent + 1
            end
        end)
        return sent > 0
    end
    if triggerEvent then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_FIREARM_SHOT, payload)
        return true
    end
    return false
end
