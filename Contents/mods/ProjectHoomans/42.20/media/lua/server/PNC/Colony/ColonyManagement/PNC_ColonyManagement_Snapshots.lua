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

function Management.BuildSnapshot(player, options)
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
            local value = summary(record, player); people[#people+1]=value
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
    local settlement = base and PNC.BaseService.BuildSnapshot(base) or nil
    local utilities = base and PNC.WaterUtilityService
        and PNC.WaterUtilityService.BuildSnapshot(base.id)
        or { waterLiters = 0, capacityLiters = 0, tanks = 0,
            catchers = 0, litersPerTenMinutes = 0, facilities = {} }
    enrichSettlement(settlement, base, tasks)
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
        generatedAt=PNC.NeedsUtils.WorldAgeHours() }
end


return Management
