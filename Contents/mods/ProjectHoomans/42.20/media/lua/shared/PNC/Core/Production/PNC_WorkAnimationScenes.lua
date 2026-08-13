PNC = PNC or {}

local Scenes = PNC.AnimationScenes
if not Scenes or not Scenes.Register then return false end
local function tr(key) return getText and getText(key) or key end
local RESEARCH_LABEL = tr("UI_PNC_WorkScene_Research")
local CRAFT_LABEL = tr("UI_PNC_WorkScene_Craft")
local DISASSEMBLY_LABEL = tr("UI_PNC_WorkScene_Disassemble")
local CONSTRUCTION_LABEL = tr("UI_PNC_WorkScene_Construct")

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
    blocking = false, stepGapMs = 180,
    steps = {
        { id = "read_book", bump = "ReadBook", durationMs = 5200 },
        { id = "wipe_brow", bump = "WipeBrow", durationMs = 1800 },
        { id = "read_book_again", bump = "ReadBook", durationMs = 5200 },
        { id = "wipe_head", bump = "WipeHead", durationMs = 1900 },
        { id = "affirm", bump = "Yes", durationMs = 1700 },
    },
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

Scenes.Register("production.construct", {
    label = CONSTRUCTION_LABEL,
    description = tr("UI_PNC_WorkScene_ConstructDescription"),
    category = "production", priority = 40, repeatMode = "loop",
    -- These are the two concrete PNC bump nodes exposed by the animation
    -- graph. The scene remains nonblocking so WorkBehavior can keep adding
    -- work points while the ordered sequence repeats for the whole task.
    blocking = false, stepGapMs = 150,
    steps = {
        { id = "hammer_high", bump = "Hammer", durationMs = 2800 },
        { id = "hammer_low", bump = "HammerLow", durationMs = 3000 },
    },
    interrupts = interrupts(),
})

return true
