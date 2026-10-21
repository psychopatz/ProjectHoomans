--[[
    Restored population bodies can report persistent outfit/population ids as
    zero or nil during the first registration tick. The persisted startup hint
    is valid only for the explicit restored-body rebind path; a newly spawned
    body must not inherit it.
]]

local T = require "tests/support/test"
T.addPackagePaths()

local BODY_ROOT = T.path(
    "ProjectHoomans", "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
)

local nowMs = 10000

PNC = {
    Core = {
        Now = function() return nowMs end,
        GenerateID = function(prefix) return prefix .. "_1" end,
        IsAuthority = function() return true end,
        LogInfo = function() end,
        LogWarn = function() end,
        LogDebug = function() end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        BODY_SHELL_CARRIER_VERSION = 1,
        BODY_SHELL_OUTFIT = "PNCShellCarrier",
    },
}

local outfitID = 0
local populationID = nil

local function makeBody()
    local body = { modData = {} }
    function body:getModData() return self.modData end
    function body:getPersistentOutfitID() return outfitID end
    function body:getPersistentID() return populationID end
    return body
end

T.load(BODY_ROOT .. "PNC_BodyLifecycle_State.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_World.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskLedger.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")

local Lifecycle = PNC.BodyLifecycle
local record = {
    id = "npc_restore_identity",
    runtime = {
        bodyLease = "body_saved",
        restoredBodyRebindPending = true,
        startupBodyHint = {
            instanceID = "42",
            populationId = "9001",
            lease = "body_saved",
        },
    },
}
local body = makeBody()

T.equal(Lifecycle.StampLiveBody(record, body), "body_saved",
    "restored body lease was not retained")
T.equal(record.liveBodyInstanceID, "42",
    "restored outfit identity was lost during transient engine read")
T.equal(record.liveBodyPopulationID, "9001",
    "restored population identity was lost during transient engine read")
T.equal(record.runtime.startupBodyHint, nil,
    "restored hint remained active after body stamping")

-- A later zero/nil read must not erase the last confirmed identity.
Lifecycle.RefreshLiveBodyIdentity(record, body, "body_audit")
T.equal(record.liveBodyInstanceID, "42",
    "transient outfit read erased confirmed identity")
T.equal(record.liveBodyPopulationID, "9001",
    "transient population read erased confirmed identity")

-- Once the engine exposes a real value, it supersedes the persisted hint.
outfitID = 77
populationID = 9002
Lifecycle.RefreshLiveBodyIdentity(record, body, "body_audit_ready")
T.equal(record.liveBodyInstanceID, "77",
    "engine outfit identity did not supersede the restored hint")
T.equal(record.liveBodyPopulationID, "9002",
    "engine population identity did not supersede the restored hint")

-- The same hint must never bleed into a newly spawned body.
outfitID = 0
populationID = nil
local newRecord = {
    id = "npc_new_body",
    runtime = {},
}
local newBody = makeBody()
Lifecycle.StampLiveBody(newRecord, newBody)
T.equal(newRecord.liveBodyInstanceID, nil,
    "new body inherited a stale outfit identity")
T.equal(newRecord.liveBodyPopulationID, nil,
    "new body inherited a stale population identity")

return T.finish("pnc_restored_body_identity_smoke")
