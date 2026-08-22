local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

local function tableSize(value)
    local count = 0
    for _, _ in pairs(value or {}) do
        count = count + 1
    end
    return count
end

local function validatePersistedValue(value, seen)
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
        validatePersistedValue(child, seen)
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
T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
T.load(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
T.load(SHARED .. "Communities/PNC_CommunityConstants.lua")
T.load(SHARED .. "Communities/PNC_CommunityProfiles.lua")
T.load(SHARED .. "Communities/PNC_CommunityMath.lua")
T.load(SHARED .. "Communities/PNC_CommunityTypes.lua")
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")

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
T.equal(empty.schemaVersion, 2, "community registry schema")
T.equal(empty.revision, 0, "community registry revision")
T.equal(tableSize(empty.byID), 0, "community registry empty")
T.equal(tableSize(empty.sitesByID), 0,
    "community site registry empty")
local settledDefaults =
    CommunityTypes.BuildCreationDefaults("settled", "settler")
T.equal(settledDefaults.radius, 35, "settled radius")
T.equal(settledDefaults.capacity.population, 12,
    "settled population capacity")
T.equal(settledDefaults.security, 35,
    "settler security adjustment")
T.equal(settledDefaults.capacity.storage, 120,
    "settler storage adjustment")
local campedDefaults =
    CommunityTypes.BuildCreationDefaults("camped", "refugee")
T.equal(campedDefaults.radius, 15, "camp radius")
T.equal(campedDefaults.capacity.population, 8,
    "camp population capacity")
T.equal(campedDefaults.morale, -10,
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
T.equal(normalized.status, "inactive",
    "invalid status normalized")
T.equal(normalized.home.z, 32, "z clamps")
T.equal(normalized.home.radius, 200, "radius clamps")
T.equal(normalized.capacity.population, 500,
    "population capacity clamps")
T.equal(normalized.capacity.beds, 0, "beds clamp")
T.equal(normalized.capacity.storage, 100000,
    "storage clamps")
T.equal(normalized.security, 100, "security clamps")
T.equal(normalized.morale, -100, "morale clamps")
T.equal(normalized.supplies.food, 1000000,
    "supply upper clamp")
T.equal(normalized.supplies.tools, 0,
    "supply lower clamp")
local area = CommunityTypes.NewCommunity({
    id = "community_area",
    factionID = "faction_area",
    name = "Area",
    mode = "settled",
    status = "active",
    home = { x = 0, y = 0, z = 0, radius = 10 },
})
T.equal(
    CommunityMath.GetDistanceFromHome(area, 6, 8, 0),
    10,
    "distance helper"
)
T.truthy(
    CommunityMath.IsInsideHomeArea(area, 6, 8, 0),
    "inside home"
)
T.falsy(
    CommunityMath.IsInsideHomeArea(area, 0, 0, 1),
    "different floor outside"
)
T.truthy(CommunityTypes.AreEqual(
    CommunityTypes.NormalizeRegistry(
        CommunityTypes.NormalizeRegistry({ byID = {} })
    ),
    CommunityTypes.NormalizeRegistry({ byID = {} })
), "normalization idempotent")

T.load(SERVER .. "PNC_FactionService.lua")
T.load(SERVER .. "PNC_CommunityService.lua")
T.load(SERVER .. "PNC_CommunityValidation.lua")
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
T.truthy(ok, "create settler faction")
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
T.truthy(ok, "create settlement")
T.equal(area.id, "community_collision",
    "first community ID")
ok, _, area = PNC.Communities.Create({
    factionID = settlers.id,
    name = "Hill Farm",
    mode = "settled",
    home = { x = 140, y = 100, z = 0 },
})
T.truthy(ok, "same faction second community")
T.equal(area.id, "community_farm",
    "community collision skipped")
local farmID = area.id
local _, _, camp = PNC.Communities.Create({
    factionID = refugees.id,
    name = "Highway Camp",
    mode = "camped",
    home = { x = 300, y = 300, z = 0 },
})
local campID = camp.id
local farmSite = {
    kind = "building",
    home = { x = 140, y = 100, z = 0, radius = 12 },
    bounds = {
        minX = 134, minY = 94,
        maxX = 146, maxY = 106,
        minZ = 0, maxZ = 0,
    },
}
farmSite.id = PNC.Communities.BuildSiteID(farmSite)
T.truthy(PNC.Communities.ReserveSite(
    farmID, farmSite, worldHour
), "reserve building site")
T.equal(PNC.Communities.GetSite(
    farmSite.id
).occupantCommunityID, farmID,
    "site occupancy stored")
local campSite = {
    kind = "radius",
    home = { x = 300, y = 300, z = 0, radius = 15 },
    bounds = {
        minX = 285, minY = 285,
        maxX = 315, maxY = 315,
        minZ = 0, maxZ = 0,
    },
}
campSite.id = PNC.Communities.BuildSiteID(campSite)
T.truthy(PNC.Communities.ReserveSite(
    campID, campSite, worldHour
), "reserve camp site")
T.equal(#PNC.Communities.GetForFaction(settlers.id), 2,
    "multiple communities per faction")
T.equal(#PNC.Communities.GetForFaction(refugees.id), 1,
    "refugee camp indexed")
T.falsy(PNC.Communities.Create({
    factionID = "faction_missing",
    name = "Invalid",
    mode = "settled",
    home = { x = 0, y = 0, z = 0 },
}), "valid faction required")
T.falsy(PNC.Communities.Create({
    factionID = settlers.id,
    name = "Invalid",
    mode = "mobile",
    home = { x = 0, y = 0, z = 0 },
}), "invalid mode rejected")

-- Membership requires matching faction and remains independent of other data.
local alice = newNPC("npc_alice")
local bob = newNPC("npc_bob")
local outsider = newNPC("npc_outsider")
local firstCommunityID = "community_collision"
T.truthy(PNC.Factions.AddNPC(settlers.id, alice.id, {}),
    "alice joins settlers")
T.truthy(PNC.Factions.AddNPC(settlers.id, bob.id, {}),
    "bob joins settlers")
T.truthy(PNC.Factions.AddNPC(refugees.id, outsider.id, {}),
    "outsider joins refugees")
T.truthy(PNC.Communities.AddNPC(
    firstCommunityID,
    bob.id,
    { communityRole = "resident", joinedAt = 200 }
), "bob joins first community")
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
T.truthy(ok, "community assignment")
T.equal(alice.affiliation.communityID, farmID,
    "community affiliation stored")
T.equal(alice.affiliation.communityRole, "guard",
    "community role")
T.equal(alice.recordRevision, beforeRecord + 1,
    "membership record revision")
T.equal(alice.presenceRevision, alicePresence,
    "membership presence unchanged")
T.equal(alice.social.revision, aliceSocial,
    "membership social unchanged")
T.equal(alice.social.relationships.keep.revision,
    aliceRelationship, "relationship unchanged")
T.equal(alice.social.conduct.revision, aliceConduct,
    "conduct unchanged")
T.equal(PNC.Factions.Get(settlers.id).revision,
    factionRelationRevision, "faction revision unchanged")
T.falsy(PNC.Communities.AddNPC(
    farmID, outsider.id, {}
), "owning faction required")
T.falsy(PNC.Communities.AddNPC(
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
T.truthy(ok, "same-faction community transfer")
T.equal(alice.affiliation.communityID,
    firstCommunityID, "transfer destination")
T.equal(PNC.Communities.Registry.revision,
    beforeRegistry + 1, "one registry transfer revision")
T.falsy(PNC.Communities.TransferNPC(
    alice.id,
    campID,
    {}
), "cross-faction community transfer rejected")

-- Leadership, removal, death, and abstract presence.
T.falsy(PNC.Communities.SetLeader(
    firstCommunityID,
    outsider.id,
    203
), "leader must be member")
T.truthy(PNC.Communities.SetLeader(
    firstCommunityID,
    alice.id,
    203
), "set community leader")
T.equal(PNC.Communities.Get(
    firstCommunityID
).leaderNPCID, alice.id, "leader persisted")
alice.presenceState = "abstract"
T.equal(alice.affiliation.communityID,
    firstCommunityID, "abstract membership retained")
alice.alive = false
T.truthy(PNC.Communities.OnNPCDeath(alice.id),
    "community death reconciliation")
T.equal(alice.affiliation.communityID, nil,
    "death clears active membership")
T.equal(PNC.Communities.Get(
    firstCommunityID
).leaderNPCID, nil, "death clears leadership")
T.equal(PNC.Communities.Get(
    firstCommunityID
).currentPopulation, 1, "death updates population")
alice.alive = true
T.truthy(PNC.Communities.AddNPC(
    firstCommunityID,
    alice.id,
    { communityRole = "resident" }
), "re-add alice")

-- Supplies are atomic and bounded; insufficient removal fails.
local communityRevision =
    PNC.Communities.Get(firstCommunityID).revision
T.truthy(PNC.Communities.AddSupply(
    firstCommunityID, "food", 10
), "add supply")
T.equal(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 10, "supply read")
T.falsy(PNC.Communities.RemoveSupply(
    firstCommunityID, "food", 11
), "insufficient supply rejects")
T.equal(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 10, "failed removal atomic")
T.truthy(PNC.Communities.RemoveSupply(
    firstCommunityID, "food", 4
), "remove supply")
T.equal(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 6, "supply removal")
T.truthy(PNC.Communities.SetSupply(
    firstCommunityID, "food", 99999999
), "supply setter clamps")
T.equal(PNC.Communities.GetSupply(
    firstCommunityID, "food"
), 1000000, "supply setter upper bound")
T.truthy(PNC.Communities.Get(
    firstCommunityID
).revision > communityRevision, "supply revises community")

-- Reads and identical setters are revision-neutral copies.
local readCopy = PNC.Communities.Get(firstCommunityID)
readCopy.name = "mutated"
T.equal(PNC.Communities.Get(
    firstCommunityID
).name, "Riverside Farm", "read returns copy")
local readRevision = PNC.Communities.Registry.revision
PNC.Communities.List()
PNC.Communities.GetForFaction(settlers.id)
T.equal(PNC.Communities.Registry.revision,
    readRevision, "pure reads unchanged")
local currentSecurity =
    PNC.Communities.Get(firstCommunityID).security
T.falsy(PNC.Communities.SetSecurity(
    firstCommunityID,
    currentSecurity
), "identical setter unchanged")
T.equal(PNC.Communities.Registry.revision,
    readRevision, "identical setter revision")

-- Faction removal clears placement without changing unrelated revisions.
local socialBeforeRemoval = alice.social.revision
local presenceBeforeRemoval = alice.presenceRevision
T.truthy(PNC.Factions.RemoveNPC(
    settlers.id,
    alice.id,
    "removed",
    210
), "faction removal")
T.equal(alice.affiliation.communityID, nil,
    "faction removal clears community")
T.equal(PNC.Communities.Get(
    firstCommunityID
).memberIDs[alice.id], nil,
    "faction removal clears member index")
T.equal(alice.social.revision, socialBeforeRemoval,
    "faction removal social unchanged")
T.equal(alice.presenceRevision, presenceBeforeRemoval,
    "faction removal presence unchanged")

-- Faction archive and destroy retire owned community records.
T.truthy(PNC.Communities.TransferNPC(
    bob.id,
    farmID,
    {
        communityRole = "worker",
        worldAgeHours = 219,
    }
), "bob community assignment")
T.truthy(PNC.Factions.Archive(
    settlers.id,
    "community_test",
    220
), "archive owning faction")
for _, community in ipairs(
    PNC.Communities.GetForFaction(settlers.id)
) do
    T.equal(community.status, "archived",
        "owned community archived")
    T.equal(community.leaderNPCID, nil,
        "archived community leader clear")
    T.equal(tableSize(community.memberIDs), 0,
        "archived community members clear")
end

-- Wiped communities release their sites for reuse; a stable player-character
-- claim prevents later occupation without persisting an IsoPlayer.
T.truthy(PNC.Communities.AddNPC(
    campID,
    outsider.id,
    { communityRole = "resident" }
), "outsider occupies camp")
outsider.alive = false
local wiped, wipedReason =
    PNC.Communities.OnNPCDeath(outsider.id)
T.truthy(wiped, "wipeout reconciles")
T.equal(wipedReason, "community_wiped_out",
    "last death destroys community")
T.equal(PNC.Communities.Get(campID).status,
    "destroyed", "wiped community destroyed")
T.equal(PNC.Communities.GetSite(campSite.id).status,
    "vacant", "wiped site released")
local _, _, replacement = PNC.Communities.Create({
    factionID = refugees.id,
    name = "Replacement Camp",
    mode = "camped",
    home = campSite.home,
    createdAt = 222,
})
T.truthy(PNC.Communities.ReserveSite(
    replacement.id,
    campSite,
    222
), "vacant site reoccupied")
T.truthy(PNC.Communities.Destroy(
    replacement.id,
    "claim_test",
    223
), "replacement releases site")
local playerKey = PNC.EntityRef.ForPlayerIdentity(
    "Patrick",
    "char_site_test"
)
T.truthy(PNC.Communities.ClaimSite(
    campSite.id,
    playerKey,
    224
), "player character claims site")
T.equal(PNC.Communities.GetSite(
    campSite.id
).claimantKey, playerKey,
    "stable claimant stored")
local _, _, blockedCommunity = PNC.Communities.Create({
    factionID = refugees.id,
    name = "Blocked Camp",
    mode = "camped",
    home = campSite.home,
    createdAt = 225,
})
local reserved, reserveReason =
    PNC.Communities.ReserveSite(
        blockedCommunity.id,
        campSite,
        225
    )
T.falsy(reserved, "claimed site cannot be occupied")
T.equal(reserveReason, "site_claimed",
    "claim blocks occupation specifically")
outsider.alive = true
T.equal(bob.affiliation.communityID, nil,
    "faction archive clears community affiliation")
T.truthy(PNC.Factions.Destroy(
    settlers.id,
    "community_test_destroy",
    221
), "destroy owning faction")
for _, community in ipairs(
    PNC.Communities.GetForFaction(settlers.id)
) do
    T.equal(community.status, "destroyed",
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
T.equal(oldAffiliation.schemaVersion, 2,
    "affiliation migrates to V2")
T.equal(oldAffiliation.communityID, nil,
    "old affiliation gets no invented community")
T.equal(oldAffiliation.communityRole, "resident",
    "old affiliation default community role")
local migratedRegistry =
    CommunityTypes.NormalizeRegistry({})
T.equal(tableSize(migratedRegistry.byID), 0,
    "migration creates empty community registry")
T.truthy(CommunityTypes.AreEqual(
    migratedRegistry,
    CommunityTypes.NormalizeRegistry(migratedRegistry)
), "community migration idempotent")

T.truthy(PNC.Communities.Save(),
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
T.truthy(PNC.Communities.Load(),
    "community registry reloads")
T.equal(partial.affiliation.communityID, nil,
    "missing partial community reference clears")
T.equal(partial.presenceRevision, partialPresence,
    "migration leaves presence revision")
T.equal(PNC.Communities.Get(campID).name,
    "Highway Camp", "community registry persists on reload")

-- Deterministic index rebuild and invariant detection/repair.
local campRecord = PNC.Communities.Registry.byID[campID]
campRecord.memberIDs.ghost = true
PNC.Communities.Registry.byFaction = {}
local invalid = PNC.CommunityValidation.ValidateRegistry()
T.falsy(invalid.ok, "validator detects invalid indexes")
T.truthy(PNC.CommunityValidation.RepairIndexes(),
    "index repair changes invalid indexes")
local repaired = PNC.CommunityValidation.ValidateRegistry()
T.truthy(repaired.ok, "index repair restores invariants")
T.falsy(PNC.CommunityValidation.RepairIndexes(),
    "correct rebuild unchanged")

-- Debug data is primitive-only and does not expose complete NPC records.
T.load(SERVER .. "PNC_CommunityDebug.lua")
local snapshot = PNC.CommunityDebug.BuildSnapshot(
    campID,
    refugees.id,
    outsider.id
)
validatePersistedValue(snapshot)
T.equal(snapshot.selectedNPC.inventory, nil,
    "debug excludes inventory")
T.truthy(snapshot.selectedNPC.presenceRevision ~= nil,
    "debug includes presence evidence")
validatePersistedValue(PNC.Communities.Registry)
T.finish("pnc_communities_foundation_smoke")

T.finish("pnc_communities_foundation_smoke")
