local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

local function assertEq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", tostring(msg), tostring(expected), tostring(actual)), 2)
    end
end

local function assertTruthy(val, msg)
    if not val then
        error(tostring(msg or "expected truthy value"), 2)
    end
end

local serverMode = false
local bloodDecalsOption = 10
local splats = {}

isServer = function() return serverMode end
isClient = function() return false end
ZombRand = function(bound) return math.floor((bound or 1) / 2) end
getCore = function()
    return {
        getOptionBloodDecals = function() return bloodDecalsOption end,
    }
end

local chunk = {
    addBloodSplat = function(_, x, y, z, splatType)
        splats[#splats + 1] = { x = x, y = y, z = z, splatType = splatType }
    end,
}

local square = {
    _solid = true,
    isSolidFloor = function(self) return self._solid end,
    getChunk = function() return chunk end,
    getX = function() return 10 end,
    getY = function() return 20 end,
}

local body = {
    getX = function() return 10.5 end,
    getY = function() return 20.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return square end,
}

PNC = { Core = { Now = function() return 10000 end } }
local Wounds = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BloodDrops"

local record = { id = "npc_bleed_1", alive = true, x = 10.5, y = 20.5, z = 0, runtime = {} }
local health = { state = "normal" }

-- 1) Non-bleeding NPC drops no blood.
assertEq(Wounds.TryDropBleedingBlood(record, body, { bleedingRate = 0 }, health, 10000), false, "Non-bleeding NPC should not drop blood")
assertEq(#splats, 0, "No splats should be created when bleedingRate is 0")

-- 2) Respects player's Blood Decals = 0 (None) setting in singleplayer.
bloodDecalsOption = 0
assertEq(Wounds.TryDropBleedingBlood(record, body, { bleedingRate = 0.06 }, health, 10000), false, "Blood option 0 should suppress blood drops")
assertEq(#splats, 0, "No splats should be created when blood option is 0")

-- 3) Full Blood Decals = 10 drops blood within current tile and sets cooldown.
bloodDecalsOption = 10
assertEq(Wounds.TryDropBleedingBlood(record, body, { bleedingRate = 0.06 }, health, 10000), true, "Bleeding NPC should drop blood when option > 0")
assertEq(#splats, 1, "Exactly 1 blood splat should be added")
assertTruthy(splats[1].x >= 10.05 and splats[1].x <= 10.95, "Splat X should stay inside current tile")
assertTruthy(splats[1].y >= 20.05 and splats[1].y <= 20.95, "Splat Y should stay inside current tile")
assertTruthy(splats[1].splatType >= 0 and splats[1].splatType <= 7, "Moderate bleeding should emit indexed small droplet (0..7)")

-- Cooldown prevents spamming on immediate next tick.
assertEq(Wounds.TryDropBleedingBlood(record, body, { bleedingRate = 0.06 }, health, 11000), false, "Cooldown should throttle blood drops")
local nextAtFull = record.runtime.nextBloodDropAt

-- 4) Lower blood option (5 = 50%) doubles the interval compared to 10 (100%).
bloodDecalsOption = 5
record.runtime.nextBloodDropAt = 0
assertEq(Wounds.TryDropBleedingBlood(record, body, { bleedingRate = 0.06 }, health, 20000), true, "50% blood option should still drop blood")
local intervalFull = nextAtFull - 10000
local intervalHalf = record.runtime.nextBloodDropAt - 20000
assertTruthy(intervalHalf > intervalFull * 1.5, "50% blood setting should lengthen drop interval")

-- 5) Dedicated MP server emits native chunk:addBloodSplat regardless of local client getCore() option.
serverMode = true
bloodDecalsOption = 0
record.runtime.nextBloodDropAt = 0
assertEq(Wounds.TryDropBleedingBlood(record, body, { bleedingRate = 0.06 }, { state = "incapacitated" }, 30000), true, "MP server should emit native AddBlood even for incapacitated bleeding NPC")
assertEq(#splats, 3, "MP server should have emitted 3rd splat")

print("PASS: pnc_npc_bleeding_blood_drops_smoke")
