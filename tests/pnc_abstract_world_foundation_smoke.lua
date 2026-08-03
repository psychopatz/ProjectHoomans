local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/"

local function equal(actual, expected, label)
    if actual ~= expected then error((label or "equal") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end
local function truthy(value, label) equal(value == true, true, label) end
local function near(actual, expected, epsilon, label)
    if math.abs(actual - expected) > epsilon then error((label or "near")
        .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual)) end
end

local worldHour = 100
local modData = {}
function isClient() return false end
function isServer() return true end
function getCell() return nil end
function getGameTime()
    return { getWorldAgeHours = function() return worldHour end }
end
Events = { OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end } }
ModData = { getOrCreate = function(key)
    modData[key] = modData[key] or {}
    return modData[key]
end }

PNC = {
    Core = {
        IsAuthority = function() return true end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
        LogWarn = function() end,
    },
    Const = { PRESENCE_LIVE = "live" },
    Registry = { Data = {}, Dirty = {} },
    SpatialIndex = { QueryPlayers = function() return {} end,
        UpdateNPC = function() end },
}
function PNC.Registry.Get(id) return PNC.Registry.Data[id] end
function PNC.Registry.GetLiveZombie() return nil end
function PNC.Registry.MarkDirty(record, reason)
    PNC.Registry.Dirty[record.id] = reason
end

dofile(SHARED .. "Director/PNC_DirectorConfig.lua")
dofile(SHARED .. "Director/PNC_AbstractWorldTypes.lua")
dofile(SHARED .. "Scheduling/PNC_Scheduler.lua")

local faction = { id = "faction_test", archetypeID = "looter",
    leaderNPCID = "npc_1", status = "active",
    memberIDs = { npc_1 = true, npc_2 = true },
    mobile = { active = true, site = { id = "site_origin", kind = "building",
        home = { x = 0, y = 0, z = 0, radius = 10 },
        bounds = { minX = -2, minY = -2, maxX = 2, maxY = 2,
            minZ = 0, maxZ = 0 } } },
}
PNC.Factions = {
    Get = function(id) return id == faction.id and faction or nil end,
    List = function() return { faction } end,
    IsMobileGroup = function(value) return value and value.mobile
        and value.mobile.active == true end,
    EnsureLoaded = function() return true end,
}
PNC.Communities = { EnsureLoaded = function() return true end,
    ListSites = function() return {} end }
PNC.GroupNeeds = { Ensure = function()
    return { hunger = 20, hydration = 80, fatigue = 70 }
end }

PNC.Registry.Data.npc_1 = { id = "npc_1", alive = true,
    presenceState = "abstract", x = 0, y = 0, z = 0,
    health = { current = 100, max = 100 }, weaponMode = "ranged",
    equipment = { primaryFullType = "Base.Pistol" },
    affiliation = { role = "leader" } }
PNC.Registry.Data.npc_2 = { id = "npc_2", alive = true,
    presenceState = "abstract", x = 0, y = 0, z = 0,
    health = { current = 75, max = 100 }, weaponMode = "melee",
    equipment = { primaryFullType = "Base.Axe" },
    affiliation = { role = "raider" } }

dofile(SERVER .. "PNC_AbstractWorldStore.lua")
dofile(SERVER .. "PNC_AbstractLocationManager.lua")
dofile(SERVER .. "PNC_AbstractGroupManager.lua")
dofile(SERVER .. "PNC_AbstractCombatProfile.lua")
dofile(SERVER .. "PNC_AbstractEncounterDetector.lua")
dofile(SERVER .. "PNC_AbstractTraversal.lua")
dofile(SERVER .. "PNC_WorldDirector.lua")

PNC.AbstractWorldStore.Load()
local origin = assert(PNC.AbstractLocations.RegisterSite(faction.mobile.site))
local store = assert(PNC.AbstractLocations.Register({ id = "aloc_store",
    type = "BUILDING", x = 120, y = 0, z = 0,
    tags = { COMMERCIAL = true, FOOD = true },
    resourcePotential = { food = 90, water = 20 }, danger = 5 }))
local danger = assert(PNC.AbstractLocations.Register({ id = "aloc_danger",
    type = "BUILDING", x = 80, y = 0, z = 0,
    tags = { DANGEROUS = true }, resourcePotential = { food = 5 },
    danger = 90 }))

local group = assert(PNC.AbstractGroups.Create({ id = "agroup_test",
    factionId = faction.id, groupType = "LOOTER",
    memberIds = { "npc_1", "npc_2" }, mission = "SCAVENGE",
    state = "IDLE", location = PNC.AbstractLocations.Ref(origin),
    resources = { ammo = 100, food = 20, water = 40 } }))

local chosen = assert(PNC.AbstractTraversal.ChooseDestination(group))
equal(chosen.id, store.id, "food-rich destination selected")
truthy(PNC.AbstractTraversal.Begin(group, chosen, worldHour))
equal(group.state, "TRAVELING", "mission and state stay separate")
equal(group.mission, "SCAVENGE", "mission preserved during travel")
truthy(group.stateEndsAt > worldHour, "travel timer assigned")

local refugee = assert(PNC.AbstractGroups.Create({ id = "agroup_refugee",
    groupType = "REFUGEE", memberIds = {}, mission = "IDLE", state = "IDLE",
    location = PNC.AbstractLocations.Ref(store), resources = {} }))
equal(#PNC.AbstractLocations.GetGroupOccupants(store), 1,
    "occupancy registered")
worldHour = group.stateEndsAt
truthy(PNC.AbstractTraversal.Arrive(group, worldHour))
equal(group.location.id, store.id, "logical arrival")
equal(group.state, "ARRIVED", "arrival state")
equal(PNC.Registry.Data.npc_1.x, store.x - 1,
    "abstract member moved without body")
equal(#PNC.AbstractWorldStore.Registry.encounters, 1,
    "shared-location encounter detected")
equal(PNC.AbstractWorldStore.Registry.encounters[1].outcome, "DETECTED",
    "combat intentionally unresolved")

PNC.SpatialIndex.QueryPlayers = function()
    return { { getX = function() return store.x end,
        getY = function() return store.y end } }
end
local observed = assert(PNC.AbstractEncounters.Create(
    store, group, refugee, worldHour))
equal(observed.outcome, "MATERIALIZATION_REQUIRED",
    "nearby player blocks abstract resolution")
equal(observed.abstractResolutionAllowed, false,
    "observation safety is explicit in report")
PNC.SpatialIndex.QueryPlayers = function() return {} end

local highAmmo = assert(PNC.AbstractCombatProfile.Get(group, true))
truthy(highAmmo.combatantCount < highAmmo.memberCount,
    "role-weighted combatants differ from population")
local cached, cacheState = PNC.AbstractCombatProfile.Get(group, false)
equal(cacheState, "cached", "unchanged profile reused")
near(cached.rangedPower, highAmmo.rangedPower, 0.0001, "cached power stable")
group.resources.ammo = 1
local lowAmmo, rebuildState = PNC.AbstractCombatProfile.Get(group, false)
equal(rebuildState, "rebuilt", "ammo change invalidates signature")
truthy(lowAmmo.rangedPower < highAmmo.rangedPower,
    "low ammo reduces effective ranged power")

PNC.Registry.GetLiveZombie = function(id)
    return id == "npc_1" and {} or nil
end
equal(PNC.AbstractGroups.RefreshLOD(group, worldHour), "ACTIVE",
    "live member promotes group LOD")
equal(group.state, "ACTIVE", "active group leaves strategic state machine")
local advanced, activeReason = PNC.AbstractTraversal.Advance(group, worldHour)
equal(advanced, false, "active group does not traverse abstractly")
equal(activeReason, "active_simulation", "active traversal gate reason")
PNC.Registry.GetLiveZombie = function() return nil end
equal(PNC.AbstractGroups.RefreshLOD(group, worldHour), "ABSTRACT",
    "group returns to abstraction")
equal(group.state, "ARRIVED", "abstract occupancy restored")

local jobRuns = 0
truthy(PNC.Scheduler.RegisterJob("test", 1, function(_, budget)
    jobRuns = jobRuns + budget return budget
end, { budget = 3, startAt = 200 }))
equal(PNC.Scheduler.PumpJobs(199), 0, "job not early")
equal(PNC.Scheduler.PumpJobs(200), 1, "due job runs")
equal(jobRuns, 3, "job receives work budget")
equal(PNC.Scheduler.PumpJobs(200.5), 0, "interval enforced")

truthy(PNC.AbstractWorldStore.Save())
PNC.AbstractWorldStore.Registry = {}
PNC.AbstractWorldStore.Loaded = false
truthy(PNC.AbstractWorldStore.Load())
equal(PNC.AbstractGroups.Get("agroup_test").location.id, "aloc_store",
    "group persistence round-trip")
truthy(PNC.AbstractGroups.Get("agroup_test").combatProfile ~= nil,
    "combat cache persistence round-trip")
equal(PNC.AbstractGroups.Get("agroup_test").simulation.lod, "ABSTRACT",
    "safe simulation default")

-- Ensure the dangerous option really participated but scored lower.
local foundDanger = false
for _, evaluation in ipairs(group.diagnostics.destinationEvaluations or {}) do
    if evaluation.locationId == danger.id then foundDanger = true end
end
truthy(foundDanger, "bounded candidate scoring exposed for debug")

print("pnc_abstract_world_foundation_smoke: ok")
