local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Catalog = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)

local function explain(pool, context, salt)
    local result = Catalog.ExplainSelection(pool, context, salt or "b5")
    T.truthy(result and result.ok, "selection explanation is available")
    return result
end

local blade = explain("semantic.combat.kill.killer.aggressive", {
    npcID = "npc-blade",
    combatWeaponFamily = "long_blade",
    combatHitZone = "head_neck",
    combatSkillBand = "trained",
    combatWeaponNamed = true,
}, "blade-head")
T.equal(blade.selectedID,
    "semantic.combat.kill.killer.aggressive.blade_head_01",
    "aggressive head blade kill selects grounded gore family")

local torsoBlade = explain("semantic.combat.kill.killer.aggressive", {
    npcID = "npc-blade-torso",
    combatWeaponFamily = "long_blade",
    combatHitZone = "torso",
    combatSkillBand = "trained",
    combatWeaponNamed = true,
}, "blade-torso")
T.falsy(string.find(tostring(torsoBlade.selectedID), "blade_head", 1, true),
    "torso blade kill cannot select head/teeth family")

local firearm = explain("semantic.combat.kill.killer.brave", {
    npcID = "npc-gun",
    combatWeaponFamily = "firearm",
    combatHitZone = "head_neck",
    combatSkillBand = "high",
    combatWeaponNamed = true,
}, "gun-high")
T.equal(firearm.selectedID,
    "semantic.combat.kill.killer.brave.firearm_high_01",
    "high-skill brave firearm kill selects sharpshooting family")
T.falsy(string.find(firearm.selectedID, "blade", 1, true),
    "firearm kill cannot select blade family")

local nervous = explain("semantic.combat.kill.killer.shaken", {
    npcID = "npc-lowgun",
    combatWeaponFamily = "firearm",
    combatHitZone = "head_neck",
    combatSkillBand = "low",
    combatWeaponNamed = true,
}, "gun-low")
T.equal(nervous.selectedID,
    "semantic.combat.kill.killer.shaken.firearm_low_01",
    "low-skill shaken firearm kill selects relief/surprise family")

local unarmed = explain("semantic.combat.kill.killer.practical", {
    npcID = "npc-hands",
    combatWeaponFamily = "unarmed",
    combatHitZone = "head_neck",
    combatSkillBand = "trained",
    combatWeaponNamed = false,
}, "hands")
T.equal(unarmed.selectedID,
    "semantic.combat.kill.killer.practical.unarmed_01",
    "unarmed kill has a distinct grounded family")

local unknown = explain("semantic.combat.kill.killer.practical", {
    npcID = "npc-unknown",
    combatWeaponFamily = "other_melee",
    combatHitZone = "unknown",
    combatSkillBand = "low",
    combatWeaponNamed = false,
}, "unknown")
T.contains(unknown.selectedID, "semantic.combat.reaction.kill_killer_practical_",
    "unknown/modded melee degrades to existing generic safe fallback")

T.finish("pnc_semantic_combat_weapon_selection_smoke")
