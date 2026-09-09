local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock, serial = 1000, 0
local dirty = 0
local applied = 0
local square
local loadSquare

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

PNC = {
    Core = {
        Now = function() return clock end,
        DeepCopy = copy,
        GenerateID = function(prefix)
            serial = serial + 1
            return tostring(prefix) .. ":" .. tostring(serial)
        end,
    },
    Registry = {
        Get = function() return { name = "Tester" } end,
    },
    WorkRepository = {
        State = { byId = {} },
        Load = function() end,
        MarkDirty = function() dirty = dirty + 1 end,
    },
}

_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if square and x == 10 and y == 20 and z == 0 then
                return square
            end
            return nil
        end,
    }
end

Events = {
    LoadGridsquare = { Add = function(fn) loadSquare = fn end },
    OnTick = { Add = function() end },
}

local Effects = T.load("ProjectHoomans", "server",
    "PNC/Production/WorldEffects/PNC_WorldEffectService.lua")
local owner = {
    id = "owner:one",
    worldEffect = {
        id = "effect:one", kind = "TEST_EFFECT", state = "PENDING",
        x = 10, y = 20, z = 0, createdAt = clock,
    },
}

T.truthy(Effects.RegisterProvider("test", {
    List = function() return { owner } end,
    GetOwnerID = function(value) return value.id end,
    GetEffects = function(value) return { value.worldEffect } end,
    MarkDirty = function() dirty = dirty + 1 end,
}), "test provider registration")
T.truthy(Effects.Register("TEST_EFFECT", {
    Apply = function(value, effect)
        if not square then return false, "TARGET_CHUNK_LOADING" end
        value.applied = true
        effect.state = "APPLIED"
        applied = applied + 1
        return true, "APPLIED"
    end,
}), "test effect registration")

Effects.RebuildIndex()
local snapshot = Effects.BuildSnapshot()
T.equal(snapshot.summary.pending, 1, "pending effect appears in summary")
T.equal(snapshot.rows[1].endpoints[1].loaded, false,
    "unloaded endpoint is visible in debug snapshot")

local appliedNow, visited = Effects.Reconcile(clock, nil, 4)
T.equal(appliedNow, 0, "unloaded effect is not applied")
T.equal(visited, 1, "bounded retry visits one effect")
T.equal(owner.worldEffect.attempts, 1,
    "failed world application records an attempt")
T.equal(owner.worldEffect.lastReason, "TARGET_CHUNK_LOADING",
    "failed world application exposes its reason")

square = { getX = function() return 10 end,
    getY = function() return 20 end, getZ = function() return 0 end }
-- The load hook bypasses the old retry backoff because the exact prerequisite
-- (the target square) has just become available.
clock = 1500
T.truthy(loadSquare, "generic load-square hook registered")
loadSquare(square)
T.equal(applied, 1, "loaded-square retry applies the effect")
T.equal(owner.worldEffect.state, "APPLIED",
    "effect reaches the applied state")
T.truthy(owner.applied, "effect adapter receives its owner")

local all = Effects.BuildSnapshot({ state = "ALL" })
T.equal(all.summary.applied, 1, "applied effect remains inspectable")
T.equal(all.rows[1].state, "APPLIED", "all-state filter exposes applied row")
T.truthy(dirty > 0, "effect lifecycle marks its provider dirty")

local lumberOwner = {
    id = "tree:one",
    outputEffect = {
        id = "lumber-output:one", kind = "LUMBER_OUTPUT",
        operation = "LUMBER_OUTPUT", state = "PENDING", phase = "CARRYING",
        sourceMode = "LIVE", deliveryMode = "WORLD_FLOOR",
        lootSource = "vanilla_tree_loot", pickupState = "NPC_INVENTORY",
        x = 10, y = 20, z = 0, quantity = 2, expectedLogYield = 2,
        sourceX = 10, sourceY = 20, sourceZ = 0,
        destinationX = 30, destinationY = 40, destinationZ = 0,
        destinationNodeId = "node:one", destinationStorageId = "storage:one",
        totalQuantity = 3, actualQuantity = 3,
        items = {
            { fullType = "Base.Log", quantity = 1, delivered = true },
            { fullType = "Base.Splinters", quantity = 2 },
        },
    },
}
T.truthy(Effects.RegisterProvider("lumber", {
    List = function() return { lumberOwner } end,
    GetOwnerID = function(value) return value.id end,
    GetEffects = function(value) return { value.outputEffect } end,
}), "lumber provider registration")
local lumberSnapshot = Effects.BuildSnapshot({
    state = "ALL", kind = "LUMBER_OUTPUT",
})
T.equal(#lumberSnapshot.rows, 1,
    "lumber output is visible through the world-effects snapshot")
T.equal(lumberSnapshot.rows[1].actualQuantity, 3,
    "lumber debug row exposes actual captured item quantity")
T.equal(lumberSnapshot.rows[1].progress, 1,
    "lumber debug row reports delivered item progress")
T.equal(lumberSnapshot.rows[1].phase, "CARRYING",
    "lumber debug row exposes the delivery phase")
T.equal(#lumberSnapshot.rows[1].endpoints, 2,
    "lumber debug row exposes floor and stockpile endpoints")
T.equal(lumberSnapshot.rows[1].endpoints[2].loaded, false,
    "lumber debug row reports an unloaded stockpile endpoint")

T.finish("pnc_world_effect_service_smoke")
