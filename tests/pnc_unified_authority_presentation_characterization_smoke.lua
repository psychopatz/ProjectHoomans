local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

-- This characterization started by recording that the native presentation
-- adapter projected only `text`. The current presentation contract closes that observed split by
-- normalizing the already-selected `resolvedText` field; keep the assertion
-- here as a regression against the original authority defect.
PNC = {
    SemanticSpeechPresentationInternal = {
        Clean = function(value, fallback)
            value = tostring(value or "")
            return value ~= "" and value or fallback
        end,
        FirstBoolean = function(first, second)
            if first ~= nil then return first end
            return second
        end,
        PlayerUUID = function() return "player-presentation" end,
    },
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_SemanticSpeechPresentation_Receive_Payload.lua"
)

local payload = PNC.SemanticSpeechPresentationInternal.BuildReceivePayload({
    ambientFlavor = {
        flavorID = "semantic.combat.reaction.kill_witness_practical_01",
        resolvedText = "The semantic selection was made here.",
        responsePlanID = "semantic.combat.reaction.plan",
        realizationID = "semantic.combat.reaction.variant",
    },
    sourceOverrides = {},
    presentationOverrides = {},
    context = {},
    speaker = { fullName = "Mara" },
    eventID = "event:presentation:resolved-text",
    npcID = "npc-presentation",
    role = "neutral",
    relationshipState = "neutral",
    relationshipTier = "reserved",
    eventType = "zombie_kill_witnessed",
})

T.equal(payload.text, "The semantic selection was made here.",
    "resolvedText is projected into the native payload")
T.equal(payload.flavorID, "semantic.combat.reaction.kill_witness_practical_01",
    "the presentation alias remains available without owning semantic text")
T.equal(payload.responsePlanID, "semantic.combat.reaction.plan",
    "semantic provenance already crossed the presentation boundary")
T.equal(payload.realizationID, "semantic.combat.reaction.variant",
    "semantic realization provenance already crossed the presentation boundary")

T.finish("pnc_unified_authority_presentation_characterization_smoke")
