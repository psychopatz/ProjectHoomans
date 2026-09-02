local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now, serial = 1000, 0
local square = { corpses = {} }
function square:isFree() return true end
function square:addCorpse(corpse)
    self.corpses[#self.corpses + 1] = corpse
    corpse.square = self
end

local corpse = {
    x = 40, y = 40, z = 0,
    data = {},
}
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:getModData() return self.data end
function corpse:transmitModData() end
square:addCorpse(corpse)

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if tonumber(z) ~= 0 then return nil end
            if tonumber(x) == 40 and tonumber(y) == 40 then return square end
            if tonumber(x) == 60 and tonumber(y) == 60 then
                return { isFree = function() return true end }
            end
            return nil
        end,
    }
end

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { get = function() return nil end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    local function intersects(left, right)
        for z, level in pairs(left and left.levels or {}) do
            local rightLevel = right and right.levels and right.levels[z]
            for y, spans in pairs(level.rows or {}) do
                local other = rightLevel and rightLevel.rows
                    and rightLevel.rows[y] or nil
                for index = 1, #spans, 2 do
                    for otherIndex = 1, #(other or {}), 2 do
                        if spans[index] <= other[otherIndex + 1]
                            and other[otherIndex] <= spans[index + 1]
                        then return true end
                    end
                end
            end
        end
        return false
    end
    return {
        normalize = function(region) return region end,
        countTiles = function() return 1 end,
        validate = function(region) return true, nil, region end,
        isConnected = function() return true end,
        containsPoint = function() return true end,
        intersects = intersects,
    }
end

local record = {
    id = "npc:manual", alive = true, x = 5, y = 5, z = 0, runtime = {},
    affiliation = { factionID = "faction:one", communityID = "colony:one" },
}
local body = { x = 5, y = 5, z = 0 }
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end

PNC = {
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            serial = serial + 1
            return tostring(prefix) .. ":" .. tostring(serial)
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local copy = {}
            for key, item in pairs(value) do copy[key] = item end
            return copy
        end,
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x1 - x2, y1 - y2
            return math.sqrt(dx * dx + dy * dy)
        end,
        Log = function() end,
        LogWarn = function() end,
    },
    Registry = {
        Get = function(id)
            return tostring(id) == record.id and record or nil
        end,
        ForEach = function(callback) callback(record) end,
        GetLiveZombie = function(id)
            return tostring(id) == record.id and body or nil
        end,
    },
    HomeDutyService = {
        IsAtHome = function() return true end,
        IsReturningHome = function() return false end,
        GetBase = function() return nil end,
    },
    BaseService = {},
    BaseValidationService = { CanUse = function() return true end },
    SettlementRepository = {
        State = { bases = {} },
        MarkDirty = function() end,
        Save = function() end,
    },
    BodyLifecycle = {
        Internal = {
            forEachCorpse = function(target, callback)
                for _, item in ipairs(target and target.corpses or {}) do
                    callback(item)
                end
            end,
        },
    },
    OrderSystem = {
        SetOrder = function(target, order) target.orderSpec = order end,
    },
}

local base = {
    id = "base:one", colonyId = "colony:one", factionId = "faction:one",
}
base.corpseHaul = {
    sourceRegion = { levels = { [0] = { rows = { [40] = { 40, 40 } } } } },
    destinationRegion = {
        levels = { [0] = { rows = { [60] = { 60, 60 } } } },
    },
    revision = 1,
}
PNC.SettlementRepository.State.bases[base.id] = base
PNC.BaseService.Get = function(id)
    return tostring(id) == base.id and base or nil
end
PNC.BaseService.GetForColony = function(id)
    return tostring(id) == base.colonyId and base or nil
end

local Definitions = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_WorkDefinitions.lua")
local Repository = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkRepository.lua")
Repository.Import(nil)
local Work = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkService.lua")

local Priority = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskPriority.lua")
local Intent = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskIntent.lua")
local Leases = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskLeaseService.lua")
package.preload["PNC/Tasking/PNC_TaskPriority"] = function() return Priority end
package.preload["PNC/Tasking/PNC_TaskIntent"] = function() return Intent end
package.preload["PNC/Tasking/PNC_TaskLeaseService"] = function() return Leases end
package.preload["PNC/Tasking/PNC_TaskExecutors"] = function() return {} end
package.preload[
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"
] = function() return {} end

local Tasking = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_Tasking.lua")
local Provider = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_WorkTaskProvider.lua")
local CorpseService = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_CorpseHaulService.lua")

local rejected, rejectionReason = CorpseService.SetConfiguration({}, {
    baseId = base.id,
    sourceRegion = { levels = { [0] = { rows = { [40] = { 40, 41 } } } } },
    destinationRegion = { levels = { [0] = { rows = { [40] = { 41, 42 } } } } },
})
T.falsy(rejected, "server accepted overlapping corpse-haul zones")
T.equal(rejectionReason, "CORPSE_HAUL_ZONES_OVERLAP",
    "server returned the wrong overlap rejection reason")
T.equal(base.corpseHaul.destinationRegion.levels[0].rows[60][1], 60,
    "overlap rejection mutated the saved corpse destination")

local saved, saveReason = CorpseService.SetConfiguration({}, {
    baseId = base.id,
    sourceRegion = base.corpseHaul.sourceRegion,
    destinationRegion = base.corpseHaul.destinationRegion,
})
T.truthy(saved and saveReason == "CORPSE_HAUL_ZONES_SAVED",
    "manual dispatch test configures corpse zones")

local accepted, reason, order = CorpseService.RequestManual(record)
T.truthy(accepted, "manual corpse request is accepted")
T.equal(reason, "CORPSE_HAUL_ORDER_FORCED",
    "manual corpse request returns its stable reason")
T.truthy(order, "manual corpse request returns the durable order")

local stored = Work.Queries.Get(order.id)
T.truthy(stored and stored.workerId == record.id,
    "real tasking arbiter assigns the selected worker")
T.equal(stored.status, Definitions.STATUS.TRAVEL_TO_STATION,
    "assigned corpse work enters the live travel state")
T.equal(record.runtime.workOrderId, order.id,
    "work assignment is projected onto the live worker")
T.truthy(record.orderSpec and record.orderSpec.kind == "production_work",
    "live worker receives the shared production order")
T.truthy(Leases.ForNPC(record.id),
    "manual corpse request creates a shared task lease")
T.truthy(Provider.GetCandidates(record.id)[1] == nil,
    "assigned corpse order is no longer offered as an unclaimed candidate")

T.finish("pnc_corpse_haul_manual_tasking_smoke")
