local T = require "tests/support/test"

-- This is intentionally a pipeline test rather than a service-only test. It
-- starts with a valid rod in a non-primary slot, runs the shared work-item
-- lease and hand presentation, drives a live job through travel and the
-- stand, and then exercises combat priority and a replica body.
PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local serial = 0
local requests = {}
local added = {}
local moves = {}
local fishingTransitions = {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

local function makeItem(itemID, fullType)
    local item = {
        id = itemID, type = fullType, fullType = fullType, cond = 10,
    }
    function item:getFullType() return self.fullType end
    function item:IsWeapon() return true end
    function item:isRequiresEquippedBothHands() return false end
    return item
end

local hammer = makeItem("hammer", "Base.ClawHammer")
local rod = makeItem("rod", "Base.FishingRod")
local record

local function presentationItem(fullType)
    local item = makeItem("presentation:" .. tostring(fullType), fullType)
    return item
end

local function inventoryEnsure(target)
    return target.inventory
end

local function equipPrimary(target, itemID)
    local inventory = target.inventory
    local previous = inventory.equipped.primary
    if previous and inventory.items[previous] then
        inventory.items[previous].equipSlot = nil
    end
    inventory.equipped.primary = itemID
    if itemID and inventory.items[itemID] then
        inventory.items[itemID].equipSlot = "primary"
        target.equipment.primaryFullType = inventory.items[itemID].type
    else
        target.equipment.primaryFullType = nil
    end
    return true, "equipped"
end

local function makeBody(x, y, z, primary)
    local body = {
        x = x, y = y, z = z, primary = primary, secondary = nil,
        variables = {}, attached = {}, modData = {},
    }
    function body:getX() return self.x end
    function body:getY() return self.y end
    function body:getZ() return self.z end
    function body:getPrimaryHandItem() return self.primary end
    function body:getSecondaryHandItem() return self.secondary end
    function body:setPrimaryHandItem(item) self.primary = item end
    function body:setSecondaryHandItem(item) self.secondary = item end
    function body:setVariable(key, value) self.variables[key] = value end
    function body:resetEquippedHandsModels() self.handReset = (self.handReset or 0) + 1 end
    function body:setAttachedItem(location, item) self.attached[location] = item end
    function body:getModData() return self.modData end
    function body:faceLocationF(xTarget, yTarget)
        self.faced = { x = xTarget, y = yTarget }
    end
    return body
end

local body = makeBody(100.5, 100.5, 0, hammer)

local visuals = {
    ClearAttachedItems = function(target) target.attached = {} end,
    RefreshModel = function() end,
}

local inventory = {
    EnsureRecordInventory = inventoryEnsure,
    EquipPrimary = equipPrimary,
    CanAccept = function() return true, "accepted" end,
    AddItems = function(_, specs)
        added[#added + 1] = specs[1]
        return true, "added"
    end,
}

PNC = {
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            serial = serial + 1
            return tostring(prefix) .. ":" .. tostring(serial)
        end,
        DeepCopy = copy,
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x1 - x2, y1 - y2
            return math.sqrt(dx * dx + dy * dy)
        end,
        LogWarn = function() end,
        LogInfo = function() end,
    },
    Visuals = visuals,
    Inventory = inventory,
    Const = {
        FISHING_DEFAULT_RADIUS = 16,
        FISHING_INTERACTION_RADIUS = 1.75,
        FISHING_MAX_ZONE_TILES = 10000,
        FISHING_MAX_WORKERS = 16,
        FISHING_WORK_POINTS_PER_SECOND = 20,
        FISHING_REQUIRED_WORK_POINTS = 100,
        FISHING_BASE_CATCH_CHANCE = 1,
        FISHING_SKILL_CATCH_BONUS = 0,
        FISHING_FATIGUE_STOP = 0.70,
        ORDER_FISHING = "fishing",
        PRESENCE_ABSTRACT = "abstract",
    },
    Registry = {
        Get = function() return record end,
        GetLiveZombie = function() return body end,
    },
    Skills = {
        GetLevel = function() return 0 end,
        AddXP = function() return true end,
    },
    OrderSystem = {
        SetOrder = function(target, order) target.orderSpec = copy(order) end,
        RegisterNormalizer = function() end,
    },
    Tasking = { Events = { Emit = function() end } },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        HaltMovement = function() end,
        MoveRecord = function(_, _, x, y, z, _, _, reason)
            moves[#moves + 1] = { x = x, y = y, z = z, reason = reason }
        end,
    },
    JobSystem = { RegisterOrder = function() end },
    BehaviorRegistry = { Register = function() end },
}
PsychopatzCore.DebugTrace = {
    Record = function(entry)
        fishingTransitions[#fishingTransitions + 1] = entry
    end,
}

WeaponType = {
    FIREARM = {}, HANDGUN = {}, SPEAR = {}, HEAVY = {},
    TWO_HANDED = {}, ONE_HANDED = {},
}
WeaponType.getWeaponType = function() return WeaponType.ONE_HANDED end

T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Items.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Slots.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment.lua")
PNC.Equipment.CreateItem = function(fullType)
    if fullType ~= "Base.ClawHammer"
        and fullType ~= "Base.FishingRod"
    then
        return nil, "invalid_full_type"
    end
    return presentationItem(fullType), "test_item"
end

T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_JobRequirements.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_WorkItemService.lua")

local squares = {}
local function squareKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local Properties = {}
function Properties:has(flag)
    return flag == "water" and self.water == true
end

for x = 0, 2 do
    for y = 0, 2 do
        local square = {
            water = x == 2 and y == 1,
            isFree = function() return true end,
        }
        function square:getProperties()
            return setmetatable({ water = self.water }, { __index = Properties })
        end
        squares[squareKey(x, y, 0)] = square
    end
end

IsoFlagType = { water = "water" }
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[squareKey(x, y, z)]
        end,
    }
end

local GridRegion = {}
function GridRegion.validate(region) return true, nil, region end
function GridRegion.bounds()
    return { minX = 0, maxX = 2, minY = 0, maxY = 2,
        minZ = 0, maxZ = 0 }
end
function GridRegion.countTiles() return 9 end
function GridRegion.isConnected() return true end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return GridRegion
end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { register = function() return true end }
end

record = {
    id = "npc:live-fishing-pipeline", alive = true, recruited = true,
    presenceState = "live", x = body.x, y = body.y, z = body.z,
    equipment = { primaryFullType = hammer.type },
    inventory = {
        equipped = { primary = hammer.id },
        items = { hammer = hammer, rod = rod },
    },
}

local fishingRequests = {}
PNC.AnimationScenes = {
    Request = function(target, _, sceneID)
        fishingRequests[#fishingRequests + 1] = sceneID
        target.runtime = target.runtime or {}
        target.runtime.animationScene = { id = sceneID }
        return true, "requested"
    end,
    Stop = function() return true end,
}

local WorkItems = PNC.WorkItemService
local ensured, ensureReason, ensureReport = WorkItems.Ensure(
    record, "FISHING", body, {
        owner = "work:FISHING", priority = "WORK",
        applyHands = true, forceHeld = true,
    })
T.truthy(ensured, ensureReason or "shared fishing work item acquired")
T.equal(ensureReport.selected.fullType, "Base.FishingRod",
    "shared selector chose the rod from inventory")
T.equal(WorkItems.GetLease(record, "FISHING").owner, "work:FISHING",
    "fishing lease owner")
T.equal(record.inventory.equipped.primary, "rod",
    "fishing lease equips the rod in the authoritative inventory")
T.equal(body:getPrimaryHandItem():getFullType(), "Base.FishingRod",
    "fishing lease presents the rod in the native primary hand")

local SharedFishing = T.load("ProjectHoomans", "shared",
    "PNC/Core/Fishing/PNC_Fishing.lua")
PNC.Fishing = SharedFishing
local Service = T.load("ProjectHoomans", "server",
    "PNC/Fishing/PNC_FishingService.lua")
Service.FishingDiagnostics.SetEnabled(true)
local zone, zoneReason = Service.CreateZone({
    id = "fishing:live-pipeline", minX = 0, minY = 0,
    maxX = 2, maxY = 2, z = 0, npcIds = { record.id },
    catchChance = 1, requiredWorkPoints = 100,
    workPointsPerSecond = 20,
})
T.truthy(zone, zoneReason or "live fishing zone")
local spot = zone.fishingSpots[1]
T.truthy(spot, "live fishing stand")

T.truthy(Service.AssignWorker(zone.id, record.id), "worker assigned")
local lease = {
    npcId = record.id, leaseId = "lease:live-pipeline", executionMode = "LIVE",
}
T.truthy(Service.StartJob(lease), "live fishing started")
T.equal(Service.GetJob(record.id).phase, "TRAVEL",
    "live fishing starts in travel when the stand is distant")

local Behavior = T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Fishing.lua")
Behavior.Tick(record, body)
T.equal(#moves, 1, "fishing behavior requests one travel move")
T.equal(Service.GetJob(record.id).workPoints, 0,
    "travel does not award work points")

local assignedSpot = Service.GetJob(record.id).spot
body.x, body.y, body.z = assignedSpot.standX, assignedSpot.standY,
    assignedSpot.standZ
record.x, record.y, record.z = body.x, body.y, body.z
now = 7000
local ticked, _, tickReason = Service.TickJob(lease)
T.truthy(ticked, tickReason or "live fishing reaches the stand")
local job = Service.GetJob(record.id)
T.equal(job.phase, "WORKING", "arrival promotes fishing to working")
T.equal(record.runtime.fishing.phase, "WORKING",
    "working phase is published to the runtime/nameplate path")
T.equal(job.workPoints, 0,
    "live arrival does not award travel time as work")
now = 11000
local progressTicked, _, progressReason = Service.TickJob(lease)
T.truthy(progressTicked, progressReason or "live fishing progress tick")
job = Service.GetJob(record.id)
T.truthy(job.workPoints > 0, "working phase accumulates points")
now = 13000
ticked, _, tickReason = Service.TickJob(lease)
T.truthy(ticked, tickReason or "live fishing working tick")
job = Service.GetJob(record.id)
T.truthy(job.attemptIndex >= 1, "working phase rolls an attempt")
T.equal(job.lastAttemptChance, 1, "attempt chance is recorded")
T.truthy(job.lastAttemptRoll ~= nil, "attempt roll is recorded")
T.equal(job.lastAttemptSuccess, true, "successful attempt is recorded")
T.truthy(#added >= 1, "successful attempt routes fish through inventory")
local sawAttemptPhase = false
local sawOutputPhase = false
for _, entry in ipairs(fishingTransitions) do
    local phase = entry.data and entry.data.phase or nil
    sawAttemptPhase = sawAttemptPhase or phase == "ATTEMPT"
    sawOutputPhase = sawOutputPhase or phase == "OUTPUT"
end
T.truthy(sawAttemptPhase, "attempt phase is observable in diagnostics")
T.truthy(sawOutputPhase, "output phase is observable in diagnostics")

Behavior.Tick(record, body)
T.equal(fishingRequests[#fishingRequests], "fishing.strike",
    "attempt requests the fishing strike scene")
T.equal(body.variables.PNCPrimary, "Base.FishingRod",
    "live work presentation keeps the rod selected")

local acquiredCombat = PNC.Equipment.AcquirePrimaryLease(
    record, "combat", hammer.id, { priority = "COMBAT", reason = "test_combat" })
T.truthy(acquiredCombat, "combat lease takes priority")
PNC.Equipment.ApplyCombatState(body, record, true, true)
T.equal(body:getPrimaryHandItem():getFullType(), "Base.ClawHammer",
    "combat temporarily overrides the fishing tool")
local releasedCombat = PNC.Equipment.ReleaseCombatLease(
    record, body, "test_combat_end")
T.truthy(releasedCombat, "combat lease releases")
T.equal(PNC.Equipment.GetActivePrimaryLease(record).owner, "work:FISHING",
    "fishing lease becomes active after combat")
T.equal(body:getPrimaryHandItem():getFullType(), "Base.FishingRod",
    "fishing rod is restored after combat")

isClient = function() return true end
isServer = function() return false end
local remoteRecord = {
    id = record.id, activeJob = "Fishing", orderSpec = record.orderSpec,
    equipment = { primaryFullType = "Base.ClawHammer" },
    runtime = {
        workItems = copy(record.runtime.workItems),
        workPresentation = PNC.Equipment.BuildWorkPresentationSummary(record),
    },
}
local remoteBody = makeBody(assignedSpot.standX, assignedSpot.standY,
    assignedSpot.standZ, nil)
local replicaOK, replicaReason = PNC.Equipment.ApplyReplicaHands(
    remoteBody, remoteRecord)
T.truthy(replicaOK, replicaReason or "replica work presentation")
T.equal(remoteBody:getPrimaryHandItem():getFullType(), "Base.FishingRod",
    "multiplayer replica presents the leased fishing rod")

T.finish("pnc_fishing_live_pipeline_smoke")
