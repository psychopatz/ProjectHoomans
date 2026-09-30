-- Bandits compatibility: ownership detection, identity, and cache access.
--
-- Owns every read of Bandits' own caches so no other Hoomans module has to know
-- BanditZombie / BanditServerZombie shapes. Other Bandits spokes depend only on
-- this shared table; no spoke requires a sibling spoke.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.Bandits or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
PNC.Compatibility.Bandits = Bridge

local ActorRef = PNC.Compatibility.ActorRef
    or require "PNC/Core/Compatibility/PNC_Compatibility_ActorRef"
local ActorOwnership = PNC.Compatibility.ActorOwnership
    or require "PNC/Core/Compatibility/PNC_ActorOwnership"

-- Ownership predicate. Registered with ActorOwnership so Hoomans behaviour
-- lanes can opt out of Bandits bodies without importing Bandits internals.
function Internal.IsBanditBody(body)
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

function Internal.ActorID(body)
    if not body then return nil end
    if BanditUtils and type(BanditUtils.GetCharacterID) == "function" then
        return BanditUtils.GetCharacterID(body)
    end
    if body.getPersistentOutfitID then
        return body:getPersistentOutfitID()
    end
    return body.id
end

function Internal.GetBody(id)
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

-- Raw cache hit for the hot enumeration path. Callers fall back to GetBody.
function Internal.CachedBody(id)
    return BanditZombie and BanditZombie.Cache
        and BanditZombie.Cache[id] or nil
end

function Internal.LightCache()
    if BanditZombie and type(BanditZombie.GetAllB) == "function" then
        return BanditZombie.GetAllB()
    end
    if BanditZombie and BanditZombie.CacheLightB then
        return BanditZombie.CacheLightB
    end
    return BanditServerZombie and BanditServerZombie.Cache or nil
end

function Internal.MakeRef(body, light)
    local id = light and (light.id or light.actorId) or Internal.ActorID(body)
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

return Bridge
