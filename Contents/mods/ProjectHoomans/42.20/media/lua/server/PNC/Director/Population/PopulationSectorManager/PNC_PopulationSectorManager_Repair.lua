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

function Sectors.RebuildIndexes()
    Sectors.GroupIDs, Sectors.CommunityIDs = {}, {}
    Sectors.GroupSector, Sectors.CommunitySector = {}, {}
    for _, group in ipairs(PNC.AbstractGroups.List()) do Sectors.RegisterGroup(group) end
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active" and community.mode ~= "nomadic" then
            Sectors.RegisterCommunity(community)
        end
    end
    Sectors.Metrics.rebuilds = Sectors.Metrics.rebuilds + 1
    return true
end

function Sectors.Repair(budget)
    budget = math.max(1, math.floor(tonumber(budget) or Config.INDEX_REPAIR_BUDGET))
    local entities = {}
    for _, group in ipairs(PNC.AbstractGroups.List()) do
        entities[#entities + 1] = { kind = "GROUP", id = group.id, value = group }
    end
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active" and community.mode ~= "nomadic" then
            entities[#entities + 1] = { kind = "SETTLEMENT", id = community.id,
                value = community }
        end
    end
    table.sort(entities, function(a, b)
        return a.kind == b.kind and a.id < b.id or a.kind < b.kind
    end)
    if #entities == 0 then return 0 end
    Sectors.RepairCursor = math.max(1,
        math.min(#entities, tonumber(Sectors.RepairCursor) or 1))
    local checked = 0
    while checked < budget and checked < #entities do
        local entity = entities[Sectors.RepairCursor]
        local expected
        if entity.kind == "GROUP" then
            expected = entity.value.location and Sectors.IDForPosition(
                entity.value.location.x, entity.value.location.y) or nil
        else
            local home = entity.value.home
            expected = home and Sectors.IDForPosition(home.x, home.y) or nil
        end
        local actual = entity.kind == "GROUP" and Sectors.GroupSector[entity.id]
            or Sectors.CommunitySector[entity.id]
        if expected ~= actual then
            Sectors.Metrics.mismatches = Sectors.Metrics.mismatches + 1
            if entity.kind == "GROUP" then Sectors.RegisterGroup(entity.value)
            else Sectors.RegisterCommunity(entity.value) end
        end
        checked = checked + 1
        Sectors.RepairCursor = Sectors.RepairCursor % #entities + 1
    end
    Sectors.Metrics.repairs = Sectors.Metrics.repairs + 1
    return checked
end

function Sectors.SetSuppression(id, kind, reason)
    local _, runtime = Sectors.Ensure(id)
    local field = kind == "SETTLEMENT" and "settlementSuppressionReason"
        or "groupSuppressionReason"
    local normalized = tostring(reason or "NONE")
    if runtime[field] == normalized then return false end
    runtime[field] = normalized
    if PNC.PopulationLog and PNC.PopulationLog.Info then
        PNC.PopulationLog.Info("SUPPRESSION_CHANGED", { sectorId = id,
            kind = kind, reason = normalized })
    end
    return true
end

