local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

local worldHour = 420
local globalData = {}

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return worldHour * 3600000 end
function ZombRand() return 11 end
function getGameTime()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnGameStart = { Add = function() end },
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
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")
T.load(SHARED .. "Communities/PNC_CommunityConstants.lua")

local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local Constants = PNC.FactionConstants
local CommunityConstants = PNC.CommunityConstants

local dirty = {}
PNC.Registry = {
    Data = {},
    DirtyByID = dirty,
}
function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record)
    record.recordRevision = (tonumber(record.recordRevision) or 0) + 1
    return true
end

local function newNPC(id)
    local record = {
        id = id,
        name = id,
        alive = true,
        tacticalClass = "neutral",
        affiliation = Types.NewAffiliation(),
        recordRevision = 0,
        presenceRevision = 1,
    }
    PNC.Registry.Data[id] = record
    return record
end

T.load(SERVER .. "Factions/PNC_FactionService.lua")

local factionIndex = 0
PNC.Factions.IDGenerator = function()
    factionIndex = factionIndex + 1
    return "faction_staffing_" .. tostring(factionIndex)
end

-- The settlement roster helpers live with the director they belong to.
PNC.CommunityDirector = PNC.CommunityDirector or { Internal = {} }
PNC.Communities = PNC.Communities or {}
T.load(SERVER .. "Communities/CommunityDirector/PNC_CommunityDirector_Core.lua")
T.load(SERVER
    .. "Communities/CommunityDirector/PNC_CommunityDirector_TraderStaffing.lua")

local H = PNC.CommunityDirector.Internal
local Factions = PNC.Factions
local Staffing = PNC.SettlementTraderStaffing

-- 1. Role model: a settlement may hold a trader, and a member with no job is a
--    civilian, while unrelated archetypes keep their own defaults.
T.truthy(Constants.VALID_ROLES.trader, "trader is a valid faction role")
T.equal(Constants.VALID_ROLES.worker, nil, "worker is not a faction role")
T.equal(Archetypes.Get("settler").defaultRole, "civilian",
    "settler default role is a civilian")
T.truthy(Archetypes.Get("settler").allowedRoles.trader,
    "settler allows a trader")
T.equal(Archetypes.Get("settler").allowedRoles.worker, nil,
    "settler has no worker role")
T.equal(Archetypes.Get("refugee").defaultRole, "civilian",
    "refugee default role is a civilian")
T.truthy(Archetypes.Get("refugee").allowedRoles.trader,
    "refugee allows a trader")
T.equal(Archetypes.Get("looter").defaultRole, "civilian",
    "looter roster unchanged")
T.falsy(Archetypes.Get("looter").allowedRoles.trader,
    "looter camps stay coercion-only")
T.equal(Archetypes.Get("trader").defaultRole, "civilian",
    "mobile trader roster unchanged")

-- 2. Settlement roster: leader, trader, guard, then specialists, then civilians.
T.equal(H.FactionRole("settler", 1), "leader", "settlement leader slot")
T.equal(H.FactionRole("settler", 2), "trader", "settlement trader slot")
T.equal(H.FactionRole("settler", 3), "guard", "settlement guard slot")
T.equal(H.FactionRole("settler", 4), "medic", "settlement medic slot")
T.equal(H.FactionRole("settler", 10), "civilian",
    "a member with no job is a civilian")
T.equal(H.FactionRole("refugee", 1), "leader", "refugee leader slot")
T.equal(H.FactionRole("refugee", 2), "trader", "refugee trader slot")
T.equal(H.FactionRole("refugee", 7), "civilian",
    "refugee member with no job is a civilian")
T.equal(H.FactionRole("looter", 2), "raider", "looter roster unchanged")

-- 3. Community roles derive from the faction role instead of a second table.
T.equal(H.CommunityRole("leader"), "resident", "leader community role")
T.equal(H.CommunityRole("guard"), "guard", "guard community role")
T.equal(H.CommunityRole("medic"), "medic", "medic community role")
T.equal(H.CommunityRole("trader"), "resident", "trader community role")
T.equal(H.CommunityRole("farmer"), "resident", "farmer community role")
T.equal(H.CommunityRole("worker"), "resident",
    "unknown faction role falls back to resident")
T.equal(H.CommunityRole("civilian"), "resident", "civilian community role")
T.truthy(CommunityConstants.VALID_ROLES[H.CommunityRole("trader")],
    "derived community role is valid")
T.truthy(CommunityConstants.VALID_ROLES[H.CommunityRole("leader")],
    "derived leader community role is valid")

-- 4. The role service now accepts a settlement trader and still rejects junk.
local function createSettlement(archetypeID, roles, name)
    local ok, reason, faction = Factions.Create({
        name = name or ("Roster " .. tostring(archetypeID)),
        archetypeID = archetypeID,
        createdAt = worldHour,
    })
    T.truthy(ok, "create faction " .. tostring(archetypeID)
        .. " reason=" .. tostring(reason))
    local ids = {}
    for index = 1, #roles do
        local record = newNPC(
            "npc_" .. tostring(faction.id)
                .. "_" .. tostring(#ids + 1)
        )
        local added, addReason = Factions.AddNPC(
            faction.id, record.id, { role = roles[index] })
        T.truthy(added, "add " .. tostring(roles[index])
            .. " reason=" .. tostring(addReason))
        ids[#ids + 1] = record.id
    end
    return faction, ids
end

local legacy, legacyIDs = createSettlement(
    "settler", { "leader", "guard", "civilian" }, "Legacy Settlement")
T.equal(
    Factions.GetNPCAffiliation(legacyIDs[3]).role,
    "civilian",
    "legacy member keeps its civilian role"
)
local promoted, promoteReason = Factions.SetNPCRole(legacyIDs[3], "trader")
T.truthy(promoted, "settler accepts a trader role: "
    .. tostring(promoteReason))
T.equal(Factions.GetNPCAffiliation(legacyIDs[3]).role, "trader",
    "trader role stored")
local rejected, rejectReason = Factions.SetNPCRole(legacyIDs[1], "not_a_role")
T.falsy(rejected, "unknown role rejected")
T.equal(rejectReason, "role_not_allowed", "unknown role reason")

-- 5. EnsureTrader reconciles a legacy settlement through the staffed path.
local staffed, staffedReason = Staffing.EnsureTrader(legacy.id, worldHour)
T.truthy(staffed, "legacy settlement staffed: " .. tostring(staffedReason))
T.equal(staffedReason, "already_staffed",
    "an existing trader is not replaced")
T.equal(Staffing.TraderMember(legacy.id), legacyIDs[3], "trader member lookup")

local fresh, freshIDs = createSettlement(
    "settler", { "leader", "guard", "civilian" }, "Fresh Settlement")
T.falsy(Staffing.TraderMember(fresh.id), "fresh settlement has no trader yet")
local assigned, assignedReason = Staffing.EnsureTrader(fresh.id, worldHour)
T.truthy(assigned, "civilian promoted: " .. tostring(assignedReason))
T.equal(assignedReason, "trader_assigned", "assignment reason")
T.equal(Staffing.TraderMember(fresh.id), freshIDs[3],
    "the member with no job became the trader")

local small = createSettlement(
    "settler", { "leader", "guard" }, "Small Settlement")
local smallOK, smallReason = Staffing.EnsureTrader(small.id, worldHour)
T.falsy(smallOK, "a two member settlement is left alone")
T.equal(smallReason, "too_small", "too small reason")

local camp = createSettlement(
    "looter", { "leader", "raider", "civilian" }, "Looter Camp")
local campOK, campReason = Staffing.EnsureTrader(camp.id, worldHour)
T.falsy(campOK, "looter camps do not trade")
T.equal(campReason, "archetype_not_eligible", "looter reason")

local mobileFaction = createSettlement(
    "settler", { "leader", "trader", "guard" }, "Mobile Group")
Factions.Registry.byID[mobileFaction.id].mobile = { active = true }
local mobileOK, mobileReason = Staffing.EnsureTrader(mobileFaction.id, worldHour)
T.falsy(mobileOK, "mobile groups are not settlements")
T.equal(mobileReason, "mobile_group", "mobile reason")

local ready = createSettlement(
    "settler", { "leader", "trader", "civilian" }, "Ready Settlement")
local readyOK, readyReason = Staffing.EnsureTrader(ready.id, worldHour)
T.truthy(readyOK, "already staffed settlement accepted")
T.equal(readyReason, "already_staffed", "already staffed reason")

-- 6. The bounded pass reports exactly what it did.
local pending, pendingIDs = createSettlement(
    "settler", { "leader", "guard", "civilian", "civilian" }, "Pending Settlement")
local summary = Staffing.Reconcile(worldHour)
T.equal(summary.scanned, 7, "reconcile scanned every faction")
T.equal(summary.staffed, 1, "reconcile staffed the pending settlement")
T.equal(summary.alreadyStaffed, 3, "reconcile skipped staffed settlements")
T.equal(summary.tooSmall, 1, "reconcile skipped the small settlement")
T.equal(summary.skipped, 2, "reconcile skipped camp and mobile group")
T.equal(summary.failed, 0, "reconcile had no failures")
T.equal(summary.truncated, false, "reconcile stayed inside its budget")
T.equal(Staffing.TraderMember(pending.id), pendingIDs[3],
    "reconcile promoted a member with no job")
T.equal(Staffing.MINIMUM_MEMBERS, 3, "minimum roster documented")

-- 7. A second pass changes nothing.
local second = Staffing.Reconcile(worldHour)
T.equal(second.staffed, 0, "second pass is a no-op")
T.equal(second.failed, 0, "second pass has no failures")
T.truthy(Staffing.StartHookRegistered, "world start hook registered")

T.finish("pnc_settlement_trader_staffing_smoke")
