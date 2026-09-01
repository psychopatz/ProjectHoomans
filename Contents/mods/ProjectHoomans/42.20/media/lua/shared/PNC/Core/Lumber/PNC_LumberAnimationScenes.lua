-- Nonblocking chopping presentation. Damage remains server-side in the
-- lumber executor; this scene only drives the live NPC's visual state.
PNC = PNC or {}

local Scenes = PNC.AnimationScenes
if not Scenes or not Scenes.Register then return false end
local function tr(key) return getText and getText(key) or key end

Scenes.Register("lumber.chop", {
    label = tr("UI_PNC_LumberScene_Chop"),
    description = tr("UI_PNC_LumberScene_ChopDescription"),
    category = "lumber",
    priority = 40,
    repeatMode = "loop",
    blocking = false,
    steps = {
        { id = "chop_tree", bump = "ChopTree", durationMs = 1500 },
    },
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})

return true
