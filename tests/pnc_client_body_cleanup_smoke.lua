local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local FILE =
    T.path("ProjectHoomans", "client", "PNC/PNC_ClientPresenceSync.lua")

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local bodies = {}
local function makeBody(spec)
    local removed = false
    local modData = spec.modData or {}
    local worn = spec.naked and {} or { "shirt" }
    local visuals = spec.naked and {} or { "shirt_visual" }
    local body = {
        getModData = function() return modData end,
        getPersistentOutfitID = function() return spec.instanceID end,
        getOnlineID = function() return spec.onlineID end,
        getX = function() return spec.x end,
        getY = function() return spec.y end,
        getZ = function() return spec.z or 0 end,
        getWornItems = function() return makeList(worn) end,
        getItemVisuals = function() return makeList(visuals) end,
        isDead = function() return removed end,
        setVariable = function() end,
        removeFromWorld = function() removed = true end,
        removeFromSquare = function() removed = true end,
    }
    body.wasRemoved = function() return removed end
    bodies[#bodies + 1] = body
    return body
end

local canonical = makeBody({
    instanceID = 1001,
    onlineID = 11,
    x = 10,
    y = 10,
    modData = {
        PNC_NPC = true,
        PNC_UUID = "npc_client",
        PNC_BodyKind = "live",
        PNC_BodyLease = "lease-new",
    },
})
local duplicate = makeBody({
    instanceID = 1002,
    onlineID = 12,
    x = 10.2,
    y = 10,
    modData = {
        PNC_NPC = true,
        PNC_UUID = "npc_client",
        PNC_BodyKind = "live",
        PNC_BodyLease = "lease-old",
    },
})
local nakedLegacy = makeBody({
    instanceID = 1003,
    onlineID = 13,
    x = 10.4,
    y = 10,
    naked = true,
})
local unrelatedNaked = makeBody({
    instanceID = 1004,
    onlineID = 14,
    x = 30,
    y = 30,
    naked = true,
})
local onlineIDCollision = makeBody({
    instanceID = 1005,
    onlineID = 11,
    x = 40,
    y = 40,
    modData = {
        PNC_NPC = true,
        PNC_UUID = "different_npc",
        PNC_BodyLease = "different-lease",
    },
})

getCell = function()
    return {
        getZombieList = function() return makeList(bodies) end,
    }
end
getSpecificPlayer = function() return nil end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        CLIENT_BODY_SCAN_MS = 750,
        CLIENT_BODY_SCAN_UNRESOLVED_MS = 200,
    },
    Core = {
        Now = function() return 1000 end,
        IsClientOnly = function() return true end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    Network = {
        ClientState = {
            snapshots = {
                npc_client = {
                    id = "npc_client",
                    alive = true,
                    presenceState = "live",
                    presenceRevision = 7,
                    liveBodyInstanceID = 1001,
                    liveBodyOnlineID = 11,
                    liveBodyLease = "lease-new",
                    x = 10,
                    y = 10,
                    z = 0,
                    visualState = {},
                },
            },
        },
        GetZombieOnlineID = function(body)
            local value = body:getOnlineID()
            return value and value >= 0 and value or nil
        end,
    },
    ClientInterpolation = {},
    LiveBodyControl = {
        EnforceManagedSafety = function() return true end,
        MaintainHumanizedBody = function() return true end,
    },
}

T.load(FILE)

PNC.ClientPresenceSync.OnTick()
T.equal(canonical.wasRemoved(), false, "canonical client body preserved")
T.equal(duplicate.wasRemoved(), true, "old UUID body pruned")
T.equal(nakedLegacy.wasRemoved(), true, "nearby naked legacy body pruned")
T.equal(unrelatedNaked.wasRemoved(), false, "unrelated naked body preserved")
T.equal(onlineIDCollision.wasRemoved(), false,
    "online-ID collision body preserved")
T.equal(onlineIDCollision:getModData().PNC_UUID, "different_npc",
    "online-ID collision was not rebound to the wrong NPC")

local exact = makeBody({
    instanceID = 2001,
    onlineID = 21,
    x = 5,
    y = 5,
    modData = { PNC_NPC = true, PNC_UUID = "other" },
})
local removalCollision = makeBody({
    instanceID = 2002,
    onlineID = 21,
    x = 5.2,
    y = 5,
    modData = { PNC_NPC = true, PNC_UUID = "not_other" },
})
T.equal(PNC.ClientPresenceSync.RemoveBodyInstance({
    id = "other",
    bodyInstanceID = "2001",
    bodyOnlineID = 21,
    reason = "server_startup_cleanup",
}), 1, "exact client body removal count")
T.equal(exact.wasRemoved(), true, "exact server-directed body removed")
T.equal(removalCollision.wasRemoved(), false,
    "online-ID collision was not removed with another NPC")
T.finish("pnc_client_body_cleanup_smoke")

T.finish("pnc_client_body_cleanup_smoke")
