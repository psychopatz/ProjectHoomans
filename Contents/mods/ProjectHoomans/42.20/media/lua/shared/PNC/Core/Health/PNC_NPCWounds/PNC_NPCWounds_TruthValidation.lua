-- Negative semantic truth validator for realized injury/physiology text.
PNC = PNC or {}
local Wounds = PNC.NPCWounds
local TreatmentSpeech = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_TreatmentSpeech"

local LOCOMOTION_IMPAIRMENTS = {
    limb_mobility = true,
    pelvic_mobility = true,
}

local function hasWord(low, pattern)
    return string.find(low, pattern) ~= nil
end

function Wounds.ValidateRealizationAgainstSelectedWound(text, truth, physiology)
    local low = string.lower(tostring(text or ""))
    local t = type(truth) == "table" and (truth.selectedWound or truth) or {}
    local p = type(physiology) == "table" and physiology or (type(truth) == "table" and truth.physiology) or {}
    local violations = {}

    if t.splinted ~= true and (hasWord(low, "%f[%a]splint") or hasWord(low, "in a brace")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_splint_when_not_splinted" }
    end
    if t.bandaged ~= true and (hasWord(low, "%f[%a]bandaged") or hasWord(low, "%f[%a]wrapped")
        or hasWord(low, "my bandage") or hasWord(low, "your bandage")
        or hasWord(low, "my dressing") or hasWord(low, "your dressing")
        or hasWord(low, "may benda")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_bandaged_when_unbandaged" }
    end
    if t.stitched ~= true and (hasWord(low, "%f[%a]stitched") or hasWord(low, "%f[%a]sutured") or hasWord(low, "tinahi")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_stitched_when_not_stitched" }
    end
    if t.haveGlass ~= true and (hasWord(low, "%f[%a]glass%f[%A]") or hasWord(low, "%f[%a]shard") or hasWord(low, "%f[%a]bubog")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_embedded_glass_when_absent" }
    end
    if t.haveBullet ~= true and (hasWord(low, "bullet lodged")
        or hasWord(low, "lodged bullet") or hasWord(low, "embedded bullet") or hasWord(low, "lead's still in")
        or hasWord(low, "may tingga") or (t.woundType ~= "bullet" and hasWord(low, "%f[%a]bullet"))) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_lodged_bullet_when_absent" }
    end
    local loco = LOCOMOTION_IMPAIRMENTS[tostring(t.functionalImpairment or "")] == true
    if not loco and (hasWord(low, "can't run") or hasWord(low, "can't sprint") or hasWord(low, "can't walk") or hasWord(low, "%f[%a]limp") or hasWord(low, "iika%-ika") or hasWord(low, "hindi makatakbo") or hasWord(low, "hindi ako makatakas")) then
        violations[#violations + 1] = { code = "FUNCTION_REALIZATION_MISMATCH", detail = "claimed_locomotion_loss_without_mobility_impairment" }
    end
    local feverBand = tostring(p.feverBand or (t.feverActive and "feverish" or "none"))
    if feverBand == "none" then
        if (hasWord(low, "burning up") or hasWord(low, "fever's") or hasWord(low, "i'm feverish")
            or hasWord(low, "i feel feverish") or hasWord(low, "i have a fever") or hasWord(low, "umaapoy na ang lagnat") or hasWord(low, "nilalagnat na ako"))
            and not (hasWord(low, "without the fever") or hasWord(low, "no fever") or hasWord(low, "don't feel feverish") or hasWord(low, "praying the fever") or hasWord(low, "watch the fever") or hasWord(low, "watch for fever") or hasWord(low, "wala pa akong lagnat") or hasWord(low, "sana hindi lagnatin") or hasWord(low, "ligtas sa lagnat"))
        then
            violations[#violations + 1] = { code = "INFECTION_REALIZATION_MISMATCH", detail = "claimed_active_fever_when_absent" }
        end
    end
    if t.knoxExposure ~= "confirmed" then
        if (hasWord(low, "i'm turning") or hasWord(low, "about to turn"))
            and not (hasWord(low, "not turning") or hasWord(low, "won't turn"))
        then
            violations[#violations + 1] = { code = "INFECTION_REALIZATION_MISMATCH", detail = "claimed_certain_turning_without_confirmed_knox" }
        end
    end
    return #violations == 0, violations
end

local CLAIMS = {
    bandaged = { "bandaged", "TREATMENT_REALIZATION_MISMATCH" },
    bandageDirty = { "bandageDirty", "TREATMENT_REALIZATION_MISMATCH" },
    splinted = { "splinted", "TREATMENT_REALIZATION_MISMATCH" },
    stitched = { "stitched", "TREATMENT_REALIZATION_MISMATCH" },
    cauterized = { "cauterized", "TREATMENT_REALIZATION_MISMATCH" },
    haveGlass = { "haveGlass", "TREATMENT_REALIZATION_MISMATCH" },
    haveBullet = { "haveBullet", "TREATMENT_REALIZATION_MISMATCH" },
    bleeding = { "bleeding", "TREATMENT_REALIZATION_MISMATCH" },
    locomotionImpaired = { "locomotionImpaired", "FUNCTION_REALIZATION_MISMATCH" },
    ordinaryInfection = { "ordinaryInfection", "INFECTION_REALIZATION_MISMATCH" },
}

function Wounds.ValidateInjuryClaims(evidence, profile, knowledge)
    local wound = profile.selectedWound
    if not wound then return false, "SELECTED_WOUND_UNAVAILABLE" end
    for _, clause in ipairs(evidence.clauses or {}) do
        if clause.diagnostic == "REFERENCE_AMBIGUOUS" and clause.referenceMode ~= "explicit" then
            return false, "REFERENCE_AMBIGUOUS"
        end
        for _, claim in ipairs(clause.claims or {}) do
            if TreatmentSpeech.IsMaterialClaim(claim)
                and not TreatmentSpeech.Matches(wound, claim, knowledge == "inferred")
            then
                return false, "TREATMENT_REALIZATION_MISMATCH", claim
            end
            local spec = CLAIMS[claim]
            if spec and wound[spec[1]] ~= true then return false, spec[2], claim end
            if claim == "locomotionImpaired" and not LOCOMOTION_IMPAIRMENTS[wound.functionalImpairment] then
                return false, "FUNCTION_REALIZATION_MISMATCH", claim
            end
            if claim == "fever" then
                local fever = (profile.physiology or {}).feverBand
                if not fever or fever == "none" then return false, "INFECTION_REALIZATION_MISMATCH", claim end
            elseif claim == "knoxConfirmed" and wound.knoxExposure ~= "confirmed" then
                return false, "INFECTION_REALIZATION_MISMATCH", claim
            end
        end
    end
    for _, row in ipairs(evidence.relations or {}) do
        if row.realizedRelation and row.realizedRelation ~= row.relation then
            return false, "CONNECTOR_RELATION_MISMATCH", row.relation
        end
    end
    return true
end

return Wounds
