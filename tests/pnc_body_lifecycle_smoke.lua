local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/"

package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local now = 1000
local record = {
    id = "npc_lifecycle",
    name = "Lifecycle Test",
    alive = true,
    presenceState = "live",
    presenceRevision = 0,
    runtime = {},
}
local records = { [record.id] = record }

PNC = {
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix) return prefix .. "_1" end,
        IsAuthority = function() return true end,
        DeepCopy = function(value) return value end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        BODY_TAG_VERSION = 1,
        BODY_AUDIT_INTERVAL_MS = 250,
        CORPSE_AUDIT_INTERVAL_MS = 1000,
        CORPSE_AUDIT_BATCH_SIZE = 12,
        CORPSE_REANIMATE_RETRY_MAX = 3,
    },
}

local bodies = {}
local function makeBody(outfitID, onlineID)
    local modData = {}
    local body = {
        removedFromWorld = false,
        removedFromSquare = false,
        getModData = function() return modData end,
        getPersistentOutfitID = function() return outfitID end,
        getOnlineID = function() return onlineID end,
        getActionStateName = function() return "idle" end,
        removeFromWorld = function(self) self.removedFromWorld = true end,
        removeFromSquare = function(self) self.removedFromSquare = true end,
    }
    bodies[#bodies + 1] = body
    return body
end

PNC.Registry = {
    LiveByID = {},
    EnsureLoaded = function() end,
    Get = function(id) return records[tostring(id)] end,
    GetLiveZombie = function(id) return PNC.Registry.LiveByID[tostring(id)] end,
    ForEach = function(callback)
        local _, candidate
        for _, candidate in pairs(records) do callback(candidate) end
    end,
}

getCell = function()
    return {
        getZombieList = function() return makeList(bodies) end,
        getGridSquare = function() return nil end,
    }
end

dofile(ROOT .. "Presence/PNC_BodyLifecycle.lua")

local first = makeBody(101, 11)
assertEqual(PNC.BodyLifecycle.StampLiveBody(record, first), "body_1", "generated body lease")
assertEqual(first:getModData().PNC_UUID, record.id, "stamped NPC id")
assertEqual(first:getModData().PNC_BodyKind, "live", "stamped body kind")
PNC.Registry.LiveByID[record.id] = first

local second = makeBody(202, 22)
record.runtime.bodyLease = "body_1"
second:getModData().PNC_NPC = true
second:getModData().PNC_UUID = record.id
second:getModData().PNC_BodyKind = "live"
second:getModData().PNC_BodyLease = "body_1"
second:getModData().PNC_TagVersion = 1

local audit = PNC.BodyLifecycle.AuditLoadedBodies(now, true)
assertEqual(audit.scanned, 2, "audited body count")
assertEqual(audit.duplicates, 1, "duplicate body count")
assertEqual(audit.removed, 1, "removed duplicate count")
assertEqual(audit.rebound, 1, "rebound body count")
assertEqual(PNC.Registry.LiveByID[record.id], second, "accepted live body")
assertEqual(first.removedFromWorld, true, "duplicate removed from world")

local diagnostics = PNC.BodyLifecycle.BuildDiagnostics(record)
assertEqual(diagnostics.bodyState, "bound", "diagnostic body state")
assertEqual(diagnostics.liveBodyOnlineID, 22, "diagnostic online ID")
assertEqual(diagnostics.bodyActionState, "idle", "diagnostic action state")
assertEqual(diagnostics.debugRecording, false, "diagnostic recording defaults off")
record.runtime.debug = true
diagnostics = PNC.BodyLifecycle.BuildDiagnostics(record)
assertEqual(diagnostics.debugRecording, true, "diagnostic recording state")

PNC.BodyLifecycle.RemoveLiveBody(record, second, "test_abstract")
assertEqual(record.presenceState, "abstract", "detached presence state")
assertEqual(record.runtime.bodyLease, nil, "cleared body lease")
assertEqual(PNC.Registry.LiveByID[record.id], nil, "cleared live registry")
assertEqual(second.removedFromWorld, true, "live body removed from world")

print("pnc_body_lifecycle_smoke: ok")
