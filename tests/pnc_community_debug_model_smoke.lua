local CLIENT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual="
            .. tostring(actual))
    end
end

local function assertContains(value, expected, label)
    if not string.find(
        tostring(value),
        tostring(expected),
        1,
        true
    ) then
        error((label or "assertContains") .. ": missing "
            .. tostring(expected) .. " in " .. tostring(value))
    end
end

function getText(key) return key end

PNC = {}
dofile(
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
assertEqual(#communities, 1, "community item count")
assertContains(communities[1].detail, "settled/active",
    "community list detail")
local factions =
    PNC.CommunityDebugModel.BuildFactionItems(snapshot)
assertEqual(#factions, 1, "faction item count")
local npcs = PNC.CommunityDebugModel.BuildNPCItems(snapshot)
assertContains(npcs[1].detail, "guard", "NPC role detail")
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
assertContains(formatted, "Test Farm", "selected community")
assertContains(formatted, "1/12", "population capacity")
assertContains(formatted, "distance 1.0", "containment distance")
assertContains(formatted, "presence=7", "presence revision")
local denied = PNC.CommunityDebugModel.BuildRows(
    snapshot,
    false,
    "not_authorized"
)
assertEqual(#denied, 1, "unauthorized model row")
assertContains(denied[1].value, "not_authorized",
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
dofile(
    CLIENT
        .. "UI/Communities/PNC_CommunityDebugOverlay.lua"
)
assertEqual(PNC.CommunityDebugOverlay.Toggle(), true,
    "overlay toggles on")
assertEqual(requested, 1, "overlay requests diagnostic")
assertEqual(
    PNC.CommunityDebugOverlay.GetNPCDiagnostic(
        "npc_test"
    ).communityID,
    "community_test",
    "overlay diagnostic lookup"
)
assertEqual(PNC.CommunityDebugOverlay.Toggle(), false,
    "overlay toggles off")
PNC.MapDisplay = {
    AreBasesVisible = function() return true end,
}
assertEqual(PNC.CommunityDebugOverlay.Update(true), true,
    "map bases request diagnostics independently")
assertEqual(requested, 2,
    "map bases generated a sanitized request")

print("pnc_community_debug_model_smoke: PASS")
