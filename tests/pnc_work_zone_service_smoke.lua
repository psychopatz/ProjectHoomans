local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local GridRegion = T.load(
    "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/PC_GridRegion.lua")
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return GridRegion
end
local CoreZones = T.load(
    "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/PC_ZoneRegistry.lua")
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return CoreZones
end

local clock = 100
PNC = {
    Core = {
        Now = function() return clock end,
    },
    WorkDefinitions = {
        PRIORITY = { NORMAL_WORK = 40, FORCED_ORDER = 90 },
        JobForOperation = function(op)
            if op == "FARMING" then return "Farmer" end
            if op == "LUMBER" then return "Lumber" end
            return nil
        end,
    },
    WorkPolicy = {
        IsEnabled = function(record, job)
            return record and record.jobs and record.jobs[job] ~= false
        end,
        WorkServicePriority = function(record, job)
            return record and record.priorityByJob and record.priorityByJob[job] or 45
        end,
    },
}

local WorkZone = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkZoneService.lua")

local zone = T.truthy(WorkZone.CreateZone({
    id = "zone:farm:1",
    operation = "FARMING",
    colonyId = "colony-1",
    bounds = { minX = 10, maxX = 11, minY = 20, maxY = 21, z = 0 },
}))
T.equal(zone.id, "zone:farm:1", "CreateZone stores canonical zone id")
T.equal(zone.enabled, true, "new zone defaults to enabled")
T.truthy(CoreZones.get("zone:farm:1"), "CreateZone registers geometry in PC_ZoneRegistry")

local listed = WorkZone.ListZones({ colonyId = "colony-1", operation = "FARMING" })
T.equal(#listed, 1, "ListZones filters by colonyId and operation")

-- Bounded cursor scanning covers all 4 tiles across two 2-tile steps
local seenFirst = {}
local okScan1, scanned1 = WorkZone.ScanStep("zone:farm:1", function(x, y)
    seenFirst[#seenFirst + 1] = tostring(x) .. ":" .. tostring(y)
end, { budget = 2 })
T.equal(okScan1, true, "first bounded scan step succeeds")
T.equal(scanned1, 2, "first bounded scan visits budget=2 tiles")
T.equal(seenFirst[1], "10:20", "scan starts at top-left tile")
T.equal(seenFirst[2], "11:20", "scan advances horizontally first")

local seenSecond = {}
local okScan2, scanned2 = WorkZone.ScanStep("zone:farm:1", function(x, y)
    seenSecond[#seenSecond + 1] = tostring(x) .. ":" .. tostring(y)
end, { budget = 2 })
T.equal(okScan2, true, "second bounded scan step succeeds")
T.equal(scanned2, 2, "second bounded scan visits remaining 2 tiles")
T.equal(seenSecond[1], "10:21", "cursor continues across row boundary")
T.equal(seenSecond[2], "11:21", "cursor finishes bottom-right tile")

-- Target claims enforce TTL exclusivity and allow renewal / release
local okClaim1 = WorkZone.ClaimTarget("zone:farm:1", "10:20:0", "npc:a", { ttlSeconds = 5 })
T.equal(okClaim1, true, "worker a claims target tile")
local okConflict, conflictReason = WorkZone.ClaimTarget("zone:farm:1", "10:20:0", "npc:b")
T.equal(okConflict, false, "worker b cannot steal active target claim")
T.equal(conflictReason, "TARGET_CLAIMED", "active claim returns TARGET_CLAIMED")

local okRenew = WorkZone.RenewTarget("zone:farm:1", "10:20:0", "npc:a", 10)
T.equal(okRenew, true, "worker a can renew active TTL claim")
clock = clock + 11
local okTakeover = WorkZone.ClaimTarget("zone:farm:1", "10:20:0", "npc:b", { ttlSeconds = 5 })
T.equal(okTakeover, true, "worker b can claim tile once previous TTL expires")
T.equal(WorkZone.ReleaseTarget("zone:farm:1", "10:20:0", "npc:b"), true,
    "worker b releases target claim cleanly")

-- Dual-mode dispatch: autonomous WorkPolicy vs manual AssignWorker
local autonomousWorker = {
    id = "npc:auto",
    jobs = { Farmer = true },
    priorityByJob = { Farmer = 55 },
}
local disabledWorker = { id = "npc:off", jobs = { Farmer = false } }
local modeAuto, prioAuto = WorkZone.ResolveDispatchMode(zone, autonomousWorker)
T.equal(modeAuto, "NORMAL_WORK", "enabled worker uses autonomous NORMAL_WORK mode")
T.equal(prioAuto, 55, "autonomous mode uses WorkPolicy priority")
local modeOff, reasonOff = WorkZone.ResolveDispatchMode(zone, disabledWorker)
T.equal(modeOff, nil, "disabled Farmer job cannot claim zone autonomously")
T.equal(reasonOff, "JOB_DISABLED", "disabled worker returns JOB_DISABLED")

T.truthy(WorkZone.AssignWorker("zone:farm:1", "npc:off"), "manual AssignWorker succeeds")
local modeForced, prioForced = WorkZone.ResolveDispatchMode(zone, disabledWorker)
T.equal(modeForced, "FORCED_ORDER", "explicitly assigned worker uses FORCED_ORDER mode")
T.equal(prioForced, 90, "FORCED_ORDER uses forced priority")
WorkZone.ClaimTarget("zone:farm:1", "11:20:0", "npc:off", { ttlSeconds = 5 })
T.truthy(WorkZone.UnassignWorker("zone:farm:1", "npc:off"), "UnassignWorker removes assignment")
T.equal(zone.claims["11:20:0"], nil, "UnassignWorker releases worker claims")

local okDisable = WorkZone.DisableZone("zone:farm:1")
T.equal(okDisable, true, "DisableZone updates zone enabled flag")
T.equal(zone.enabled, false, "disabled zone marks enabled=false")
local okDisabledClaim, disabledReason = WorkZone.ClaimTarget("zone:farm:1", "10:20:0", "npc:a")
T.equal(okDisabledClaim, false, "disabled zone rejects target claims")
T.equal(disabledReason, "WORK_ZONE_DISABLED", "disabled zone returns WORK_ZONE_DISABLED")

T.equal(WorkZone.DeleteZone("zone:farm:1"), true, "DeleteZone removes work zone")
T.equal(WorkZone.GetZone("zone:farm:1"), nil, "deleted zone is no longer retrievable")
T.equal(CoreZones.get("zone:farm:1"), nil, "DeleteZone removes geometry from PC_ZoneRegistry")

T.finish("pnc_work_zone_service_smoke")
