local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Behaviors/PNC_Behavior_Roaming.lua"

local now = 1000
local visible = true
local queryCount = 0
local moveCount = 0
local haltCount = 0
local transitionCount = 0
local arrivalAt
local player = {
    x = 20,
    y = 0,
    z = 0,
}

function player:getX() return self.x end
function player:getY() return self.y end
function player:getZ() return self.z end
function player:isAlive() return true end

PNC = {
    Const = {
        JOB_ROAM = "Roam",
        ORDER_ROAM = "roam",
        ORDER_HOSTILE_ROAM = "hostile_roam",
        ROAM_MODE_AREA = "area",
        ROAM_MODE_PLAYER = "player",
        ROAM_DEFAULT_RADIUS = 8,
        ROAM_TARGET_RADIUS = 12,
        ROAM_REACHED_DISTANCE = 0.8,
        ROAM_PLAYER_TARGET_REFRESH_MS = 1000,
        ROAM_PLAYER_ARRIVAL_DISTANCE = 3,
        ROAM_PLAYER_AREA_RADIUS = 24,
        ROAM_PAUSE_MIN_MS = 5000,
        ROAM_PAUSE_MAX_MS = 12000,
        ROAM_THREAT_MOVING_SCAN_MS = 250,
        ROAM_THREAT_IDLE_SCAN_MS = 500,
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        GetNearestPlayerPosition = function()
            queryCount = queryCount + 1
            return {
                player = player,
                x = player.x,
                y = player.y,
                z = player.z,
            }
        end,
    },
    Perception = {
        CanSeeWorldObject = function()
            return visible, visible and "clear" or "blocked"
        end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            record.runtime.target = nil
        end,
        HaltMovement = function()
            haltCount = haltCount + 1
        end,
        MoveRecord = function(record, _, x, y, z, mode, distance, reason)
            moveCount = moveCount + 1
            record.lastMove = {
                x = x,
                y = y,
                z = z,
                mode = mode,
                distance = distance,
                reason = reason,
            }
        end,
    },
    BehaviorTargeting = {
        ResolveRoamingEngageTarget = function()
            return nil
        end,
    },
    BehaviorCombat = {
        TickEngage = function()
            error("combat should not run without a target")
        end,
    },
    MobileGroupDirectorInternal = {
        WorldAge = function() return 42 end,
        EnterPlayerRoamArea = function(record, _, at)
            transitionCount = transitionCount + 1
            arrivalAt = at
            record.orderSpec.roamMode = "area"
            return true
        end,
    },
    BehaviorRegistry = {
        Register = function(_, tick)
            PNC._roamingTick = tick
        end,
    },
    JobSystem = {
        RegisterOrder = function() end,
    },
    OrderSystem = {
        RegisterNormalizer = function() end,
    },
}

ZombRandFloat = function() return 0 end
T.load(FILE)

local record = {
    id = "player_roamer",
    factionID = "faction_mobile",
    x = 0,
    y = 0,
    z = 0,
    anchorX = 0,
    anchorY = 0,
    anchorZ = 0,
    runtime = {},
    orderSpec = {
        kind = "roam",
        roamMode = "player",
        moveMode = "walk",
        reachedDistance = 1.5,
    },
}

T.truthy(PNC._roamingTick(record, {}))
T.equal(queryCount, 1, "initial player target query")
T.equal(moveCount, 1, "initial player approach move")
T.equal(record.lastMove.reason, "mobile_roam_to_player",
    "player approach reason")

now = 1100
player.x = 21
T.truthy(PNC._roamingTick(record, {}))
T.equal(queryCount, 1,
    "player target refresh is throttled between steering intervals")

now = 2100
T.truthy(PNC._roamingTick(record, {}))
T.equal(queryCount, 2, "player target refresh after throttle interval")

record.x = 20
record.runtime = {}
record.orderSpec.roamMode = "player"
now = 2200
visible = false
T.truthy(PNC._roamingTick(record, {}))
T.equal(transitionCount, 0,
    "hidden player does not end the approach phase")
T.equal(haltCount, 0, "hidden player still receives an approach move")

visible = true
T.truthy(PNC._roamingTick(record, {}))
T.equal(transitionCount, 1,
    "visible player at arrival distance enters area phase")
T.equal(arrivalAt, 42,
    "player arrival uses world-age hours for the persistent timer")
T.equal(moveCount, 4,
    "arrival transition does not issue another player path request")

T.finish("pnc_player_roam_smoke")
