-- Regression coverage for the live/abstract travel handoff:
-- a live journey that embodied locomotion cannot serve must move to the
-- elapsed-time abstract lane, and every escalation path must end the journey.
local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local PRESENCE = ROOT .. "Presence/PNC_Presence/"

local nowMs = 1000
local worldHour = 0
local records = {}
local orders = {}
local notifyCount = 0
local notifyArgs = nil
local warnCount = 0
local nearestByID = {}

getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do
        output[key] = deepCopy(item)
    end
    return output
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        ORDER_TRAVEL = "travel",
        ORDER_ROAM = "roam",
        ORDER_GUARD = "guard",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 6,
        TRAVEL_SCHEMA_VERSION = 2,
        TRAVEL_DEFAULT_ARRIVAL_ACTION = "roam",
        TRAVEL_ROUTE_MAX_POINTS = 128,
        TRAVEL_METADATA_MAX_DEPTH = 3,
        TRAVEL_METADATA_MAX_ENTRIES = 64,
        TRAVEL_SPEED_WALK_TILES_PER_HOUR = 300,
        TRAVEL_SPEED_RUN_TILES_PER_HOUR = 480,
        TRAVEL_ARRIVAL_RADIUS = 1,
        TRAVEL_POSITION_REFRESH_MS = 250,
        TRAVEL_LIVE_PROGRESS_TIMEOUT_MS = 12000,
        TRAVEL_LIVE_RECOVERY_COOLDOWN_MS = 5000,
        TRAVEL_LIVE_MAX_DISTANCE = 64,
        TRAVEL_LIVE_MAX_RECOVERIES = 3,
        TRAVEL_LIVE_MAX_ESCALATIONS = 2,
        TRAVEL_LIVE_ESCALATION_COOLDOWN_MS = 15000,
        TRAVEL_JOURNEY_STALL_TIMEOUT_MS = 45000,
        TRAVEL_JOURNEY_WATCHDOG_INTERVAL_MS = 5000,
        TRAVEL_JOURNEY_WATCHDOG_MAX_PER_PASS = 8,
        TRAVEL_JOURNEY_WATCHDOG_MAX_FAILURES = 2,
        MATERIALIZE_DISTANCE = 28,
        ABSTRACT_DISTANCE = 40,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        GenerateID = function(prefix)
            return tostring(prefix) .. ":fixture"
        end,
        DeepCopy = deepCopy,
        LogWarn = function() warnCount = warnCount + 1 end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        ForEach = function(callback)
            for id, record in pairs(records) do callback(record, id) end
        end,
        MarkDirty = function() end,
        GetLiveZombie = function() return nil end,
    },
    Network = {
        QueueRosterDelta = function() end,
    },
    Scheduler = {
        SLOT_MS = 50,
        Schedule = function() end,
    },
    SimulationClock = {
        Wake = function() end,
    },
    SpatialIndex = {
        UpdateNPC = function() end,
    },
    BehaviorCommon = {},
    TraversalQuery = {
        GetOccupancyReason = function() return nil end,
    },
    HomeDutyService = {
        OnTravelFailed = function(record, reason, journey)
            notifyCount = notifyCount + 1
            notifyArgs = { record = record, reason = reason, journey = journey }
            return true
        end,
    },
}

PNC.OrderSystem = {
    SetOrder = function(record, order)
        orders[#orders + 1] = order
        record.orderSpec = order
    end,
}

PNC.Presence = PNC.Presence or {}
PNC.Presence.Internal = PNC.Presence.Internal or {}
PNC.Presence.Internal.FindNearestPlayer = function(record)
    return nearestByID[record.id]
end

T.load(ROOT .. "Travel/PNC_Travel_Route.lua")
T.load(ROOT .. "Travel/PNC_Travel_Providers.lua")
T.load(ROOT .. "Travel/PNC_Travel_Arrivals.lua")
T.load(ROOT .. "Travel/PNC_Travel_Model.lua")
T.load(ROOT .. "Travel/PNC_Travel_Projection.lua")
T.load(ROOT .. "Travel/PNC_Travel_Service.lua")
T.load(PRESENCE .. "PNC_Presence_Decisions.lua")

local Service = PNC.Travel.Service
local Model = PNC.Travel.Model
local Presence = PNC.Presence

local function newRecord(id)
    local record = {
        id = id,
        name = id,
        x = 0,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "live",
        runtime = {},
    }
    records[id] = record
    return record
end

local function startJourney(record, distance, options)
    options = type(options) == "table" and options or {}
    local journey = T.truthy(Service.Start(record, {
        destination = { x = distance, y = 0, z = 0 },
        routeProvider = "direct",
        speedTilesPerWorldHour = 100,
        ownerMod = options.ownerMod,
        ownerRef = options.ownerRef,
        arrivalAction = options.arrivalAction,
    }), "journey start for " .. tostring(record.id))
    T.near(journey.distanceTotal, distance, 1, "route distance")
    return journey
end

-- 1. Distance policy ------------------------------------------------------
local longRecord = newRecord("handoff_long")
local longJourney = startJourney(longRecord, 200)
T.truthy(Model.LiveHandoffRequired(longJourney),
    "a 200 tile live journey must hand off")

local shortRecord = newRecord("handoff_short")
local shortJourney = startJourney(shortRecord, 40)
T.falsy(Model.LiveHandoffRequired(shortJourney),
    "a 40 tile live journey stays embodied")

shortJourney.controller = "abstract"
T.falsy(Model.LiveHandoffRequired(shortJourney),
    "an abstract journey never re-requests a handoff")
shortJourney.controller = "live"

shortJourney.handoffForced = true
T.truthy(Model.LiveHandoffRequired(shortJourney),
    "a forced handoff applies to a short journey")

shortJourney.handoffForced = nil
shortJourney.state = "arrived"
T.falsy(Model.LiveHandoffRequired(shortJourney),
    "a terminal journey never hands off")

-- The shipped default applies when the constant is missing.
local savedMax = PNC.Const.TRAVEL_LIVE_MAX_DISTANCE
PNC.Const.TRAVEL_LIVE_MAX_DISTANCE = nil
T.truthy(Model.LiveHandoffRequired(longJourney),
    "missing max distance falls back to the shipped default")
local shortFallback = newRecord("handoff_default_short")
local shortFallbackJourney = startJourney(shortFallback, 60)
T.falsy(Model.LiveHandoffRequired(shortFallbackJourney),
    "default max distance keeps a 60 tile journey embodied")
PNC.Const.TRAVEL_LIVE_MAX_DISTANCE = savedMax

-- 2. Presence handoff decision --------------------------------------------
longRecord.presenceState = "live"
nearestByID[longRecord.id] = { distSq = 30 * 30 }
T.truthy(Presence.ShouldAbstract(longRecord, nearestByID[longRecord.id]),
    "handoff abstracts beyond the materialize radius before the range rule")

nearestByID[longRecord.id] = { distSq = 10 * 10 }
T.falsy(Presence.ShouldAbstract(longRecord, nearestByID[longRecord.id]),
    "handoff keeps the body while a player is close enough to see it")

nearestByID[longRecord.id] = nil
T.truthy(Presence.ShouldAbstract(longRecord, nil),
    "handoff abstracts a long journey with no player nearby")

T.falsy(Presence.ShouldAbstract(shortRecord, { distSq = 20 * 20 }),
    "a short journey keeps the normal 40 tile range rule")

longRecord.runtime.forceLive = true
T.truthy(Presence.ShouldAbstract(longRecord, { distSq = 30 * 30 }),
    "a forced-live record still hands off a journey it cannot walk")
T.falsy(Presence.ShouldAbstract(longRecord, { distSq = 10 * 10 }),
    "a forced-live record keeps its body while a player is close")
nearestByID[longRecord.id] = nil
T.falsy(Presence.ShouldMaterialize(longRecord, nil),
    "a forced-live handoff journey is not pulled back with no player nearby")
T.truthy(Presence.ShouldMaterialize(longRecord, { distSq = 10 * 10 }),
    "a forced-live handoff journey materializes for a nearby player")
longRecord.runtime.forceLive = nil

longRecord.runtime.target = { kind = "zombie" }
T.falsy(Presence.ShouldAbstract(longRecord, { distSq = 30 * 30 }),
    "an unleased combat target still refuses abstraction")
longRecord.runtime.target = nil

-- 3. Terminal failure and owner notification ------------------------------
local homeRecord = newRecord("handoff_home")
homeRecord.presenceState = "live"
local homeJourney = startJourney(homeRecord, 200, {
    ownerMod = "ProjectHoomans",
    ownerRef = "colony_return_home",
    arrivalAction = { type = "colony_home", baseId = "base:1" },
})
T.truthy(homeRecord.orderSpec.kind == "travel",
    "the journey installed its travel order")
local failed, failReason = Service.FailJourney(
    homeRecord, "live_unreachable", "fixture")
T.truthy(failed, "fail journey reported success")
T.equal(failReason, "live_unreachable", "failure reason")
T.equal(homeJourney.state, "cancelled", "failed journey is terminal")
T.falsy(homeJourney.handoffForced, "failure clears the pending handoff")
T.equal(homeJourney.failureReason, "live_unreachable", "failure reason stored")
T.truthy(homeRecord.orderSpec == nil,
    "the travel order was released to the order system")
T.equal(notifyCount, 1, "the journey owner was notified once")
T.equal(notifyArgs.reason, "live_unreachable", "owner notification reason")
T.truthy(notifyArgs.journey == homeJourney, "owner notification journey")

local orphanRecord = newRecord("handoff_orphan")
orphanRecord.presenceState = "live"
startJourney(orphanRecord, 200, { ownerRef = "map_command" })
Service.FailJourney(orphanRecord, "owner_lost", "fixture")
T.equal(notifyCount, 1, "an unregistered owner is not notified")

-- A terminal journey never re-projects the record.
local beforeX = homeRecord.x
homeRecord.travel.state = "cancelled"
worldHour = worldHour + 10
Service.Advance(homeRecord, worldHour)
T.near(homeRecord.x, beforeX, 0.0001,
    "a cancelled journey must not move its record")

-- 4. Orphaned-journey watchdog -------------------------------------------
local watchedRecord = newRecord("handoff_watchdog")
watchedRecord.presenceState = "live"
local watchedJourney = startJourney(watchedRecord, 200, { ownerRef = "map_command" })
-- Simulate a travel order that was replaced by another order.
watchedRecord.orderSpec = { kind = "guard", x = 0, y = 0, z = 0 }
watchedJourney.liveLastProgressAt = nowMs - 60000
Service.LastLiveJourneyAuditAt = 0
T.equal(Service.AuditActiveLiveJourneys(nowMs, true), 1,
    "an orphaned live journey is escalated")
T.truthy(watchedJourney.handoffForced, "watchdog requests the handoff")
T.equal(watchedJourney.watchdogFailures, 1, "watchdog failure count")
T.truthy(watchedRecord.runtime.forcePresenceCheck == true,
    "watchdog wakes the presence pass")

nowMs = nowMs + 6000
Service.LastLiveJourneyAuditAt = 0
Service.AuditActiveLiveJourneys(nowMs, true)
T.equal(watchedJourney.state, "en_route", "second strike keeps the journey")
nowMs = nowMs + 6000
Service.LastLiveJourneyAuditAt = 0
Service.AuditActiveLiveJourneys(nowMs, true)
T.equal(watchedJourney.state, "cancelled",
    "repeated owner loss ends the journey")

-- An owned journey with recent progress is left alone.
local healthyRecord = newRecord("handoff_healthy")
healthyRecord.presenceState = "live"
local healthyJourney = startJourney(healthyRecord, 200)
healthyJourney.liveLastProgressAt = nowMs
Service.LastLiveJourneyAuditAt = 0
T.equal(Service.AuditActiveLiveJourneys(nowMs, true), 0,
    "a progressing owned journey is not escalated")

-- Abstract journeys are owned by the abstract sweep.
local abstractRecord = newRecord("handoff_abstract")
abstractRecord.presenceState = "abstract"
local abstractJourney = startJourney(abstractRecord, 200)
abstractJourney.liveLastProgressAt = nowMs - 60000
Service.LastLiveJourneyAuditAt = 0
T.equal(Service.AuditActiveLiveJourneys(nowMs, true), 0,
    "abstract journeys are skipped by the live watchdog")

-- 5. Live stall escalation ladder ----------------------------------------
local stallRecord = newRecord("handoff_stall")
stallRecord.presenceState = "live"
local stallJourney = startJourney(stallRecord, 200)
local stalledBody = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
nowMs = 1000
Service.CheckLiveProgress(stallRecord, stalledBody, nowMs)
T.equal(stallJourney.liveRecoveryCount or 0, 0,
    "the first live sample establishes the progress lease")
local escalations = 0
local step
for step = 1, 8 do
    nowMs = nowMs + 14000
    Service.CheckLiveProgress(stallRecord, stalledBody, nowMs)
    if stallJourney.handoffForced == true then escalations = escalations + 1 end
end
T.truthy((stallJourney.liveRecoveryCount or 0) > 3,
    "repeated stalls drive the recovery ladder")
T.truthy(escalations >= 1, "the ladder requested the abstract handoff")
T.truthy(warnCount >= 1, "escalation is observable in the log")

T.finish("pnc_travel_live_handoff_smoke")
