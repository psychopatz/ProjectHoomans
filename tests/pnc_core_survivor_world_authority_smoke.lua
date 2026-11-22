local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return false end

local roots = {}
ModData = {
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
    get = function(key)
        return roots[key]
    end,
}

local initCallbacks = {}
local saveCallbacks = {}
Events = {
    OnInitGlobalModData = {
        Add = function(callback)
            initCallbacks[#initCallbacks + 1] = callback
        end,
    },
    OnSave = {
        Add = function(callback)
            saveCallbacks[#saveCallbacks + 1] = callback
        end,
    },
}

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(child, seen)
    end
    return output
end

PNC = {
    Core = { DeepCopy = deepCopy },
}

local Authority = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/PNC_CoreSurvivorWorldAuthority.lua"
)

T.truthy(Authority.Registry,
    "Hoomans must activate Core SurvivorWorld runtime")
T.equal(roots["PsychopatzCore.SurvivorWorld"], nil,
    "activation must not allocate Core ModData before init")

local status = Authority.RefreshStatus()
T.truthy(status.active, "Core SurvivorWorld status active")
T.truthy(status.coreEmpty, "Core begins empty")
T.equal(status.needsImport, nil, "pre-SurvivorWorld import state omitted")

for _, callback in ipairs(initCallbacks) do callback() end
status = Authority.RefreshStatus()
T.truthy(status.active, "init keeps Core SurvivorWorld active")
T.truthy(status.coreEmpty, "init alone keeps empty Core state")

assert(Authority.Registry:UpsertFaction({
    id = "faction_canon",
    name = "Canonical Faction",
    archetypeID = "survivor",
    memberActorIDs = { "actor_canon" },
}))
assert(Authority.Registry:UpsertCommunity({
    id = "community_canon",
    factionID = "faction_canon",
    name = "Canonical Camp",
    mode = "settled",
    status = "active",
    home = { x = 100, y = 200, z = 0, radius = 20 },
    memberActorIDs = { "actor_canon" },
}))
assert(Authority.Registry:UpsertLocation({
    id = "aloc_canon",
    kind = "SETTLEMENT",
    x = 100, y = 200, z = 0,
}))
assert(Authority.Registry:UpsertGroup({
    id = "agroup_canon",
    factionID = "faction_canon",
    homeCommunityID = "community_canon",
    groupType = "CARAVAN",
    memberActorIDs = { "actor_canon" },
    leaderActorID = "actor_canon",
    location = {
        id = "aloc_canon",
        kind = "SETTLEMENT",
        x = 100, y = 200, z = 0,
    },
}))

status = Authority.RefreshStatus()
T.truthy(status.active, "populated Core stays active")
T.falsy(status.coreEmpty, "populated Core is no longer empty")
T.equal(status.core.factions, 1, "Core faction count reported")
T.equal(status.core.communities, 1, "Core community count reported")
T.equal(status.core.locations, 1, "Core location count reported")
T.equal(status.core.groups, 1, "Core group count reported")
T.equal(status.core.discoveryPlayers, 0, "Core discovery count reported")

T.finish("pnc_core_survivor_world_authority_smoke")
