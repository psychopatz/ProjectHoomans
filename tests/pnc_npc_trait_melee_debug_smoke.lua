local T = require "tests/support/test"

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")
local Model = T.load(
    "ProjectHoomans", "client", "PNC/UI/PNC_NPCTraitDebugModel.lua")

local ok, id = Registry.Register({
    id = "debugmod:melee_trait",
    labelKey = "UI_DebugMod_Trait_Melee",
    effects = {
        combat = {
            melee = {
                attackRateMultiplier = 1.20,
                windupTimeMultiplier = 0.85,
                hitChanceBias = -0.04,
                pressureAccuracyBias = 0.03,
            },
        },
    },
})
T.truthy(ok, "debug melee trait registration succeeds")

local definition = Registry.GetDefinition(id)
local rows = {}
for _, row in ipairs(Model.BuildRows(definition)) do
    rows[#rows + 1] = row.label .. "=" .. row.value
end
local detail = table.concat(rows, "\n")
T.contains(detail, "Combat / Melee / Attack rate=x1.20 (+20%)",
    "debug details format melee cadence")
T.contains(detail, "Combat / Melee / Wind-up time=x0.85 (-15%)",
    "debug details format melee wind-up")
T.contains(detail, "Combat / Melee / Hit chance=-4.00 percentage points",
    "debug details format melee accuracy")
T.contains(detail, "Combat / Melee / Pressure accuracy=+3.00 percentage points",
    "debug details format melee pressure accuracy")

T.finish("pnc_npc_trait_melee_debug_smoke")
