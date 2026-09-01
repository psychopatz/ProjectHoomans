local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PNC = {
    Const = { ORDER_CAMP = "camp" },
    Core = {
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Network = { Internal = { SnapshotParts = {} } },
    Registry = { GetLiveZombie = function() return nil end },
    FacilityReservations = { ByResource = {
        ["seat:12:20:0:0"] = "reservation:other",
    } },
}

local Parts = T.load("ProjectHoomans", "shared",
    "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState.lua")

local record = {
    id = "npc:camp-overlay",
    x = 10, y = 20, z = 0,
    orderSpec = {
        kind = "camp", campId = "camp:test",
        x = 10, y = 20, z = 0, radius = 3, resourceRadius = 12,
    },
    runtime = {
        facilityActivity = {
            campActivity = true, capability = "living",
            resourceKey = "seat:12:20:0:0",
            resourceKind = "seating_surface", phase = "SEATED",
        },
    },
    campState = {
        campId = "camp:test", anchorX = 10, anchorY = 20, anchorZ = 0,
        campRadius = 3, resourceRadius = 12, resources = {
            {
                detectorId = "bed", resourceKind = "sleep_surface",
                resourceKey = "bed:10:20:0", x = 10.5, y = 20.5, z = 0,
                originX = 10, originY = 20, originZ = 0,
            },
            {
                detectorId = "faucet", resourceKind = "water_source",
                resourceKey = "faucet:11:20:0:1", x = 11.5, y = 20.5, z = 0,
                originX = 11, originY = 20, originZ = 0,
            },
            {
                detectorId = "seat", resourceKind = "seating_surface",
                resourceKey = "seat:12:20:0:0", role = "living.chair",
                x = 12.5, y = 20.5, z = 0,
                originX = 12, originY = 20, originZ = 0,
            },
        },
    },
}

local debug = Parts.BuildCampResourceDebugState(record)
T.equal(debug.resourceCount, 3, "camp overlay keeps all captured resources")
T.equal(debug.bedCount, 1, "camp overlay counts beds")
T.equal(debug.waterCount, 1, "camp overlay counts water sources")
T.equal(debug.seatingCount, 1, "camp overlay counts seats separately")
T.equal(debug.otherCount, 0, "camp overlay does not misclassify seats")
T.equal(debug.campRadius, 3, "camp overlay exposes the activity radius")
T.equal(debug.resourceRadius, 12,
    "camp overlay keeps the discovery radius separate")
T.equal(debug.facilities[1].category, "bed", "bed category is exposed")
T.equal(debug.facilities[1].supportedJobs[1], "sleep",
    "beds expose sleep as a supported job")
T.equal(debug.facilities[2].category, "water", "water category is exposed")
T.equal(debug.facilities[2].supportedJobs[1], "drink",
    "water sources expose drink as a supported job")
T.equal(debug.facilities[3].category, "seating", "seat category is exposed")
T.equal(debug.facilities[3].supportedJobs[1], "sit",
    "seats expose sit as a supported job")
T.truthy(debug.facilities[3].selected,
    "active camp resource is selected in the overlay")
T.truthy(debug.facilities[3].available,
    "active reservation remains available to its owner")

T.finish("pnc_camp_overlay_smoke")
