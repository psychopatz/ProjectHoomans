local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

-- P0 characterization: the native presentation adapter historically projected
-- only `text`. Several semantic-first producers supplied their selected
-- wording as `resolvedText`, leaving a legacy flavorID available to Core's
-- generic fallback resolver. Keep this test explicit until P1 closes the
-- boundary; it prevents the migration from being blind to the split owner.
PNC = {
    SocialFlavorPresentationInternal = {
        Clean = function(value, fallback)
            value = tostring(value or "")
            return value ~= "" and value or fallback
        end,
        FirstBoolean = function(first, second)
            if first ~= nil then return first end
            return second
        end,
        PlayerUUID = function() return "player-p0" end,
    },
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_SocialFlavorPresentation_Receive_Payload.lua"
)

local payload = PNC.SocialFlavorPresentationInternal.BuildReceivePayload({
    ambientFlavor = {
        flavorID = "social.witnessed_player_kill",
        resolvedText = "The semantic selection was made here.",
        responsePlanID = "semantic.combat.reaction.plan",
        realizationID = "semantic.combat.reaction.variant",
    },
    sourceOverrides = {},
    presentationOverrides = {},
    context = {},
    speaker = { fullName = "Mara" },
    eventID = "event:p0:resolved-text",
    npcID = "npc-p0",
    role = "neutral",
    relationshipState = "neutral",
    relationshipTier = "reserved",
    eventType = "witnessed_player_kill",
})

T.equal(payload.text, nil,
    "P0 records that resolvedText was not projected into the native payload")
T.equal(payload.flavorID, "social.witnessed_player_kill",
    "P0 records the legacy selector still remained available")
T.equal(payload.responsePlanID, "semantic.combat.reaction.plan",
    "semantic provenance already crossed the presentation boundary")
T.equal(payload.realizationID, "semantic.combat.reaction.variant",
    "semantic realization provenance already crossed the presentation boundary")

T.finish("pnc_unified_authority_p0_characterization_smoke")
