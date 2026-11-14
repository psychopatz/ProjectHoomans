-- ProjectHoomans combat-kill wording projected from final ConvoEngine plans
-- into the existing phrase-family/SpeechRealization authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local DEFAULT_OWNER = "projecthoomans.dialogue_content.events"

local function installFamily(templateID, options)
    local opts = { defaultContentOwner = DEFAULT_OWNER }
    if type(options) == "table" then
        for key, value in pairs(options) do
            opts[key] = value
        end
    end
    return ConvoPlanFamily.install(templateID, opts)
end

local SINGLE_TEMPLATES = {
    "combat.kill.killer.aggressive.blade_head",
    "combat.kill.killer.aggressive.axe_head",
    "combat.kill.killer.aggressive.blunt",
    "combat.kill.killer.aggressive.spear",
    "combat.kill.killer.brave.firearm_high",
    "combat.kill.killer.brave.blade_head",
    "combat.kill.killer.brave.axe",
    "combat.kill.killer.brave.spear",
    "combat.kill.killer.cold.firearm_high",
    "combat.kill.killer.cold.blade_head",
    "combat.kill.killer.cold.heavy_melee",
    "combat.kill.killer.practical.firearm_high",
    "combat.kill.killer.practical.firearm_low",
    "combat.kill.killer.practical.blade",
    "combat.kill.killer.practical.axe_spear",
    "combat.kill.killer.practical.blunt",
    "combat.kill.killer.practical.unarmed",
    "combat.kill.killer.reserved.firearm",
    "combat.kill.killer.reserved.blade",
    "combat.kill.killer.shaken.firearm_low",
    "combat.kill.killer.shaken.blade_head",
    "combat.kill.killer.shaken.unarmed",
    "combat.kill.killer.supportive.firearm",
    "combat.kill.killer.supportive.melee",
    "combat.player_assaulted.shaken",
    "combat.player_assaulted.aggressive",
    "combat.player_assaulted.brave",
    "combat.player_assaulted.reserved",
    "combat.player_assaulted.default",
}

for _, templateID in ipairs(SINGLE_TEMPLATES) do
    installFamily(templateID)
end

local MULTI_SAY_FAMILIES = {
    { id = "combat.kill.killer.aggressive.firearm_high_named", count = 2 },
    { id = "combat.human_kill.aggressive", count = 3 },
    { id = "combat.human_kill.brave", count = 3 },
    { id = "combat.human_kill.cold", count = 3 },
    { id = "combat.human_kill.practical", count = 3 },
    { id = "combat.human_kill.reserved", count = 3 },
    { id = "combat.human_kill.shaken", count = 3 },
    { id = "combat.human_kill.supportive", count = 3 },
    { id = "combat.reaction.kill_killer_aggressive", count = 3 },
    { id = "combat.reaction.kill_killer_brave", count = 3 },
    { id = "combat.reaction.kill_killer_cold", count = 3 },
    { id = "combat.reaction.kill_killer_practical", count = 3 },
    { id = "combat.reaction.kill_killer_reserved", count = 3 },
    { id = "combat.reaction.kill_killer_shaken", count = 3 },
    { id = "combat.reaction.kill_killer_supportive", count = 3 },
    { id = "combat.reaction.kill_witness_aggressive", count = 3 },
    { id = "combat.reaction.kill_witness_brave", count = 3 },
    { id = "combat.reaction.kill_witness_cold", count = 3 },
    { id = "combat.reaction.kill_witness_practical", count = 3 },
    { id = "combat.reaction.kill_witness_reserved", count = 3 },
    { id = "combat.reaction.kill_witness_shaken", count = 3 },
    { id = "combat.reaction.kill_witness_supportive", count = 3 },
}

for _, entry in ipairs(MULTI_SAY_FAMILIES) do
    installFamily(entry.id)
    for index = 1, entry.count do
        local key = tostring(index)
        installFamily(entry.id, {
            planID = entry.id,
            realizationKey = key,
            installAs = entry.id .. ".say." .. key,
        })
    end
end

return true
