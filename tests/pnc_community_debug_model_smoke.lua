local T = require "tests/support/test"

local CLIENT =
    T.path("ProjectHoomans", "client", "PNC/")

function getText(key) return key end

PNC = {}
T.load(
    CLIENT
        .. "UI/Communities/PNC_CommunityDebugModel.lua"
)

local snapshot = {
    registry = {
        schemaVersion = 1,
        revision = 5,
        count = 1,
    },
    communities = {
        {
            id = "community_test",
            factionID = "faction_test",
            name = "Test Farm",
            mode = "settled",
            status = "active",
            home = { x = 10, y = 20, z = 0, radius = 35 },
            leaderNPCID = "npc_test",
            currentPopulation = 1,
            populationCapacity = 12,
            overcrowded = false,
            capacity = { beds = 8, storage = 120 },
            security = 35,
            morale = 2,
            supplies = {
                food = 10,
                medicine = 2,
                ammunition = 0,
                tools = 1,
                materials = 3,
            },
            revision = 4,
        },
    },
    factions = {
        {
            id = "faction_test",
            name = "Test Settlers",
            archetypeID = "settler",
            status = "active",
        },
    },
    roster = {
        {
            id = "npc_test",
            name = "Test NPC",
            communityID = "community_test",
            communityName = "Test Farm",
            communityRole = "guard",
        },
    },
    selectedCommunity = nil,
    selectedNPC = {
        id = "npc_test",
        name = "Test NPC",
        x = 11,
        y = 20,
        z = 0,
        communityID = "community_test",
        communityRole = "guard",
        insideHome = true,
        distanceFromHome = 1,
        affiliationRevision = 2,
        recordRevision = 3,
        presenceRevision = 7,
    },
    supplyCategories = {
        "food", "medicine", "ammunition", "tools", "materials",
    },
}
snapshot.selectedCommunity = snapshot.communities[1]

local communities =
    PNC.CommunityDebugModel.BuildCommunityItems(snapshot)
T.equal(#communities, 1, "community item count")
T.contains(communities[1].detail, "settled/active",
    "community list detail")
local factions =
    PNC.CommunityDebugModel.BuildFactionItems(snapshot)
T.equal(#factions, 1, "faction item count")

local mobileFactionSnapshot = {
    factions = {
        {
            id = "faction_mobile",
            name = "Road Raiders",
            archetypeID = "looter",
            status = "active",
            mobile = {
                active = true,
                controlMode = "strategic",
                pathMode = "player",
                target = {
                    kind = "player_base",
                    baseID = "base_player",
                },
            },
        },
    },
    selectedFactionID = "faction_mobile",
    mobileGroups = {},
}
mobileFactionSnapshot.mobileGroups[1] =
    mobileFactionSnapshot.factions[1]
local mobileItems =
    PNC.CommunityDebugModel.BuildFactionItems(
        mobileFactionSnapshot
    )
T.contains(mobileItems[1].detail,
    "mobile/strategic/player-base=base_player",
    "mobile faction list detail")
local mobileRows = PNC.CommunityDebugModel.BuildRows(
    mobileFactionSnapshot,
    true,
    nil
)
local mobileText = {}
for _, item in ipairs(mobileRows) do
    mobileText[#mobileText + 1] = item.label .. "=" .. item.value
end
T.contains(table.concat(mobileText, "\n"),
    "Mobile control=strategic / path=player",
    "mobile control debug row")
T.contains(table.concat(mobileText, "\n"),
    "Mobile types=looter:strategic",
    "mobile type debug row")
local npcs = PNC.CommunityDebugModel.BuildNPCItems(snapshot)
T.contains(npcs[1].detail, "guard", "NPC role detail")
local rows = PNC.CommunityDebugModel.BuildRows(
    snapshot,
    true,
    nil
)
local values = {}
for _, item in ipairs(rows) do
    values[#values + 1] = item.label .. "=" .. item.value
end
local formatted = table.concat(values, "\n")
T.contains(formatted, "Test Farm", "selected community")
T.contains(formatted, "1/12", "population capacity")
T.contains(formatted, "distance 1.0", "containment distance")
T.contains(formatted, "presence=7", "presence revision")
local denied = PNC.CommunityDebugModel.BuildRows(
    snapshot,
    false,
    "not_authorized"
)
T.equal(#denied, 1, "unauthorized model row")
T.contains(denied[1].value, "not_authorized",
    "authorization reason")

-- The overlay controller requests snapshots and toggles settings only; it has
-- no service or persistent registry reference.
local requested = 0
local visible = false
PNC.Core = { Now = function() return 2000 end }
PNC.Network = {
    ClientState = {
        communityDebug = {
            npcDiagnostics = {
                { id = "npc_test", communityID = "community_test" },
            },
        },
    },
}
PNC.Client = {
    RequestCommunityDebug = function()
        requested = requested + 1
        return true
    end,
}
PNC.Nameplates = {
    IsCommunityDebugEnabled = function() return visible end,
    SetCommunityDebugEnabled = function(value)
        visible = value == true
        return visible
    end,
    ToggleCommunityDebug = function()
        visible = not visible
        return visible
    end,
}
T.load(
    CLIENT
        .. "UI/Communities/PNC_CommunityDebugOverlay.lua"
)
T.equal(PNC.CommunityDebugOverlay.Toggle(), true,
    "overlay toggles on")
T.equal(requested, 1, "overlay requests diagnostic")
T.equal(
    PNC.CommunityDebugOverlay.GetNPCDiagnostic(
        "npc_test"
    ).communityID,
    "community_test",
    "overlay diagnostic lookup"
)
T.equal(PNC.CommunityDebugOverlay.Toggle(), false,
    "overlay toggles off")
PNC.MapDisplay = {
    AreBasesVisible = function() return true end,
}
T.equal(PNC.CommunityDebugOverlay.Update(true), true,
    "map bases request diagnostics independently")
T.equal(requested, 2,
    "map bases generated a sanitized request")
T.finish("pnc_community_debug_model_smoke")

T.finish("pnc_community_debug_model_smoke")
