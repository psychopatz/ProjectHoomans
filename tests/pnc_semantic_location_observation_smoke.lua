local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsClientCode = function() return true end },
}

local candidate = {
    kind = "camp_site",
    scope = "room",
    siteID = "site-house",
    roomID = "room-hallway",
    roomType = "HALLWAY",
    label = "hallway",
    x = 10,
    y = 20,
    z = 0,
}
local enumerateCalls = 0
PNC = {
    Semantics = {
        ClientCampSiteHints = {
            Enumerate = function(context, options)
                enumerateCalls = enumerateCalls + 1
                T.equal(context.cell, "loaded-cell",
                    "location observation passes the loaded cell to the adapter")
                T.equal(options.maxRooms, 8,
                    "location observation keeps a bounded room cap")
                return { candidate }
            end,
        },
    },
}

local Observation = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticLocationObservation.lua"
)

local fixture = Observation.Observe({
    locationObservation = {
        schemaVersion = 1,
        kind = "semantic_location_observation",
        source = "harness_fixture",
        campSiteCandidates = { candidate },
    },
})
T.equal(fixture.source, "harness_fixture",
    "harness supplies the shared compact location observation contract")
T.equal(fixture.campSiteCandidates[1].roomID, "room-hallway",
    "fixture preserves stable primitive CampSite identity")

local generated = Observation.Observe({
    player = { x = 10, y = 20, z = 0 },
    selectionOrigin = { x = 10, y = 20, z = 0 },
    cell = "loaded-cell",
}, { maxCampSites = 8 })
T.equal(generated.source, "client_loaded_cell",
    "production observation is sourced from the loaded client cell")
T.equal(generated.campSiteCandidates[1].roomID, "room-hallway",
    "production observation projects the adapter primitives")
T.equal(enumerateCalls, 1,
    "location observation enumerates once for a bounded cache key")

Observation.ClearCache()
local refreshed = Observation.Observe({
    locationObservation = generated,
    player = { x = 10, y = 20, z = 0 },
    selectionOrigin = { x = 10, y = 20, z = 0 },
    cell = "loaded-cell",
}, { maxCampSites = 8 })
T.equal(refreshed.source, "client_loaded_cell",
    "generated observations are re-observed rather than treated as durable state")
T.equal(enumerateCalls, 2,
    "refresh reuses the adapter after a bounded observation expiry")

T.finish("pnc_semantic_location_observation_smoke")
