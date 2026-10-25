local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
PsychopatzCore = {
    Conversation = {
        Text = {
            RegisterFallback = function() end,
        },
    },
}

local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Authority = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)

local rendererCalls = 0
PsychopatzCore.SocialFlavor = {
    Resolve = function()
        rendererCalls = rendererCalls + 1
        return "renderer must not choose this reaction"
    end,
}

local function resolveReaction()
    Catalog.ResetSelections()
    return Reactions.Resolve({
        eventType = "companion_command_acknowledgement",
        eventID = "authority-boundary-proof",
        context = {
            eventType = "companion_command_acknowledgement",
            npcID = "npc-mara",
            currentTopic = "medical_distress",
        },
    })
end

local first = T.truthy(
    resolveReaction(),
    "semantic reaction resolves before presentation"
)
T.equal(first.responsePlanID, "semantic.companion.reaction",
    "reaction family is selected by the semantic authority")
T.equal(first.realizationFamily, "semantic.companion.reaction",
    "realization family is stable before rendering")
T.equal(first.realizationID, "semantic.companion.reaction.default",
    "realization identity is selected before rendering")
T.truthy(first.responsePlan,
    "semantic authority returns the response plan before rendering")

local firstText = first.responsePlan.turns[1].segments[1].text
local replacement = resolveReaction()
T.equal(rendererCalls, 0,
    "replacing the legacy renderer does not participate in semantic selection")
T.equal(replacement.responsePlanID, first.responsePlanID,
    "renderer replacement cannot change the response plan owner")
T.equal(replacement.realizationFamily, first.realizationFamily,
    "renderer replacement cannot change the realization family")
T.equal(replacement.realizationID, first.realizationID,
    "renderer replacement cannot change the realization identity")
T.equal(replacement.responsePlan.turns[1].segments[1].text, firstText,
    "renderer replacement cannot change the selected response plan")

local direct = Authority.Resolve({
    poolID = "semantic.flow.farewell",
    responsePlanID = "semantic.flow.farewell",
    realizationFamily = "semantic.flow.farewell",
    act = "FAREWELL",
    topic = "farewell",
    context = { npcID = "npc-mara", socialStyle = "friendly" },
    salt = "authority-boundary-farewell",
})
T.truthy(direct and direct.groundedFactRefs,
    "canonical boundary always exposes bounded grounded fact references")
T.equal(direct.selectionSource, "semantic_response_catalog",
    "selection provenance identifies the semantic catalog")

local function representative(label, expectedPool, resolver)
    Catalog.ResetSelections()
    local result = T.truthy(resolver(), label .. " resolves through semantic authority")
    T.equal(result.responsePlanID, expectedPool,
        label .. " response plan is selected before presentation")
    T.equal(result.realizationFamily, expectedPool,
        label .. " realization family is selected before presentation")
    T.truthy(result.realizationID,
        label .. " realization identity is selected before presentation")
    T.truthy(result.responsePlan,
        label .. " response plan exists before presentation")
end

representative("greeting", "semantic.flow.greeting.opening", function()
    return Authority.Resolve({
        poolID = "semantic.flow.greeting.opening",
        responsePlanID = "semantic.flow.greeting.opening",
        realizationFamily = "semantic.flow.greeting.opening",
        act = "GREET",
        topic = "greeting",
        context = { npcID = "npc-mara", socialStyle = "friendly" },
        salt = "authority-boundary-greeting",
    })
end)

representative("farewell", "semantic.flow.farewell", function()
    return Authority.Resolve({
        poolID = "semantic.flow.farewell",
        responsePlanID = "semantic.flow.farewell",
        realizationFamily = "semantic.flow.farewell",
        act = "FAREWELL",
        topic = "farewell",
        context = { npcID = "npc-mara", socialStyle = "friendly" },
        salt = "authority-boundary-farewell-repeat",
    })
end)

representative("emote", "semantic.emote.reply", function()
    return Authority.Resolve({
        poolID = "semantic.emote.reply",
        responsePlanID = "semantic.emote.reply",
        realizationFamily = "semantic.emote.reply",
        act = "REACT",
        topic = "water",
        context = {
            npcID = "npc-mara",
            action = "thumbsup",
            previousTopic = "water",
        },
        salt = "authority-boundary-emote",
    })
end)

local playerEmote = Authority.Resolve({
    poolID = "semantic.emote.player",
    responsePlanID = "semantic.emote.player",
    realizationFamily = "emote_player",
    act = "GREET",
    context = {
        npcID = "player:alice",
        action = "wavehi",
        eventType = "player_emote_wavehi",
    },
    salt = "authority-boundary-player-emote",
})
T.equal(playerEmote.responsePlanID, "semantic.emote.player",
    "player emote speech resolves through the semantic response pool")
T.equal(playerEmote.realizationFamily, "emote_player",
    "player emote speech has a semantic realization family")
T.equal(playerEmote.realizationID, "semantic.emote.player.wavehi",
    "player emote selects the gesture-specific realization")
T.equal(playerEmote.compatibilityFlavorID, "vanilla_emote_wavehi",
    "player emote keeps Flavor only as an authored content alias")
T.equal(playerEmote.responsePlan.dialogueAct, "GREET",
    "player emote response plan preserves the semantic act")

representative("companion acknowledgement", "semantic.companion.reaction", function()
    return Reactions.Resolve({
        eventType = "companion_command_acknowledgement",
        eventID = "authority-boundary-companion",
        context = { eventType = "companion_command_acknowledgement" },
    })
end)

local campRejection = Authority.Resolve({
    poolID = "semantic.companion.reaction",
    responsePlanID = "semantic.companion.reaction",
    realizationFamily = "companion_command_reply",
    act = "REACT",
    topic = "companion_command",
    context = {
        eventType = "companion_command_rejection",
        commandID = "camp",
    },
    salt = "authority-boundary-camp-rejection",
})
T.equal(campRejection.realizationID,
    "semantic.companion.reaction.camp_rejected",
    "companion gameplay rejection selects semantic camp meaning first")
T.equal(campRejection.compatibilityFlavorID, "camp_rejected",
    "selected companion meaning retains the authored content alias")

representative("combat reaction", "semantic.combat.reaction", function()
    return Reactions.Resolve({
        eventType = "combat_awareness",
        eventID = "authority-boundary-combat",
        context = { eventType = "combat_awareness" },
    })
end)

representative("medical distress", "semantic.medical.distress", function()
    return Reactions.Resolve({
        eventType = "medical_distress",
        eventID = "authority-boundary-medical",
        context = {
            eventType = "medical_distress",
            downedNeed = "bleedout",
        },
    })
end)

representative("leader-loss grief", "semantic.leader_loss.reaction", function()
    return Reactions.Resolve({
        eventType = "leader_loss",
        eventID = "authority-boundary-leader-loss",
        context = {
            eventType = "leader_loss",
            leaderGrief = "devoted",
        },
    })
end)

T.equal(rendererCalls, 0,
    "renderer substitution cannot select any representative reaction family")

T.finish("pnc_semantic_realization_authority_smoke")
