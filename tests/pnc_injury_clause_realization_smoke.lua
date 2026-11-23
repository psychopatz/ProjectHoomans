local T = require "tests/support/test"
T.addPackagePaths()

local coreRepository = os.getenv("PZ_TEST_CORE_REPOSITORY") or "../psychopatzCore"
package.path = coreRepository .. "/tools/semantic_harness/lua/?.lua;" .. package.path
local Protocol = require "Protocol"

local relativeCatalog = "media/translation/TL/Conversation/Text/convo/ConvoEngine_realization.json"
local localizations = {
    PsychopatzCore = Protocol.decode(T.read("PsychopatzCore", "common_mod", relativeCatalog)),
    ProjectHoomans = Protocol.decode(T.read("ProjectHoomans", "common_mod", relativeCatalog)),
}
CustomTranslationManager = {
    get = function(owner, _, key) return localizations[owner] and localizations[owner][key] end,
}

local Composition = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundComposition"
local profile = {
    totalWoundCount = 1,
    selectedWound = {
        bodyPart = "UpperLeg_R", bodyRegion = "lower_limb", bandaged = true,
        locomotionImpaired = true, functionalImpairment = "limb_mobility",
    },
}

local en = assert(Composition.Realize(profile, { locale = "EN" }))
T.equal(en.text, "My thigh is bandaged, but it's slowing me down.", "EN composition uses truthful clauses")
T.equal(en.relations[1].relation, "CONTRAST")
T.equal(en.clauses[2].referenceMode, "reference")
T.equal(en.clauses[2].refersTo.id, "UpperLeg_R")

local tl = assert(Composition.Realize(profile, { locale = "TL" }))
T.equal(tl.text, "May benda ang hita ko, pero bumabagal pa rin ang kilos ko dahil dito.", "TL uses its own grammar and lexemes")

profile.selectedWound.bandageDirty = true
profile.totalWoundCount = 2
local multiple = assert(Composition.Realize(profile, { locale = "EN" }))
T.contains(multiple.text, "the injury on my thigh", "ambiguous reference uses an explicit noun")
T.equal(multiple.clauses[1].modifiers[1], "DRESSING_DIRTY")
T.equal(multiple.clauses[2].diagnostic, "REFERENCE_AMBIGUOUS")
T.equal(multiple.clauses[2].referenceMode, "explicit")

profile.selectedWound.functionalImpairment = "none"
T.falsy(Composition.Realize(profile, { locale = "EN" }), "the plan cannot claim mobility loss based on severity alone")
profile.selectedWound.functionalImpairment = "limb_mobility"
profile.selectedWound.bandaged = false
T.falsy(Composition.Realize(profile, { locale = "EN" }), "other wound treatment cannot authorize a dressing claim")

local treatmentWound = {
    bodyPart = "ForeArm_L", bandaged = true, bandageType = "Base.AlcoholRippedSheets",
    sterileDressing = true,
}
local treated = { totalWoundCount = 1, selectedWound = treatmentWound }
local self = assert(Composition.Realize(treated, { locale = "EN" }))
T.contains(self.text, "a sterilized strip of cloth")
T.equal(self.clauses[1].claims[2], "COMBAT_TREATMENT_STERILE_RAG")
local observed = assert(Composition.Realize(treated, { locale = "TL", observed = true }))
T.contains(observed.text, "piraso ng tela")
T.falsy(string.find(observed.text, "isterilisado", 1, true), "sterility is not visible")
local disclosed = assert(Composition.Realize(treated, { locale = "TL", observed = true, treatmentKnown = true }))
T.contains(disclosed.text, "isterilisadong piraso ng tela")
T.contains(disclosed.text, "tinakpan mo", "observer perspective survives disclosure")

PNC.NPCWounds = {}
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_TruthValidation"
local check = PNC.NPCWounds.ValidateInjuryClaims
T.truthy(check(self, treated, "experienced"))
local accepted, mismatch = check(self, treated, "inferred")
T.falsy(accepted)
T.equal(mismatch, "TREATMENT_REALIZATION_MISMATCH")
T.truthy(check(observed, treated, "inferred"))

treatmentWound.bandageDirty = true
treatmentWound.spentBandageType = "Base.RippedSheetsDirty"
local dirty = assert(Composition.Realize(treated, { locale = "EN", observed = true }))
T.contains(dirty.text, "looks dirty")
T.equal(dirty.clauses[1].claims[2], "COMBAT_TREATMENT_RAG")
T.falsy(check(self, treated, "experienced"), "a spent dressing cannot be described as sterile")
T.truthy(check(dirty, treated, "inferred"))

treatmentWound.bandaged, treatmentWound.splinted, treatmentWound.splintItem = false, true, "Base.Plank"
local splint = assert(Composition.Realize(treated, { locale = "EN", observed = true }))
T.contains(splint.text, "a plank for a splint")
T.truthy(check(splint, treated, "inferred"))
treatmentWound.splinted = false
T.falsy(check(splint, treated, "inferred"), "a stored item does not imply an applied splint")
treatmentWound.bandaged, treatmentWound.bandageDirty, treatmentWound.virtualDressing = true, false, true
T.falsy(Composition.Realize(treated, { locale = "EN" }), "a virtual dressing contributes no material")

local ClausePlan = require "PsychopatzCore/ConvoEngine/ClausePlan"
local plan, reason = ClausePlan.Normalize({ clauses = {
    { strategy = "FIRST" }, { strategy = "SECOND", relation = "but" },
} })
T.falsy(plan)
T.equal(reason, "relation_invalid", "logical relations must be semantic IDs")
