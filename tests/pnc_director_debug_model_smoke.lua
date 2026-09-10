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
    metrics = {}, groups = {
        {
            id = "agroup_mobile",
            factionId = "faction_mobile",
            groupType = "LOOTER",
            mission = "SCAVENGE",
            state = "TRAVELING",
            memberIds = { "npc_mobile" },
            location = { id = "aloc_origin", x = 10, y = 20, z = 0 },
            targetLocation = { id = "aloc_target" },
            mobile = {
                active = true,
                activity = "traveling_to_settlement",
                presence = "abstract",
                travel = {
                    departureDay = 2,
                    startedAt = 48,
                    destination = {
                        kind = "player_colony",
                        baseID = "base_player",
                        locationID = "aloc_target",
                        x = 110,
                        y = 120,
                        z = 0,
                    },
                },
            },
        },
    }, locations = {}, jobs = {},
    mobileCounts = {
        road_roaming = 0,
        street_roaming = 0,
        en_route = 1,
        arrival_pending = 0,
    },
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
local mobileItems = PNC.DirectorDebugModel.GroupItems(snapshot)
T.contains(mobileItems[1].label, "MOBILE / LOOTER",
    "mobile group list label")
T.contains(mobileItems[1].detail, "EN ROUTE",
    "mobile group lifecycle detail")
local rows = PNC.DirectorDebugModel.DetailRows(snapshot, nil, nil, sector,
    true, nil)
local output = {}
for _, item in ipairs(rows) do
    output[#output + 1] = item.label .. "=" .. item.value
end
local formatted = table.concat(output, "\n")
T.contains(formatted, "WORLD-SEED / 12345", "world seed row")
T.contains(formatted, "META_BUILDINGS_REGISTERED", "discovery row")
T.contains(formatted, "en_route=1", "mobile aggregate row")
T.contains(formatted, "priority=100.00", "starter queue row")
T.contains(formatted, "population_starter_attempt", "persistence row")
local mobileRows = PNC.DirectorDebugModel.DetailRows(
    snapshot, snapshot.groups[1], nil, nil, true, nil)
local mobileOutput = {}
for _, item in ipairs(mobileRows) do
    mobileOutput[#mobileOutput + 1] = item.label .. "=" .. item.value
end
T.contains(table.concat(mobileOutput, "\n"),
    "Mobile destination=player_colony / base_player",
    "mobile destination detail")
T.finish("pnc_director_debug_model_smoke")

T.finish("pnc_director_debug_model_smoke")
