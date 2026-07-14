local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local removedId
local broadcastId
PNC = {
    Core = {
        Now = function() return 1000 end,
        GenerateID = function() return "token" end,
    },
    Const = {
        BODY_TAG_VERSION = 1,
        PRESENCE_CORPSE = "corpse",
    },
    Registry = {
        MarkDirty = function() end,
        RemoveRecord = function(id) removedId = id end,
    },
    Network = {
        BroadcastRemoval = function(id) broadcastId = id end,
    },
    BodyLifecycle = { Internal = {} },
}

dofile(ROOT .. "PNC_BodyLifecycle_State.lua")
dofile(ROOT .. "PNC_BodyLifecycle_World.lua")
dofile(ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")
dofile(ROOT .. "PNC_BodyLifecycle_Corpses.lua")

local reanimateAt
local corpseModData = {}
local corpse = {
    getModData = function() return corpseModData end,
    getX = function() return 1 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
    setFakeDead = function() end,
    setReanimateTime = function(_, value) reanimateAt = value end,
}
local record = {
    id = "infected_npc",
    alive = false,
    presenceState = "corpse",
    x = 1, y = 2, z = 0,
    runtime = {},
    corpse = { token = "corpse_token", createdWorldHour = 20 },
    health = {
        body = {
            infection = { fatal = true, reanimateAtWorldHour = 25 },
        },
    },
}

assert(PNC.BodyLifecycle.Internal.stampCorpse(record, corpse, "corpse_token"), "corpse stamp failed")
assertEqual(reanimateAt, 25, "infected corpse reanimation time")
assertEqual(corpseModData.PNC_BodyKind, "corpse", "managed corpse tag")

local clearedVariables = {}
local released = {}
released.getModData = function() return corpseModData end
released.clearVariable = function(_, name) clearedVariables[name] = true end
released.setUseless = function(_, value) released.useless = value end
released.setNoTeeth = function(_, value) released.noTeeth = value end
released.setZombiesDontAttack = function(_, value) released.zombiesDontAttack = value end
released.setReanimate = function() end
released.setCanWalk = function(_, value) released.canWalk = value end
released.getHealth = function() return 1 end

assert(PNC.BodyLifecycle.ReleaseReanimatedNPC(record, released), "reanimated release failed")
assertEqual(corpseModData.PNC_NPC, nil, "managed NPC tag cleared")
assertEqual(corpseModData.PNC_UUID, nil, "managed UUID cleared")
assertEqual(corpseModData.PNC_ReanimatedFrom, "infected_npc", "reanimation provenance")
assertEqual(released.useless, false, "ordinary zombie AI restored")
assertEqual(released.noTeeth, false, "ordinary zombie bite restored")
assertEqual(released.canWalk, true, "ordinary zombie locomotion restored")
assertEqual(clearedVariables.PNCLive, true, "humanized variables cleared")
assertEqual(broadcastId, "infected_npc", "client removal broadcast")
assertEqual(removedId, "infected_npc", "registry removal")

print("pnc_infected_reanimation_smoke: ok")
