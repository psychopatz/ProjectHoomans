local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "UI/Factions/PNC_FactionDebugModel.lua"

local function expectRowContaining(rows, label, fragment)
    for _, item in ipairs(rows) do
        if item.label == label
            and string.find(item.value, fragment, 1, true)
        then
            return
        end
    end
    error("missing row " .. label .. " containing " .. fragment)
end

PNC = {}
T.load(FILE)

local snapshot = {
    registrySchemaVersion = 3,
    registryRevision = 4,
    selectedFactionID = "faction_test",
    selectedNPCID = "npc_one",
    currentPlayerFactionID = "faction_player",
    factions = {
        {
            id = "faction_test",
            name = "Test Cooperative",
            archetypeID = "settler",
            archetypeLabel = "Settlement",
            status = "active",
        },
    },
    roster = {
        {
            id = "npc_one",
            name = "Alice",
            affiliation = {
                factionID = "faction_test",
                membershipStatus = "member",
                role = "medic",
                rank = "senior",
            },
        },
    },
    selectedFaction = {
        id = "faction_test",
        name = "Test Cooperative",
        archetypeID = "settler",
        archetypeLabel = "Settlement",
        status = "active",
        leaderNPCID = "npc_one",
        memberCount = 1,
        playerMemberCount = 0,
        revision = 3,
        createdAt = 10,
        archivedAt = 0,
        tags = { debugCreated = true },
        policy = {
            outsiderPolicy = "neutral",
            warThreshold = 70,
            peaceThreshold = 25,
        },
    },
    selectedTargetFaction = {
        id = "faction_player",
        name = "Player Survivors",
    },
    relationForward = {
        targetFactionID = "faction_player",
        state = "war",
        previousState = "hostile",
        standing = -50,
        trust = -30,
        fear = 10,
        grievance = 70,
        atWar = true,
        allied = false,
        truceUntil = 0,
        revision = 2,
        incidents = {},
    },
    relationReverse = {
        targetFactionID = "faction_test",
        state = "hostile",
        previousState = "neutral",
        standing = -20,
        trust = -10,
        fear = 25,
        grievance = 30,
        atWar = true,
        allied = false,
        truceUntil = 0,
        revision = 4,
        incidents = {},
    },
    intentPreview = {
        intent = "attack",
        reason = "factions_at_war",
        attackAllowed = true,
        pursueAllowed = true,
        commandable = false,
    },
    intentTrace = {
        selectedRule = "at_war",
        fallback = false,
    },
    diplomacy = {
        {
            targetFactionID = "faction_player",
            state = "war",
            atWar = true,
            standing = -50,
        },
    },
    members = {
        {
            npcID = "npc_one",
            name = "Alice",
            affiliation = {
                membershipStatus = "member",
                role = "medic",
                rank = "senior",
                joinedAt = 10,
                revision = 2,
            },
        },
    },
    actionResult = {
        ok = true,
        action = "leader",
        factionID = "faction_test",
        npcID = "npc_one",
    },
    activeAggregationEpisodes = {
        {
            key = "faction_source|faction_target|npc:attacker|npc:victim",
            state = "finalized_minor",
            hitCount = 1,
            totalDamage = 4,
            expiresAt = 12,
        },
    },
    reconciliationJobs = {},
    telemetry = {
        count = 1,
        maximum = 512,
        enabled = true,
        entries = {
            {
                sequence = 7,
                category = "aggregation",
                operation = "record_attack",
                result = "finalized_minor",
                reason = "incident_added",
            },
        },
    },
    validationResult = {
        ok = true,
        checks = 14,
        errors = {},
        warnings = {},
    },
}

local factionItems =
    PNC.FactionDebugModel.BuildFactionItems(snapshot)
local npcItems = PNC.FactionDebugModel.BuildNPCItems(snapshot)
T.truthy(#factionItems == 1, "one faction item")
T.truthy(factionItems[1].detail == "Settlement / active",
    "faction list formatting")
T.truthy(#npcItems == 1, "one NPC item")
T.truthy(npcItems[1].detail == "faction_test",
    "NPC affiliation formatting")

local provisionalSnapshot = {
    factions = snapshot.factions,
    currentPlayerDiplomacyFaction = {
        id = "faction_provisional",
        name = "Patrick Diplomacy",
        archetypeID = "settler",
        archetypeLabel = "Settlement",
        status = "active",
    },
}
local targetItems =
    PNC.FactionDebugModel.BuildTargetFactionItems(
        provisionalSnapshot
    )
T.truthy(#targetItems == 2,
    "provisional diplomacy identity is target-selectable")
T.truthy(targetItems[2].id == "faction_provisional",
    "provisional identity remains hidden from source list")

local rows =
    PNC.FactionDebugModel.BuildRows(snapshot, true)
expectRowContaining(rows, "Registry", "revision 4")
expectRowContaining(rows, "Your faction", "faction_player")
expectRowContaining(rows, "Faction", "Test Cooperative")
expectRowContaining(rows, "Archetype", "Settlement")
expectRowContaining(rows, "Leader", "npc_one")
expectRowContaining(rows, "Member Alice", "npc_one")
expectRowContaining(rows, "  affiliation", "member / medic / senior")
expectRowContaining(rows, "Diplomacy faction_player", "war / standing")
expectRowContaining(rows, "Source -> target", "war / standing")
expectRowContaining(rows, "Last action", "leader")
expectRowContaining(rows, "    full episode key",
    "faction_source|faction_target|npc:attacker|npc:victim")
expectRowContaining(rows, "#7 aggregation", "record_attack")
local shortened = PNC.FactionDebugModel.ShortenID(
    "faction_source|faction_target|npc:attacker|npc:victim",
    24
)
T.truthy(#shortened <= 24, "long ID shortened visually")
T.truthy(shortened ~=
    "faction_source|faction_target|npc:attacker|npc:victim",
    "short ID presentation differs")

local dashboard =
    PNC.FactionDebugModel.BuildDashboard(snapshot, true)
T.truthy(dashboard.status == "ready", "dashboard ready")
T.truthy(dashboard.source.name == "Test Cooperative",
    "dashboard source")
T.truthy(dashboard.forward.atWar == true, "dashboard war state")
T.truthy(dashboard.reverse.revision == 4,
    "dashboard preserves directed reverse relation")
T.truthy(dashboard.intent.attackAllowed == true,
    "dashboard intent")
T.truthy(dashboard.activeEpisodeCount == 1,
    "dashboard episode count")
T.truthy(dashboard.validation.ok == true,
    "dashboard invariant status")

local overview = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "overview"
)
expectRowContaining(overview, "Source faction", "Test Cooperative")
expectRowContaining(overview, "Diplomatic state", "war")
expectRowContaining(overview, "Invariant check", "PASS")

local mobileRows = PNC.FactionDebugModel.BuildRows({
    factions = {},
    selectedFaction = {
        id = "faction_mobile",
        name = "Road Raiders",
        archetypeID = "looter",
        archetypeLabel = "Looter Gang",
        status = "active",
        mobile = {
            active = true,
            controlMode = "strategic",
            pathMode = "player",
            activity = "traveling_to_settlement",
            groupState = "TRAVELING",
            presence = "abstract",
            travel = {
                kind = "settlement",
                startedAt = 24,
                departureDay = 1,
                destination = {
                    kind = "ai_settlement",
                    locationID = "aloc_settlement",
                    x = 80,
                    y = 90,
                    z = 0,
                },
            },
            strategicTarget = {
                kind = "player_base",
                baseID = "base_player",
                x = 10,
                y = 20,
                z = 0,
            },
            site = {
                id = "site_staging",
                home = { x = 1, y = 2, z = 0 },
            },
            nextMoveAt = 42,
            relocationCount = 1,
        },
    },
    currentPlayerFactionID = "faction_player",
}, true, nil)
expectRowContaining(mobileRows, "Group type", "control=strategic")
expectRowContaining(mobileRows, "Mobile state", "EN ROUTE")
expectRowContaining(mobileRows, "Mobile objective", "player base")
expectRowContaining(mobileRows, "Mobile target", "aloc_settlement")
expectRowContaining(mobileRows, "Settlement travel", "day 1")

local mobilePoolSnapshot = {
    currentPlayerFactionID = "faction_player",
    mobileGroups = {
        {
            id = "faction_road",
            name = "Street Nav Group",
            archetypeID = "trader",
            mobile = {
                active = true,
                activity = "street_roaming",
                ambient = { objective = "road" },
                presence = "abstract",
            },
        },
        {
            id = "faction_ai_travel",
            name = "AI Settlement Travelers",
            archetypeID = "refugee",
            mobile = {
                active = true,
                activity = "traveling_to_settlement",
                groupState = "TRAVELING",
                presence = "abstract",
                travel = {
                    destination = {
                        kind = "ai_settlement",
                        factionID = "faction_ai",
                        locationID = "ai_settlement",
                        x = 100,
                        y = 110,
                        z = 0,
                    },
                },
            },
        },
        {
            id = "faction_player_travel",
            name = "Player Colony Raiders",
            archetypeID = "looter",
            mobile = {
                active = true,
                activity = "traveling_to_settlement",
                groupState = "TRAVELING",
                presence = "abstract",
                travel = {
                    destination = {
                        kind = "player_colony",
                        factionID = "faction_player",
                        baseID = "base_player",
                        locationID = "player_colony",
                        x = 200,
                        y = 210,
                        z = 0,
                    },
                },
            },
        },
        {
            id = "faction_street",
            name = "Street Wanderers",
            archetypeID = "trader",
            mobile = {
                active = true,
                activity = "street_roaming",
                ambient = { objective = "shelter" },
                presence = "live",
            },
        },
    },
    selectedFaction = {
        id = "faction_player_travel",
        name = "Player Colony Raiders",
        mobile = {
            active = true,
            activity = "traveling_to_settlement",
            groupState = "TRAVELING",
            presence = "abstract",
            travel = {
                startedAt = 50,
                departureDay = 2,
                destination = {
                    kind = "player_colony",
                    factionID = "faction_player",
                    baseID = "base_player",
                    locationID = "player_colony",
                    x = 200,
                    y = 210,
                    z = 0,
                },
            },
        },
    },
}
local mobileItems = PNC.FactionDebugModel.BuildMobileItems(
    mobilePoolSnapshot)
T.equal(#mobileItems, 4, "mobile tab lists every mobile group")
T.equal(mobileItems[1].pool, "staging",
    "mobile tab starts with the road staging pool")
T.equal(mobileItems[3].pool, "player_colony",
    "mobile tab isolates groups traveling toward the player colony")
local poolCounts = PNC.FactionDebugModel.BuildMobilePoolCounts(
    mobilePoolSnapshot)
T.equal(poolCounts.staging, 1, "staging pool count")
T.equal(poolCounts.en_route, 2, "en-route pool count includes player target")
T.equal(poolCounts.player_colony, 1, "player colony pool count")
T.equal(poolCounts.ai_settlement, 1, "AI settlement pool count")
T.equal(poolCounts.street_roaming, 1, "street roaming pool count")
local playerFilterItems = PNC.FactionDebugModel.BuildMobileItems(
    mobilePoolSnapshot, "player_colony")
T.equal(#playerFilterItems, 1,
    "player colony filter only shows player-bound travelers")
T.equal(playerFilterItems[1].category, "player_colony",
    "player colony filter category")
local aiFilterItems = PNC.FactionDebugModel.BuildMobileItems(
    mobilePoolSnapshot, "ai_settlement")
T.equal(#aiFilterItems, 1,
    "AI settlement filter only shows AI-bound travelers")
T.equal(aiFilterItems[1].category, "ai_settlement",
    "AI settlement filter category")
local mobileTabRows = PNC.FactionDebugModel.BuildGUIRows(
    mobilePoolSnapshot, true, nil, "mobile")
expectRowContaining(mobileTabRows, "WAITING ON ROAD", "1 group")
expectRowContaining(mobileTabRows, "TRAVELING TO PLAYER COLONY", "1 group")
expectRowContaining(mobileTabRows, "TRAVELING TO AI SETTLEMENT", "1 group")
expectRowContaining(mobileTabRows, "Destination", "base_player")

local diplomacy = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "diplomacy"
)
expectRowContaining(diplomacy, "Source -> target state", "war")
expectRowContaining(diplomacy, "Target -> source state", "hostile")
expectRowContaining(diplomacy, "Intent rule", "at_war")

local members = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "members"
)
expectRowContaining(members, "Alice", "npc_one")
expectRowContaining(members, "Selected presence revision", "0")

local diagnostics = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "diagnostics"
)
expectRowContaining(diagnostics, "Invariant validation", "PASS")
expectRowContaining(diagnostics, "#7 aggregation", "record_attack")

local populationPending = PNC.FactionDebugModel.BuildGUIRows({
    factions = {}, roster = {}, populationDirector = {
        currentSettlements = 0, currentGroups = 0,
        pendingSettlements = 1, pendingGroups = 1,
        bootstrapPhase = "STARTER_IMMEDIATE",
        starter = { completed = false },
    },
}, true, nil, "overview")
expectRowContaining(populationPending, "Population starter", "PENDING")
expectRowContaining(populationPending, "Generated population", "pending=1/1")

local unauthorized =
    PNC.FactionDebugModel.BuildRows(nil, false)
expectRowContaining(
    unauthorized,
    "Access",
    "Admin/debug mode required"
)
T.finish("pnc_faction_debug_model_smoke")

T.finish("pnc_faction_debug_model_smoke")
