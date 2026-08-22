local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/")

PNC = {}
T.load(FILE .. "UI/Director/PNC_DirectorDebugModel.lua")

local sector = { id = "psector_7_11", active = true, relevant = true,
    discovered = true, nearbyPlayers = 1, survivorCount = 0,
    groupCount = 0, desiredGroups = 5, settlementCount = 0,
    desiredSettlements = 1, candidatePool = 8, pendingGroups = 1,
    pendingSettlements = 1, groupCooldownRemaining = 0,
    settlementCooldownRemaining = 0,
    groupSuppressionReason = "QUEUED",
    settlementSuppressionReason = "QUEUED" }
local snapshot = {
    metrics = {}, groups = {}, locations = {}, jobs = {},
    population = {
        metrics = { enabled = true, paused = false, bootstrapPhase = "COMPLETE",
            players = 1, activeSectors = 1 },
        resolved = {}, sectors = { sector },
        starter = { pending = true, attempts = 1,
            populationSeed = 12345, worldSeed = "WORLD-SEED",
            lastRun = { at = 2.75, sectorsQueried = 1, discovered = 8,
                selectedSectorId = sector.id, queued = true,
                reason = "queued" } },
        candidateMetrics = { discovered = 8, evaluated = 4, rejected = 1,
            metaQueries = 1, metaMatched = 20, metaInspected = 20,
            starterDiscovered = 8 },
        selectedDiscovery = { reason = "META_BUILDINGS_REGISTERED",
            matched = 20, inspected = 20, found = 8, residential = 7,
            seed = 555 },
        store = { revision = 12, dirty = true,
            lastMutationReason = "population_starter_attempt" },
        queue = { { kind = "SETTLEMENT", sectorId = sector.id,
            priority = 100, attempts = 0, remainingHours = 24,
            source = "WORLD_POPULATION_BOOTSTRAP" } },
        reservations = {}, candidateEvaluations = {}, history = {}, log = {},
    },
}

local sectors = PNC.DirectorDebugModel.SectorItems(snapshot)
T.truthy(#sectors == 1, "sector list count")
T.contains(sectors[1].detail, "sites 8", "sector candidate detail")
local rows = PNC.DirectorDebugModel.DetailRows(snapshot, nil, nil, sector,
    true, nil)
local output = {}
for _, item in ipairs(rows) do
    output[#output + 1] = item.label .. "=" .. item.value
end
local formatted = table.concat(output, "\n")
T.contains(formatted, "WORLD-SEED / 12345", "world seed row")
T.contains(formatted, "META_BUILDINGS_REGISTERED", "discovery row")
T.contains(formatted, "priority=100.00", "starter queue row")
T.contains(formatted, "population_starter_attempt", "persistence row")
T.finish("pnc_director_debug_model_smoke")

T.finish("pnc_director_debug_model_smoke")
