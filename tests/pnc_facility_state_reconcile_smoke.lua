-- Facilities whose construction order disappeared used to stay non-BUILT
-- forever. For a stockpile that is a hard lock-out: no storage access, and no
-- UI path to rebuild it (the Command Hub hides the button, the FACILITIES tab
-- never lists the stockpile, and CANCEL CONSTRUCTION needs an order that no
-- longer exists). The reconciler heals those states from evidence.
local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }

local logLines = {}
local facilities = {}
local orders = {}
local storageForSettlement = nil
local refreshed = {}

-- facilityIds is a set (base.facilityIds[id] = true), not an array.
local base = { id = "base:1", colonyId = "colony:1", facilityIds = {
    ["facility:stockpile"] = true, ["facility:table"] = true,
    ["facility:built"] = true,
} }

PNC = {
    Core = {
        LogInfo = function(message) logLines[#logLines + 1] = "INFO " .. tostring(message) end,
        LogWarn = function(message) logLines[#logLines + 1] = "WARN " .. tostring(message) end,
    },
    WorkService = {
        Queries = { Get = function(id) return orders[id] end },
    },
    ColonyStorageRepository = {
        GetForSettlement = function() return storageForSettlement end,
    },
    BaseService = { Get = function(id) return id == "base:1" and base or nil end },
    BaseValidationService = { CanUse = function() return true end },
    SettlementRepository = {
        Load = function() end,
        MarkDirty = function() end,
        GetFacility = function(id) return facilities[id] end,
        State = { bases = { ["base:1"] = base }, facilities = facilities },
    },
    FacilityService = {
        RefreshState = function(facility) refreshed[#refreshed + 1] = facility.id end,
        RebuildIndexes = function() end,
        Internal = {},
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityService/PNC_FacilityService_Reconcile.lua")

-- 1. Reconstructing with its order gone: restore to built.
facilities["facility:stockpile"] = { id = "facility:stockpile",
    definitionId = "stockpile", baseId = "base:1", level = 1,
    constructionState = "RECONSTRUCTING",
    constructionWorkOrderId = "order:gone" }
orders["order:gone"] = { id = "order:gone", status = "CANCELLED" }
storageForSettlement = { id = "storage:1" }
local count, report = Service.ReconcileConstructionStates(base)
local stockpile = facilities["facility:stockpile"]
T.equal(stockpile.constructionState, "BUILT",
    "lost reconstruct restores the facility to built")
T.falsy(stockpile.constructionWorkOrderId ~= nil,
    "stale work order reference is cleared")
T.truthy(count >= 1, "a repair is reported")
T.truthy(#refreshed > 0, "repaired facility state is refreshed")
T.contains(table.concat(logLines, "|"), "facility_state_repaired",
    "repairs are logged")

-- 2. A facility with a live order is left alone.
logLines = {}
facilities["facility:table"] = { id = "facility:table",
    definitionId = "research_facility", baseId = "base:1", level = 1,
    constructionState = "UNDER_CONSTRUCTION",
    constructionWorkOrderId = "order:live" }
orders["order:live"] = { id = "order:live", status = "IN_PROGRESS" }
count = Service.ReconcileConstructionStates(base)
T.equal(facilities["facility:table"].constructionState, "UNDER_CONSTRUCTION",
    "an in-progress construction is not touched")
T.equal(facilities["facility:table"].constructionWorkOrderId, "order:live",
    "an in-progress construction keeps its order")

-- 3. Planned stockpile whose storage the colony is using: this is the softlock
--    the player hit - a planned stockpile loses storage access entirely.
facilities["facility:stockpile"] = { id = "facility:stockpile",
    definitionId = "stockpile", baseId = "base:1", level = 1,
    constructionState = "PLANNED", constructionWorkOrderId = nil }
count = Service.ReconcileConstructionStates(base)
T.equal(facilities["facility:stockpile"].constructionState, "BUILT",
    "planned stockpile with live storage is restored")

-- 4. Planned stockpile with no storage: leave it planned (it is rebuildable)
--    but drop any stale order reference.
storageForSettlement = nil
facilities["facility:stockpile"] = { id = "facility:stockpile",
    definitionId = "stockpile", baseId = "base:1", level = 1,
    constructionState = "PLANNED", constructionWorkOrderId = "order:gone" }
count = Service.ReconcileConstructionStates(base)
T.equal(facilities["facility:stockpile"].constructionState, "PLANNED",
    "unbuilt stockpile with no storage stays planned")
T.falsy(facilities["facility:stockpile"].constructionWorkOrderId ~= nil,
    "stale order reference is cleared so it can be queued again")

-- 5. Built facilities are never rewritten.
facilities["facility:built"] = { id = "facility:built",
    definitionId = "research_facility", baseId = "base:1", level = 1,
    constructionState = "BUILT" }
count = Service.ReconcileConstructionStates(base)
T.equal(facilities["facility:built"].constructionState, "BUILT",
    "built facilities are untouched")

-- 6. The player-facing action validates permissions before healing.
local result = Service.ReconcileAction(nil, { facilityId = "facility:built" })
T.truthy(result.ok, "reconcile action succeeds for an authorised player")
T.equal(result.reason, "FACILITY_STATE_OK",
    "a healthy facility reports no repair needed")
PNC.BaseValidationService.CanUse = function() return false end
result = Service.ReconcileAction(nil, { facilityId = "facility:built" })
T.falsy(result.ok, "reconcile action refuses an unauthorised player")
T.equal(result.reason, "NO_PERMISSION", "permission failure is reported")
PNC.BaseValidationService.CanUse = function() return true end

-- 7. The load-time heal walks every base.
facilities["facility:stockpile"] = { id = "facility:stockpile",
    definitionId = "stockpile", baseId = "base:1", level = 1,
    constructionState = "RECONSTRUCTING",
    constructionWorkOrderId = "order:gone" }
storageForSettlement = { id = "storage:1" }
T.truthy(Service.ReconcileAllConstructionStates() >= 1,
    "load-time heal repairs stuck facilities")

T.finish("pnc_facility_state_reconcile_smoke")
