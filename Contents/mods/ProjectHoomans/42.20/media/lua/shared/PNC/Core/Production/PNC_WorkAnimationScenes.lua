PNC = PNC or {}

local Scenes = PNC.AnimationScenes
if not Scenes or not Scenes.Register then return false end
local function tr(key) return getText and getText(key) or key end
local RESEARCH_LABEL = tr("UI_PNC_WorkScene_Research")
local CRAFT_LABEL = tr("UI_PNC_WorkScene_Craft")
local DISASSEMBLY_LABEL = tr("UI_PNC_WorkScene_Disassemble")

local function interrupts()
    return { movement = true, combat = true, externalBump = true,
        abstract = true }
end

Scenes.Register("production.research", {
    label = RESEARCH_LABEL,
    description = tr("UI_PNC_WorkScene_ResearchDescription"),
    category = "production", priority = 40, repeatMode = "loop",
    -- WorkBehavior must keep ticking while the scene supplies presentation;
    -- otherwise a blocking loop owns BehaviorSystem and freezes work progress.
    blocking = false, bump = "Read", durationMs = 4200,
    interrupts = interrupts(),
})

Scenes.Register("production.craft", {
    label = CRAFT_LABEL,
    description = tr("UI_PNC_WorkScene_CraftDescription"),
    category = "production", priority = 40, repeatMode = "loop",
    blocking = false, stepGapMs = 250,
    steps = {
        { id = "measure", bump = "Build", durationMs = 3200 },
        { id = "assemble", bump = "SawLog", durationMs = 4200 },
    },
    interrupts = interrupts(),
})

Scenes.Register("production.disassemble", {
    label = DISASSEMBLY_LABEL,
    description = tr("UI_PNC_WorkScene_DisassembleDescription"),
    category = "production", priority = 40, repeatMode = "loop",
    blocking = false, bump = "Build", durationMs = 3800,
    interrupts = interrupts(),
})

return true
