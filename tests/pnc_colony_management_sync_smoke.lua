local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "server" } })

local listeners = {}
local player = { id = "player-1" }
local base = { id = "base-1", revision = 7 }
local sent
local tickCallback

PsychopatzCore = {
    Events = {
        subscribe = function(eventType, listener)
            listeners[eventType] = listener
            return true
        end,
    },
}
PNC = {
    ColonyManagement = {
        Internal = {},
        Internal = {
            BuildSettlementSnapshot = function(value)
            return { id = value.id, revision = value.revision }
            end,
        },
    },
    Network = {
        SendSettlementDelta = function(target, settlement)
            sent = { target = target, settlement = settlement }
        end,
    },
    BaseValidationService = {
        CanUse = function() return true end,
    },
    BaseService = {
        Get = function(id)
            return tostring(id) == base.id and base or nil
        end,
    },
    SettlementRepository = {
        GetFacility = function(id)
            return tostring(id) == "facility-1"
                and { id = id, baseId = base.id } or nil
        end,
    },
    EventTypes = {
        BASE_CREATED = "base.created",
        BASE_ZONE_CHANGED = "base.zoneChanged",
        FACILITY_CREATED = "facility.created",
        FACILITY_STATE_CHANGED = "facility.stateChanged",
        FACILITY_UPGRADED = "facility.upgraded",
        FACILITY_DESTROYED = "facility.destroyed",
        STOCKPILE_NODE_CHANGED = "stockpile.nodeChanged",
    },
}
Events = { OnTick = {
    Add = function(callback) tickCallback = callback end,
} }
isServer = function() return false end
getSpecificPlayer = function() return player end

T.load("ProjectHoomans", "server",
    "PNC/Colony/ColonyManagement/PNC_ColonyManagement_SettlementSync.lua")

T.truthy(listeners[PNC.EventTypes.FACILITY_STATE_CHANGED],
    "facility state changes are not subscribed")
listeners[PNC.EventTypes.FACILITY_STATE_CHANGED]({ facilityId = "facility-1" })
T.falsy(sent, "settlement delta was sent before the coalescing tick")
T.truthy(tickCallback, "settlement sync did not install its tick flush")
tickCallback()
T.truthy(sent, "facility state change did not push a settlement delta")
T.equal(sent.target, player, "settlement delta targeted the wrong player")
T.equal(sent.settlement.id, base.id,
    "settlement delta was built from the wrong base")

T.finish("pnc_colony_management_sync_smoke")
