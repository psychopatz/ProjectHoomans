local CATALOG_FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/Debug/"
        .. "PNC_AnimationDebugCatalog.lua"

PNC = {}
dofile(CATALOG_FILE)

local catalog = PNC.AnimationDebugCatalog
assert(catalog.generatedCount == 544, "catalog must include every zombie XML node")
assert(#catalog.entries == 544, "catalog entry count mismatch")
assert(catalog.stateCounts.hitreaction == 41, "nested hitreaction nodes missing")
assert(catalog.stateCounts.bumped == 236, "bumped node inventory mismatch")

local attack
local inheritedStagger
local keys = {}
for _, entry in ipairs(catalog.entries) do
    local key = entry.folder .. "/" .. entry.file
    assert(not keys[key], "duplicate catalog entry: " .. key)
    keys[key] = true
    if entry.state == "bumped"
        and entry.file == "PNC_Anim_Attack2H2.xml"
    then
        attack = entry
    elseif entry.state == "staggerback"
        and entry.file == "PNC_Anim_small.xml"
    then
        inheritedStagger = entry
    end
end

assert(attack, "Attack2H2 XML node missing")
assert(attack.node == "PNC_Anim_Attack2H2", "Attack2H2 node name mismatch")
assert(attack.anim == "Bob_AttackBat01_HitB", "Attack2H2 clip mismatch")
assert(attack.playable == true, "Attack2H2 must be playable")
assert(attack.conditions[2].name == "BumpType", "Attack2H2 selector missing")
assert(
    attack.conditions[2].value == "PNC_Legacy_Attack2H2",
    "Attack2H2 selector is not isolated from the canonical PNC graph"
)

assert(inheritedStagger, "derived stagger node missing")
assert(
    inheritedStagger.conditions[2].name == "hitforce",
    "x_extends condition name was not inherited by array index"
)
assert(
    inheritedStagger.conditions[2].kind == "LESS",
    "derived condition type did not override its parent"
)
assert(
    inheritedStagger.conditions[2].value == "0.0",
    "x_extends numeric condition value was not inherited"
)

print("pnc_animation_debug_catalog_smoke: ok")
