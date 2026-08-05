local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local now = 1000
local removals = {}
local warnings = {}
local records = {}
local bodies = {}
local directSafetyApplications = 0

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        BODY_SHELL_RESPAWN_DELAY_MS = 350,
        BODY_SHELL_MAINTENANCE_MS = 1000,
        BODY_SHELL_STARTUP_PASSES = 3,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        GenerateID = function(prefix) return prefix .. "_test" end,
        LogWarn = function(message) warnings[#warnings + 1] = message end,
        LogInfo = function() end,
    },
    LiveBodyControl = {
        EnforceManagedSafety = function() return true end,
        ApplyHumanizedBodyFlags = function()
            directSafetyApplications = directSafetyApplications + 1
        end,
        SuppressZombieSounds = function() return true end,
    },
    Network = {
        BroadcastBodyRemoval = function(id, instanceID, onlineID, reason)
            removals[#removals + 1] = {
                id = id,
                instanceID = instanceID,
                onlineID = onlineID,
                reason = reason,
            }
        end,
    },
}

local function makeBody(spec)
    local modData = spec.modData or {}
    local removed = false
    local worn = spec.naked and {} or { "shirt" }
    local visuals = spec.naked and {} or { "shirt_visual" }
    local body = {
        getModData = function() return modData end,
        getPersistentOutfitID = function() return spec.instanceID end,
        getOnlineID = function() return spec.onlineID or -1 end,
        getX = function() return spec.x end,
        getY = function() return spec.y end,
        getZ = function() return spec.z or 0 end,
        getWornItems = function() return makeList(worn) end,
        getItemVisuals = function() return makeList(visuals) end,
        getVariableBoolean = function(_, name)
            return spec.variables and spec.variables[name] == true or false
        end,
        isUseless = function() return spec.useless == true end,
        isDead = function() return removed end,
        removeFromWorld = function() removed = true end,
        removeFromSquare = function() removed = true end,
    }
    body.wasRemoved = function() return removed end
    bodies[#bodies + 1] = body
    return body
end

PNC.Registry = {
    LiveByID = {},
    EnsureLoaded = function() end,
    Get = function(id) return records[tostring(id)] end,
    ForEach = function(callback)
        local _, record
        for _, record in pairs(records) do
            callback(record)
        end
    end,
}

getCell = function()
    return {
        getZombieList = function() return makeList(bodies) end,
    }
end

dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_LiveBodies.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup.lua")

records.marked = {
    id = "marked",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = {},
}
records.legacy = {
    id = "legacy",
    alive = true,
    presenceState = "abstract",
    x = 20,
    y = 20,
    z = 0,
    runtime = {
        startupBodyHint = { instanceID = "202" },
    },
}
records.canonical = {
    id = "canonical",
    alive = true,
    presenceState = "live",
    x = 30,
    y = 30,
    z = 0,
    runtime = { bodyLease = "lease-current" },
}

local marked = makeBody({
    instanceID = 101,
    onlineID = 11,
    x = 10,
    y = 10,
    naked = false,
    modData = {
        PNC_NPC = true,
        PNC_UUID = "marked",
        PNC_BodyKind = "live",
        PNC_BodyLease = "lease-old",
    },
})
local legacyNaked = makeBody({
    instanceID = 202,
    onlineID = 22,
    x = 20.4,
    y = 20,
    naked = true,
})
local unrelatedNaked = makeBody({
    instanceID = 303,
    onlineID = 33,
    x = 50,
    y = 50,
    naked = true,
})
local canonical = makeBody({
    instanceID = 404,
    onlineID = 44,
    x = 30,
    y = 30,
    naked = true,
    modData = {
        PNC_NPC = true,
        PNC_UUID = "canonical",
        PNC_BodyKind = "live",
        PNC_BodyLease = "lease-current",
    },
})
PNC.Registry.LiveByID.canonical = canonical

PNC.BodyLifecycle.BeginStartupBodyCleanup(now)
local first = PNC.BodyLifecycle.PumpStartupBodyCleanup(now, true)
assertEqual(first.removed, 2, "stale startup shells removed")
assertEqual(marked.wasRemoved(), true, "marked persisted shell removed")
assertEqual(legacyNaked.wasRemoved(), true, "naked body-hint shell removed")
assertEqual(unrelatedNaked.wasRemoved(), false, "unrelated naked zombie preserved")
assertEqual(canonical.wasRemoved(), false, "canonical body preserved")
assertEqual(#removals, 2, "instance removal packets sent")
assertEqual(#warnings, 2, "repair logs emitted")

now = now + 16
PNC.BodyLifecycle.PumpStartupBodyCleanup(now, false)
now = now + 16
PNC.BodyLifecycle.PumpStartupBodyCleanup(now, false)
assertEqual(
    PNC.BodyLifecycle.IsStartupBodyCleanupComplete(),
    true,
    "startup gate released after quiet passes"
)

records.priority = {
    id = "priority",
    alive = true,
    presenceState = "abstract",
    x = 60,
    y = 60,
    z = 0,
    runtime = {},
}
local earlyNaked = makeBody({
    instanceID = 505,
    onlineID = 55,
    x = 60.2,
    y = 60,
    naked = true,
})
PNC.BodyLifecycle.BeginStartupBodyCleanup(now, true)
assertEqual(
    PNC.BodyLifecycle.InterceptLoadedShell(
        earlyNaked,
        "test_early_zombie_update"
    ),
    true,
    "early zombie lane removed naked shell"
)
assertEqual(earlyNaked.wasRemoved(), true, "early naked shell removed immediately")
assertEqual(directSafetyApplications, 3,
    "matched shells made harmless before removal")
local synchronous = PNC.BodyLifecycle.RunStartupBodyCleanupNow(
    now,
    "test_world_ready",
    true
)
assertEqual(synchronous.complete, true,
    "world-ready cleanup completed synchronously")

print("pnc_persisted_shell_cleanup_smoke: ok")
