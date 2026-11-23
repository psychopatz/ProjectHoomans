-- Negative semantic truth validator for realized injury/physiology text.
PNC = PNC or {}
local Wounds = PNC.NPCWounds

local LOCOMOTION_IMPAIRMENTS = {
    limb_mobility = true,
    pelvic_mobility = true,
    multi_system = true,
}

local function hasWord(low, pattern)
    return string.find(low, pattern) ~= nil
end

function Wounds.ValidateRealizationAgainstSelectedWound(text, truth, physiology)
    local low = string.lower(tostring(text or ""))
    local t = type(truth) == "table" and (truth.selectedWound or truth) or {}
    local p = type(physiology) == "table" and physiology or (type(truth) == "table" and truth.physiology) or {}
    local violations = {}

    if t.splinted ~= true and (hasWord(low, "%f[%a]splint") or hasWord(low, "brace")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_splint_when_not_splinted" }
    end
    if t.bandaged ~= true and (hasWord(low, "%f[%a]bandag") or hasWord(low, "%f[%a]wrap") or hasWord(low, "%f[%a]dressing") or hasWord(low, "%f[%a]bendahe")) then
        if not (hasWord(low, "need") or hasWord(low, "kailangan") or hasWord(low, "without") or hasWord(low, "forget") or hasWord(low, "sayang") or hasWord(low, "tie") or hasWord(low, "patch")) then
            violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_bandaged_when_unbandaged" }
        end
    end
    if t.stitched ~= true and (hasWord(low, "%f[%a]stitched") or hasWord(low, "%f[%a]sutured") or hasWord(low, "tinahi")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_stitched_when_not_stitched" }
    end
    if t.haveGlass ~= true and (hasWord(low, "%f[%a]glass%f[%A]") or hasWord(low, "%f[%a]shard") or hasWord(low, "%f[%a]bubog")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_embedded_glass_when_absent" }
    end
    if t.haveBullet ~= true and t.woundType ~= "bullet" and (hasWord(low, "%f[%a]bullet") or hasWord(low, "lead's still in") or hasWord(low, "may tingga")) then
        violations[#violations + 1] = { code = "TREATMENT_REALIZATION_MISMATCH", detail = "claimed_lodged_bullet_when_absent" }
    end
    local loco = t.locomotionImpaired == true or LOCOMOTION_IMPAIRMENTS[tostring(t.functionalImpairment or "")] == true
    if not loco and (hasWord(low, "can't run") or hasWord(low, "can't sprint") or hasWord(low, "can't walk") or hasWord(low, "%f[%a]limp") or hasWord(low, "iika%-ika") or hasWord(low, "hindi makatakbo") or hasWord(low, "hindi ako makatakas")) then
        violations[#violations + 1] = { code = "FUNCTION_REALIZATION_MISMATCH", detail = "claimed_locomotion_loss_without_mobility_impairment" }
    end
    local feverBand = tostring(p.feverBand or (t.feverActive and "feverish" or "none"))
    if feverBand == "none" and t.knoxExposure ~= "confirmed" then
        if (hasWord(low, "burning up") or hasWord(low, "fever's") or hasWord(low, "umaapoy na ang lagnat") or hasWord(low, "nilalagnat na ako"))
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

return Wounds
