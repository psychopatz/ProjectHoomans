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

isServer = function() return true end
isClient = function() return false end
PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }

local RipRules = require "PNC/WorldItems/PNC_WorldItemContext_RipRules"

local corpseShirt = {
    isClothing = true,
    isEquipped = function() return true end,
    getFabricType = function() return "Cotton" end,
    getDirtyness = function() return 0.5 end,
    getBloodLevel = function() return 0.4 end,
}

-- 1) Equipped clothing is protected by default (live NPC's own clothes).
assertEq(RipRules.InspectRippable(corpseShirt, "Base.Tshirt_DefaultTEXTURE_TINT", "clothing"), nil,
    "Equipped clothing must not be ripped outside corpse source")

-- 2) Worn clothing on a dead zombie corpse IS rippable into Base.RippedSheets!
local rip = RipRules.InspectRippable(corpseShirt, "Base.Tshirt_DefaultTEXTURE_TINT", "clothing", {
    sourceType = "corpse",
    allowEquipped = true,
})
assertTruthy(rip, "Corpse worn cotton shirt must be rippable")
assertEq(rip.canRip, true, "Corpse shirt canRip should be true")
assertEq(rip.outputType, "Base.RippedSheets", "Cotton shirt should rip into Base.RippedSheets")
assertEq(rip.outputCount, 2, "Cotton shirt should yield 2 ripped sheets")
assertEq(rip.requiresScissors, false, "Cotton shirt should not require scissors")

print("PASS: pnc_corpse_rip_and_medical_deadlock_smoke")
