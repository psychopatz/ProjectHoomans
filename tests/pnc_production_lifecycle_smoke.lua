local Paths = dofile("tests/pnc_test_paths.lua")
local ROOT = Paths.modRoot("ProjectHoomans") .. "media/lua/"
package.path = ROOT .. "shared/?.lua;" .. ROOT .. "server/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then error((label or "value") .. " expected="
        .. tostring(expected) .. " actual=" .. tostring(actual), 2) end
end
local function truthy(value, label)
    if not value then error((label or "value") .. " expected truthy", 2) end
end
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
    ReadProductionRecord = function(_, recordIndex)
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

local occupied = {}
PNC.FacilityService = { AcquireActivity = function(_, npcId, capability)
    if occupied[capability] then return { ok = false,
        reason = "NO_ACTIVITY_CAPACITY" } end
    occupied[capability] = npcId
    return { ok = true, componentId = capability, facilityId = "facility",
        reservationId = capability, abstract = true }
end }
local constructionFacility = { id = "construction_facility", baseId = "b1",
    definitionId = "barracks", constructionState = "PLANNED" }
local constructionDestroyed = false
local reconstructedComponent
PNC.SettlementRepository = { GetFacility = function(id)
    return id == constructionFacility.id and constructionFacility or nil
end }
PNC.FacilityDefinitions = { Get = function()
    return { buildCosts = {{ fullType = "Base.Money", amount = 1 }},
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
PNC.FacilityReservations = {
    Release = function(id) occupied[id] = nil; return true end,
    Start = function() return true end,
}

PNC.Registry.Data.worker = { id = "worker", alive = true, factionId = "f1",
    communityId = "c1", skills = { Carpentry = 5 }, runtime = {},
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
local Construction = require "PNC/Production/PNC_ConstructionService"
truthy(Research.Commands.UnlockRecipe("c1", 1, "f1"), "seed known recipe")

local first = assert(Crafting.Commands.QueueCraft({}, 1, 1))
local blocked, reason = Crafting.Commands.QueueCraft({}, 1, 1)
equal(blocked, nil, "reservation blocks double spend")
equal(reason, "MISSING_MATERIALS", "material blocker")
truthy(Work.Commands.Cancel(first.id), "craft cancellation")
equal(inventory["Base.Plank"], 2, "cancel preserves inputs")

local craft = assert(Crafting.Commands.QueueCraft({}, 1, 1))
truthy(Work.Commands.Assign(craft.id, "worker"), "craft assignment")
truthy(Work.Commands.AddProgress(craft.id, "worker", 100), "craft completion")
equal(inventory["Base.Plank"], 0, "inputs consumed once")
equal(inventory["Base.SpearCrafted"], 1, "output created once")
local persisted = WorkRepository.Get(craft.id)
persisted.completionCommitted = false
persisted.payload.inputsCommitted, persisted.payload.outputCommitted = false, false
persisted.status, persisted.progress = "WAITING_FOR_WORKER", 0
truthy(Work.Commands.Assign(craft.id, "worker"), "recovered craft assignment")
truthy(Work.Commands.AddProgress(craft.id, "worker", 100), "recovered completion")
equal(inventory["Base.Plank"], 0, "recovery does not reconsume")
equal(inventory["Base.SpearCrafted"], 1, "recovery does not duplicate output")

ResearchRepository.ByColony, ResearchRepository.Runtime = {}, {}
local reverse = assert(Research.Commands.ReverseEngineer({}, 2))
truthy(Work.Commands.Cancel(reverse.id), "reverse cancellation")
equal(inventory["Base.Axe"], 1, "cancel preserves specimen")
reverse = assert(Research.Commands.ReverseEngineer({}, 2))
truthy(Work.Commands.Assign(reverse.id, "worker"), "reverse assignment")
truthy(Work.Commands.AddProgress(reverse.id, "worker", 100), "reverse completion")
equal(inventory["Base.Axe"], 0, "reverse consumes specimen once")
truthy(Research.Queries.HasRecipe("c1", 1), "reverse unlocks recipe")

ResearchRepository.ByColony, ResearchRepository.Runtime = {}, {}
local blueprint = assert(Research.Commands.StudyBlueprint({}, 1))
truthy(Work.Commands.Assign(blueprint.id, "worker"), "blueprint assignment")
truthy(Work.Commands.AddProgress(blueprint.id, "worker", 100),
    "blueprint completion")
equal(inventory["PNC.RecipeBlueprint"], 1, "blueprint returned by policy")
truthy(Research.Queries.HasRecipe("c1", 1), "blueprint unlocks recipe")

local kitOK, kit = Research.Commands.CreateSpearTestKit({})
truthy(kitOK, "spear debug kit")
equal(kit.recipeId, 1, "spear kit targets deterministic recipe")
truthy(inventory["Base.Plank"] >= 8, "spear kit adds crafting materials")
truthy(inventory["Base.SpearCrafted"] >= 2,
    "spear kit adds reverse-engineering and deconstruction specimens")

local abandonedBuild = assert(Construction.QueueBuild({}, constructionFacility,
    PNC.FacilityDefinitions.Get()))
local replacement = assert(Construction.QueueDeconstruct({},
    constructionFacility))
equal(Work.Queries.Get(abandonedBuild.id).status, "CANCELLED",
    "deconstruct replaces unfinished build")
equal(reserved["Base.Money"], 0,
    "replacing unfinished build releases its materials")
truthy(Work.Commands.Cancel(replacement.id),
    "cancel replacement deconstruction")
equal(constructionFacility.constructionState, "PLANNED",
    "cancelled replacement leaves the plan intact")

local build = assert(Construction.QueueBuild({}, constructionFacility,
    PNC.FacilityDefinitions.Get()))
equal(constructionFacility.constructionState, "UNDER_CONSTRUCTION",
    "build enters construction state")
truthy(Work.Commands.Assign(build.id, "worker"), "constructor assignment")
truthy(Work.Commands.AddProgress(build.id, "worker", 4),
    "first constructor contributes work points")
equal(Work.BuildActionInformation(PNC.Registry.Data.worker).percent, 40,
    "action information reports shared order progress")
PNC.Registry.Data.worker.alive = false
PNC.Registry.Data.backup = { id = "backup", alive = true, factionId = "f1",
    communityId = "c1", skills = { Carpentry = 5 }, runtime = {},
    allowedJobs = { Constructor = true } }
clock = clock + 1001
Work.Tick(clock)
equal(Work.Queries.Get(build.id).progress, 4,
    "worker interruption preserves construction progress")
clock = clock + 1001
Work.Tick(clock)
equal(Work.Queries.Get(build.id).workerId, "backup",
    "another constructor continues the interrupted order")
equal(Work.BuildActionInformation(PNC.Registry.Data.backup).percent, 40,
    "replacement worker sees existing progress")
truthy(Work.Commands.AddProgress(build.id, "backup", 100),
    "replacement constructor completes shared work points")
equal(inventory["Base.Money"], 0, "construction consumes reserved material")
equal(constructionFacility.constructionState, "BUILT",
    "construction completion activates facility")
local reconstruct = assert(Construction.QueueReconstruct({},
    constructionFacility, { action = "set", component = {
        id = "room:1", kind = "region", role = "sleep.area" } }))
equal(constructionFacility.constructionState, "RECONSTRUCTING",
    "zone edit enters reconstruction state")
truthy(Work.Commands.Assign(reconstruct.id, "backup"),
    "reconstruction assignment")
truthy(Work.Commands.AddProgress(reconstruct.id, "backup", 100),
    "abstract reconstruction completes by work points")
equal(reconstructedComponent.id, "room:1",
    "zone mutation commits only after reconstruction")
equal(constructionFacility.constructionState, "BUILT",
    "reconstruction restores built state")
local deconstruct = assert(Construction.QueueDeconstruct({},
    constructionFacility))
truthy(Work.Commands.Assign(deconstruct.id, "backup"),
    "deconstruction assignment")
truthy(Work.Commands.AddProgress(deconstruct.id, "backup", 100),
    "abstract deconstruction completes by work points")
equal(constructionDestroyed, true, "deconstruction removes facility parts")

print("pnc_production_lifecycle_smoke: OK")
