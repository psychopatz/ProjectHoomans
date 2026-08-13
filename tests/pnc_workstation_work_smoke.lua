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
local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}; for key, entry in pairs(value) do output[key] = deepCopy(entry) end
    return output
end

local clock = 1000
PNC = { Core = { Now = function() return clock end, DeepCopy = deepCopy },
    Skills = { GetLevel = function(record, skillId)
        return record.skills and record.skills[skillId] or 0
    end },
    Registry = { Data = {}, GetLiveZombie = function() return nil end },
    OrderSystem = { SetOrder = function(record, order) record.orderSpec = order end },
}
function PNC.Registry.Get(id) return PNC.Registry.Data[tostring(id)] end
function PNC.Registry.ForEach(callback)
    for _, record in pairs(PNC.Registry.Data) do callback(record) end
end

local occupied = {}
local stations = {
    ["work.research"] = { "research:1" },
    ["work.craft"] = { "workshop:1:craft" },
    ["work.disassemble"] = { "workshop:1:disassemble" },
}
PNC.FacilityService = { AcquireActivity = function(_, npcId, capability)
    for _, stationId in ipairs(stations[capability] or {}) do
        if not occupied[stationId] then
            local reservationId = "facility:" .. stationId
            occupied[stationId] = reservationId
            return { ok = true, componentId = stationId,
                facilityId = string.match(stationId, "^([^:]+:[^:]+)") or stationId,
                reservationId = reservationId, abstract = true,
                target = { x = 10, y = 10, z = 0 } }
        end
    end
    return { ok = false, reason = "NO_ACTIVITY_CAPACITY" }
end }
PNC.FacilityReservations = { Release = function(id)
    for stationId, reservationId in pairs(occupied) do
        if reservationId == id then occupied[stationId] = nil end
    end
    return true
end }

local workers = {
    { id = "researcher", alive = true, factionId = "f1", communityId = "c1",
        skills = { Carpentry = 4 }, runtime = {} },
    { id = "crafter1", alive = true, factionId = "f1", communityId = "c1",
        skills = { Carpentry = 5 }, runtime = {} },
    { id = "crafter2", alive = true, factionId = "f1", communityId = "c1",
        skills = { Carpentry = 5 }, runtime = {} },
    { id = "crafter3", alive = true, factionId = "f1", communityId = "c1",
        skills = { Carpentry = 5 }, runtime = {} },
    { id = "unskilled", alive = true, factionId = "f1", communityId = "c1",
        skills = { Carpentry = 1 }, runtime = {} },
}
for _, worker in ipairs(workers) do PNC.Registry.Data[worker.id] = worker end

local Definitions = require "PNC/Core/Production/PNC_WorkDefinitions"
local Repository = require "PNC/Production/PNC_WorkRepository"
Repository.Import(nil)
local Work = require "PNC/Production/PNC_WorkService"
Work.ClaimsByStation, Work.ClaimsByWorker = {}, {}
Work.RegisterCompletion("CRAFT", function() return true end)
Work.RegisterCompletion("DISASSEMBLE", function() return true end)
Work.RegisterCompletion("RESEARCH", function() return true end)

local function queue(operation, requiredWork, skill)
    return Work.Commands.Queue({ operation = operation, colonyId = "c1",
        factionId = "f1", baseId = "b1", requiredWork = requiredWork or 10,
        requiredSkills = {{ skillId = "Carpentry", level = skill or 2 }} })
end

local craft1 = queue("CRAFT")
truthy(Work.Commands.Assign(craft1.id, "crafter1"), "first craft claim")
equal(Work.Queries.Get(craft1.id).stationId, "workshop:1:craft", "craft station")

local craft2 = queue("CRAFT")
local ok, reason = Work.Commands.Assign(craft2.id, "crafter2")
equal(ok, false, "second same-workshop craft rejected")
equal(reason, "NO_ACTIVITY_CAPACITY", "same craft blocker")

local disassembly = queue("DISASSEMBLE")
truthy(Work.Commands.Assign(disassembly.id, "crafter2"),
    "craft and disassemble concurrent")
equal(Work.Queries.Get(disassembly.id).stationId,
    "workshop:1:disassemble", "separate disassembly station")

stations["work.craft"][2] = "workshop:2:craft"
truthy(Work.Commands.Assign(craft2.id, "crafter3"), "second workshop craft")
equal(Work.Queries.Get(craft2.id).stationId, "workshop:2:craft",
    "second workshop station")

local research1 = queue("RESEARCH")
truthy(Work.Commands.Assign(research1.id, "researcher"), "research claim")
local research2 = queue("RESEARCH")
ok = Work.Commands.Assign(research2.id, "unskilled")
equal(ok, false, "research capacity or eligibility blocks second")

local gated = queue("CRAFT", 10, 5)
ok, reason = Work.Commands.Assign(gated.id, "unskilled")
equal(ok, false, "skill gate")
equal(reason, "NO_QUALIFIED_WORKER", "skill blocker")

clock = clock + 5000
truthy(Work.Commands.AddElapsed(craft1.id, "crafter1", 5),
    "abstract work progress")
truthy(Work.Queries.Get(craft1.id).progress > 5,
    "skill scaled rate")
clock = clock + 5000
truthy(Work.Commands.AddElapsed(craft1.id, "crafter1", 5),
    "abstract completion")
equal(Work.Queries.Get(craft1.id).status, Definitions.STATUS.COMPLETED,
    "completed once")
equal(Work.ClaimsByStation["workshop:1:craft"], nil,
    "completion releases station")

truthy(Work.Commands.Cancel(disassembly.id), "cancel")
equal(occupied["workshop:1:disassemble"], nil,
    "cancel releases facility reservation")

local collected = false
PNC.Registry.Data.liveCrafter = { id = "liveCrafter", alive = true,
    factionId = "f1", communityId = "c1", x = 2, y = 3, z = 0,
    skills = { Carpentry = 5 }, runtime = {} }
PNC.Registry.GetLiveZombie = function(id)
    return id == "liveCrafter" and {} or nil
end
PNC.StockpileAccessService = { FindNearest = function()
    return { id = "stockpile:1", x = 4, y = 5, z = 0 }
end }
Work.RegisterCollection("CRAFT", function(order, worker)
    collected = order ~= nil and worker.id == "liveCrafter"
    order.payload.inputsStaged = true
    return true
end)
local liveCraft = queue("CRAFT")
liveCraft = Work.Queries.Get(liveCraft.id)
liveCraft.payload = { reservationId = "materials:1" }
PNC.WorkRepository.Put(liveCraft)
truthy(Work.Commands.Assign(liveCraft.id, "liveCrafter"),
    "live craft assignment")
equal(Work.Queries.Get(liveCraft.id).status,
    Definitions.STATUS.TRAVEL_TO_STOCKPILE, "stockpile leg starts first")
equal(PNC.Registry.Data.liveCrafter.orderSpec.phase, "COLLECT_INPUTS",
    "live worker targets stockpile")
truthy(Work.Commands.CollectInputs(liveCraft.id, "liveCrafter"),
    "stockpile collection")
equal(collected, true, "collection handler invoked")
equal(PNC.Registry.Data.liveCrafter.orderSpec.phase, "WORK_AT_STATION",
    "worker continues to station after collection")

print("pnc_workstation_work_smoke: OK")
