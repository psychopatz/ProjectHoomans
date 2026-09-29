--[[
    Colony-management projection groups.

    The complete snapshot is larger than one engine packet, so a caller states
    which groups it needs. These assertions pin the two halves of that contract:

      1. a sectioned build returns only the requested groups, and never builds
         the expensive projections it was not asked for, and
      2. a build without `sections` still returns the complete snapshot, so
         every existing consumer keeps its current contract.
]]

local T = require "tests/support/test"

T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")

local ownerKey = "player:mp_account:character_mp"
local calls = {}
local lastStorageOptions

local function count(name)
    calls[name] = (calls[name] or 0) + 1
end

local function callCount(name)
    return calls[name] or 0
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = deepCopy(child) end
    return output
end

local faction = {
    id = "faction_mp",
    name = "Multiplayer Colony",
    archetypeID = "settler",
    revision = 1,
    tags = {},
    ownerPlayerKey = ownerKey,
    playerMemberKeys = { [ownerKey] = true },
}

local player = {
    getUsername = function() return "mp-user" end,
    getOnlineID = function() return 17 end,
}

PNC = {
    Core = { DeepCopy = deepCopy },
    Const = { ORDER_FOLLOW = "follow" },
    NeedsDefinitions = {
        TYPES = { "hunger", "thirst", "fatigue" },
        GetLevel = function() return "NORMAL" end,
    },
    NeedsUtils = { WorldAgeHours = function() return 100 end },
    WorkPolicy = {
        IsEnabled = function() return true end,
        Snapshot = function() return {} end,
    },
    IndividualNeeds = {
        Ensure = function(record) return record.needs end,
        GetHighestPriority = function() return nil, 0 end,
        GetActivity = function() return "Following" end,
    },
    PlayerCharacters = {
        GetEntityKey = function() return ownerKey, "resolved" end,
        GetCharacterUUID = function() return nil end,
    },
    Factions = {
        Get = function(id) return id == faction.id and faction or nil end,
        GetFactionForPlayerKey = function(key)
            return key == ownerKey and faction or nil
        end,
    },
    ColonyStorageService = {
        BuildSnapshot = function(_, options)
            count("storageProjection")
            lastStorageOptions = options
            local rows = { { name = "Nails", quantity = 4 } }
            if options and options.includeRows == false then rows = nil end
            return {
                storageId = "storage_mp",
                usedWeight = 12,
                debugAuthorized = true,
                rows = rows,
                access = {
                    hasStockpile = true,
                    insideBase = true,
                    reason = "writable",
                },
            }
        end,
        ResolveForPlayer = function()
            count("storageRecord")
            return { id = "storage_mp", revision = 3 }
        end,
    },
    ColonyStorageRepository = {
        Get = function() return { id = "storage_mp" } end,
    },
    ColonyResearchService = {
        BuildSnapshot = function()
            count("research")
            return { entries = { { id = "tech_one" } } }
        end,
    },
    CraftingService = {
        Queries = {
            BuildSnapshot = function()
                count("workshop")
                return { knownRecipes = { "recipe_one" }, orders = {} }
            end,
        },
    },
    BuildingService = {
        BuildSnapshot = function()
            count("building")
            return { recipes = { { id = "wall" } }, queue = {} }
        end,
    },
    TaskRequestService = {
        Queries = {
            BuildSnapshot = function()
                count("tasks")
                return { { id = "task_one" } }
            end,
        },
    },
    ProvisionPolicyService = {
        BuildSnapshot = function()
            count("provision")
            return { lanes = {} }
        end,
    },
    ProvisionEvaluator = {
        MeasureStorage = function()
            count("provisionStorage")
            return { food = 1 }
        end,
    },
    BaseService = {
        GetForColony = function()
            count("base")
            return { id = "base_mp", colonyId = "colony_mp" }
        end,
        BuildSnapshot = function()
            count("settlement")
            return { id = "base_mp", facilities = {}, stockpileNodeIds = {} }
        end,
    },
    SettlementRepository = {
        GetStockpileNode = function() return nil end,
    },
    FacilityService = { BuildSnapshot = function() return nil end },
    LumberService = { GetSnapshot = function() return nil end },
    FishingService = { GetSnapshot = function() return nil end },
    Communities = {
        GetForFaction = function()
            return { { id = "colony_mp", status = "active" } }
        end,
    },
    Journals = {
        NPC_CAPACITY = 32,
        GetNPC = function(npcID)
            count("journal")
            return { { message = "entry-" .. tostring(npcID), time = 1 } }
        end,
    },
    Registry = { Data = {
        npc_one = {
            id = "npc_one", name = "One", alive = true, recruited = true,
            affiliation = { factionID = faction.id },
            needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
        },
    } },
}

T.load(SHARED .. "PNC/Core/Identity/PNC_Identity_Verifier.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandRegistry.lua")
T.load(SERVER .. "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Core.lua")
T.load(SERVER .. "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots.lua")

local function hasKey(value, key)
    return value[key] ~= nil
end

-- ---------------------------------------------------------------------------
-- Unchanged default: no `sections` means the complete snapshot.
-- ---------------------------------------------------------------------------
local full = PNC.ColonyManagement.BuildSnapshot(player)
for _, key in ipairs({
    "colony", "faction", "identityStatus", "storage", "storageStatus",
    "provisionStorage", "research", "workshop", "building", "tasks",
    "provisionSettings", "settlement", "utilities", "zoneState",
    "people", "attention", "levels", "supplyShortages", "generatedAt",
}) do
    T.truthy(hasKey(full, key), "full snapshot keeps " .. key)
end
T.equal(#full.people, 1, "full snapshot still lists colonists")
T.equal(full.people[1].journal ~= nil, true, "full snapshot keeps journal detail")

-- ---------------------------------------------------------------------------
-- The colonist window's request: header + roster + settlement only.
-- ---------------------------------------------------------------------------
for key in pairs(calls) do calls[key] = nil end
local roster = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "roster", "settlement" },
})
T.truthy(hasKey(roster, "colony"), "sectioned roster keeps the colony header")
T.truthy(hasKey(roster, "identityStatus"), "sectioned roster keeps identity")
T.truthy(hasKey(roster, "faction"), "sectioned roster keeps the faction")
T.equal(#roster.people, 1, "sectioned roster lists colonists")
T.truthy(hasKey(roster, "settlement"), "sectioned roster keeps settlement")
for _, key in ipairs({
    "storage", "storageStatus", "provisionStorage", "research", "workshop",
    "building", "tasks", "provisionSettings", "zoneState",
}) do
    T.falsy(hasKey(roster, key), "sectioned roster omits " .. key)
end
T.equal(callCount("storageProjection"), 0,
    "stockpile row projection is not built for a roster request")
T.equal(callCount("research"), 0, "research is not built for a roster request")
T.equal(callCount("workshop"), 0, "workshop is not built for a roster request")
T.equal(callCount("building"), 0, "building is not built for a roster request")
T.equal(callCount("provision"), 0, "provision settings not built")
T.equal(callCount("tasks"), 1,
    "settlement decoration still resolves the task projection once")
T.equal(callCount("settlement"), 1, "settlement built once")

-- ---------------------------------------------------------------------------
-- The storage window's request: header + stockpile only.
-- ---------------------------------------------------------------------------
for key in pairs(calls) do calls[key] = nil end
local storage = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "storage" },
})
T.truthy(hasKey(storage, "storage"), "storage projection present")
T.truthy(hasKey(storage, "storageStatus"), "storage status present")
T.falsy(hasKey(storage, "people"), "storage request omits the colonist roster")
T.falsy(hasKey(storage, "settlement"), "storage request omits settlement")
T.equal(callCount("storageProjection"), 1, "stockpile projection built once")
T.equal(callCount("settlement"), 0, "settlement not built for storage")

-- ---------------------------------------------------------------------------
-- Research and construction need the storage record, never the row projection.
-- ---------------------------------------------------------------------------
for key in pairs(calls) do calls[key] = nil end
local catalogs = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "research", "building" },
})
T.truthy(hasKey(catalogs, "research"), "research present")
T.truthy(hasKey(catalogs, "building"), "building present")
T.falsy(hasKey(catalogs, "storage"), "research request omits stockpile rows")
T.equal(callCount("storageProjection"), 0,
    "research does not build the stockpile row projection")
T.equal(callCount("storageRecord"), 1,
    "research resolves the storage record instead")
T.equal(callCount("research"), 1, "research built once")
T.equal(callCount("building"), 1, "building built once")

-- ---------------------------------------------------------------------------
-- The light access projection: same authorization state, no stockpile rows.
-- ---------------------------------------------------------------------------
for key in pairs(calls) do calls[key] = nil end
lastStorageOptions = nil
local access = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "research", "storageAccess" },
})
T.truthy(hasKey(access, "storageAccess"), "access projection present")
T.falsy(hasKey(access, "storage"), "access request omits the full projection")
T.falsy(hasKey(access, "people"), "access request omits the colonist roster")
T.truthy(hasKey(access, "research"), "access request keeps research")
T.equal(access.storageAccess.debugAuthorized, true,
    "access projection keeps the debug authorization flag")
T.equal(callCount("storageProjection"), 1, "access projection built once")
T.equal(callCount("research"), 1, "research built for the access request")
T.truthy(lastStorageOptions ~= nil, "storage service received options")
T.equal(lastStorageOptions.includeRows, false,
    "access projection skips the stockpile row scan")

-- A full storage request still carries the rows, and does not duplicate the
-- access table alongside them.
for key in pairs(calls) do calls[key] = nil end
local fullStorage = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "storage" },
})
T.truthy(hasKey(fullStorage, "storage"), "full storage projection present")
T.truthy(hasKey(fullStorage.storage, "rows"), "full storage keeps the rows")
T.falsy(hasKey(fullStorage, "storageAccess"),
    "full storage does not duplicate the access table")

-- ---------------------------------------------------------------------------
-- The journal is the heaviest per-colonist field and travels only for the
-- colonist the client names as its detail target.
-- ---------------------------------------------------------------------------
PNC.Registry.Data.npc_two = {
    id = "npc_two", name = "Two", alive = true, recruited = true,
    affiliation = { factionID = faction.id },
    needs = { hunger = 0.2, thirst = 0.2, fatigue = 0.2 },
}
local detail = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "roster" },
    detailNpcID = "npc_two",
})
T.equal(#detail.people, 2, "detail request still lists every colonist")
local byID = {}
for _, person in ipairs(detail.people) do byID[person.id] = person end
T.truthy(byID.npc_two.journal ~= nil, "detail target carries its journal")
T.equal(#byID.npc_two.journal, 1, "detail target journal entries arrive")
T.falsy(byID.npc_one.journal ~= nil, "other colonists omit the journal")
T.truthy(byID.npc_one.needs ~= nil, "other colonists keep their needs")
T.truthy(byID.npc_one.activity ~= nil, "other colonists keep their activity")
T.equal(callCount("journal"), 1,
    "only the detail target's journal is fetched")

local noDetail = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "header", "roster" },
})
local fullByID = {}
for _, person in ipairs(noDetail.people) do fullByID[person.id] = person end
T.truthy(fullByID.npc_one.journal ~= nil,
    "a request without a detail target keeps every journal")

-- ---------------------------------------------------------------------------
-- Unknown or empty section names fall back to the header only.
-- ---------------------------------------------------------------------------
for key in pairs(calls) do calls[key] = nil end
local header = PNC.ColonyManagement.BuildSnapshot(player, {
    sections = { "not_a_section" },
})
T.truthy(hasKey(header, "colony"), "unknown section keeps the header")
T.falsy(hasKey(header, "people"), "unknown section omits the roster")
T.equal(callCount("storageProjection"), 0, "unknown section builds nothing else")

T.finish("pnc_colony_management_sections_smoke")
