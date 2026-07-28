local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertNear(actual, expected, tolerance, label)
    if math.abs((tonumber(actual) or 0) - expected) > tolerance then
        error((label or "assertNear") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local worldHour = 0
local nowMs = 1000
local records = {}
local dirtyCount = 0
local rosterCount = 0
local arrivalCount = 0

getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        ORDER_TRAVEL = "travel",
        ORDER_ROAM = "roam",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 6,
        TRAVEL_SCHEMA_VERSION = 2,
        TRAVEL_DEFAULT_ARRIVAL_ACTION = "roam",
        TRAVEL_ROUTE_MAX_POINTS = 128,
        TRAVEL_METADATA_MAX_DEPTH = 3,
        TRAVEL_METADATA_MAX_ENTRIES = 64,
        TRAVEL_SPEED_WALK_TILES_PER_HOUR = 300,
        TRAVEL_SPEED_RUN_TILES_PER_HOUR = 480,
        TRAVEL_SPEED_VEHICLE_TILES_PER_HOUR = 1500,
        TRAVEL_ARRIVAL_RADIUS = 1,
        TRAVEL_POSITION_REFRESH_MS = 250,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        GenerateID = function(prefix)
            return tostring(prefix) .. ":fixture"
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        ForEach = function(callback)
            for id, record in pairs(records) do callback(record, id) end
        end,
        MarkDirty = function() dirtyCount = dirtyCount + 1 end,
        GetLiveZombie = function() return nil end,
    },
    Network = {
        QueueRosterDelta = function() rosterCount = rosterCount + 1 end,
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
}

dofile(ROOT .. "Travel/PNC_Travel_Route.lua")
dofile(ROOT .. "Travel/PNC_Travel_Providers.lua")
dofile(ROOT .. "Travel/PNC_Travel_Arrivals.lua")
dofile(ROOT .. "Travel/PNC_Travel_Model.lua")
dofile(ROOT .. "Travel/PNC_Travel_Projection.lua")
dofile(ROOT .. "Travel/PNC_Travel_Service.lua")

PNC.Travel.Service.RegisterListener("arrived", function()
    arrivalCount = arrivalCount + 1
end)

local waypointRecord = {
    id = "waypoint",
    name = "Waypoint Walker",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "abstract",
    runtime = {},
}
records[waypointRecord.id] = waypointRecord

local journey = assert(PNC.Travel.Service.Start(waypointRecord, {
    journeyId = "journey:waypoint",
    destination = { x = 200, y = 0, z = 0 },
    route = {
        { x = 100, y = 0, z = 0, waitWorldHours = 0.5, tag = "checkpoint" },
        { x = 200, y = 0, z = 0 },
    },
    speedTilesPerWorldHour = 100,
    ownerMod = "TravelFixture",
    ownerRef = "mission:42",
    metadata = { purpose = "trade", nested = { safe = true } },
}))
assertNear(journey.etaWorldHour, 2.5, 0.0001, "initial ETA includes wait")
assert(waypointRecord.orderSpec.kind == "travel", "travel order was not installed")

worldHour = 1.25
PNC.Travel.Service.Advance(waypointRecord, worldHour)
assert(journey.state == "waiting", "waypoint wait state was not entered")
assertNear(waypointRecord.x, 100, 0.001, "wait waypoint x")
assertNear(journey.waitRemainingWorldHours, 0.25, 0.001,
    "wait time did not consume elapsed world time")

worldHour = 1.75
PNC.Travel.Service.Advance(waypointRecord, worldHour)
assert(journey.state == "en_route", "journey did not leave waypoint wait")
assertNear(waypointRecord.x, 125, 0.001, "post-wait travel position")

assert(PNC.Travel.Service.Pause(waypointRecord, "fixture_pause"))
worldHour = 9
local paused = PNC.Travel.Service.GetProgress(waypointRecord, worldHour)
assertNear(paused.x, 125, 0.001, "paused journey moved")
assert(paused.state == "paused", "paused projection changed state")
assert(PNC.Travel.Service.Resume(waypointRecord, "fixture_resume"))
worldHour = 9.5
PNC.Travel.Service.Advance(waypointRecord, worldHour)
assertNear(waypointRecord.x, 175, 0.001, "resumed journey progress")

local retargeted = assert(PNC.Travel.Service.Retarget(waypointRecord, {
    destination = { x = 275, y = 0, z = 0 },
    durationWorldHours = 1,
}))
assert(retargeted.journeyId == "journey:waypoint",
    "retarget changed the stable journey id")
assert(retargeted.routeVersion == 2, "retarget did not revise route geometry")
assertNear(retargeted.origin.x, 175, 0.001, "retarget origin")
assertNear(retargeted.speedTilesPerWorldHour, 100, 0.001,
    "duration-derived speed")

-- A route provider is the extension seam for roads, threat avoidance, jobs,
-- trading routes, and other future planners.
assert(PNC.Travel.Providers.RegisterRouteProvider("fixture_detour",
    function(_, _, origin, destination)
        return {
            origin,
            { x = origin.x, y = 50, z = origin.z, tag = "detour" },
            destination,
        }
    end
))
local providerRecord = {
    id = "provider",
    name = "Provider Walker",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "abstract",
    runtime = {},
}
records[providerRecord.id] = providerRecord
local providerJourney = assert(PNC.Travel.Service.Start(providerRecord, {
    journeyId = "journey:provider",
    destination = { x = 100, y = 0, z = 0 },
    routeProvider = "fixture_detour",
    speedProfile = "walk",
}))
assert(#providerJourney.route.points == 3,
    "custom route provider geometry was not retained")
assert(providerJourney.routeProvider == "fixture_detour",
    "custom route provider id was lost")
assert(PNC.Travel.Providers.RegisterRouteProvider("fixture_broken",
    function()
        error("fixture provider failure")
    end
))
local fallbackRoute, fallbackProvider = PNC.Travel.Providers.ResolveRoute(
    providerRecord,
    {
        origin = { x = 0, y = 0, z = 0 },
        destination = { x = 10, y = 0, z = 0 },
        routeProvider = "fixture_broken",
    }
)
assert(fallbackProvider == "direct" and #fallbackRoute.points == 2,
    "failed route provider did not degrade to a direct route")

local handoffRecord = {
    id = "handoff",
    name = "Handoff Walker",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "live",
    runtime = {},
}
records[handoffRecord.id] = handoffRecord
worldHour = 0
local handoffJourney = assert(PNC.Travel.Service.Start(handoffRecord, {
    journeyId = "journey:handoff",
    destination = { x = 100, y = 0, z = 0 },
    speedTilesPerWorldHour = 100,
}))
local body = {
    getX = function() return 25 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
worldHour = 0.25
PNC.Travel.Service.SyncLivePosition(
    handoffRecord,
    body,
    worldHour
)
assertNear(handoffJourney.distanceTravelled, 25, 0.001,
    "live body progress did not project onto the route")
PNC.Travel.Service.OnAbstracted(handoffRecord, body)
handoffRecord.presenceState = "abstract"
worldHour = 0.75
PNC.Travel.Service.Advance(handoffRecord, worldHour)
assertNear(handoffRecord.x, 75, 0.001,
    "abstract handoff did not continue from the live position")
handoffRecord.presenceState = "live"
PNC.Travel.Service.OnMaterialized(handoffRecord)
assert(handoffJourney.controller == "live",
    "materialization did not return journey control to the live body")
assertNear(handoffRecord.x, 75, 0.001,
    "materialization handoff changed the canonical position")

local liveArrivalRecord = {
    id = "live-arrival",
    name = "Live Arrival",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "live",
    runtime = {},
}
records[liveArrivalRecord.id] = liveArrivalRecord
worldHour = 0
local liveArrivalJourney = assert(PNC.Travel.Service.Start(
    liveArrivalRecord,
    {
        journeyId = "journey:live-arrival",
        destination = { x = 10, y = 5, z = 0 },
        arrivalAction = {
            type = "roam",
            radius = 9,
        },
    }
))
local arrivedBody = {
    getX = function() return 10 end,
    getY = function() return 5 end,
    getZ = function() return 0 end,
}
PNC.Travel.Service.TickLive(liveArrivalRecord, arrivedBody, worldHour)
assert(liveArrivalJourney.state == "arrived",
    "live journey did not reach arrival state")
assert(liveArrivalJourney.arrivalHandled == true
    and liveArrivalJourney.arrivalHandledBy == "roam",
    "live journey arrival action was not handled")
assert(liveArrivalRecord.orderSpec.kind == "roam",
    "live arrival did not switch to roaming")
assertNear(liveArrivalRecord.orderSpec.x, 10, 0.001,
    "live arrival roam center x")
assertNear(liveArrivalRecord.orderSpec.y, 5, 0.001,
    "live arrival roam center y")
assertNear(liveArrivalRecord.orderSpec.radius, 9, 0.001,
    "live arrival roam radius")

local customArrivalCalls = 0
local customAction
assert(PNC.Travel.Arrivals.RegisterHandler("trading",
    function(record, _, action)
        customArrivalCalls = customArrivalCalls + 1
        customAction = action
        record.orderSpec = {
            kind = "trading",
            marketID = action.marketID,
        }
        return true, "trading_started"
    end
), "custom arrival handler did not register")
local tradingRecord = {
    id = "trading-arrival",
    name = "Trading Arrival",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "abstract",
    runtime = {},
}
records[tradingRecord.id] = tradingRecord
worldHour = 0
local tradingJourney = assert(PNC.Travel.Service.Start(tradingRecord, {
    journeyId = "journey:trading-arrival",
    destination = { x = 10, y = 0, z = 0 },
    speedTilesPerWorldHour = 10,
    arrivalAction = {
        type = "trading",
        marketID = "market:west-point",
    },
}))
worldHour = 1
PNC.Travel.Service.Advance(tradingRecord, worldHour)
assert(customArrivalCalls == 1,
    "custom arrival handler was not called exactly once")
assert(customAction.marketID == "market:west-point",
    "custom arrival action lost its parameters")
assert(tradingRecord.orderSpec.kind == "trading"
    and tradingRecord.orderSpec.marketID == "market:west-point",
    "custom arrival handler could not install its behavior")
PNC.Travel.Service.Advance(tradingRecord, worldHour + 1)
assert(customArrivalCalls == 1,
    "completed arrival action was dispatched twice")
local tradingSummary = PNC.Travel.Model.BuildSummary(
    tradingJourney,
    true
)
local restoredTrading = PNC.Travel.Model.Normalize(
    tradingSummary,
    tradingRecord,
    worldHour
)
assert(restoredTrading.arrivalAction.type == "trading"
    and restoredTrading.arrivalAction.marketID == "market:west-point"
    and restoredTrading.arrivalHandled == true,
    "arrival action did not survive journey persistence")

-- Population-scale abstraction: all 100 records advance in one O(N) refresh,
-- without creating or pathing any live engine bodies.
records = {}
for i = 1, 100 do
    local record = {
        id = "scale:" .. tostring(i),
        name = "Scale Traveller " .. tostring(i),
        x = i,
        y = i * 2,
        z = 0,
        alive = true,
        presenceState = "abstract",
        runtime = {},
    }
    records[record.id] = record
    assert(PNC.Travel.Service.Start(record, {
        journeyId = "journey:scale:" .. tostring(i),
        destination = { x = i + 300, y = i * 2, z = 0 },
        durationWorldHours = 1,
    }))
end
rosterCount = 0
worldHour = 10
for _, record in pairs(records) do
    record.travel.lastAdvancedWorldHour = 10
    record.travel.departedWorldHour = 10
end
nowMs = 2000
worldHour = 10.5
assert(PNC.Travel.Service.RefreshAbstractPositions(nowMs, true) == 100,
    "100-NPC abstract refresh count")
assert(rosterCount == 0,
    "abstract interpolation emitted per-step roster traffic")
for _, record in pairs(records) do
    assertNear(record.travel.distanceTravelled, 150, 0.001,
        "100-NPC half-route projection")
end
nowMs = 3000
worldHour = 11
assert(PNC.Travel.Service.RefreshAbstractPositions(nowMs, true) == 100,
    "100-NPC arrival refresh count")
assert(rosterCount == 100,
    "arrival state changes were not replicated once per traveller")
for _, record in pairs(records) do
    assert(record.travel.state == "arrived",
        "abstract traveller did not arrive coherently")
    assert(record.orderSpec.kind == "roam",
        "abstract arrival did not switch to default roaming")
    assertNear(record.orderSpec.radius, 6, 0.001,
        "abstract default roam radius")
end

assert(dirtyCount > 0 and rosterCount > 0,
    "travel changes were not connected to persistence/network dirtiness")
assert(arrivalCount >= 100, "arrival events were not emitted")

print("pnc_travel_service_smoke: ok")
