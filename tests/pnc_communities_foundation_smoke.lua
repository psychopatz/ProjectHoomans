local SHARED =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual="
            .. tostring(actual))
    end
end

local function assertTrue(value, label)
    assertEqual(value == true, true, label)
end

local function assertFalse(value, label)
    assertEqual(value == false, true, label)
end

local function tableSize(value)
    local count = 0
    for _, _ in pairs(value or {}) do
        count = count + 1
    end
    return count
end

local function assertSaveSafe(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "string"
        or kind == "number" or kind == "boolean"
    then
        if kind == "number"
            and (
                value ~= value
                or value == math.huge
                or value == -math.huge
            )
        then
            error("non-finite community value")
        end
        return
    end
    if kind ~= "table" or getmetatable(value) ~= nil then
        error("unsafe community value: " .. kind)
    end
    seen = seen or {}
    if seen[value] then error("community persistence cycle") end
    seen[value] = true
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe community key")
        end
        assertSaveSafe(child, seen)
    end
    seen[value] = nil
end

local globalData = {}
local worldHour = 200

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return worldHour * 3600000 end
function ZombRand() return 9 end
function getGameTime()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

PNC = {}
dofile(SHARED .. "Base/PNC_Core.lua")
dofile(SHARED .. "Factions/PNC_FactionConstants.lua")
dofile(SHARED .. "Factions/PNC_FactionArchetypes.lua")
dofile(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
dofile(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
dofile(SHARED .. "Communities/PNC_CommunityConstants.lua")
dofile(SHARED .. "Communities/PNC_CommunityProfiles.lua")
dofile(SHARED .. "Communities/PNC_CommunityMath.lua")
dofile(SHARED .. "Communities/PNC_CommunityTypes.lua")
dofile(SHARED .. "Factions/PNC_FactionTypes.lua")

local FactionTypes = PNC.FactionTypes
local CommunityTypes = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath

local dirty = {}
PNC.Registry = { Data = {} }
function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record)
    record.recordRevision =
        (tonumber(record.recordRevision) or 0) + 1
    dirty[record.id] = true
    return true
end

local function newNPC(id)
    local record = {
        id = id,
        name = id,
        alive = true,
        faction = "colonist",
        affiliation = FactionTypes.NewAffiliation(),
        recordRevision = 0,
        presenceRevision = 7,
        social = {
            revision = 8,
            relationships = {
                keep = { revision = 9 },
            },
            conduct = { revision = 10 },
        },
        x = 100,
        y = 100,
        z = 0,
    }
    PNC.Registry.Data[id] = record
    return record
end

-- Pure defaults, normalization, bounds, and geometry.
local empty = CommunityTypes.NewRegistry()
assertEqual(empty.schemaVersion, 1, "community registry schema")
assertEqual(empty.revision, 0, "community registry revision")
assertEqual(tableSize(empty.byID), 0, "community registry empty")
local settledDefaults =
    CommunityTypes.BuildCreationDefaults("settled", "settler")
assertEqual(settledDefaults.radius, 35, "settled radius")
assertEqual(settledDefaults.capacity.population, 12,
    "settled population capacity")
assertEqual(settledDefaults.security, 35,
    "settler security adjustment")
assertEqual(settledDefaults.capacity.storage, 120,
    "settler storage adjustment")
local campedDefaults =
    CommunityTypes.BuildCreationDefaults("camped", "refugee")
assertEqual(campedDefaults.radius, 15, "camp radius")
assertEqual(campedDefaults.capacity.population, 8,
    "camp population capacity")
assertEqual(campedDefaults.morale, -10,
    "refugee camp morale adjustment")

local normalized = CommunityTypes.NewCommunity({
    id = "community_bounds",
    factionID = "faction_bounds",
    name = "Bounds",
    mode = "settled",
    status = "invalid",
    home = {
        x = 10,
        y = 20,
        z = 99,
        radius = 999,
    },
    capacity = {
        population = 999,
        beds = -5,
        storage = 999999,
    },
    security = 999,
    morale = -999,
    supplies = { food = 99999999, tools = -1 },
})
assertEqual(normalized.status, "inactive",
    "invalid status normalized")
assertEqual(normalized.home.z, 32, "z clamps")
assertEqual(normalized.home.radius, 200, "radius clamps")
assertEqual(normalized.capacity.population, 500,
    "population capacity clamps")
assertEqual(normalized.capacity.beds, 0, "beds clamp")
assertEqual(normalized.capacity.storage, 100000,
    "storage clamps")
assertEqual(normalized.security, 100, "security clamps")
assertEqual(normalized.morale, -100, "morale clamps")
assertEqual(normalized.supplies.food, 1000000,
    "supply upper clamp")
assertEqual(normalized.supplies.tools, 0,
    "supply lower clamp")
local area = CommunityTypes.NewCommunity({
    id = "community_area",
    factionID = "faction_area",
    name = "Area",
    mode = "settled",
    status = "active",
    home = { x = 0, y = 0, z = 0, radius = 10 },
})
assertEqual(
    CommunityMath.GetDistanceFromHome(area, 6, 8, 0),
    10,
    "distance helper"
)
assertTrue(
    CommunityMath.IsInsideHomeArea(area, 6, 8, 0),
    "inside home"
)
assertFalse(
    CommunityMath.IsInsideHomeArea(area, 0, 0, 1),
    "different floor outside"
)
assertTrue(CommunityTypes.AreEqual(
    CommunityTypes.NormalizeRegistry(
        CommunityTypes.NormalizeRegistry({ byID = {} })
    ),
    CommunityTypes.NormalizeRegistry({ byID = {} })
), "normalization idempotent")

dofile(SERVER .. "PNC_FactionService.lua")
dofile(SERVER .. "PNC_CommunityService.lua")
dofile(SERVER .. "PNC_CommunityValidation.lua")
PNC.Factions.Load()
PNC.Communities.Load()

local factionIDs = {
    "faction_settlers",
    "faction_refugees",
}
local factionIndex = 0
PNC.Factions.IDGenerator = function()
    factionIndex = factionIndex + 1
    return factionIDs[factionIndex]
end
local ok, _, settlers = PNC.Factions.Create({
    name = "Settlers",
    archetypeID = "settler",
    createdAt = worldHour,
})
assertTrue(ok, "create settler faction")
local _, _, refugees = PNC.Factions.Create({
    name = "Refugees",
    archetypeID = "refugee",
    createdAt = worldHour,
})

-- IDs are authority-generated, collision checked, and never name-derived.
local communityIDs = {
    "community_collision",
    "community_collision",
    "community_farm",
    "community_camp",
}
local communityIndex = 0
PNC.Communities.IDGenerator = function()
    communityIndex = communityIndex + 1
    return communityIDs[communityIndex]
        or "community_extra_" .. tostring(communityIndex)
end
ok, _, area = PNC.Communities.Create({
    factionID = settlers.id,
    name = "Riverside Farm",
    mode = "settled",
    home = { x = 100, y = 100, z = 0 },
    createdAt = worldHour,
})
assertTrue(ok, "create settlement")
assertEqual(area.id, "community_collision",
    "first community ID")
ok, _, area = PNC.Communities.Create({
    factionID = settlers.id,
    name = "Hill Farm",
    mode = "settled",
    home = { x = 140, y = 100, z = 0 },
})
assertTrue(ok, "same faction second community")
assertEqual(area.id, "community_farm",
    "community collision skipped")
local farmID = area.id
local _, _, camp = PNC.Communities.Create({
    factionID = refugees.id,
    name = "Highway Camp",
    mode = "camped",
    home = { x = 300, y = 300, z = 0 },
})
local campID = camp.id
assertEqual(#PNC.Communities.GetForFaction(settlers.id), 2,
    "multiple communities per faction")
assertEqual(#PNC.Communities.GetForFaction(refugees.id), 1,
    "refugee camp indexed")
assertFalse(PNC.Communities.Create({
    factionID = "faction_missing",
    name = "Invalid",
    mode = "settled",
    home = { x = 0, y = 0, z = 0 },
}), "valid faction required")
assertFalse(PNC.Communities.Create({
    factionID = settlers.id,
    name = "Invalid",
    mode = "mobile",
    home = { x = 0, y = 0, z = 0 },
}), "invalid mode rejected")

-- Membership requires matching faction and remains independent of other data.
local alice = newNPC("npc_alice")
local bob = newNPC("npc_bob")
local outsider = newNPC("npc_outsider")
assertTrue(PNC.Factions.AddNPC(settlers.id, alice.id, {}),
    "alice joins settlers")
assertTrue(PNC.Factions.AddNPC(settlers.id, bob.id, {}),
    "bob joins settlers")
assertTrue(PNC.Factions.AddNPC(refugees.id, outsider.id, {}),
    "outsider joins refugees")
local alicePresence = alice.presenceRevision
local aliceSocial = alice.social.revision
local aliceRelationship =
    alice.social.relationships.keep.revision
local aliceConduct = alice.social.conduct.revision
local factionRelationRevision =
    PNC.Factions.Get(settlers.id).revision
local beforeRecord = alice.recordRevision
ok = PNC.Communities.AddNPC(farmID, alice.id, {
    communityRole = "guard",
    joinedAt = 201,
})
assertTrue(ok, "community assignment")
assertEqual(alice.affiliation.communityID, farmID,
    "community affiliation stored")
assertEqual(alice.affiliation.communityRole, "guard",
    "community role")
assertEqual(alice.recordRevision, beforeRecord + 1,
    "membership record revision")
assertEqual(alice.presenceRevision, alicePresence,
    "membership presence unchanged")
assertEqual(alice.social.revision, aliceSocial,
    "membership social unchanged")
assertEqual(alice.social.relationships.keep.revision,
    aliceRelationship, "relationship unchanged")
assertEqual(alice.social.conduct.revision, aliceConduct,
    "conduct unchanged")
assertEqual(PNC.Factions.Get(settlers.id).revision,
    factionRelationRevision, "faction revision unchanged")
assertFalse(PNC.Communities.AddNPC(
    farmID, outsider.id, {}
), "owning faction required")
local firstCommunityID = "community_collision"
assertFalse(PNC.Communities.AddNPC(
    firstCommunityID, alice.id, {}
), "one current community")

-- Transfer is atomic inside one faction and rejects cross-faction transfer.
local beforeRegistry =
    PNC.Communities.Registry.revision
ok = PNC.Communities.TransferNPC(
    alice.id,
    firstCommunityID,
    { worldAgeHours = 202 }
)
assertTrue(ok, "same-faction community transfer")
assertEqual(alice.affiliation.communityID,
    firstCommunityID, "transfer destination")
assertEqual(PNC.Communities.Registry.revision,
    beforeRegistry + 1, "one registry transfer revision")
assertFalse(PNC.Communities.TransferNPC(
    alice.id,
    campID,
    {}
), "cross-faction community transfer rejected")

-- Leadership, removal, death, and abstract presence.
assertFalse(PNC.Communities.SetLeader(
    firstCommunityID,
    outsider.id,
    203
), "leader must be member")
assertTrue(PNC.Communities.SetLeader(
    firstCommunityID,
    alice.id,
    203
), "set community leader")
assertEqual(PNC.Communities.Get(
    firstCommunityID
).leaderNPCID, alice.id, "leader persisted")
alice.presenceState = "abstract"
assertEqual(alice.affiliation.communityID,
    firstCommunityID, "abstract membership retained")
alice.alive = false
assertTrue(PNC.Communities.OnNPCDeath(alice.id),
    "community death reconciliation")
assertEqual(alice.affiliation.communityID, nil,
    "death clears active membership")
assertEqual(PNC.Communities.Get(
    firstCommunityID
).leaderNPCID, nil, "death clears leadership")
assertEqual(PNC.Communities.Get(
    firstCommunityID
).currentPopulation, 0, "death updates population")
alice.alive = true
assertTrue(PNC.Communities.AddNPC(
    firstCommunityID,
    alice.id,
    { communityRole = "resident" }
), "re-add alice")

-- Supplies are atomic and bounded; insufficient removal fails.
local communityRevision =
    PNC.Communities.Get(firstCommunityID).revision
assertTrue(PNC.Communities.AddSupply(
    firstCommunityID, "food", 10
), "add supply")
assertEqual(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 10, "supply read")
assertFalse(PNC.Communities.RemoveSupply(
    firstCommunityID, "food", 11
), "insufficient supply rejects")
assertEqual(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 10, "failed removal atomic")
assertTrue(PNC.Communities.RemoveSupply(
    firstCommunityID, "food", 4
), "remove supply")
assertEqual(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 6, "supply removal")
assertTrue(PNC.Communities.SetSupply(
    firstCommunityID, "food", 99999999
), "supply setter clamps")
assertEqual(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 1000000, "supply setter upper bound")
assertTrue(PNC.Communities.Get(
    firstCommunityID
).revision > communityRevision, "supply revises community")

-- Reads and identical setters are revision-neutral copies.
local readCopy = PNC.Communities.Get(firstCommunityID)
readCopy.name = "mutated"
assertEqual(PNC.Communities.Get(
    firstCommunityID
).name, "Riverside Farm", "read returns copy")
local readRevision = PNC.Communities.Registry.revision
PNC.Communities.List()
PNC.Communities.GetForFaction(settlers.id)
assertEqual(PNC.Communities.Registry.revision,
    readRevision, "pure reads unchanged")
local currentSecurity =
    PNC.Communities.Get(firstCommunityID).security
assertFalse(PNC.Communities.SetSecurity(
    firstCommunityID,
    currentSecurity
), "identical setter unchanged")
assertEqual(PNC.Communities.Registry.revision,
    readRevision, "identical setter revision")

-- Faction removal clears placement without changing unrelated revisions.
local socialBeforeRemoval = alice.social.revision
local presenceBeforeRemoval = alice.presenceRevision
assertTrue(PNC.Factions.RemoveNPC(
    settlers.id,
    alice.id,
    "removed",
    210
), "faction removal")
assertEqual(alice.affiliation.communityID, nil,
    "faction removal clears community")
assertEqual(PNC.Communities.Get(
    firstCommunityID
).memberIDs[alice.id], nil,
    "faction removal clears member index")
assertEqual(alice.social.revision, socialBeforeRemoval,
    "faction removal social unchanged")
assertEqual(alice.presenceRevision, presenceBeforeRemoval,
    "faction removal presence unchanged")

-- Faction archive and destroy retire owned community records.
assertTrue(PNC.Communities.AddNPC(
    farmID,
    bob.id,
    { communityRole = "worker" }
), "bob community assignment")
assertTrue(PNC.Factions.Archive(
    settlers.id,
    "community_test",
    220
), "archive owning faction")
for _, community in ipairs(
    PNC.Communities.GetForFaction(settlers.id)
) do
    assertEqual(community.status, "archived",
        "owned community archived")
    assertEqual(community.leaderNPCID, nil,
        "archived community leader clear")
    assertEqual(tableSize(community.memberIDs), 0,
        "archived community members clear")
end
assertEqual(bob.affiliation.communityID, nil,
    "faction archive clears community affiliation")
assertTrue(PNC.Factions.Destroy(
    settlers.id,
    "community_test_destroy",
    221
), "destroy owning faction")
for _, community in ipairs(
    PNC.Communities.GetForFaction(settlers.id)
) do
    assertEqual(community.status, "destroyed",
        "owned community destroyed")
end

-- Migration is deterministic, creates no community, and clears partial refs.
local oldAffiliation = FactionTypes.NormalizeAffiliation({
    schemaVersion = 1,
    factionID = refugees.id,
    membershipStatus = "member",
    role = "civilian",
    rank = "member",
})
assertEqual(oldAffiliation.schemaVersion, 2,
    "affiliation migrates to V2")
assertEqual(oldAffiliation.communityID, nil,
    "old affiliation gets no invented community")
assertEqual(oldAffiliation.communityRole, "resident",
    "old affiliation default community role")
local migratedRegistry =
    CommunityTypes.NormalizeRegistry({})
assertEqual(tableSize(migratedRegistry.byID), 0,
    "migration creates empty community registry")
assertTrue(CommunityTypes.AreEqual(
    migratedRegistry,
    CommunityTypes.NormalizeRegistry(migratedRegistry)
), "community migration idempotent")

assertTrue(PNC.Communities.Save(),
    "community registry saves")
local partial = newNPC("npc_partial_reference")
partial.affiliation = FactionTypes.NormalizeAffiliation({
    factionID = refugees.id,
    membershipStatus = "member",
    role = "civilian",
    rank = "member",
    communityID = "community_missing",
    communityRole = "worker",
    communityJoinedAt = 190,
})
local partialPresence = partial.presenceRevision
assertTrue(PNC.Communities.Load(),
    "community registry reloads")
assertEqual(partial.affiliation.communityID, nil,
    "missing partial community reference clears")
assertEqual(partial.presenceRevision, partialPresence,
    "migration leaves presence revision")
assertEqual(PNC.Communities.Get(campID).name,
    "Highway Camp", "community registry persists on reload")

-- Deterministic index rebuild and invariant detection/repair.
local campRecord = PNC.Communities.Registry.byID[campID]
campRecord.memberIDs.ghost = true
PNC.Communities.Registry.byFaction = {}
local invalid = PNC.CommunityValidation.ValidateRegistry()
assertFalse(invalid.ok, "validator detects invalid indexes")
assertTrue(PNC.CommunityValidation.RepairIndexes(),
    "index repair changes invalid indexes")
local repaired = PNC.CommunityValidation.ValidateRegistry()
assertTrue(repaired.ok, "index repair restores invariants")
assertFalse(PNC.CommunityValidation.RepairIndexes(),
    "correct rebuild unchanged")

-- Debug data is primitive-only and does not expose complete NPC records.
dofile(SERVER .. "PNC_CommunityDebug.lua")
local snapshot = PNC.CommunityDebug.BuildSnapshot(
    campID,
    refugees.id,
    outsider.id
)
assertSaveSafe(snapshot)
assertEqual(snapshot.selectedNPC.inventory, nil,
    "debug excludes inventory")
assertTrue(snapshot.selectedNPC.presenceRevision ~= nil,
    "debug includes presence evidence")
assertSaveSafe(PNC.Communities.Registry)

print("pnc_communities_foundation_smoke: PASS")
