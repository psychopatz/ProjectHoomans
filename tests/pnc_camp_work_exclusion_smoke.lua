local T = require "tests/support/test"

T.addPackagePaths()

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = deepCopy(entry) end
    return output
end

local sentHome = 0
local camped = {
    id = "camped", alive = true,
    affiliation = { factionID = "f1", communityID = "c1" },
    x = 10, y = 10, z = 0,
    runtime = {}, orderSpec = { kind = "camp" },
}

PNC = {
    Core = { Now = function() return 1000 end, DeepCopy = deepCopy },
    Skills = { GetLevel = function() return 5 end },
    Registry = { Data = { camped = camped },
        Get = function(id) return PNC.Registry.Data[tostring(id)] end,
        GetLiveZombie = function() return nil end,
    },
    HomeDutyService = {
        IsCamped = function(record)
            return record and record.orderSpec
                and record.orderSpec.kind == "camp"
        end,
        IsAtHome = function() return true end,
        IsReturningHome = function() return false end,
        SendHome = function() sentHome = sentHome + 1; return true end,
    },
    OrderSystem = {
        SetOrder = function(record, order) record.orderSpec = order end,
    },
}

function PNC.Registry.ForEach(callback)
    for _, record in pairs(PNC.Registry.Data) do callback(record) end
end

local Definitions = require "PNC/Core/Production/PNC_WorkDefinitions"
local Repository = require "PNC/Production/PNC_WorkRepository"
Repository.Import(nil)
local Work = require "PNC/Production/PNC_WorkService"
Work.ClaimsByStation, Work.ClaimsByWorker = {}, {}

local function queue(operation, locationPolicy)
    return T.truthy(Work.Commands.Queue({
        operation = operation, colonyId = "c1", factionId = "f1",
        baseId = "b1", requiredWorkerId = camped.id, manual = true,
        requiredWork = 1, locationPolicy = locationPolicy,
    }), operation .. " queued")
end

local lumber = queue("LUMBER", {
    start = "ANYWHERE", execution = "REMOTE", returnHome = "STAY",
})
local corpse = queue("CORPSE_HAUL", {
    start = "HOME", execution = "REMOTE", returnHome = "HOME",
})

local ok, reason = Work.Queries.CanAssign(lumber.id, camped.id)
T.equal(ok, false, "camped lumber is not assignable")
T.equal(reason, "WORKER_CAMPED", "camped lumber reason")

ok, reason = Work.Commands.Assign(corpse.id, camped.id)
T.equal(ok, false, "camped corpse haul is not assignable")
T.equal(reason, "WORKER_CAMPED", "camped corpse haul reason")

local assignable = Work.Queries.ListAssignableForWorker(camped.id)
T.equal(#assignable, 0, "camped worker has no queued work candidates")

local selected, findReason = Work.Internal.findWorker(corpse)
T.equal(selected, nil, "camped worker is not selected for home work")
T.equal(findReason, "NO_QUALIFIED_WORKER", "camped worker search reason")
T.equal(sentHome, 0, "camped worker is not sent home for work")

camped.orderSpec = { kind = "guard" }
T.truthy(Work.Queries.CanAssign(lumber.id, camped.id),
    "non-camped worker remains eligible")

return T.finish("pnc_camp_work_exclusion_smoke")
