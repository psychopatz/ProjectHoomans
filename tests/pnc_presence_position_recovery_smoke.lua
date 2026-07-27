local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local warnings = {}
local registeredBody
local dirtyDomain
local spawn
local body = {
    DoZombieStats = function() end,
    setUseless = function() end,
}
local zombieList = {
    size = function() return 1 end,
    get = function() return body end,
}
local function makeSquare(vehicleIntersecting)
    return {
        isFree = function() return true end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        isVehicleIntersecting = function() return vehicleIntersecting == true end,
    }
end
local clearSquare = makeSquare(false)
local vehicleSquare = makeSquare(true)
local cell = {
    getGridSquare = function(_, x)
        return x == 1 and vehicleSquare or clearSquare
    end,
}

getCell = function() return cell end
addZombiesInOutfit = function(x, y, z, _, outfit)
    spawn = { x = x, y = y, z = z, outfit = outfit }
    return zombieList
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MATERIALIZE_DISTANCE = 40,
        ABSTRACT_DISTANCE = 50,
    },
    Core = {
        Now = function() return 1000 end,
        IsAuthority = function() return true end,
        GetNearestPlayerPosition = function() return { distSq = 0 } end,
        LogWarn = function(message) warnings[#warnings + 1] = message end,
        LogRecordDebug = function() end,
    },
    Registry = {
        GetLiveZombie = function() return nil end,
        RegisterLiveZombie = function(_, value) registeredBody = value end,
        MarkDirty = function(_, domain) dirtyDomain = domain end,
    },
    Health = {
        Update = function() end,
    },
    Animation = {
        ApplyLiveSetup = function() end,
        Apply = function() end,
    },
    Visuals = {
        ApplyHumanVisuals = function() end,
    },
    Equipment = {
        Apply = function() end,
    },
    PathService = {},
    ZombieAggro = {},
    Network = {
        BroadcastRecord = function() end,
    },
    Inventory = {
        EnsureRecordInventory = function() end,
    },
    VisualProfiles = {
        ResolveSpawnOutfit = function() return "PNCCompanionMale" end,
    },
}

dofile(ROOT .. "Pathing/PNC_TraversalQuery.lua")
dofile(ROOT .. "Presence/PNC_Presence.lua")

local passengerRecord = {
    alive = true,
    presenceState = "abstract",
    x = 0,
    y = 0,
    z = 0,
    runtime = {
        vehiclePassenger = { active = true, vehicleId = "vehicle:7", seat = 1 },
    },
}
assertEqual(
    PNC.Presence.ShouldMaterialize(passengerRecord),
    false,
    "abstract vehicle passenger stays bodyless"
)

local record = {
    id = "saved_vehicle_stuck",
    name = "Saved Vehicle Stuck",
    alive = true,
    presenceState = "abstract",
    x = 1.5,
    y = 0.5,
    z = 0,
    runtime = {},
}

local materialized = PNC.Presence.Materialize(record, "range_enter")
assertEqual(materialized, body, "saved NPC materialized")
assertEqual(registeredBody, body, "repaired body registered")
assertEqual(spawn.x, 0.5, "vehicle-stuck spawn repaired x")
assertEqual(spawn.y, 0.5, "vehicle-stuck spawn repaired y")
assertEqual(spawn.outfit, "Naked", "PNC engine shell uses naked base outfit")
assertEqual(record.x, spawn.x, "repaired record x")
assertEqual(record.presenceState, "live", "repaired record live")
assertEqual(record.runtime.positionRecovery.lastEvent, "materialize_relocate",
    "materialize recovery metadata")
assertEqual(record.runtime.positionRecovery.lastReason, "vehicle",
    "materialize recovery reason")
assertEqual(dirtyDomain, "position_recovery", "materialize recovery persisted")
assertEqual(#warnings, 1, "materialize recovery log count")
assert(
    string.find(warnings[1], "event=materialize_relocate", 1, true),
    "materialize recovery warning missing event"
)

local clearRecord = {
    id = "saved_clear",
    name = "Saved Clear",
    alive = true,
    presenceState = "abstract",
    x = 0.75,
    y = 0.75,
    z = 0,
    runtime = {},
}
materialized = PNC.Presence.Materialize(clearRecord, "range_enter")
assertEqual(materialized, body, "clear saved NPC materialized")
assertEqual(spawn.x, 0.75, "clear saved x preserved")
assertEqual(spawn.y, 0.75, "clear saved y preserved")
assertEqual(clearRecord.runtime.positionRecovery, nil, "clear saved NPC not repaired")
assertEqual(#warnings, 1, "clear materialization emitted no recovery log")

print("pnc_presence_position_recovery_smoke: ok")
