local T = require "tests/support/test"
T.addPackagePaths()

PNC = { NPCWounds = {} }
local Wounds = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_TruthValidation"
local profile = {
    treatmentState = "splinted",
    selectedWound = {
        bodyPart = "UpperLeg_R", bandaged = true, splinted = false,
        stitched = false, haveGlass = false, haveBullet = false,
        functionalImpairment = "none", knoxExposure = "possible",
    },
    physiology = { feverBand = "none" },
}

for _, row in ipairs({
    { "My thigh is splinted.", "TREATMENT_REALIZATION_MISMATCH" },
    { "My thigh was stitched.", "TREATMENT_REALIZATION_MISMATCH" },
    { "There's glass in my thigh.", "TREATMENT_REALIZATION_MISMATCH" },
    { "There's a bullet lodged in my thigh.", "TREATMENT_REALIZATION_MISMATCH" },
    { "I can't run.", "FUNCTION_REALIZATION_MISMATCH" },
    { "I'm feverish.", "INFECTION_REALIZATION_MISMATCH" },
    { "I'm turning.", "INFECTION_REALIZATION_MISMATCH" },
}) do
    local ok, violations = Wounds.ValidateRealizationAgainstSelectedWound(row[1], profile)
    T.falsy(ok, row[1])
    T.equal(violations[1].code, row[2], row[1])
end
T.truthy(Wounds.ValidateRealizationAgainstSelectedWound("My thigh is bandaged.", profile))
profile.selectedWound.bandaged = false
T.falsy(Wounds.ValidateRealizationAgainstSelectedWound("My thigh is wrapped.", profile))
T.truthy(Wounds.ValidateRealizationAgainstSelectedWound("Help me wrap it.", profile), "a request does not claim treatment completed")

local ok, reason = Wounds.ValidateInjuryClaims({ clauses = { { claims = { "splinted" } } } }, profile)
T.falsy(ok, "typed treatment claim cannot borrow whole-body splint summary")
T.equal(reason, "TREATMENT_REALIZATION_MISMATCH")
ok, reason = Wounds.ValidateInjuryClaims({ clauses = {
    { diagnostic = "REFERENCE_AMBIGUOUS", referenceMode = "reference", claims = {} },
} }, profile)
T.falsy(ok)
T.equal(reason, "REFERENCE_AMBIGUOUS")
T.truthy(Wounds.ValidateInjuryClaims({ clauses = {
    { diagnostic = "REFERENCE_AMBIGUOUS", referenceMode = "explicit", claims = {} },
} }, profile), "explicit fallback resolves the reference")
ok, reason = Wounds.ValidateInjuryClaims({ relations = {
    { relation = "CONTRAST", realizedRelation = "ADD" },
} }, profile)
T.falsy(ok)
T.equal(reason, "CONNECTOR_RELATION_MISMATCH")
