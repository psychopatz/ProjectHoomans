if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationSectors = PNC.PopulationSectors or {}
PNC.PopulationSectorInternal = PNC.PopulationSectorInternal or {}

local Sectors = PNC.PopulationSectors
local H = PNC.PopulationSectorInternal
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Core = PNC.Core

function Sectors.RegisterGroup(group)
    if not group or not group.id or not group.location then return false end
    local id = Sectors.IDForPosition(group.location.x, group.location.y)
    local old = Sectors.GroupSector[group.id]
    if old and old ~= id then H.Remove(Sectors.GroupIDs, old, group.id) end
    Sectors.GroupSector[group.id] = id
    H.Add(Sectors.GroupIDs, id, group.id)
    local state, runtime = Sectors.Ensure(id)
    runtime.relevant = true
    state.discovered = true
    state.hadGroups = true
    return true
end

function Sectors.UnregisterGroup(groupID)
    local id = Sectors.GroupSector[tostring(groupID or "")]
    if not id then return false end
    H.Remove(Sectors.GroupIDs, id, groupID)
    Sectors.GroupSector[groupID] = nil
    return true, id
end

function Sectors.RegisterCommunity(community)
    local home = community and (community.home
        or community.site and community.site.home) or nil
    if not community or not community.id or not home then return false end
    local id = Sectors.IDForPosition(home.x, home.y)
    local old = Sectors.CommunitySector[community.id]
    if old and old ~= id then H.Remove(Sectors.CommunityIDs, old, community.id) end
    Sectors.CommunitySector[community.id] = id
    H.Add(Sectors.CommunityIDs, id, community.id)
    local state, runtime = Sectors.Ensure(id)
    runtime.relevant = true
    state.discovered = true
    state.hadSettlements = true
    return true
end

function Sectors.UnregisterCommunity(communityID)
    local id = Sectors.CommunitySector[tostring(communityID or "")]
    if not id then return false end
    H.Remove(Sectors.CommunityIDs, id, communityID)
    Sectors.CommunitySector[communityID] = nil
    return true, id
end

function H.Count(map)
    local total = 0
    for _ in pairs(map or {}) do total = total + 1 end
    return total
end

function Sectors.CountGroups(id)
    local total = 0
    for groupID in pairs(Sectors.GroupIDs[id] or {}) do
        local group = PNC.AbstractGroups.Get(groupID)
        if group and not group.homeCommunityId then total = total + 1 end
    end
    return total
end
function Sectors.CountAllGroups(id) return H.Count(Sectors.GroupIDs[id]) end
function Sectors.CountSettlements(id) return H.Count(Sectors.CommunityIDs[id]) end

