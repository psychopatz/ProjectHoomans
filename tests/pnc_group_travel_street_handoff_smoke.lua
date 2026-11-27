local T = require "tests/support/test"
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Director/PNC_CoreGroupTraversalBridge.lua")

-- Verify seamless materialize/abstract street handoff for traveling SurvivorWorld groups.
local function assertEq(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEq") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function assertTrue(cond, label)
    if not cond then
        error((label or "assertTrue") .. " failed")
    end
end

local Bridge = require "PNC/Core/Director/PNC_CoreGroupTraversalBridge"
assertTrue(type(Bridge.ExtractRemainingWaypoints) == "function", "ExtractRemainingWaypoints exists")
assertTrue(type(Bridge.SyncMemberLivePosition) == "function", "SyncMemberLivePosition exists")

-- Build a multi-waypoint corridor group journey directly.
local group = {
    id = "grp_street_handoff_1",
    state = "TRAVELING",
    location = { id = "loc_a", x = 100, y = 100, z = 0 },
    targetLocation = { id = "loc_b", x = 400, y = 100, z = 0 },
    memberIds = { "npc_handoff_1" },
    journey = {
        schemaVersion = 1,
        journeyID = "j_handoff_1",
        groupID = "grp_street_handoff_1",
        state = "en_route",
        mode = "abstract",
        speed = 50,
        startAt = 10,
        lastAdvancedAt = 11,
        eta = 16,
        distanceTotal = 300,
        distanceTravelled = 50,
        progress = 50 / 300,
        segmentIndex = 1,
        segmentProgress = 0.5,
        x = 150,
        y = 100,
        z = 0,
        origin = { x = 100, y = 100, z = 0 },
        destination = { x = 400, y = 100, z = 0 },
        route = {
            points = {
                { x = 100, y = 100, z = 0, tag = "origin" },
                { x = 200, y = 100, z = 0, tag = "corridor" },
                { x = 300, y = 100, z = 0, tag = "corridor" },
                { x = 400, y = 100, z = 0, tag = "destination" },
            },
            cumulative = { 0, 100, 200, 300 },
            totalDistance = 300,
            provider = "corridor",
        },
    },
}

local waypoints = Bridge.ExtractRemainingWaypoints(group, 150, 100, 0)
assertTrue(type(waypoints) == "table" and #waypoints == 3, "3 remaining waypoints extracted")
assertEq(waypoints[1].x, 200, "first remaining waypoint x")
assertEq(waypoints[3].x, 400, "final waypoint x")

-- Stub PNC.AbstractGroups lookup for Service.OnMaterialized / OnAbstracted.
local prevAbstractGroups = PNC.AbstractGroups
PNC.AbstractGroups = {
    FindByMember = function(id)
        if id == "npc_handoff_1" then return group end
        return nil
    end,
    Get = function(id)
        if id == group.id then return group end
        return nil
    end,
}

local record = {
    id = "npc_handoff_1",
    name = "Street Traveler",
    alive = true,
    recruited = false,
    x = 150,
    y = 100,
    z = 0,
    runtime = {},
}

local fakeBodyX, fakeBodyY, fakeBodyZ = 150, 100, 0
local fakeBody = {
    getX = function() return fakeBodyX end,
    getY = function() return fakeBodyY end,
    getZ = function() return fakeBodyZ end,
}

local prevGetLiveZombie = PNC.Registry and PNC.Registry.GetLiveZombie
if PNC.Registry then
    PNC.Registry.GetLiveZombie = function(id)
        if id == "npc_handoff_1" then return fakeBody end
        return nil
    end
end

-- 1. Materialize hands remaining corridor waypoints to live travel.
PNC.Travel.Service.OnMaterialized(record)
assertTrue(type(record.travel) == "table", "ephemeral travel attached on materialize")
assertTrue(record.travel.ephemeralGroupHandoff == true, "marked ephemeralGroupHandoff")
assertEq(record.travel.handoffGroupId, group.id, "handoffGroupId matches")
assertTrue(type(record.orderSpec) == "table" and record.orderSpec.ephemeralDefault == true, "orderSpec marked ephemeralDefault")
local target = PNC.Travel.Service.GetCurrentTarget(record)
assertTrue(target ~= nil and target.x == 200 and target.y == 100, "live target points to next street waypoint")

-- 2. Simulate walking forward along the street to x=260, then abstract.
fakeBodyX = 260
PNC.Travel.Service.OnAbstracted(record, fakeBody)
assertEq(record.travel, nil, "ephemeral record.travel cleared on abstract")
assertEq(record.orderSpec, nil, "ephemeral travel order cleared on abstract")
assertTrue(group.journey.distanceTravelled >= 159.9 and group.journey.distanceTravelled <= 160.1,
    "group journey distanceTravelled advanced to ~160 (got " .. tostring(group.journey.distanceTravelled) .. ")")
assertEq(group.journey.x, 260, "group journey x synced to live body")

-- 3. Verify backward position does not rewind group journey.
local syncedBackward, backReason = Bridge.SyncMemberLivePosition(group, 120, 100, 0, 12)
assertEq(syncedBackward, false, "backward position rejected")
assertEq(backReason, "not_advanced", "backward reason is not_advanced")

if PNC.Registry then
    PNC.Registry.GetLiveZombie = prevGetLiveZombie
end
PNC.AbstractGroups = prevAbstractGroups
print("PASS: pnc_group_travel_street_handoff_smoke")
