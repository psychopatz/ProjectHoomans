-- Bandits foreign-actor adapter.
--
-- This module is the only Hoomans compatibility code that knows Bandits'
-- cache and brain APIs. Future integrations should add a sibling adapter.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local API = PNC.Compatibility.API
    or require "PNC/Core/Compatibility/PNC_Compatibility_API"
local ActorRef = PNC.Compatibility.ActorRef
    or require "PNC/Core/Compatibility/PNC_Compatibility_ActorRef"
local ActorOwnership = PNC.Compatibility.ActorOwnership
    or require "PNC/Core/Compatibility/PNC_ActorOwnership"
local Relationships = PNC.Compatibility.Bandits
    and PNC.Compatibility.Bandits.Relationships
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Relationships"
local Combat = PNC.Compatibility.Bandits
    and PNC.Compatibility.Bandits.Combat
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Combat"
local Flavor = PNC.Compatibility.Bandits
    and PNC.Compatibility.Bandits.Flavor
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Flavor"

local function isBanditBody(body)
    local modData
    if ActorOwnership.IsHoomansOwned(body) then
        return false
    end
    if ActorOwnership.ReadVariableBoolean(body, "Bandit") then
        return true
    end
    modData = body and body.getModData and body:getModData() or nil
    return modData and (
        modData.Bandit == true
        or modData.isBandit == true
    ) or false
end

local function actorID(body)
    if not body then return nil end
    if BanditUtils and type(BanditUtils.GetCharacterID) == "function" then
        return BanditUtils.GetCharacterID(body)
    end
    if body.getPersistentOutfitID then
        return body:getPersistentOutfitID()
    end
    return body.id
end

local function getBody(id)
    local body
    if not id then return nil end
    if BanditZombie and type(BanditZombie.GetInstanceById) == "function" then
        body = BanditZombie.GetInstanceById(id)
        if body then return body end
    end
    if BanditZombie and BanditZombie.Cache then
        body = BanditZombie.Cache[id]
            or (tonumber(id) and BanditZombie.Cache[tonumber(id)] or nil)
        if body then return body end
    end
    if BanditServerZombie and BanditServerZombie.Cache then
        body = BanditServerZombie.Cache[id]
            or (tonumber(id)
                and BanditServerZombie.Cache[tonumber(id)] or nil)
        if body then return body end
    end
    return nil
end

local function getBanditLightCache()
    if BanditZombie and type(BanditZombie.GetAllB) == "function" then
        return BanditZombie.GetAllB()
    end
    if BanditZombie and BanditZombie.CacheLightB then
        return BanditZombie.CacheLightB
    end
    return BanditServerZombie and BanditServerZombie.Cache or nil
end

local function makeRef(body, light)
    local id = light and (light.id or light.actorId) or actorID(body)
    if not id then return nil end
    return ActorRef.New("Bandits", id, "foreign_npc", body, {
        generation = body and body.getPersistentOutfitID
            and body:getPersistentOutfitID() or nil,
        x = light and light.x or nil,
        y = light and light.y or nil,
        z = light and light.z or nil,
        visible = true,
    })
end

local function getActorRef(context)
    return makeRef(context and context.actor, context and context.light)
end

local function resolveTarget(context)
    local ref = context and context.ref
    local body = ref and ref.worldObject or ref and getBody(ref.actorId)
    if not body or not isBanditBody(body)
        or not body.isAlive or not body:isAlive()
    then
        return nil
    end
    return makeRef(body)
end

local function enumerateTargets(context)
    local output = {}
    local cache = getBanditLightCache()
    local source = context and context.source
    local radius = tonumber(context and context.radius) or math.huge
    local radiusSq = radius * radius
    local id
    local light
    local body
    local ref
    local dx
    local dy
    if type(cache) == "table" then
        for id, light in pairs(cache) do
            body = BanditZombie and BanditZombie.Cache
                and BanditZombie.Cache[id]
                or getBody(light and (light.id or id))
            if body and body.isAlive and body:isAlive() then
                ref = makeRef(body, light)
                if ref and source and source.x ~= nil and source.y ~= nil then
                    dx = (tonumber(ref.x) or 0)
                        - (tonumber(source.x) or 0)
                    dy = (tonumber(ref.y) or 0)
                        - (tonumber(source.y) or 0)
                    if (dx * dx) + (dy * dy) <= radiusSq then
                        output[#output + 1] = ref
                        output[ref.actorId] = true
                    end
                elseif ref then
                    output[#output + 1] = ref
                    output[ref.actorId] = true
                end
            end
        end
    end
    if isServer and isServer() and getCell then
        local cell = getCell()
        local zombieList = cell and cell.getZombieList
            and cell:getZombieList() or nil
        local index
        if zombieList then
            for index = 0, zombieList:size() - 1 do
                body = zombieList:get(index)
                if body and isBanditBody(body)
                    and body.isAlive and body:isAlive()
                then
                    ref = makeRef(body)
                    if ref and not output[ref.actorId]
                        and source and source.x ~= nil
                        and source.y ~= nil
                    then
                        dx = (tonumber(ref.x) or 0)
                            - (tonumber(source.x) or 0)
                        dy = (tonumber(ref.y) or 0)
                            - (tonumber(source.y) or 0)
                        if (dx * dx) + (dy * dy) <= radiusSq then
                            output[#output + 1] = ref
                            output[ref.actorId] = true
                        end
                    elseif ref and not output[ref.actorId] then
                        output[#output + 1] = ref
                        output[ref.actorId] = true
                    end
                end
            end
        end
    end
    return output
end

local function canAttack(context)
    local target = context and context.target
    local attacker = context and context.attacker
    if target and target.provider == "Bandits" then
        return Relationships.CanHoomanAttackBandit({
            attacker = attacker,
            target = target,
            context = context.context,
        })
    end
    return Relationships.CanBanditAttackHooman({
        attacker = attacker,
        target = target,
        context = context.context,
    })
end

local function onEvent(context)
    local eventName = context and context.event
    local payload = context and context.context or {}
    local target = payload.target
    local body = target and target.worldObject
    if eventName ~= "foreign_damage_applied"
        or not body
        or not Flavor
        or type(Flavor.Say) ~= "function"
    then
        return false
    end
    return Flavor.Say(body, "HOOMANS_HIT") == true
end

return ActorOwnership.RegisterAdapter({
    id = "Bandits",
    version = "Bandits2-B42.20",
    apiVersion = 1,
    detect = isBanditBody,
    capabilities = {
        targeting = true,
        relationships = true,
        damage = true,
        events = true,
        flavor = false,
    },
    getActorRef = getActorRef,
    resolveTarget = resolveTarget,
    enumerateTargets = enumerateTargets,
    canAttack = canAttack,
    applyDamage = Combat.ApplyDamage,
    onEvent = onEvent,
    updateFiles = {
        "client/BanditUpdate.lua",
        "client/BanditZombie.lua",
        "server/BanditServerZombie.lua",
    },
})
