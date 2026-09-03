if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local owned = Internal.owned
local summary = Internal.summary

local function playerKey(player)
    if player and type(player.getUsername) == "function" then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    if player and type(player.getOnlineID) == "function" then
        return tostring(player:getOnlineID() or "")
    end
    return "local"
end

local function ownedZoneSnapshot(service, player)
    local data = service and service.Data or nil
    local zones = data and data.zones or nil
    local ownerID = playerKey(player)
    local selected
    if type(zones) ~= "table" or type(service.GetSnapshot) ~= "function" then
        return nil
    end
    for _, zone in pairs(zones) do
        if tostring(zone.ownerId or "") == ownerID
            and tostring(zone.ownerType or "player") == "player"
            and zone.enabled ~= false
            and (not selected or tostring(zone.id) < tostring(selected.id))
        then selected = zone end
    end
    return selected and service.GetSnapshot(selected.id) or nil
end

local function enrichSettlement(settlement, base, tasks)
    if not settlement then return end
    settlement.facilities = {}
    settlement.stockpileNodes = {}
    for facilityId, _ in pairs(base.facilityIds or {}) do
        local facility = PNC.FacilityService.BuildSnapshot(facilityId)
        if facility then
            settlement.facilities[#settlement.facilities + 1] = facility
        end
    end
    for nodeId, _ in pairs(base.stockpileNodeIds or {}) do
        local node = PNC.SettlementRepository.GetStockpileNode(nodeId)
        if node then
            settlement.stockpileNodes[#settlement.stockpileNodes + 1] =
                PNC.Core.DeepCopy(node)
        end
    end
    table.sort(settlement.facilities, function(a, b)
        local first = tostring(a.definitionId or "") .. ":"
            .. tostring(a.id or "")
        local second = tostring(b.definitionId or "") .. ":"
            .. tostring(b.id or "")
        return first < second
    end)
    table.sort(settlement.stockpileNodes, function(a, b)
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    local taskByFacility = {}
    for _, task in ipairs(tasks) do
        if task.facilityId then
            taskByFacility[tostring(task.facilityId)] = task
        end
    end
    for _, facility in ipairs(settlement.facilities) do
        facility.activeTask = taskByFacility[tostring(facility.id)]
    end
end

local function taskSnapshotForColony(colonyId)
    if PNC.TaskRequestService and PNC.TaskRequestService.Queries
        and PNC.TaskRequestService.Queries.BuildSnapshot
    then
        return PNC.TaskRequestService.Queries.BuildSnapshot(colonyId)
    end
    if PNC.WorkService and PNC.WorkService.Queries
        and PNC.WorkService.Queries.BuildTaskSnapshot
    then
        return PNC.WorkService.Queries.BuildTaskSnapshot(colonyId)
    end
    return {}
end

-- Settlement consumers need a compact, authoritative refresh when a facility
-- changes outside a command request (for example when construction completes).
-- Keep this separate from the much heavier colony-management snapshot.
function Internal.BuildSettlementSnapshot(baseOrId, tasks)
    local base = type(baseOrId) == "table" and baseOrId
        or PNC.BaseService and PNC.BaseService.Get(baseOrId) or nil
    if not base or not PNC.BaseService
        or not PNC.BaseService.BuildSnapshot
    then
        return nil
    end
    tasks = type(tasks) == "table" and tasks
        or taskSnapshotForColony(base.colonyId)
    local settlement = PNC.BaseService.BuildSnapshot(base)
    enrichSettlement(settlement, base, tasks)
    return settlement
end

function Management.BuildSnapshot(player, options)
    options = type(options) == "table" and options or {}
    local people, attention, counts = {}, {}, { hunger={}, thirst={}, fatigue={} }
    local supplyShortages = { food = {}, hydration = {}, medical = {} }
    local playerFaction, colony
    if PNC.Recruitment and PNC.Recruitment.ReconcileOwned then
        for _, record in pairs(PNC.Registry.Data or {}) do
            if record.alive ~= false and owned(record, player) then
                PNC.Recruitment.ReconcileOwned(player, record)
            end
        end
    end
    if PNC.Factions and PNC.Factions.GetPlayerFaction then playerFaction = PNC.Factions.GetPlayerFaction(player) end
    if playerFaction and PNC.Communities and PNC.Communities.GetForFaction then
        for _, value in ipairs(PNC.Communities.GetForFaction(playerFaction.id) or {}) do if value.status == "active" then colony=value; break end end
    end
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false and owned(record, player) then
            local value = summary(record, player, options); people[#people+1]=value
            for _, needType in ipairs(Definitions.TYPES) do
                local level=Definitions.GetLevel(needType, value.needs[needType]); counts[needType][level]=(counts[needType][level] or 0)+1
                if level == "CRITICAL" or level == "SEVERE" or level == "MODERATE" then attention[#attention+1]={ severity=level, npcID=value.id, name=value.name, needType=needType, value=value.needs[needType] } end
            end
            local supply = record.runtime and record.runtime.supply
                and record.runtime.supply.byKind or {}
            for kind, bucket in pairs({
                FOOD = supplyShortages.food,
                HYDRATION = supplyShortages.hydration,
                MEDICAL = supplyShortages.medical,
            }) do
                local lane = supply[kind]
                if lane and lane.phase == "FAILED" then
                    bucket[#bucket + 1] = {
                        npcID = record.id,
                        name = tostring(record.name or record.id),
                        reason = lane.lastFailureReason,
                        nextRetry = lane.nextRetry,
                    }
                end
            end
        end
    end
    table.sort(people,function(a,b) return a.name<b.name end)
    table.sort(attention,function(a,b) return a.value>b.value end)
    local storage = PNC.ColonyStorageService
        and PNC.ColonyStorageService.BuildSnapshot
        and PNC.ColonyStorageService.BuildSnapshot(player, options) or nil
    local storageState = storage and PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.Get(storage.storageId) or nil
    local research = PNC.ColonyResearchService
        and PNC.ColonyResearchService.BuildSnapshot(storageState)
        or { entries = {} }
    local workshop = colony and PNC.CraftingService
        and PNC.CraftingService.Queries.BuildSnapshot(colony.id)
        or { knownRecipes = {}, orders = {} }
    local building = colony and PNC.BuildingService
        and PNC.BuildingService.BuildSnapshot(player, storageState, colony)
        or { recipes = {}, queue = {} }
    local tasks = colony and PNC.TaskRequestService
        and PNC.TaskRequestService.Queries.BuildSnapshot(colony.id)
        or colony and PNC.WorkService and PNC.WorkService.Queries
            and PNC.WorkService.Queries.BuildTaskSnapshot
            and PNC.WorkService.Queries.BuildTaskSnapshot(colony.id) or {}
    local provisionSettings = PNC.ProvisionPolicyService
        and PNC.ProvisionPolicyService.BuildSnapshot
        and PNC.ProvisionPolicyService.BuildSnapshot(player) or nil
    local provisionStorage = PNC.ProvisionEvaluator
        and PNC.ProvisionEvaluator.MeasureStorage
        and PNC.ProvisionEvaluator.MeasureStorage(storageState) or {}
    local base = colony and PNC.BaseService
        and PNC.BaseService.GetForColony(colony.id) or nil
    local settlement = Internal.BuildSettlementSnapshot(base, tasks)
    local utilities = base and PNC.WaterUtilityService
        and PNC.WaterUtilityService.BuildSnapshot(base.id)
        or { waterLiters = 0, capacityLiters = 0, tanks = 0,
            catchers = 0, litersPerTenMinutes = 0, facilities = {} }
    local factionSnapshot = playerFaction and {
        id = playerFaction.id,
        name = playerFaction.name,
        archetypeID = playerFaction.archetypeID,
        emblem = PNC.Core.DeepCopy(playerFaction.emblem),
        revision = playerFaction.revision,
        renamePending = playerFaction.tags
            and playerFaction.tags.factionNamePending == true or false,
    } or nil
    return { colony=colony, faction=factionSnapshot,
        people=people, attention=attention, levels=counts,
        storage=storage, research=research, workshop=workshop,
        building=building, tasks=tasks,
        supplyShortages=supplyShortages,
        provisionStorage=provisionStorage,
        provisionSettings=provisionSettings,
        settlement=settlement, utilities=utilities,
        zoneState={
            lumber=ownedZoneSnapshot(PNC.LumberService, player),
            fishing=ownedZoneSnapshot(PNC.FishingService, player),
        },
        generatedAt=PNC.NeedsUtils.WorldAgeHours() }
end


return Management
