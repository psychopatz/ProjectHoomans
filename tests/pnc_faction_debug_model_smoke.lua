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
    registrySchemaVersion = 2,
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
    },
    diplomacy = {
        {
            factionAID = "faction_player",
            factionBID = "faction_test",
            state = "war",
            reason = "test",
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
assertContains(rows, "Diplomacy faction_player", "war / test")
assertContains(rows, "Last action", "leader")

local unauthorized =
    PNC.FactionDebugModel.BuildRows(nil, false)
assertContains(
    unauthorized,
    "Access",
    "Admin/debug mode required"
)

print("pnc_faction_debug_model_smoke: ok")
