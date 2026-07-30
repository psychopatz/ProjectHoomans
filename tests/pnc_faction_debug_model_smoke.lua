local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "UI/Factions/PNC_FactionDebugModel.lua"

local function assertContains(rows, label, fragment)
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
dofile(FILE)

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
assert(#factionItems == 1, "one faction item")
assert(factionItems[1].detail == "Settlement / active",
    "faction list formatting")
assert(#npcItems == 1, "one NPC item")
assert(npcItems[1].detail == "faction_test",
    "NPC affiliation formatting")

local rows =
    PNC.FactionDebugModel.BuildRows(snapshot, true)
assertContains(rows, "Registry", "revision 4")
assertContains(rows, "Your faction", "faction_player")
assertContains(rows, "Faction", "Test Cooperative")
assertContains(rows, "Archetype", "Settlement")
assertContains(rows, "Leader", "npc_one")
assertContains(rows, "Member Alice", "npc_one")
assertContains(rows, "  affiliation", "member / medic / senior")
assertContains(rows, "Diplomacy faction_player", "war / standing")
assertContains(rows, "Source -> target", "war / standing")
assertContains(rows, "Last action", "leader")
assertContains(rows, "    full episode key",
    "faction_source|faction_target|npc:attacker|npc:victim")
assertContains(rows, "#7 aggregation", "record_attack")
local shortened = PNC.FactionDebugModel.ShortenID(
    "faction_source|faction_target|npc:attacker|npc:victim",
    24
)
assert(#shortened <= 24, "long ID shortened visually")
assert(shortened ~=
    "faction_source|faction_target|npc:attacker|npc:victim",
    "short ID presentation differs")

local dashboard =
    PNC.FactionDebugModel.BuildDashboard(snapshot, true)
assert(dashboard.status == "ready", "dashboard ready")
assert(dashboard.source.name == "Test Cooperative",
    "dashboard source")
assert(dashboard.forward.atWar == true, "dashboard war state")
assert(dashboard.reverse.revision == 4,
    "dashboard preserves directed reverse relation")
assert(dashboard.intent.attackAllowed == true,
    "dashboard intent")
assert(dashboard.activeEpisodeCount == 1,
    "dashboard episode count")
assert(dashboard.validation.ok == true,
    "dashboard invariant status")

local overview = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "overview"
)
assertContains(overview, "Source faction", "Test Cooperative")
assertContains(overview, "Diplomatic state", "war")
assertContains(overview, "Invariant check", "PASS")

local diplomacy = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "diplomacy"
)
assertContains(diplomacy, "Source -> target state", "war")
assertContains(diplomacy, "Target -> source state", "hostile")
assertContains(diplomacy, "Intent rule", "at_war")

local members = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "members"
)
assertContains(members, "Alice", "npc_one")
assertContains(members, "Selected presence revision", "0")

local diagnostics = PNC.FactionDebugModel.BuildGUIRows(
    snapshot, true, nil, "diagnostics"
)
assertContains(diagnostics, "Invariant validation", "PASS")
assertContains(diagnostics, "#7 aggregation", "record_attack")

local unauthorized =
    PNC.FactionDebugModel.BuildRows(nil, false)
assertContains(
    unauthorized,
    "Access",
    "Admin/debug mode required"
)

print("pnc_faction_debug_model_smoke: ok")
