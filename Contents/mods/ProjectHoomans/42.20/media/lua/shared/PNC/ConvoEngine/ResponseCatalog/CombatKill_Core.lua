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
    "combat.kill.blade.aggressive.blade_head",
    "combat.kill.heavy_melee.aggressive.axe_head",
    "combat.kill.heavy_melee.aggressive.blunt",
    "combat.kill.heavy_melee.aggressive.spear",
    "combat.kill.firearm.brave.firearm_high",
    "combat.kill.blade.brave.blade_head",
    "combat.kill.heavy_melee.brave.axe",
    "combat.kill.heavy_melee.brave.spear",
    "combat.kill.firearm.cold.firearm_high",
    "combat.kill.blade.cold.blade_head",
    "combat.kill.heavy_melee.cold.heavy_melee",
    "combat.kill.firearm.practical.firearm_high",
    "combat.kill.firearm.practical.firearm_low",
    "combat.kill.blade.practical.blade",
    "combat.kill.heavy_melee.practical.axe_spear",
    "combat.kill.heavy_melee.practical.blunt",
    "combat.kill.unarmed.practical.unarmed",
    "combat.kill.firearm.reserved.firearm",
    "combat.kill.blade.reserved.blade",
    "combat.kill.firearm.shaken.firearm_low",
    "combat.kill.blade.shaken.blade_head",
    "combat.kill.unarmed.shaken.unarmed",
    "combat.kill.firearm.supportive.firearm",
    "combat.kill.heavy_melee.supportive.melee",
    "combat.assault.react.shaken",
    "combat.assault.react.aggressive",
    "combat.assault.react.brave",
    "combat.assault.react.reserved",
    "combat.assault.react.default",
}

for _, templateID in ipairs(SINGLE_TEMPLATES) do
    installFamily(templateID)
end

local MULTI_SAY_FAMILIES = {
    {
        id = "combat.kill.firearm.aggressive.firearm_high_named",
        planID = "combat.kill.firearm",
        stylePrefix = "aggressive.firearm_high_named.say.",
        count = 2,
    },
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
    if entry.planID and entry.stylePrefix then
        for index = 1, entry.count do
            local key = tostring(index)
            installFamily(entry.id .. ".say." .. key, {
                planID = entry.planID,
                style = entry.stylePrefix .. key,
                targetStyle = "neutral",
                installAs = entry.id .. ".say." .. key,
            })
        end
    else
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
end

return true
