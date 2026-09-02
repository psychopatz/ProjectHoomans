local T = require "tests/support/test"

T.addPackagePaths()

local square = { bodies = {} }
local removed = 0

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
        remove = function(_, index) table.remove(values, index + 1) end,
    }
end

local function makeCorpse()
    local modData = {
        PNC_DeathMarkerID = "duplicate_npc",
        PNC_CorpseToken = "corpse_token",
    }
    local corpse = {
        square = square,
        current = square,
        x = 10,
        y = 20,
        z = 0,
        getModData = function(self) return modData end,
        getSquare = function(self) return self.current or self.square end,
        getCurrentSquare = function(self) return self.current end,
        setCurrent = function(self, value) self.current = value end,
        setSquare = function(self, value) self.square = value end,
        getX = function(self) return self.x end,
        getY = function(self) return self.y end,
        getZ = function(self) return self.z end,
        removeFromWorld = function() removed = removed + 1 end,
        removeFromSquare = function(self) self.current = nil end,
    }
    return corpse
end

local first = makeCorpse()
local second = makeCorpse()
square.bodies = { first, second }
function square:getDeadBodys() return list(self.bodies) end
function square:getStaticMovingObjects() return list(self.bodies) end
function square:transmitRemoveItemFromSquare() end

local record = {
    id = "duplicate_npc",
    alive = false,
    x = 10,
    y = 20,
    z = 0,
    corpseToken = "corpse_token",
    corpse = { token = "corpse_token" },
    runtime = {},
}
local state = {}

PNC = {
    Core = {
        Now = function() return 1000 end,
        GenerateID = function(prefix) return prefix .. "_generated" end,
    },
    Const = {
        DEATH_MARKER_MISSING_GRACE_MS = 5000,
        PRESENCE_CORPSE = "corpse",
    },
    BodyLifecycle = { Internal = {} },
    Registry = {},
}
PNC.Registry.GetDeathMarkerRuntime = function() return state end
PNC.Registry.Get = function() return record end
PNC.BodyLifecycle.Internal.registry = function() return PNC.Registry end
PNC.BodyLifecycle.Internal.ensureRuntime = function() return record.runtime end
PNC.BodyLifecycle.Internal.mark = function() end
PNC.Registry.RemoveDeathMarker = function() end

getCell = function()
    return {
        getGridSquare = function() return square end,
    }
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAudit.lua"
)

PNC.BodyLifecycle.Internal.auditCorpseRecord(record)
T.equal(removed, 1, "corpse audit removes the duplicate engine body")
T.equal(#square.bodies, 1, "corpse audit leaves one world membership")
T.equal(state.corpseState, "inert_loaded",
    "corpse audit keeps the canonical corpse loaded")

T.finish("pnc_corpse_duplicate_audit_smoke")
