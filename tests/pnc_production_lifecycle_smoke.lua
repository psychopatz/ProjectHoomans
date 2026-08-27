local T = require "tests/support/test"

T.addPackagePaths()

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}; for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local clock, nextReservation = 1000, 1
local inventory = { ["Base.Plank"] = 2, ["Base.SpearCrafted"] = 0,
    ["Base.Axe"] = 1, ["Base.Hammer"] = 1,
    ["Base.Money"] = 1,
    ["PNC.RecipeBlueprint"] = 1 }
local reservations, reserved, transactions = {}, {}, {}
local descriptor = { key = "Base.MakeWoodenSpear", craftTime = 10,
    requiredSkills = {{ skillId = "Carpentry", level = 2 }},
    inputs = {
        { itemTypes = { "Base.Plank" }, amount = 2, consumed = true },
        { itemTypes = { "Base.Hammer" }, amount = 1, consumed = false },
    },
    outputs = {{ itemTypes = { "Base.SpearCrafted" }, amount = 1 }} }

PNC = {
    Core = { Now = function() return clock end, DeepCopy = copy },
    EventTypes = {},
    Skills = { GetLevel = function(record, skillId)
        return record.skills and record.skills[skillId] or 0
    end },
    Registry = { Data = {}, GetLiveZombie = function() return nil end },
    OrderSystem = { SetOrder = function(record, order) record.orderSpec = order end },
    RecipeKnowledgeRegistry = { Queries = {
        Resolve = function(id) return id == 1 and { id = 1, key = descriptor.key,
            status = "AVAILABLE", descriptor = descriptor } or nil end,
        GetKey = function(id) return id == 1 and descriptor.key or nil end,
        GetId = function(key) return key == descriptor.key and 1 or nil end,
    } },
    KnowledgeRepository = { GetOrCreateId = function() return 1 end },
    RecipeCatalog = { Queries = {
        GetProducerKeys = function(fullType)
            return fullType == "Base.Axe" and { descriptor.key } or {}
        end,
        Get = function() return descriptor end,
        List = function() return { descriptor } end,
    } },
    ProductionContext = { ForPlayer = function()
        return { colony = { id = "c1" }, faction = { id = "f1" },
            base = { id = "b1" }, storage = { id = "s1" } }
    end },
}
function PNC.Registry.Get(id) return PNC.Registry.Data[tostring(id)] end
function PNC.Registry.ForEach(callback)
    for _, record in pairs(PNC.Registry.Data) do callback(record) end
end

local function reserve(fullType, amount, owner)
    if (inventory[fullType] or 0) - (reserved[fullType] or 0) < amount then
        return nil, "MISSING_MATERIALS"
    end
    local id = "r:" .. tostring(nextReservation); nextReservation = nextReservation + 1
    reservations[id] = { id = id, fullType = fullType, amount = amount,
        owner = owner, storageId = "s1" }
    reserved[fullType] = (reserved[fullType] or 0) + amount
    return reservations[id]
end
local function release(id)
    local value = reservations[id]
    if not value then return false, "reservation_not_found" end
    for _, item in ipairs(value.items or { value }) do
        reserved[item.fullType] = reserved[item.fullType] - item.amount
    end
    reservations[id] = nil
    return true
end
PNC.ColonyStorageService = {
    ReserveProductionMaterials = function(_, requirements, owner)
        local items = {}
        for _, row in ipairs(requirements) do
            local fullType, amount = row.itemTypes[1], row.amount
            if (inventory[fullType] or 0) - (reserved[fullType] or 0) < amount then
                return nil, "MISSING_MATERIALS"
            end
            items[#items + 1] = { fullType = fullType, amount = amount,
                consumed = row.consumed ~= false }
        end
        local id = "r:" .. tostring(nextReservation)
        nextReservation = nextReservation + 1
        reservations[id] = { id = id, items = items, owner = owner,
            storageId = "s1" }
        for _, item in ipairs(items) do
            reserved[item.fullType] = (reserved[item.fullType] or 0) + item.amount
        end
        return reservations[id]
    end,
    ReserveProductionRecord = function(_, recordIndex, _, owner)
        return reserve(recordIndex == 1 and "PNC.RecipeBlueprint" or "Base.Axe",
            1, owner)
    end,
    ReserveProductionMatchingRecord = function(_, match, _, owner)
        return reserve(match.fullType, 1, owner)
    end,
    ReadProductionRecord = function(storageId, recordIndex)
        if storageId == "money-test" then
            return { fullType = "Base.Money", metadata = {} }
        end
        if recordIndex == 1 then return { fullType = "PNC.RecipeBlueprint",
            metadata = { PNC = { blueprint = { rid = 1 } } } } end
        return { fullType = "Base.Axe", metadata = {} }
    end,
    GetProductionReservation = function(id) return reservations[id] end,
    ReleaseProductionReservation = release,
    CommitProductionReservation = function(id, transactionId, stage)
        local key = tostring(transactionId) .. ":" .. tostring(stage)
        if transactions[key] then return true, "already_committed" end
        local value = reservations[id]
        if not value then return false, "reservation_not_found" end
        for _, item in ipairs(value.items or { value }) do
            if item.consumed ~= false then
                inventory[item.fullType] = inventory[item.fullType] - item.amount
            end
        end
        release(id); transactions[key] = true
        return true
    end,
    DepositProductionItems = function(_, products, _, transactionId, stage)
        local key = tostring(transactionId) .. ":" .. tostring(stage)
        if transactions[key] then return true, "already_committed" end
        for _, product in ipairs(products) do
            inventory[product.fullType] = (inventory[product.fullType] or 0)
                + product.quantity
        end
        transactions[key] = true
        return true
    end,
    HasProductionTransactionStage = function(_, transactionId, stage)
        return transactions[tostring(transactionId) .. ":" .. tostring(stage)] == true
    end,
    GetProductionDiagnostics = function() return { total = 0 } end,
}
local storageTier = 1
function PNC.ColonyStorageService.SetTierForSettlement(_, targetTier)
    if targetTier ~= storageTier + 1 then
        return false, "invalid_storage_tier_transition"
    end
    storageTier = targetTier
    return true, "upgraded", { tier = storageTier }
end
PNC.ColonyStorageRepository = {
    GetForSettlement = function()
        return { id = "s1", inventory = { records = { {}, {} } } }
    end,
}
local bootstrapConsumes = 0
PNC.FacilityCostService = { ConsumePlayer = function()
    bootstrapConsumes = bootstrapConsumes + 1
    return true, { affordable = true }
end }

local occupied = {}
local acquiredCapabilities = {}
PNC.FacilityService = { AcquireActivity = function(_, npcId, capability)
    acquiredCapabilities[#acquiredCapabilities + 1] = capability
    if occupied[capability] then return { ok = false,
        reason = "NO_ACTIVITY_CAPACITY" } end
    occupied[capability] = npcId
    return { ok = true, componentId = capability, facilityId = "facility",
        reservationId = capability, abstract = true }
end }
local constructionFacility = { id = "construction_facility", baseId = "b1",
    definitionId = "barracks", constructionState = "PLANNED" }
local bootstrapFacility = { id = "bootstrap_stockpile", baseId = "b1",
    definitionId = "stockpile", level = 1, constructionState = "PLANNED" }
local constructionDestroyed = false
local reconstructedComponent
PNC.SettlementRepository = { GetFacility = function(id)
    return id == constructionFacility.id and constructionFacility
        or id == bootstrapFacility.id and bootstrapFacility or nil
end }
PNC.FacilityDefinitions = { Get = function()
    return { buildCosts = {{ fullType = "Base.Money", amount = 1 }},
        upgradeCosts = {{ fullType = "Base.Money", amount = 1 }},
        buildWork = 10, reconstructWork = 6, deconstructWork = 8 }
end }
function PNC.FacilityService.ResolveWorkTarget(facility)
    if not facility then return nil, "FACILITY_NOT_FOUND" end
    return { x = 5, y = 5, z = 0, componentId = "room" }
end
function PNC.FacilityService.RefreshState(facility)
    facility.cachedState = facility.constructionState
    return true
end
function PNC.FacilityService.FinalizeDestroy(id)
    constructionDestroyed = id == constructionFacility.id
    return constructionDestroyed, constructionDestroyed and "destroyed"
        or "FACILITY_NOT_FOUND"
end
function PNC.FacilityService.FinalizeSetComponent(id, component)
    if id ~= constructionFacility.id then return false, "FACILITY_NOT_FOUND" end
    reconstructedComponent = copy(component)
    constructionFacility.constructionState = "BUILT"
    constructionFacility.constructionWorkOrderId = nil
    return true
end
function PNC.FacilityService.FinalizeUpgrade(id, targetLevel)
    local facility = PNC.SettlementRepository.GetFacility(id)
    if not facility then return false, "FACILITY_NOT_FOUND" end
    facility.level = targetLevel
    facility.constructionState = "BUILT"
    facility.constructionWorkOrderId = nil
    return true, "FacilityUpgraded"
end
PNC.FacilityReservations = {
    Release = function(id) occupied[id] = nil; return true end,
    Start = function() return true end,
}

PNC.Registry.Data.worker = { id = "worker", alive = true,
    affiliation = { factionID = "f1", communityID = "c1" },
    skills = { Carpentry = 5 }, runtime = {},
    allowedJobs = { Researcher = true, WorkshopWorker = true } }
PNC.Registry.Data.worker.allowedJobs.Constructor = true

require "PNC/Core/Production/PNC_WorkDefinitions"
require "PNC/Core/Colony/Research/PNC_ColonyResearchDefinitions"
local WorkRepository = require "PNC/Production/PNC_WorkRepository"
WorkRepository.Import(nil)
local ResearchRepository = require "PNC/Production/PNC_ResearchRepository"
ResearchRepository.Loaded = true
ResearchRepository.ByColony, ResearchRepository.Runtime = {}, {}
local Work = require "PNC/Production/PNC_WorkService"
local Research = require "PNC/Production/PNC_ResearchService"
local Crafting = require "PNC/Production/PNC_CraftingService"
local Construction = require
    "PNC/Production/ConstructionService/PNC_ConstructionService"

local provisionDisplayOrder = T.truthy(Work.Commands.Queue({
    operation = "PROVISION_PICKUP", colonyId = "c1", factionId = "f1",
    baseId = "b1", payload = {
        selected = {{ descriptor = { fullType = "Base.Apple" }, quantity = 1 }},
    },
}))
PNC.Registry.Data.worker.runtime.workOrderId = provisionDisplayOrder.id
PNC.Registry.Data.worker.orderSpec = { phase = "COLLECT_INPUTS" }
local provisionDisplay = Work.BuildActionInformation(PNC.Registry.Data.worker)
T.equal(provisionDisplay.activityItemFullType, "Base.Apple",
    "provision action snapshot exposes selected item")
T.truthy(Work.Commands.Cancel(provisionDisplayOrder.id),
    "provision display fixture cancellation")
PNC.Registry.Data.worker.runtime.workOrderId = nil
PNC.Registry.Data.worker.orderSpec = nil
T.truthy(Research.Commands.UnlockRecipe("c1", 1, "f1"), "seed known recipe")

local technology = T.truthy(Research.Commands.QueueTechnology({},
    "facility:workshop"))
local sameTechnology, duplicateReason = Research.Commands.QueueTechnology({},
    "facility:workshop")
T.equal(sameTechnology.id, technology.id,
    "duplicate technology request reuses resumable work")
T.equal(duplicateReason, "ALREADY_QUEUED",
    "duplicate technology request reports existing queue entry")
local activeTechnologyCount = 0
for _, order in ipairs(Work.Queries.List("c1")) do
    if order.operation == "RESEARCH" and order.status ~= "CANCELLED"
        and order.payload and order.payload.mode == "technology"
    then activeTechnologyCount = activeTechnologyCount + 1 end
end
T.equal(activeTechnologyCount, 1,
    "technology queue contains one authoritative task")
T.truthy(Work.Commands.Cancel(technology.id),
    "technology dedupe fixture cancellation")
local lockedHQ, lockedHQReason = Research.Commands.QueueTechnology({}, "hq:3")
T.equal(lockedHQ, nil, "later HQ research remains prerequisite gated")
T.equal(lockedHQReason, "PREREQUISITE_REQUIRED", "HQ prerequisite reason")
local hqTwo = T.truthy(Research.Commands.QueueTechnology({}, "hq:2"))
T.truthy(Work.Commands.Assign(hqTwo.id, "worker"), "HQ research assignment")
T.equal(acquiredCapabilities[#acquiredCapabilities], "work.research",
    "HQ capability research routes to the shared Log Table")
T.truthy(Work.Commands.AddProgress(hqTwo.id, "worker", 100),
    "HQ research completion")
T.truthy(Research.Queries.HasTechnology("c1", "hq:2"),
    "HQ upgrade capability unlocks only after Work Points complete")
local legacyLow = T.truthy(Work.Commands.Queue({
    operation = "RESEARCH", colonyId = "c1", factionId = "f1",
    baseId = "b1", requiredWork = 60, progress = 5,
    payload = { mode = "technology", technologyId = "facility:workshop" },
}))
local legacyHigh = T.truthy(Work.Commands.Queue({
    operation = "RESEARCH", colonyId = "c1", factionId = "f1",
    baseId = "b1", requiredWork = 60, progress = 25,
    payload = { mode = "technology", technologyId = "facility:workshop" },
}))
T.equal(Research.Commands.ReconcileDuplicates(), 1,
    "saved duplicate technology work is reconciled")
T.equal(Work.Queries.Get(legacyLow.id).status, "CANCELLED",
    "lower-progress duplicate is retired")
T.equal(Work.Queries.Get(legacyHigh.id).progress, 25,
    "most-progressed resumable research is preserved")
T.truthy(Work.Commands.Cancel(legacyHigh.id),
    "legacy research reconciliation fixture cancellation")

local first = T.truthy(Crafting.Commands.QueueCraft({}, 1, 1))
local blocked, reason = Crafting.Commands.QueueCraft({}, 1, 1)
T.equal(blocked, nil, "reservation blocks double spend")
T.equal(reason, "MISSING_MATERIALS", "material blocker")
T.truthy(Work.Commands.Cancel(first.id), "craft cancellation")
T.equal(inventory["Base.Plank"], 2, "cancel preserves inputs")

local craft = T.truthy(Crafting.Commands.QueueCraft({}, 1, 1))
T.truthy(Work.Commands.Assign(craft.id, "worker"), "craft assignment")
T.truthy(Work.Commands.AddProgress(craft.id, "worker", 100), "craft completion")
T.equal(inventory["Base.Plank"], 0, "inputs consumed once")
T.equal(inventory["Base.SpearCrafted"], 1, "output created once")
local persisted = WorkRepository.Get(craft.id)
persisted.completionCommitted = false
persisted.payload.inputsCommitted, persisted.payload.outputCommitted = false, false
persisted.status, persisted.progress = "WAITING_FOR_WORKER", 0
T.truthy(Work.Commands.Assign(craft.id, "worker"), "recovered craft assignment")
T.truthy(Work.Commands.AddProgress(craft.id, "worker", 100), "recovered completion")
T.equal(inventory["Base.Plank"], 0, "recovery does not reconsume")
T.equal(inventory["Base.SpearCrafted"], 1, "recovery does not duplicate output")

ResearchRepository.ByColony, ResearchRepository.Runtime = {}, {}
local workshopCatalog = Crafting.Queries.BuildSnapshot("c1")
T.equal(#workshopCatalog.disassemblyCandidates, 1,
    "workshop snapshot exposes only server-supported salvage items")
T.equal(workshopCatalog.disassemblyCandidates[1].fullType, "Base.Axe",
    "blueprints and currency do not leak into the salvage catalog")
T.equal(workshopCatalog.disassemblyCandidates[1].potentialYield[1].fullType,
    "Base.Plank", "salvage catalog exposes its potential material yield")
T.equal(#Crafting.Queries.DisassemblyCandidates({ id = "money-test",
    inventory = { records = {{}} } }), 0,
    "currency is never offered as salvage input")
local researchCatalog = Research.Queries.BuildSnapshot("c1")
T.equal(#researchCatalog.candidates, 1,
    "research snapshot exposes blueprint choices without reverse engineering")
T.equal(researchCatalog.candidates[1].mode, "blueprint",
    "blueprint research choice is categorized")
T.equal(Research.Commands.ReverseEngineer, nil,
    "reverse engineering command is removed")

ResearchRepository.ByColony, ResearchRepository.Runtime = {}, {}
local blueprint = T.truthy(Research.Commands.StudyBlueprint({}, 1))
T.truthy(Work.Commands.Assign(blueprint.id, "worker"), "blueprint assignment")
T.equal(acquiredCapabilities[#acquiredCapabilities], "work.research",
    "blueprint study routes to the shared Log Table")
T.truthy(Work.Commands.AddProgress(blueprint.id, "worker", 100),
    "blueprint completion")
T.equal(inventory["PNC.RecipeBlueprint"], 1, "blueprint returned by policy")
T.truthy(Research.Queries.HasRecipe("c1", 1), "blueprint unlocks recipe")

local kitOK, kit = Research.Commands.CreateSpearTestKit({})
T.truthy(kitOK, "spear debug kit")
T.equal(kit.recipeId, 1, "spear kit targets deterministic recipe")
T.truthy(inventory["Base.Plank"] >= 8, "spear kit adds crafting materials")
T.truthy(inventory["Base.SpearCrafted"] >= 2,
    "spear kit adds crafting and deconstruction specimens")

local bootstrap = T.truthy(Construction.QueueBuild({}, bootstrapFacility, {
    bootstrapFromPlayer = true, buildWork = 5, buildCosts = {
        { fullType = "Base.Money", amount = 1 },
    },
}))
T.equal(bootstrap.funded, true, "bootstrap stockpile starts funded")
T.equal(bootstrap.payload.input.bootstrap, true,
    "bootstrap stockpile skips stockpile collection")
T.equal(bootstrapConsumes, 1, "bootstrap cost comes from player inventory")
T.truthy(Work.Commands.Assign(bootstrap.id, "worker"),
    "bootstrap constructor assignment")
T.truthy(Work.Commands.AddProgress(bootstrap.id, "worker", 100),
    "bootstrap construction completion")
local stockpileUpgrade = T.truthy(Construction.QueueReconstruct({},
    bootstrapFacility, { action = "upgrade", targetLevel = 2 }))
T.equal(stockpileUpgrade.funded, false,
    "stockpile tier upgrade collects its material")
T.truthy(Work.Commands.Assign(stockpileUpgrade.id, "worker"),
    "stockpile upgrade assignment")
T.truthy(Work.Commands.AddProgress(stockpileUpgrade.id, "worker", 100),
    "stockpile upgrade completion")
T.equal(bootstrapFacility.level, 2, "stockpile facility reaches tier two")
T.equal(storageTier, 2, "stockpile facility tier updates storage capacity tier")
inventory["Base.Money"] = 1

local abandonedBuild = T.truthy(Construction.QueueBuild({}, constructionFacility,
    PNC.FacilityDefinitions.Get()))
local replacement = T.truthy(Construction.QueueDeconstruct({},
    constructionFacility))
T.equal(Work.Queries.Get(abandonedBuild.id).status, "CANCELLED",
    "deconstruct replaces unfinished build")
T.equal(reserved["Base.Money"], 0,
    "replacing unfinished build releases its materials")
T.truthy(Work.Commands.Cancel(replacement.id),
    "cancel replacement deconstruction")
T.equal(constructionFacility.constructionState, "PLANNED",
    "cancelled replacement leaves the plan intact")

local build = T.truthy(Construction.QueueBuild({}, constructionFacility,
    PNC.FacilityDefinitions.Get()))
T.equal(build.funded, false, "construction waits for material collection")
T.equal(inventory["Base.Money"], 1,
    "queued construction leaves reserved stock in storage")
T.equal(reserved["Base.Money"], 1,
    "queued construction retains its material reservation")
T.equal(constructionFacility.constructionState, "UNDER_CONSTRUCTION",
    "build enters construction state")
T.truthy(Work.Commands.Assign(build.id, "worker"), "constructor assignment")
T.truthy(Work.Commands.AddProgress(build.id, "worker", 4),
    "first constructor contributes work points")
T.equal(Work.BuildActionInformation(PNC.Registry.Data.worker).percent, 40,
    "action information reports shared order progress")
PNC.Registry.Data.worker.alive = false
constructionFacility.constructionState = "PLANNED"
PNC.Registry.Data.backup = { id = "backup", alive = true,
    affiliation = { factionID = "f1", communityID = "c1" },
    skills = { Carpentry = 5 }, runtime = {},
    allowedJobs = { Constructor = true } }
clock = clock + 1001
Work.Tick(clock)
T.equal(Work.Queries.Get(build.id).progress, 4,
    "worker interruption preserves construction progress")
T.equal(inventory["Base.Money"], 1,
    "worker interruption preserves unconsumed construction material")
T.equal(constructionFacility.constructionState, "UNDER_CONSTRUCTION",
    "active order repairs stale planned facility state")
clock = clock + 1001
Work.Tick(clock)
T.equal(Work.Queries.Get(build.id).workerId, "backup",
    "another constructor continues the interrupted order")
T.equal(Work.BuildActionInformation(PNC.Registry.Data.backup).percent, 50,
    "replacement worker resumes existing progress in the next work interval")
T.truthy(Work.Commands.AddProgress(build.id, "backup", 100),
    "replacement constructor completes shared work points")
T.equal(inventory["Base.Money"], 0,
    "construction completion consumes reserved material once")
T.equal(constructionFacility.constructionState, "BUILT",
    "construction completion activates facility")
inventory["Base.Money"] = 1
local reconstruct = T.truthy(Construction.QueueReconstruct({},
    constructionFacility, { action = "set", component = {
        id = "room:1", kind = "region", role = "sleep.area" } }))
T.equal(constructionFacility.constructionState, "RECONSTRUCTING",
    "zone edit enters reconstruction state")
T.truthy(Work.Commands.Assign(reconstruct.id, "backup"),
    "reconstruction assignment")
T.truthy(Work.Commands.AddProgress(reconstruct.id, "backup", 100),
    "abstract reconstruction completes by work points")
T.equal(reconstructedComponent.id, "room:1",
    "zone mutation commits only after reconstruction")
T.equal(constructionFacility.constructionState, "BUILT",
    "reconstruction restores built state")
local deconstruct = T.truthy(Construction.QueueDeconstruct({},
    constructionFacility))
T.truthy(Work.Commands.Assign(deconstruct.id, "backup"),
    "deconstruction assignment")
T.truthy(Work.Commands.AddProgress(deconstruct.id, "backup", 100),
    "abstract deconstruction completes by work points")
T.equal(constructionDestroyed, true, "deconstruction removes facility parts")

-- An untouched project releases its reservation when cancelled, so the next
-- project can use the stock immediately without a duplicate refund deposit.
inventory["Base.Money"] = 1
constructionFacility.constructionState = "PLANNED"
local cancelledBuild = T.truthy(Construction.QueueBuild({}, constructionFacility,
    PNC.FacilityDefinitions.Get()))
T.equal(inventory["Base.Money"], 1,
    "cancel test project leaves reserved stock unconsumed")
T.truthy(Work.Commands.Cancel(cancelledBuild.id),
    "reserved construction can be cancelled")
T.equal(inventory["Base.Money"], 1,
    "cancelling an untouched project releases its materials")
T.equal(constructionFacility.constructionState, "PLANNED",
    "cancelled construction returns to planned state")

-- A colonist whose legacy affiliation omitted communityID still cycles from
-- At Home into queued work by resolving the remembered home base.
PNC.Registry.Data.backup.affiliation.communityID = nil
PNC.Registry.Data.backup.runtime.homeBaseId = "b1"
PNC.Registry.Data.backup.orderSpec = { kind = "colony_home", baseId = "b1" }
PNC.HomeDutyService = {
    IsAtHome = function(record, baseId)
        return record.runtime.homeBaseId == baseId
    end,
    GetColonyId = function(record)
        return record.runtime.homeBaseId == "b1" and "c1" or ""
    end,
}
constructionFacility.constructionState = "BUILT"
local homeTask = T.truthy(Work.Commands.Queue({
    operation = "RECONSTRUCT", colonyId = "c1", factionId = "f1",
    baseId = "b1", requiredWork = 5,
    payload = { facilityId = constructionFacility.id, change = {} },
}))
clock = clock + 1001
Work.Tick(clock)
T.equal(Work.Queries.Get(homeTask.id).workerId, "backup",
    "At Home colonist claims the next queued task")
T.equal(PNC.Registry.Data.backup.runtime.workOrderId, homeTask.id,
    "At Home yields to emulated production work")
local taskRows = Work.Queries.BuildTaskSnapshot("c1")
local foundHomeTask
for _, task in ipairs(taskRows) do
    if task.id == homeTask.id then foundHomeTask = task end
end
T.truthy(foundHomeTask, "task snapshot contains active home task")
T.equal(foundHomeTask.workerName, "backup", "task snapshot worker name")
T.equal(foundHomeTask.executionMode, "ABSTRACT",
    "task snapshot exposes emulated execution mode")
T.truthy(Work.Commands.Cancel(homeTask.id), "cancel first cycled task")
T.equal(PNC.Registry.Data.backup.orderSpec.kind, "colony_home",
    "colonist returns to At Home between tasks")
local nextHomeTask = T.truthy(Work.Commands.Queue({
    operation = "RECONSTRUCT", colonyId = "c1", factionId = "f1",
    baseId = "b1", requiredWork = 5,
    payload = { facilityId = constructionFacility.id, change = {} },
}))
clock = clock + 1001
Work.Tick(clock)
T.equal(Work.Queries.Get(nextHomeTask.id).workerId, "backup",
    "At Home colonist cycles into another queued task")
local resumed, resumedOrder = Work.Commands.Resume(nextHomeTask.id)
T.truthy(resumed, "interrupted construction can be resumed")
T.equal(resumedOrder.status, "WAITING_FOR_WORKER",
    "resume returns the durable order to the scheduler")
T.equal(resumedOrder.blockedReason, nil,
    "resume clears the stale blocked reason")
T.equal(PNC.Registry.Data.backup.runtime.workOrderId, nil,
    "resume releases the old worker claim safely")
T.truthy(Work.Commands.Cancel(nextHomeTask.id), "cancel second cycled task")

-- Save/load keeps the project contract but drops worker and reservation state.
WorkRepository.Import({ schemaVersion = 1, nextId = 2, byId = {
    ["work:1"] = { id = "work:1", operation = "CONSTRUCT",
        status = "BLOCKED", workerId = "worker", stationId = "station",
        blockedReason = "PATH", progress = 0, requiredWork = 10,
        priority = 0, createdAt = 1, funded = true,
        payload = { facilityId = "construction_facility",
            requirements = {{ itemTypes = { "Base.Money" }, amount = 9 }},
            input = { storageId = "s1", reservationId = "r:legacy",
                staged = true, itemIds = { "item:1" }, funded = true } } },
} })
local recoveredProject = WorkRepository.Get("work:1")
T.equal(recoveredProject.status, "WAITING_FOR_WORKER",
    "recovery clears runtime blocked state for construction")
T.equal(recoveredProject.workerId, nil,
    "recovery drops construction worker assignment")
T.equal(recoveredProject.payload.requirements, nil,
    "recovery drops the duplicated construction recipe")
T.equal(recoveredProject.payload.input.reservationId, nil,
    "recovery drops the old reservation handle")
local beforeLegacyCancel = inventory["Base.Money"]
T.truthy(Work.Commands.Cancel(recoveredProject.id),
    "recovered construction can be cancelled without its old reservation")
T.equal(inventory["Base.Money"], beforeLegacyCancel + 1,
    "recovered cancellation resolves storage and refunds remaining material")

-- Pre-checkpoint saves compacted an in-progress construction input down to
-- `consume`, leaving it permanently blocked after reload. Progress now
-- restores the durable funded/committed marker for that legacy shape.
WorkRepository.Import({ schemaVersion = 1, nextId = 3, byId = {
    ["work:2"] = { id = "work:2", operation = "CONSTRUCT",
        status = "BLOCKED", progress = 89, requiredWork = 100,
        createdAt = 1, funded = false,
        previousOrder = { kind = "colony_home", baseId = "b1" },
        payload = { facilityId = "construction_facility",
            input = { consume = true } } },
} })
local recoveredCompacted = WorkRepository.Get("work:2")
T.equal(recoveredCompacted.funded, true,
    "compacted in-progress construction recovers as funded")
T.equal(recoveredCompacted.payload.input.committed, true,
    "compacted in-progress construction restores committed input state")
T.equal(recoveredCompacted.previousOrder.kind, "colony_home",
    "construction recovery retains the worker fallback order")
local compactedPrepared, compactedPrepareReason =
    Construction.Internal.Prepare(recoveredCompacted)
T.truthy(compactedPrepared,
    "recovered construction passes the normal preparation pipeline")
T.equal(compactedPrepareReason, nil,
    "recovered construction has no unavailable-input blocker")
recoveredCompacted.status = "WORKING"
recoveredCompacted.workerId, recoveredCompacted.stationId = "current",
    "station:current"
PNC.Registry.Data.current = { id = "current", alive = true,
    affiliation = { factionID = "f1", communityID = "c1" },
    skills = { Carpentry = 5 },
    runtime = { workOrderId = recoveredCompacted.id },
    orderSpec = { kind = "production_work",
        workOrderId = recoveredCompacted.id, operation = "CONSTRUCT" } }
PNC.Registry.Data.former = { id = "former", alive = true,
    affiliation = { factionID = "f1", communityID = "c1" },
    skills = { Carpentry = 5 },
    runtime = { workOrderId = recoveredCompacted.id,
        lastProductionWorkAt = clock },
    orderSpec = { kind = "production_work",
        workOrderId = recoveredCompacted.id, operation = "CONSTRUCT" } }
T.equal(Work.ReconcileWorkerState(), 1,
    "stale former worker is reconciled once")
T.equal(PNC.Registry.Data.former.runtime.workOrderId, nil,
    "stale former worker loses the old work claim")
T.equal(PNC.Registry.Data.former.orderSpec.kind, "colony_home",
    "stale former worker restores its previous order")
T.equal(recoveredCompacted.workerId, "current",
    "valid replacement worker keeps the construction claim")
T.equal(PNC.Registry.Data.current.runtime.workOrderId, recoveredCompacted.id,
    "valid replacement worker keeps its runtime claim")
T.finish("pnc_production_lifecycle_smoke")

T.finish("pnc_production_lifecycle_smoke")
