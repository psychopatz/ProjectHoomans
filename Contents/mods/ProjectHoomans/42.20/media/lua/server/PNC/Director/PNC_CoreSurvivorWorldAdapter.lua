if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.CoreSurvivorWorldAdapter =
    PNC.CoreSurvivorWorldAdapter or {}

local Adapter = PNC.CoreSurvivorWorldAdapter
local Authority = PNC.CoreSurvivorWorldAuthority
    or require "PNC/Director/PNC_CoreSurvivorWorldAuthority"
local World = Authority.World

local function registry()
    local current = Authority.Registry
    if current then return current end
    return Authority.Activate()
end

function Adapter.EnsureCanonical()
    local current, reason = registry()
    if not current then return nil, reason end

    local status = Authority.RefreshStatus()
    if status and status.needsImport == true then
        current, reason = Authority.ImportPreSurvivorWorld({
            reason = "project_hoomans_survivor_world_cutover",
        })
        if not current then return nil, reason end
    end
    return current
end

local function dirty(reason)
    local ok, failure = World.RuntimeStore.MarkDirty(reason)
    if not ok then return nil, failure end
    return true
end

function Adapter.CommitFaction(faction, reason)
    if type(faction) ~= "table" then
        return nil, "faction_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical
    canonical, failure = current:UpsertFaction(faction)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_faction_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.CommitCommunity(community, reason)
    if type(community) ~= "table" then
        return nil, "community_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical
    canonical, failure = current:UpsertCommunity(community)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_community_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.CommitLocation(location, reason)
    if type(location) ~= "table" then
        return nil, "location_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical
    canonical, failure = current:UpsertLocation(location)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_location_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.CommitGroup(group, reason)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical
    canonical, failure = current:UpsertGroup(group)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_group_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.RemoveGroup(groupID, reason)
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local removed
    removed, failure = current:RemoveGroup(groupID)
    if not removed and failure ~= "group_not_found" then
        return nil, failure
    end
    if removed then
        local ok
        ok, failure = dirty(reason or "pnc_group_removed")
        if not ok then return nil, failure end
    end
    return true
end

function Adapter.GetFaction(factionID)
    local current = registry()
    return current and current:GetFaction(factionID) or nil
end

function Adapter.GetCommunity(communityID)
    local current = registry()
    return current and current:GetCommunity(communityID) or nil
end

function Adapter.GetLocation(locationID)
    local current = registry()
    return current and current:GetLocation(locationID) or nil
end

function Adapter.GetGroup(groupID)
    local current = registry()
    return current and current:GetGroup(groupID) or nil
end

return Adapter
