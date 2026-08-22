local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local now = 1000
local nearbyZombieCount = 1
local recentAttacker
local moveCalls = {}
local combatCalls = 0
local clearAggroCalls = 0
local advanceCalls = 0
local tickLiveCalls = 0
local liveState = "en_route"

PNC = {
    Const = {
        ORDER_TRAVEL = "travel",
        PRESENCE_LIVE = "live",
        LIVE_TRAVEL_STEALTH_NEAR_RADIUS = 7,
        LIVE_TRAVEL_STEALTH_HORDE_RADIUS = 12,
        LIVE_TRAVEL_STEALTH_HORDE_COUNT = 3,
        LIVE_TRAVEL_STEALTH_SCAN_MS = 350,
        LIVE_TRAVEL_STEALTH_CLEAR_DELAY_MS = 2500,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(ax, ay, bx, by)
            return ((ax - bx) ^ 2) + ((ay - by) ^ 2)
        end,
        LogRecordDebug = function() end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Perception = {
        CountZombiesInFrame = function()
            return nearbyZombieCount
        end,
        ResolveRecentAttacker = function()
            return recentAttacker
        end,
    },
    ZombieAggro = {
        ClearForNPCBody = function()
            clearAggroCalls = clearAggroCalls + 1
        end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            record.runtime = record.runtime or {}
            record.runtime.target = nil
        end,
        MoveRecord = function(_, _, x, y, z, mode)
            moveCalls[#moveCalls + 1] = {
                x = x,
                y = y,
                z = z,
                mode = mode,
            }
        end,
        HaltMovement = function() end,
    },
    BehaviorCombat = {
        TickEngage = function(_, _, target)
            combatCalls = combatCalls + 1
            T.truthy(target == recentAttacker, "travel combat changed attacker")
        end,
    },
    Animation = {
        Apply = function() end,
    },
    NavigationRouter = {
        Clear = function() end,
    },
}

PNC.Travel = {
    Service = {
        Get = function(record)
            return record.travel
        end,
        WorldHour = function()
            return 10
        end,
        Advance = function()
            advanceCalls = advanceCalls + 1
        end,
        TickLive = function()
            tickLiveCalls = tickLiveCalls + 1
            return {
                x = 20,
                y = 30,
                z = 0,
                mode = "walk",
                stopDistance = 0.5,
            }, liveState
        end,
    },
}

T.load(ROOT .. "Stealth/PNC_Stealth.lua")
T.load(ROOT .. "Behaviors/PNC_Behavior_Travel.lua")

local zombie = {
    zombiesDontAttack = false,
    setZombiesDontAttack = function(self, value)
        self.zombiesDontAttack = value == true
    end,
}
local record = {
    id = "traveler",
    x = 10,
    y = 10,
    z = 0,
    presenceState = "live",
    runtime = {},
    travel = {
        journeyId = "journey-1",
        state = "en_route",
    },
}

T.truthy(PNC.BehaviorTravel.Tick(record, zombie), "live travel was not handled")
T.truthy(#moveCalls == 1 and moveCalls[1].mode == "sneak", "nearby zombie did not switch live travel to sneak")
T.truthy(zombie.zombiesDontAttack == true, "travel stealth did not protect the live body")
T.truthy(clearAggroCalls == 1, "travel stealth did not clear existing zombie aggro")

now = 1100
recentAttacker = {
    kind = "zombie",
    zombieId = "zed-1",
    x = 11,
    y = 10,
    z = 0,
    distSq = 1,
    visible = true,
}
local movesBeforeCombat = #moveCalls
local travelTicksBeforeCombat = tickLiveCalls
T.truthy(PNC.BehaviorTravel.Tick(record, zombie), "travel combat was not handled")
T.truthy(combatCalls == 1, "recent attacker did not preempt live travel")
T.truthy(#moveCalls == movesBeforeCombat, "journey movement continued during combat")
T.truthy(tickLiveCalls == travelTicksBeforeCombat, "journey advanced during combat")
T.truthy(record.runtime.target == recentAttacker, "recent attacker was not bound as combat target")
T.truthy(zombie.zombiesDontAttack == false, "combat did not restore zombie attack eligibility")

now = 7000
nearbyZombieCount = 0
recentAttacker = nil
T.truthy(PNC.BehaviorTravel.Tick(record, zombie), "travel did not resume")
T.truthy(#moveCalls == movesBeforeCombat + 1, "journey movement did not resume after combat")
T.truthy(moveCalls[#moveCalls].mode == "walk", "cleared threat left travel stuck in sneak")
T.truthy(record.runtime.target == nil, "combat target survived travel resume")

nearbyZombieCount = 1
now = 8000
T.truthy(PNC.BehaviorTravel.Tick(record, zombie), "second stealth travel tick failed")
T.truthy(zombie.zombiesDontAttack == true, "travel stealth was not re-entered")
liveState = "arrived"
now = 8400
T.truthy(PNC.BehaviorTravel.Tick(record, zombie), "arrival tick failed")
T.truthy(zombie.zombiesDontAttack == false, "arrival left temporary zombie protection enabled")

record.presenceState = "abstract"
now = 9000
local combatBeforeAbstract = combatCalls
local scansBeforeAbstract = clearAggroCalls
T.truthy(PNC.BehaviorTravel.Tick(record, zombie), "abstract travel was not handled")
T.truthy(advanceCalls == 1, "abstract travel did not use the abstract service")
T.truthy(combatCalls == combatBeforeAbstract, "abstract travel entered live combat")
T.truthy(clearAggroCalls == scansBeforeAbstract, "abstract travel ran live stealth logic")
T.finish("pnc_live_travel_threat_smoke")

T.finish("pnc_live_travel_threat_smoke")
