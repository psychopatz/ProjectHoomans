-- Combat injury callout, received-wound beat, and ally reaction response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.events"

local INJURY_FIGHTING_ROLES = {
    "with_wounds_head_neck_critical", "with_wounds_head_neck",
    "with_wounds_torso_critical", "with_wounds_torso",
    "with_wounds_pelvis_groin_severe", "with_wounds_pelvis_groin",
    "with_wounds_upper_limb_severe", "with_wounds_upper_limb",
    "with_wounds_lower_limb_severe", "with_wounds_lower_limb",
    "with_wounds_minor", "with_wounds_dirty_bandage",
    "patched_up_head_neck_severe", "patched_up_head_neck",
    "patched_up_torso_severe", "patched_up_torso",
    "patched_up_pelvis_groin_severe", "patched_up_pelvis_groin",
    "patched_up_upper_limb_severe", "patched_up_upper_limb",
    "patched_up_lower_limb_severe", "patched_up_lower_limb",
    "patched_up_minor",
    "with_wounds_bite_lethal", "with_wounds_bite_possible_exposure",
    "with_wounds_bite_confirmed_symptomatic", "with_wounds_bite_non_transmissible",
    "patched_up_bite_lethal", "patched_up_bite_possible_exposure",
    "patched_up_bite_confirmed_symptomatic", "patched_up_bite_non_transmissible",
    "default",
}

local WOUND_RECEIVED_TYPES = {
    "bite_lethal", "bite_possible_exposure", "bite_confirmed_symptomatic",
    "bite_non_transmissible", "bullet",
    "deep_wound_glass", "deep_wound", "fracture",
    "burn", "laceration", "scratch",
    "post_combat_injury_check", "severity_escalation", "bandage_dirty",
    "treatment_stabilized", "knox_symptom_onset", "fever_onset",
    "cold_illness_onset", "hypothermia_onset", "hyperthermia_onset",
    "soaked_chill", "default",
}

local ALLY_REACTION_ROLES = {
    "close_bond_bite_lethal", "close_bond_critical", "close_bond_patched",
    "supportive_cover_wounded", "supportive_cover_patched",
    "tactical_cover_wounded", "tactical_cover_patched",
    "squad_crossfire_wingman", "bite_non_transmissible_relief",
    "low_rel_dismissive", "low_rel_bite_execution_threat",
    "psychopath_bite_execution_threat", "default",
}

local function installInjuryTemplates(prefix, ids)
    for _, vid in ipairs(ids) do
        ConvoPlanFamily.install(prefix .. "." .. vid, {
            defaultContentOwner = CONTENT_OWNER,
        })
    end
end

installInjuryTemplates("combat.fighting.injured_callout", INJURY_FIGHTING_ROLES)
installInjuryTemplates("combat.wound.received_beat", WOUND_RECEIVED_TYPES)
installInjuryTemplates("combat.wound.ally_reaction", ALLY_REACTION_ROLES)

local INJURY_REPLY_OFFERS = {
    {
        id = "combat.injury.check_where_hit",
        labelKey = "UI_PNC_CombatInjury_CheckWhere_Label",
        labelFallback = "Ask where you're hit and how bad it is",
        utteranceKey = "UI_PNC_CombatInjury_CheckWhere_Utterance",
        utteranceFallback = "Where did they get you? Is that wrap still holding?",
        frame = { intent = "QUESTION", speechAct = "QUESTION", subject = "COMBAT_INJURY" },
        constraints = { path = "npcState.hasActiveInjury", op = "eq", value = true },
    },
    {
        id = "combat.injury.offer_cover_wrap",
        labelKey = "UI_PNC_CombatInjury_OfferCover_Label",
        labelFallback = "Cover them while they patch up",
        utteranceKey = "UI_PNC_CombatInjury_OfferCover_Utterance",
        utteranceFallback = "I have eyes on the dead. Tie that wound off right now!",
        frame = { intent = "ACCEPT", speechAct = "ACCEPT", subject = "COMBAT_INJURY", stateValue = "covered_for_treatment" },
        constraints = { path = "npcState.hasOpenWounds", op = "eq", value = true },
    },
    {
        id = "combat.injury.order_fallback",
        labelKey = "UI_PNC_CombatInjury_OrderFallback_Label",
        labelFallback = "Order them behind the line",
        utteranceKey = "UI_PNC_CombatInjury_OrderFallback_Utterance",
        utteranceFallback = "You're bleeding too hard to trade swings! Pull back behind me!",
        frame = { intent = "CLARIFY", speechAct = "CLARIFY", subject = "COMBAT_INJURY", stateValue = "ordered_fallback" },
        constraints = { path = "npcState.hasActiveInjury", op = "eq", value = true },
    },
    {
        id = "combat.injury.check_bite_exposure",
        labelKey = "UI_PNC_CombatInjury_CheckBite_Label",
        labelFallback = "Check the bite mark immediately",
        utteranceKey = "UI_PNC_CombatInjury_CheckBite_Utterance",
        utteranceFallback = "Wait, was that teeth? Let me see that bite right now!",
        frame = { intent = "WARN", speechAct = "WARN", subject = "COMBAT_INJURY", stateValue = "bitten" },
        constraints = { path = "npcState.isBitten", op = "eq", value = true },
    },
}

local FALLBACK_BY_PREFIX = {
    ["combat.fighting.injured_callout"] = "Still fighting through this wound—watch my flank!",
    ["combat.wound.received_beat"] = "Took a hit! Still on my feet!",
    ["combat.wound.ally_reaction"] = "Stay on my side—I've got your cover!",
}

local function makeInjuryVariant(poolID, prefix, vid, when, priority, act, fallback)
    local templateID = prefix .. "." .. vid
    return {
        id = poolID .. "." .. vid,
        templateID = templateID,
        fallback = fallback or FALLBACK_BY_PREFIX[prefix],
        contentOwner = CONTENT_OWNER,
        when = when,
        priority = priority or 0,
        plan = {
            dialogueAct = act,
            sourcePoolID = poolID,
            topic = "combat_injury",
            presentationClass = "BARK",
            turns = { {
                segments = {
                    { kind = "translation", templateID = templateID },
                },
                offers = INJURY_REPLY_OFFERS,
            } },
        },
    }
end

local function registerExactRolePool(poolID, prefix, variants, act, defaultId, useWoundType)
    local out = {}
    for _, vid in ipairs(variants) do
        local isDefault = vid == (defaultId or "default")
        local when = not isDefault and (useWoundType
            and { combatWoundType = vid }
            or { combatReactionRole = vid }) or nil
        out[#out + 1] = makeInjuryVariant(
            poolID, prefix, vid, when, isDefault and 10 or 95, act
        )
    end
    Catalog.Register(poolID, { variants = out })
end

registerExactRolePool(
    "semantic.combat.fighting.injured_callout",
    "combat.fighting.injured_callout",
    INJURY_FIGHTING_ROLES, "WARN", "default", false
)
registerExactRolePool(
    "semantic.combat.wound.received_beat",
    "combat.wound.received_beat",
    WOUND_RECEIVED_TYPES, "REACT", "default", true
)
registerExactRolePool(
    "semantic.combat.wound.ally_reaction",
    "combat.wound.ally_reaction",
    ALLY_REACTION_ROLES, "REACT", "default", false
)

Catalog.CombatInjuryShared = { makeVariant = makeInjuryVariant, install = installInjuryTemplates }

require "PNC/ConvoEngine/ResponseCatalog/Social_Reactions_CombatInjury_Pain"
require "PNC/ConvoEngine/ResponseCatalog/Social_Reactions_CombatInjury_Triage"

return true
