local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end

package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] =
    function() return {} end
package.preload["PsychopatzCore/Inventory/PsychopatzInventoryConstants"] =
    function() return { TYPE_ID = 1 } end

local orders = {
    farming = {
        id = "work:farming", operation = "FARMING", colonyId = "c1",
        workerId = "npc:farm", status = "WORKING", phase = "WORK_TARGET",
        requiredWork = 4, progress = 2, payload = {},
    },
    fishing = {
        id = "work:fishing", operation = "FISHING", colonyId = "c1",
        workerId = "npc:fish", status = "WAITING_RESOURCE",
        phase = "ENSURE_TOOLS", blockedReason = "FISHING_TOOL_MISSING",
        requiredWork = 1, progress = 0, payload = {},
    },
    corpse = {
        id = "work:corpse", operation = "CORPSE_HAUL", colonyId = "c1",
        workerId = "npc:haul", status = "BLOCKED",
        phase = "SOURCE_APPROACH", blockedReason = "no_approach_point",
        requiredWork = 1, progress = 0, payload = {},
    },
}

local records = {
    ["npc:farm"] = {
        id = "npc:farm", name = "Farmer",
        runtime = { workOrderId = "work:farming" },
    },
    ["npc:fish"] = {
        id = "npc:fish", name = "Angler",
        runtime = { workOrderId = "work:fishing" },
    },
    ["npc:haul"] = {
        id = "npc:haul", name = "Hauler",
        runtime = { workOrderId = "work:corpse" },
    },
}

PNC = {
    Core = { DeepCopy = copy },
    Translation = { GetKey = function() return nil end },
    WorkDefinitions = {
        STATUS = {
            QUEUED = "QUEUED",
            WAITING_FOR_WORKER = "WAITING_FOR_WORKER",
            WAITING_RESOURCE = "WAITING_RESOURCE",
            BLOCKED = "BLOCKED",
            WORKING = "WORKING",
        },
    },
    WorkItemService = {
        Check = function(record, operation)
            if operation == "FARMING" and record and record.id == "npc:farm" then
                return {
                    operation = "FARMING", ok = true, state = "READY",
                    role = "primary_tool",
                    selected = { fullType = "Base.HandFork" },
                    requirements = {
                        { role = "primary_tool", selected = { fullType = "Base.HandFork" } },
                    },
                }
            end
            return nil
        end,
        Status = function() return { state = "READY" } end,
    },
    WorkRepository = {
        Get = function(id)
            for _, order in pairs(orders) do
                if order.id == id then return order end
            end
            return nil
        end,
    },
    Registry = {
        Get = function(id) return records[id] end,
    },
    WorkService = {
        Internal = {
            terminal = function() return false end,
            copy = copy,
            workLocationState = function() return nil end,
            locationPolicy = function() return nil end,
        },
        Queries = {
            List = function()
                return { orders.farming, orders.fishing, orders.corpse }
            end,
        },
    },
    NameplatePresentation = {},
    SettlementManagementFacilityActions = { Internal = {} },
    FacilityDefinitions = {
        GetLevel = function()
            return {
                componentLimits = {
                    ["growing.plot"] = { kind = "region", maxTotalTiles = 64 },
                },
            }
        end,
    },
}

local Snapshots = T.load("ProjectHoomans", "server",
    "PNC/Production/WorkService/PNC_WorkService_Snapshots.lua")

local farmInfo = Snapshots.BuildActionInformation(records["npc:farm"])
T.equal(farmInfo.operation, "FARMING", "farming action info resolves operation")
T.equal(farmInfo.phase, "WORK_TARGET", "farming action info surfaces active toil phase")
T.equal(farmInfo.toilPhase, "WORK_TARGET", "farming action info preserves toilPhase")
T.equal(farmInfo.percent, 50, "farming action info computes completion percent")
T.equal(farmInfo.activityItemFullType, "Base.HandFork",
    "farming action info resolves active tool fullType from WorkItemService")

local fishInfo = Snapshots.BuildActionInformation(records["npc:fish"])
T.equal(fishInfo.waitingFor, "resource", "fishing resource wait inferred uniformly")
T.equal(fishInfo.waitingReason, "FISHING_TOOL_MISSING",
    "fishing waitingReason surfaces missing tool reason")

local corpseInfo = Snapshots.BuildActionInformation(records["npc:haul"])
T.equal(corpseInfo.waitingReason, "no_approach_point",
    "corpse haul blocked reason surfaces in action waitingReason")

local taskRows = Snapshots.Queries.BuildTaskSnapshot("c1")
local byOp = {}
for _, row in ipairs(taskRows) do byOp[row.operation] = row end
T.equal(byOp.FARMING.toilPhase, "WORK_TARGET", "task snapshot includes toilPhase for FARMING")
T.equal(byOp.FARMING.activityItemFullType, "Base.HandFork",
    "task snapshot includes farming tool item type")
T.equal(byOp.FISHING.waitingReason, "FISHING_TOOL_MISSING",
    "task snapshot includes waitingReason for FISHING")
T.equal(byOp.CORPSE_HAUL.phase, "SOURCE_APPROACH",
    "task snapshot includes phase for CORPSE_HAUL")

package.preload["PNC/UI/Shared/PNC_ColonyUIShared"] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        Text = function(value, fallback) return value or fallback end,
        SettlementReason = function(reason)
            return reason and ("REASON:" .. tostring(reason)) or nil
        end,
    }
end

local ActivityPresentation = T.load("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistActivityPresentation.lua")
T.contains(ActivityPresentation.Current({ actionInformation = farmInfo }),
    "FARMING (WORK_TARGET)", "activity presentation renders FARMING phase")
T.contains(ActivityPresentation.Current({ actionInformation = fishInfo }),
    "missing fishing rod", "activity presentation renders FISHING missing tool reason")
T.contains(ActivityPresentation.Current({ actionInformation = corpseInfo }),
    "no reachable work point",
    "activity presentation renders CORPSE_HAUL blocked reason")

T.load("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplatePresentation_Actions.lua")
local NameplateActions = PNC.NameplatePresentation
local npFarm = NameplateActions.WorkActionStatus({ actionInformation = farmInfo })
T.contains(npFarm, "Farming", "nameplate renders Farming verb")
T.contains(npFarm, "work target", "nameplate renders FARMING toil phase")
local npFish = NameplateActions.WorkActionStatus({ actionInformation = fishInfo })
T.contains(npFish, "Fishing", "nameplate renders Fishing verb")
T.contains(npFish, "FISHING TOOL MISSING", "nameplate renders waiting reason")
local npCorpse = NameplateActions.WorkActionStatus({ actionInformation = corpseInfo })
T.contains(npCorpse, "Hauling corpses", "nameplate renders CorpseHaul verb")
T.contains(npCorpse, "no approach point", "nameplate renders blocked reason")

-- Verify UI growing.plot validation accepts unplowed arable soil via Farming/ISFarmingMenu
local RealGridRegion = T.load(
    "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/PC_GridRegion.lua")
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return RealGridRegion
end
package.preload["PNC/UI/SettlementManagement/PNC_SettlementManagement_SelectorSupport"] = function()
    local baseBox = { levels = { [0] = { [20] = { 10, 12 } } } }
    return {
        Tr = function(_, fallback) return fallback end,
        BaseRegion = function() return baseBox end,
        FacilityRegion = function() return baseBox end,
        UsedGuideLayers = function() return {} end,
        EmptyRegion = function() return { levels = {} } end,
        ValidateConnected = function() return true, nil end,
    }
end
T.load("ProjectHoomans", "shared", "PNC/Core/Farming/PNC_Farming.lua")

local squareGrid = {}
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squareGrid[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
    }
end
CFarmingSystem = {
    instance = {
        getLuaObjectOnSquare = function(_, sq) return sq and sq.plant or nil end,
    },
}
ISFarmingMenu = {
    canDigHere = function(list)
        local sq = list and list[1]
        return sq and sq.arable == true or false
    end,
}

T.load("ProjectHoomans", "client",
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions_Area.lua")

squareGrid["10:20:0"] = { arable = true }
local opts = PNC.SettlementManagementFacilityActions.Internal.AreaOptions(
    {}, { id = "farm:1", definitionId = "farm", level = 1 }, nil, function() end, "growing.plot")
T.contains(opts.instruction, "arable soil",
    "growing.plot help instruction mentions arable soil")
local plotRegion = { levels = { [0] = { [20] = { 10, 10 } } } }
local okArable, errArable = opts.validate(plotRegion, { tileCount = 1 })
T.equal(okArable, true, "unplowed arable square passes growing.plot validation: " .. tostring(errArable))
T.equal(errArable, nil, "no error returned for unplowed arable soil")

squareGrid["10:20:0"] = { arable = false }
local okBarren, errBarren = opts.validate(plotRegion, { tileCount = 1 })
T.equal(okBarren, false, "non-arable square rejected for growing.plot")
T.equal(errBarren, "REASON:FARMLAND_REQUIRED",
    "non-arable square maps to canonical FARMLAND_REQUIRED settlement reason")

T.finish("pnc_work_ui_diagnostics_smoke")
