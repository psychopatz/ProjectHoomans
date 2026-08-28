local T = require "tests/support/test"

local entry = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_NPCWounds.lua"
)
local calls = {}
require = function(name)
    calls[#calls + 1] = name
    return {}
end
PNC = {}

T.load(entry)

local expected = {
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Definitions",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ClothingCoverage",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Clothing",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BodyState",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_WholeBody",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Infection",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Mutation",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ZombieAttack",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Debug",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Treatment",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Update",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Snapshot",
}

for index = 1, #expected do
    T.equal(
        calls[index],
        expected[index],
        "NPCWounds dependency " .. tostring(index)
    )
end
T.equal(#calls, #expected, "NPCWounds dependency count")

T.finish("pnc_npc_wounds_presence_boundary_smoke")
