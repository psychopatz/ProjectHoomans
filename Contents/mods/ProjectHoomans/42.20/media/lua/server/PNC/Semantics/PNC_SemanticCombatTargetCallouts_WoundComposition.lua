-- Realizes selected-wound facts through the existing localized utterance planner.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local UtterancePlan = require "PNC/ConvoEngine/UtterancePlan"
local TreatmentSpeech = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_TreatmentSpeech"
local Composition = {}

local BODY_PART_LEXEMES = {
    UpperLeg_L = "COMBAT_INJURY_THIGH", UpperLeg_R = "COMBAT_INJURY_THIGH",
    LowerLeg_L = "COMBAT_INJURY_SHIN", LowerLeg_R = "COMBAT_INJURY_SHIN",
    Foot_L = "COMBAT_INJURY_FOOT", Foot_R = "COMBAT_INJURY_FOOT",
    Groin = "COMBAT_INJURY_GROIN",
}

function Composition.Realize(profile, opts)
    local wound = profile and profile.selectedWound
    if not wound then return nil end
    opts = opts or {}
    local observed = opts.observed == true
    local material, treatment, dirty = TreatmentSpeech.Describe(wound, observed and not opts.treatmentKnown)
    local part = BODY_PART_LEXEMES[wound.bodyPart]
    local mobility = not observed and treatment ~= "splinted" and wound.bandaged == true
        and part and wound.locomotionImpaired == true
        and (wound.functionalImpairment == "limb_mobility" or wound.functionalImpairment == "pelvic_mobility")
    if not material and not mobility then return nil end
    local clauses = {}
    local dressing = { strategy = "INJURY_DRESSING", claims = { "bandaged" } }
    if material then
        local subject = observed and "VISIBLE" or "SELF"
        local action = treatment == "splinted" and "SPLINT" or "DRESSING"
        dressing.strategy = "INJURY_" .. subject .. "_" .. action .. "_MATERIAL"
        dressing.claims = { treatment, material }
    end
    if dirty or (not material and wound.bandageDirty == true) then
        dressing.modifiers = { "DRESSING_DIRTY" }
        dressing.claims[#dressing.claims + 1] = "bandageDirty"
    end
    clauses[1] = dressing
    if mobility then
        local referent = { id = wound.bodyPart, kind = "WOUND" }
        dressing.introduces = referent
        clauses[2] = {
            strategy = "INJURY_MOBILITY", relation = "CONTRAST", reference = referent,
            referenceAmbiguous = (tonumber(profile.totalWoundCount) or 1) > 1,
            claims = { "locomotionImpaired" },
        }
    end
    local result, reason = UtterancePlan.Realize(UtterancePlan.New({
        locale = opts and opts.locale, styleVariant = opts and opts.styleVariant,
        dialogueAct = "INFORM", strategy = "INJURY_STATUS", topic = "combat_injury",
        lexemes = { wound_part = part, treatment_material = material },
        composition = { clauses = clauses, focus = opts and opts.focus },
    }))
    if not result then return nil, reason end
    result.text = string.upper(string.sub(result.text, 1, 1)) .. string.sub(result.text, 2) .. "."
    return result
end

return Composition
