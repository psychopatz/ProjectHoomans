-- Realizes selected-wound facts through the existing localized utterance planner.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local UtterancePlan = require "PNC/ConvoEngine/UtterancePlan"
local Composition = {}

local BODY_PART_LEXEMES = {
    UpperLeg_L = "COMBAT_INJURY_THIGH", UpperLeg_R = "COMBAT_INJURY_THIGH",
    LowerLeg_L = "COMBAT_INJURY_SHIN", LowerLeg_R = "COMBAT_INJURY_SHIN",
    Foot_L = "COMBAT_INJURY_FOOT", Foot_R = "COMBAT_INJURY_FOOT",
    Groin = "COMBAT_INJURY_GROIN",
}

function Composition.Realize(profile, opts)
    local wound = profile.selectedWound
    if not wound or wound.bandaged ~= true or wound.locomotionImpaired ~= true
        or (wound.functionalImpairment ~= "limb_mobility" and wound.functionalImpairment ~= "pelvic_mobility") then
        return nil
    end
    local lexeme = BODY_PART_LEXEMES[wound.bodyPart]
    if not lexeme or not wound.bodyPart then return nil end

    local referent = { id = wound.bodyPart, kind = "WOUND" }
    local dressing = {
        strategy = "INJURY_DRESSING", claims = { "bandaged" }, introduces = referent,
    }
    if wound.bandageDirty == true then
        dressing.modifiers = { "DRESSING_DIRTY" }
        dressing.claims[2] = "bandageDirty"
    end
    local clauses = {
        dressing,
        {
            strategy = "INJURY_MOBILITY", relation = "CONTRAST",
            reference = referent, referenceAmbiguous = (tonumber(profile.totalWoundCount) or 1) > 1,
            claims = { "locomotionImpaired" },
        },
    }
    local result, reason = UtterancePlan.Realize(UtterancePlan.New({
        locale = opts and opts.locale, styleVariant = opts and opts.styleVariant,
        dialogueAct = "INFORM", strategy = "INJURY_STATUS", topic = "combat_injury",
        lexemes = { wound_part = lexeme },
        composition = { clauses = clauses, focus = opts and opts.focus },
    }))
    if not result then return nil, reason end
    result.text = string.upper(string.sub(result.text, 1, 1)) .. string.sub(result.text, 2) .. "."
    return result
end

return Composition
