local T = require "tests/support/test"

local CATALOG_FILE =
    T.path("ProjectHoomans", "client", "PNC/Debug/")
        .. "PNC_AnimationDebugCatalog.lua"

PNC = {}
T.load(CATALOG_FILE)

local catalog = PNC.AnimationDebugCatalog
T.truthy(catalog.generatedCount == 535, "catalog must include every zombie XML node")
T.truthy(#catalog.entries == 535, "catalog entry count mismatch")
T.truthy(catalog.stateCounts.hitreaction == 41, "nested hitreaction nodes missing")
T.truthy(catalog.stateCounts.bumped == 237, "bumped node inventory mismatch")

local attack
local inheritedStagger
local fenceStart
local fenceEnd
local sitChair
local keys = {}
for _, entry in ipairs(catalog.entries) do
    local key = entry.folder .. "/" .. entry.file
    T.truthy(not keys[key], "duplicate catalog entry: " .. key)
    keys[key] = true
    if entry.state == "bumped"
        and entry.file == "PNC_Anim_Attack2H2.xml"
    then
        attack = entry
    elseif entry.state == "staggerback"
        and entry.file == "PNC_Anim_small.xml"
    then
        inheritedStagger = entry
    elseif entry.state == "bumped"
        and entry.file == "PNC_Anim_ClimbFenceStart.xml"
    then
        fenceStart = entry
    elseif entry.state == "bumped"
        and entry.file == "PNC_Anim_ClimbFenceEnd.xml"
    then
        fenceEnd = entry
    elseif entry.state == "bumped"
        and entry.file == "PNC_Anim_SitChair.xml"
    then
        sitChair = entry
    end
end

T.truthy(attack, "Attack2H2 XML node missing")
T.truthy(attack.node == "PNC_Anim_Attack2H2", "Attack2H2 node name mismatch")
T.truthy(attack.anim == "Bob_AttackBat01_HitB", "Attack2H2 clip mismatch")
T.truthy(attack.playable == true, "Attack2H2 must be playable")
T.truthy(attack.conditions[2].name == "BumpType", "Attack2H2 selector missing")
T.truthy(
    attack.conditions[2].value == "PNC_Legacy_Attack2H2",
    "Attack2H2 selector is not isolated from the canonical PNC graph"
)

T.truthy(inheritedStagger, "derived stagger node missing")
T.truthy(
    inheritedStagger.conditions[2].name == "hitforce",
    "x_extends condition name was not inherited by array index"
)
T.truthy(
    inheritedStagger.conditions[2].kind == "LESS",
    "derived condition type did not override its parent"
)
T.truthy(
    inheritedStagger.conditions[2].value == "0.0",
    "x_extends numeric condition value was not inherited"
)
T.truthy(fenceStart and fenceEnd, "split fence animation nodes missing")
T.truthy(
    fenceStart.anim == "Bob_VaultOver_Start",
    "fence raise clip mismatch"
)
T.truthy(
    fenceStart.events[1].parameter == "PNCTraversalPhase=transfer",
    "fence raise does not hand off to crossing phase"
)
T.truthy(
    fenceEnd.anim == "Bob_VaultOver_End",
    "fence landing clip mismatch"
)
T.truthy(sitChair, "chair seating animation node missing")
T.truthy(sitChair.anim == "Bob_SatChair",
    "chair seating must use the vanilla chair pose")
T.truthy(sitChair.looped == true,
    "chair seating pose must remain looped")
T.finish("pnc_animation_debug_catalog_smoke")

T.finish("pnc_animation_debug_catalog_smoke")
