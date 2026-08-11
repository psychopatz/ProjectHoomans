PNC = PNC or {}
PNC.StorageAccessPolicy = PNC.StorageAccessPolicy or {}

local Policy = PNC.StorageAccessPolicy
local Repository = require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
local CommunityMath = require "PNC/Core/Communities/PNC_CommunityMath"

Policy.MODE = Policy.MODE or {
    VIRTUAL_COLONY = "VIRTUAL_COLONY",
    PHYSICAL_HOME = "PHYSICAL_HOME",
}
Policy.DEFAULT_MODE = Policy.MODE.VIRTUAL_COLONY
Policy.AccessMode = Policy.AccessMode or Policy.DEFAULT_MODE

function Policy.GetAccessMode()
    return Policy.AccessMode
end

function Policy.SetAccessMode(mode)
    mode = tostring(mode or "")
    if mode ~= Policy.MODE.VIRTUAL_COLONY
        and mode ~= Policy.MODE.PHYSICAL_HOME
    then
        return false, "invalid_storage_access_mode"
    end
    Policy.AccessMode = mode
    return true, "updated"
end

function Policy.RequiresPhysicalPresence()
    return Policy.GetAccessMode() == Policy.MODE.PHYSICAL_HOME
end

local function position(record)
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    return body and body.getX and body:getX() or tonumber(record.x),
        body and body.getY and body:getY() or tonumber(record.y),
        body and body.getZ and body:getZ() or tonumber(record.z) or 0
end

function Policy.CanUseStorage(record, storage, community, faction)
    if not record or not storage or not community or not faction then
        return false, "storage_context_missing"
    end
    if storage.ownerFactionId ~= faction.id
        or community.factionID ~= faction.id
        or not (community.memberIDs and community.memberIDs[record.id] == true)
    then
        return false, "storage_membership_denied"
    end
    if storage.settlementId and storage.settlementId ~= community.id then
        return false, "storage_settlement_mismatch"
    end
    if Policy.RequiresPhysicalPresence() then
        local x, y, z = position(record)
        if not CommunityMath.IsInsideHomeArea(community, x, y, z) then
            return false, "storage_not_at_base"
        end
    end
    return true
end

function Policy.Resolve(record)
    if not record or record.alive == false then return nil, "npc_missing" end
    local faction
    local reason
    if PNC.Factions and PNC.Factions.GetNPCFaction then
        faction, reason = PNC.Factions.GetNPCFaction(record.id)
    else
        reason = "faction_unavailable"
    end
    if not faction then return nil, reason end
    local community
    if PNC.Communities and PNC.Communities.GetNPCCommunity then
        community, reason = PNC.Communities.GetNPCCommunity(record.id)
    else
        reason = "community_unavailable"
    end
    if not community or community.status ~= "active" then
        return nil, reason or "community_inactive"
    end
    local storage
    storage, reason = Repository.GetPrimary(faction.id, community.id)
    if not storage then return nil, reason end
    local allowed
    allowed, reason = Policy.CanUseStorage(record, storage, community, faction)
    if not allowed then return nil, reason end
    return storage, nil, community, faction
end

return Policy
