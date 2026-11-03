local T = require "tests/support/test"

T.addPackagePaths()

-- This is the negative authority proof for medical response ownership.  No first-party
-- PNC_SocialFlavorDefinitions_* file is loaded; the medical phases must still
-- select a bounded semantic response plan and selected wording.
PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)

T.falsy(PNC.SocialFlavorDefinitions,
    "semantic medical selection does not require first-party definitions")

local function facts(eventRef, values)
    values = values or {}
    values.eventRef = eventRef
    values.authoritative = true
    values.disclosure = "player"
    return { [eventRef] = values }
end

local function resolve(eventType, eventID, context)
    context = context or {}
    context.eventType = eventType
    context.eventRef = eventID
    context.eventID = eventID
    local result = Reactions.Resolve({
        eventType = eventType,
        eventID = eventID,
        npcID = "npc-medical",
        act = "REQUEST",
        context = context,
    })
    T.truthy(result, eventType .. " selects a semantic realization")
    T.truthy(result.fallback and result.fallback ~= "",
        eventType .. " carries selected wording")
    T.truthy(result.responsePlan,
        eventType .. " carries its selected ResponsePlan")
    T.truthy(result.realizationFamily,
        eventType .. " carries realization provenance")
    return result
end

local call = resolve("incapacitated_call", "event:medical:call", {
    downedNeed = "bleedout",
    factRefs = { "event:medical:call" },
    semanticEventFacts = facts("event:medical:call", {
        summary = "the NPC was incapacitated",
        happened = "the NPC was incapacitated",
        need = "bleedout",
        attacker = "zombie",
    }),
})
T.equal(call.realizationFamily, "semantic.medical.distress.call",
    "incapacitated call uses the phase-specific semantic pool")
T.equal(#(call.offerIDs or {}), 3,
    "call exposes only the three grounded medical follow-ups")

local update = resolve("incapacitated_update", "event:medical:update", {
    downedNeed = "bandage",
    factRefs = { "event:medical:update" },
    semanticEventFacts = facts("event:medical:update", {
        summary = "the NPC remains incapacitated",
        need = "bandage",
    }),
})
T.equal(update.realizationFamily, "semantic.medical.distress.update",
    "incapacitated update uses the phase-specific semantic pool")
T.equal(#(update.offerIDs or {}), 2,
    "update hides the attacker question when no attacker fact is known")

local repeatLine = resolve("incapacitated_repeat", "event:medical:repeat", {
    downedNeed = "bandage",
    factRefs = { "event:medical:repeat" },
    semanticEventFacts = facts("event:medical:repeat", {
        summary = "the NPC remains incapacitated",
        need = "bandage",
    }),
})
T.equal(repeatLine.realizationFamily, "semantic.medical.distress.repeat",
    "incapacitated repeat uses the phase-specific semantic pool")
T.falsy(repeatLine.fallback == update.fallback,
    "repeat wording is a separate semantic realization")

local teammate = resolve("witnessed_teammate_hurt", "event:medical:teammate", {
    medicalBandageRequired = true,
    medicalBandageStatus = "missing",
    factRefs = { "event:medical:teammate" },
    semanticEventFacts = facts("event:medical:teammate", {
        summary = "a teammate was hurt",
        happened = "a teammate was hurt",
        attacker = "zombie",
        need = "bandage",
    }),
})
T.equal(teammate.realizationID,
    "semantic.medical.distress.teammate.missing",
    "teammate medical supply wording is selected semantically")
T.equal(#(teammate.offerIDs or {}), 3,
    "teammate hurt exposes only grounded medical follow-ups")

local treatment = resolve("treated_wound", "event:medical:treatment", {
    downedNeed = "bandage",
    factRefs = { "event:medical:treatment" },
    semanticEventFacts = facts("event:medical:treatment", {
        summary = "the wound was treated",
        need = "bandage",
    }),
})
T.equal(treatment.realizationFamily, "semantic.medical.distress.treatment",
    "treatment acknowledgement uses the semantic medical pool")
T.equal(#(treatment.offerIDs or {}), 2,
    "treatment does not invent an attacker fact")

local unknown = resolve("incapacitated_call", "event:medical:unknown", {
    downedNeed = "help",
    factRefs = { "event:medical:unknown" },
    semanticEventFacts = {},
})
T.equal(#(unknown.offerIDs or {}), 0,
    "unknown medical facts expose no stale follow-up offers")

T.finish("pnc_unified_authority_medical_smoke")
