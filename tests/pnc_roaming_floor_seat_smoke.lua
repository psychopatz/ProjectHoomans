local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local now = 2000
local stabilized = 0
local reserved = {}

ZombRand = function() return 0 end

local function distance(x1, y1, x2, y2)
    local dx = (x2 or 0) - (x1 or 0)
    local dy = (y2 or 0) - (y1 or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local square = {
    isSolid = function() return false end,
    isSolidTrans = function() return false end,
    isFree = function() return true end,
    objects = {},
}
function square:getObjects() return self.objects end

getCell = function()
    return {
        getGridSquare = function() return square end,
    }
end

local body = {
    x = 10.5, y = 20.5, z = 0,
    variables = {},
}
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:setOnFloor(value) self.onFloor = value end
function body:setSitAgainstWall(value) self.sitAgainstWall = value end
function body:setSitOnGround(value) self.sitOnGround = value end
function body:setSittingOnFurniture(value) self.sittingOnFurniture = value end
function body:setSitOnFurnitureObject(value) self.furnitureObject = value end
function body:setSitOnFurnitureDirection(value) self.furnitureDirection = value end
function body:setIsResting(value) self.resting = value end
function body:setVariable(key, value) self.variables[key] = value end
function body:clearVariable(key) self.variables[key] = nil end

PNC = {
    Const = {
        ORDER_ROAM = "roam",
        ORDER_GUARD = "guard",
        GUARD_STOP_DISTANCE = 0.55,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Distance = distance,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            record.runtime.target = nil
        end,
        HaltMovement = function() end,
        MoveRecord = function() end,
    },
    FacilityResources = {
        GetDetector = function() return nil end,
        CopyDescriptor = function(resource)
            local copy = {}
            for key, value in pairs(resource) do
                if type(value) ~= "table" then copy[key] = value end
            end
            return copy
        end,
    },
    FacilityReservations = {
        ByResource = reserved,
        ReserveResource = function(_, resource, npcId, purpose)
            local reservation = {
                id = "roam-floor-reservation:" .. tostring(npcId),
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                npcId = npcId,
                purpose = purpose,
            }
            return true, reservation
        end,
        Release = function() return true end,
        Start = function() return true end,
    },
    PerformanceScalingDiagnostics = {
        NewSeatingSessionId = function(id)
            return "seat:" .. tostring(id) .. ":1"
        end,
    },
    AnimationScenes = {
        Request = function(record, _, sceneId)
            record.runtime.animationScene = { id = sceneId }
            return true
        end,
        Interrupt = function(record)
            record.runtime.animationScene = nil
            return true
        end,
        Internal = {
            ClearScene = function(record)
                record.runtime.animationScene = nil
                return true
            end,
        },
    },
    SeatingRuntime = { LiveObjects = {} },
    LiveBodyControl = {
        StabilizePresentationBody = function()
            stabilized = stabilized + 1
        end,
    },
}

local BehaviorInternal = T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_State.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces.lua")
PNC.FacilityJobs = {
    Seating = {
        RefreshLiveSeatTarget = function() return true end,
        RetryApproach = function() return true end,
        ResetPath = function() end,
        PositionAtSeatAnchor = function() return true end,
        EnterFurnitureSeat = function(_, _, runtime)
            runtime.seatEntered = true
            runtime.phase = "SEATED"
            return true
        end,
        EnterFloorSeat = BehaviorInternal.EnterFloorSeat,
        ClearFurnitureSeat = BehaviorInternal.ClearFurnitureSeat,
        RestorePosition = function() end,
    },
}

local RoamingSeat = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityJobs/PNC_RoamingSeatService.lua")
local record = {
    id = "roamer-floor-seat",
    alive = true,
    x = 10.5, y = 20.5, z = 0,
    runtime = {
        roaming = { phase = "idle", idleSince = 0 },
    },
    orderSpec = { kind = "roam" },
}

T.truthy(RoamingSeat.TryStart(
    record, body, record.orderSpec, record.runtime.roaming, now),
    "idle roamer starts a ground sitting fallback without a chair")
local state = record.runtime.roamingSeat
T.truthy(state and state.floorSeating,
    "roaming fallback records floor seating state")
T.equal(state.resourceKind, "floor_seating",
    "roaming fallback uses the floor seating resource kind")
T.equal(state.sceneId, "facility.living.sit",
    "roaming fallback uses the looping ground sitting scene")

body.x, body.y = state.x, state.y
T.truthy(RoamingSeat.Tick(record, body, now + 1),
    "roaming floor seat enters after reaching its target")
T.truthy(body.sitOnGround,
    "roaming floor seat sets the native ground-sitting flag")
T.falsy(body.sittingOnFurniture,
    "roaming floor seat does not set the furniture-sitting flag")
T.truthy(body.resting,
    "roaming floor seat sets the native resting flag")
T.equal(record.runtime.animationScene.id, "facility.living.sit",
    "roaming floor seat starts the looping ground scene")
T.equal(stabilized, 1,
    "roaming floor seat stabilizes the managed presentation body")

RoamingSeat.OnSceneStopped(
    record,
    body,
    { id = "facility.living.sit" },
    "interrupted:combat"
)
T.falsy(body.sitOnGround,
    "combat interruption clears the native ground-sitting flag")
T.falsy(body.resting,
    "combat interruption clears the native resting flag")
T.truthy(record.runtime.roamingSeat,
    "combat interruption preserves the roaming seat for resumption")

body.x, body.y = 10.5, 20.5
local guardRecord = {
    id = "guard-floor-seat",
    alive = true,
    x = 10.5, y = 20.5, z = 0,
    anchorX = 10.5, anchorY = 20.5, anchorZ = 0,
    runtime = {},
    orderSpec = {
        kind = "guard", x = 10.5, y = 20.5, z = 0,
    },
}
PNC.BehaviorCompanion = { Internal = {} }
T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_StaticOrders.lua")
T.truthy(PNC.BehaviorCompanion.Internal.TickGuardAnchor(
    guardRecord, body),
    "guard order starts the ground sitting fallback at its anchor")
local guardState = guardRecord.runtime.roamingSeat
T.truthy(guardState and guardState.floorSeating
        and guardState.ownerKind == "guard",
    "guard fallback records a persistent floor seating owner")
T.falsy(guardState.seatUntil,
    "guard floor seating does not use the roaming timeout")
body.x, body.y = guardState.x, guardState.y
T.truthy(RoamingSeat.Tick(guardRecord, body, now + 1),
    "guard floor seating did not enter after reaching its floor target")
T.truthy(RoamingSeat.OnSceneTick(
    guardRecord, body, { id = "facility.living.sit" }, now + 100000),
    "guard ground sitting remains active beyond the roaming dwell window")

-- Physical seating is the first-choice path. Put a valid chair behind the
-- same detector used by the live roaming service and make sure the service
-- does not fall through to the virtual floor slot.
local chairObject = {}
square.objects = { chairObject }
PNC.FacilityResources.GetDetector = function()
    return {
        matches = function(_, object) return object == chairObject end,
        describe = function(_, object)
            return {
                object = object,
                resourceKind = "seating_surface",
                role = "living.chair",
                resourceKey = "seat:nearby",
            }
        end,
    }
end
PNC.FacilityInteractionTargets = {
    ResolveResource = function(resource)
        return {
            {
                x = 10.5, y = 20.5, z = 0,
                sceneId = "ambient.roam.sitFurniture",
                resourceKey = resource.resourceKey,
                resourceKind = "seating_surface",
                seating = true, validSpot = true,
                seatDirection = "S", seatSide = "Front",
            },
        }
    end,
}
local chairRecord = {
    id = "roamer-chair-seat",
    alive = true,
    x = 10.5, y = 20.5, z = 0,
    runtime = {
        roaming = { phase = "idle", idleSince = 0 },
    },
    orderSpec = { kind = "roam" },
}
T.truthy(RoamingSeat.TryStart(
    chairRecord,
    body,
    chairRecord.orderSpec,
    chairRecord.runtime.roaming,
    now + 2000
), "roaming service did not select a valid nearby chair")
local chairState = chairRecord.runtime.roamingSeat
T.equal(chairState.resourceKind, "seating_surface",
    "a valid chair must win before the floor fallback")
T.falsy(chairState.floorSeating,
    "a valid chair selection must not be marked as floor seating")
T.equal(chairState.sceneId, "ambient.roam.sitFurniture",
    "a valid chair must use the furniture sitting scene")

return T.finish("pnc_roaming_floor_seat_smoke")
