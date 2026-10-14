local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local dirty = {}

PNC = {
    Core = {
        LogWarn = function() end,
    },
    Const = {},
    Registry = {
        Data = {},
        LiveByID = {},
        EnsureLoaded = function() end,
        MarkDirty = function(_, record, reason)
            dirty[#dirty + 1] = { record = record, reason = reason }
        end,
    },
    BodyLifecycle = {
        StampLiveBody = function(record)
            record.liveBodyInstanceID = "stamped-valid-id"
        end,
        RefreshLiveBodyIdentity = function() end,
    },
}

T.load(ROOT .. "Registry/PNC_Registry/PNC_Registry_Records.lua")

local record = { id = "npc_identity" }
local zombie = {
    getPersistentOutfitID = function() return 0 end,
    getOnlineID = function() return -1 end,
}

PNC.Registry.RegisterLiveZombie(record, zombie)
T.equal(record.liveBodyInstanceID, "stamped-valid-id",
    "registry replaced a valid stamped identity with transient zero")
T.equal(record.liveBodyOnlineID, nil,
    "invalid online identity was retained")
T.equal(PNC.Registry.LiveByID.npc_identity, zombie,
    "live body was not registered")
T.finish("pnc_registry_live_identity_smoke")
