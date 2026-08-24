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

function Sectors.Get(id)
    local state, runtime = Sectors.Ensure(id)
    if not state then return nil end
    local output = Core.DeepCopy(runtime)
    for key, value in pairs(state) do output[key] = value end
    output.groupCount = Sectors.CountGroups(id)
    output.settlementCount = Sectors.CountSettlements(id)
    local survivors = {}
    for groupID in pairs(Sectors.GroupIDs[id] or {}) do
        local group = PNC.AbstractGroups.Get(groupID)
        for _, npcID in ipairs(group and group.memberIds or {}) do survivors[npcID] = true end
    end
    for communityID in pairs(Sectors.CommunityIDs[id] or {}) do
        local community = PNC.Communities.Get(communityID)
        for npcID in pairs(community and community.memberIDs or {}) do survivors[npcID] = true end
    end
    output.survivorCount = H.Count(survivors)
    return output
end

function Sectors.ListRelevant()
    local output = {}
    for id, state in pairs(H.Persistent().sectors) do
        local runtime = Sectors.Runtime[id]
        if state.discovered or runtime and runtime.relevant then
            output[#output + 1] = Sectors.Get(id)
        end
    end
    table.sort(output, function(a, b)
        if a.active ~= b.active then return a.active == true end
        return a.id < b.id
    end)
    return output
end

function Sectors.NeighborIDs(id)
    local sx, sy = Sectors.ParseID(id)
    local output = {}
    if not sx then return output end
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                output[#output + 1] = "psector_" .. tostring(sx + dx)
                    .. "_" .. tostring(sy + dy)
            end
        end
    end
    return output
end

