local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 1000
getTimeInMillis = function() return now end
getCurrentSaveName = function() return "authority-boundary-test" end
getText = function(key) return key end
Events = { OnTick = { Add = function() end } }
getSpecificPlayer = function()
    return {
        getUsername = function() return "tester" end,
        getDisplayName = function() return "Alex Survivor" end,
        getDescriptor = function()
            return {
                getForename = function() return "Alex" end,
                getSurname = function() return "Survivor" end,
            }
        end,
    }
end

PsychopatzCore = { Conversation = {} }
PNC = {
    Conversation = {},
    Network = {
        ClientState = {
            playerContext = { characterUUID = "character-boundary" },
            playerNameKnowledge = { ["npc-boundary"] = true },
            snapshots = {
                ["npc-boundary"] = { id = "npc-boundary", name = "Mara" },
            },
        },
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
}

local Flavor = require
    "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
local Client = require
    "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
local Presentation = require "PNC/Conversation/PNC_SocialFlavorPresentation"

local fallbackCalls = 0
local resolveDetailed = Flavor.ResolveDetailed
Flavor.ResolveDetailed = function(...)
    fallbackCalls = fallbackCalls + 1
    return resolveDetailed(...)
end

Client.Reset()
local accepted, reason = Presentation.Receive({
    eventID = "authority:event:missing-text",
    npcID = "npc-boundary",
    flavorID = "social.witnessed_player_kill",
    family = "semantic_boundary",
    responsePlanID = "semantic.combat.reaction.plan",
    realizationID = "semantic.combat.reaction.variant",
    semanticOwned = true,
}, {
    npcID = "npc-boundary",
    state = "neutral",
}, {
    relationshipBefore = { state = "neutral" },
})
T.falsy(accepted,
    "semantic-owned packets without selected text are rejected")
T.equal(reason, "semantic_realization_text_required",
    "missing semantic realization reports an actionable boundary reason")
T.equal(#Client.GetQueueSnapshot(), 0,
    "rejected semantic packet never enters the generic flavor queue")
T.equal(fallbackCalls, 0,
    "semantic-owned missing text never calls Core ResolveDetailed")

Client.Reset()
local resolvedAccepted = Presentation.Receive({
    eventID = "authority:event:resolved-text",
    npcID = "npc-boundary",
    flavorID = "social.witnessed_player_kill",
    family = "semantic_boundary",
    resolvedText = "The selected meaning is delivered.",
    responsePlanID = "semantic.combat.reaction.plan",
    realizationID = "semantic.combat.reaction.variant",
    semanticOwned = true,
    llmEligible = false,
}, {
    npcID = "npc-boundary",
    state = "neutral",
}, {
    relationshipBefore = { state = "neutral" },
})
T.truthy(resolvedAccepted,
    "resolvedText is normalized into the native presentation payload")
Client.Pump(now)
T.equal(fallbackCalls, 0,
    "selected semantic text does not invoke Core ResolveDetailed")

T.finish("pnc_unified_authority_p1_boundary_smoke")
