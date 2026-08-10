local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
package.path = ROOT .. "shared/?.lua;" .. ROOT .. "server/?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local persisted = {}
local nowMS = 0
local hour = 10
local player = {
    x = 1000, y = 1000,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getAccessLevel = function() return "admin" end,
}

isClient = function() return false end
isServer = function() return false end
isDebugEnabled = function() return true end
getSpecificPlayer = function() return player end
getGameTime = function()
    return { getWorldAgeHours = function() return hour end }
end
ModData = {
    getOrCreate = function(key)
        persisted[key] = persisted[key] or {}
        return persisted[key]
    end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    OnTick = { Add = function() end },
}

PNC = {
    Core = { Now = function() return nowMS end },
    PlayerCharacters = {
        GetCharacterUUID = function() return "character:test" end,
    },
}

dofile(ROOT .. "shared/PNC/Core/Discovery/PNC_WorldDiscoveryTypes.lua")

local communities = {
    settlement_one = {
        id = "settlement_one", name = "Haven", status = "active",
        factionID = "faction_haven", currentPopulation = 6,
        site = { home = { x = 100, y = 200, z = 0 } },
    },
}
local groups = {
    group_one = {
        id = "group_one", factionId = "faction_roam",
        groupType = "REFUGEE", memberIds = { "npc_one" },
        location = { x = 120, y = 220, z = 0 },
    },
}
PNC.Communities = {
    List = function() return { communities.settlement_one } end,
    Get = function(id) return communities[id] end,
}
PNC.AbstractGroups = {
    List = function() return { groups.group_one } end,
    Get = function(id) return groups[id] end,
    FindByFactionID = function(id)
        return id == "faction_roam" and groups.group_one or nil
    end,
}
PNC.Factions = {
    Get = function(id)
        return { id = id, name = id == "faction_roam"
            and "Road Refugees" or "Haven Faction" }
    end,
}
PNC.Registry = {
    Get = function()
        return { affiliation = {
            communityID = "settlement_one",
            factionID = "faction_roam",
        } }
    end,
}

dofile(ROOT .. "server/PNC/WorldDiscovery/PNC_WorldDiscovery.lua")
local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes

local function entityOf(snapshot, kind)
    for _, entity in ipairs(snapshot.entities or {}) do
        if entity.kind == kind then return entity end
    end
    return nil
end

Discovery.Load()
equal(#Discovery.BuildSnapshot(player).entities, 0,
    "new character starts with no discovered entities")

local rumor = Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_RUMORED, "radio")
equal(rumor.phase, Types.PHASE_RUMORED,
    "radio can create a rumored settlement")
local rumoredSnapshot = Discovery.BuildSnapshot(player)
equal(rumoredSnapshot.entities[1].approximate, true,
    "rumored map position is approximate")
equal(rumoredSnapshot.entities[1].name, "Unknown settlement",
    "rumor does not leak settlement identity")

Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_LOCATED, "traversal")
Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_RUMORED, "radio")
equal(Discovery.BuildSnapshot(player).entities[1].phase,
    Types.PHASE_LOCATED, "discovery phases never regress")

player.x, player.y = 100, 200
hour = 11
local radio = Discovery.RadioScan(player)
equal(radio.result.ok, true, "radio finds an undiscovered mobile group")
equal(radio.result.phase, Types.PHASE_RUMORED,
    "first radio hit records a rumor")

hour = 12
local located = Discovery.RadioScan(player)
equal(located.result.phase, Types.PHASE_LOCATED,
    "second radio hit triangulates the same signal")

Discovery.DiscoverNPCContext(player, "npc_one")
local contacted = Discovery.BuildSnapshot(player)
equal(entityOf(contacted, Types.KIND_SETTLEMENT).phase,
    Types.PHASE_CONTACTED,
    "conversation contacts settlement")
equal(entityOf(contacted, Types.KIND_MOBILE_GROUP).phase,
    Types.PHASE_CONTACTED,
    "conversation contacts mobile group")
equal(entityOf(contacted, Types.KIND_SETTLEMENT).name, "Haven",
    "contact reveals settlement identity")

Discovery.Registry = {}
Discovery.Loaded = false
Discovery.Load()
equal(#Discovery.BuildSnapshot(player).entities, 2,
    "discovery persists across reload")

print("pnc_world_discovery_smoke: ok")
