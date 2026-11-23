-- Immediate pain-reaction Beat pool (combat.injury.pain_reaction).
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
local Shared = type(Catalog) == "table" and Catalog.CombatInjuryShared or nil
if type(Shared) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local PREFIX = "combat.injury.pain_reaction"
local POOL = "semantic.combat.injury.pain_reaction"
local FALLBACK = "Gah, got hit on my {slot.wound.part}!"
local ROLES = {
    "scratch_minor", "scratch_stoic", "scratch_aggressive",
    "laceration_moderate", "laceration_severe", "laceration_aggressive", "laceration_stoic",
    "fracture", "deep_wound", "deep_wound_glass", "burn",
    "bullet", "bullet_stoic",
    "bite", "bite_panicked", "bite_non_transmissible",
    "multiple_hits_severe", "default",
}

Shared.install(PREFIX, ROLES)
local out = {}
for _, vid in ipairs(ROLES) do
    local isDefault = vid == "default"
    out[#out + 1] = Shared.makeVariant(
        POOL, PREFIX, vid,
        (not isDefault) and { combatReactionRole = vid } or nil,
        isDefault and 10 or 95, "REACT", FALLBACK
    )
end
Catalog.Register(POOL, { variants = out })

local OBS_PREFIX = "combat.injury.visible_observation"
local OBS_POOL = "semantic.combat.injury.visible_observation"
local OBS_FALLBACK = "You look hurt, {addressee.name}."
local OBS_ROLES = {
    "open_wound", "heavy_bleeding", "dirty_bandage",
    "suspected_infection", "medic_infection_assessment", "medic_triage_offer",
    "limp_mobility", "multiple_wounds_escalation", "new_wound_noticed",
    "visible_bite", "feverish_weak",
    "default",
}

Shared.install(OBS_PREFIX, OBS_ROLES)
local obsOut = {}
for _, vid in ipairs(OBS_ROLES) do
    local isDefault = vid == "default"
    obsOut[#obsOut + 1] = Shared.makeVariant(
        OBS_POOL, OBS_PREFIX, vid,
        (not isDefault) and { combatReactionRole = vid } or nil,
        isDefault and 10 or 95, "WARN", OBS_FALLBACK
    )
end
Catalog.Register(OBS_POOL, { variants = obsOut })

return true
