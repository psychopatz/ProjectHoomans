local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/WorldDiscovery/")
local PROXIMITY = ROOT .. "PNC_WorldDiscovery_Proximity.lua"

local player = {
    x = 100,
    y = 100,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
}
local records = {
    npc_one = { id = "npc_one", alive = true,
        presenceState = "abstract", x = 0, y = 0, z = 0 },
    npc_two = { id = "npc_two", alive = true,
        presenceState = "abstract", x = 0, y = 0, z = 0 },
}
local group = {
    id = "group_one",
    memberIds = { "npc_one", "npc_two" },
    location = { x = 100, y = 100, z = 0 },
}
local playerRecord = {
    entities = { mobile_group = {} },
}
local saved = 0
local sent = 0
local synced = 0
local materialized = 0

isServer = function() return false end
getSpecificPlayer = function() return player end
Events = {
    OnTick = { Add = function(callback) _G.discoveryTick = callback end },
}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return 1000 end,
        LogInfo = function() end,
    },
    WorldDiscoveryTypes = {
        KIND_SETTLEMENT = "settlement",
        KIND_MOBILE_GROUP = "mobile_group",
        PHASE_LOCATED = 2,
        ARRIVAL_UNCHECKED = "unchecked",
        ARRIVAL_SEARCHED = "searched",
        PRESENCE_UNKNOWN = "unknown",
        PRESENCE_PRESENT = "present",
        PRESENCE_ABSENT = "absent",
        ArrivalState = function(value)
            return value == "searched" and "searched" or "unchecked"
        end,
    },
    WorldDiscovery = {
        Internal = {
            CharacterUUID = function() return "character:test" end,
            PlayerRecord = function() return playerRecord end,
            DistanceSquared = function(currentPlayer, entity)
                local dx = currentPlayer:getX() - entity.x
                local dy = currentPlayer:getY() - entity.y
                return dx * dx + dy * dy
            end,
        },
        ProximityStateByPlayer = {},
        LastProximityScanAt = {},
        PROXIMITY_SCAN_MS = 2000,
        PROXIMITY_SLICE_MS = 100,
        PROXIMITY_SCAN_BUDGET = 24,
        SETTLEMENT_DISCOVERY_RANGE = 40,
        MOBILE_GROUP_DISCOVERY_RANGE = 30,
        GetCachedWorldEntities = function() return {
            { entityID = "group_one", kind = "mobile_group",
                x = 100, y = 100, z = 0 },
        } end,
        SetResolvedPhase = function(_, entity)
            playerRecord.entities.mobile_group[entity.entityID] = {
                entityID = entity.entityID,
                phase = 2,
                arrivalState = "unchecked",
            }
            return playerRecord.entities.mobile_group[entity.entityID],
                "advanced"
        end,
        MarkArrived = function(_, entity, presence)
            local entry = playerRecord.entities.mobile_group[entity.entityID]
            entry.arrivalState = "searched"
            entry.presenceStatus = presence
            return entry, "advanced"
        end,
        BuildSnapshot = function(_, result)
            return { state = "known", result = result, entities = {} }
        end,
        Save = function() saved = saved + 1 end,
        ResolvePhysicalPresence = nil,
    },
    AbstractGroups = {
        Get = function() return group end,
        SynchronizeMembersAtLocation = function()
            synced = synced + 1
            for _, record in pairs(records) do
                record.x, record.y, record.z = 100, 100, 0
            end
        end,
    },
    Registry = {
        Get = function(id) return records[id] end,
        GetLiveZombie = function() return nil end,
    },
    Presence = {
        Materialize = function(record)
            materialized = materialized + 1
            record.presenceState = "live"
            return true
        end,
    },
    Network = {
        SendWorldDiscovery = function() sent = sent + 1 end,
    },
}

T.load(PROXIMITY)
local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes

local presence = Discovery.ResolvePhysicalPresence(player, {
    entityID = "group_one", kind = Types.KIND_MOBILE_GROUP,
    x = 100, y = 100, z = 0,
})
T.equal(presence, Types.PRESENCE_PRESENT,
    "arrival materializes an abstract mobile group when its site is reached")
T.equal(synced, 1,
    "arrival synchronizes abstract member positions before materialization")
T.equal(materialized, 2,
    "arrival materializes each available mobile member")

Discovery.UpdateProximity()
T.equal(playerRecord.entities.mobile_group.group_one.arrivalState,
    Types.ARRIVAL_SEARCHED,
    "proximity stores the searched state separately from discovery phase")
T.equal(playerRecord.entities.mobile_group.group_one.presenceStatus,
    Types.PRESENCE_PRESENT,
    "proximity stores successful physical presence")
T.equal(saved, 1, "proximity batches arrival persistence")
T.equal(sent, 1, "proximity sends the updated discovery snapshot")
T.finish("pnc_world_discovery_arrival_smoke")
