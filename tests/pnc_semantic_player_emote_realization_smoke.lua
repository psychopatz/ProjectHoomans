local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local queued = {}
local executed
local state = { snapshots = {} }
local target = { id = "npc-one", name = "Mara" }
local player = {
    getUsername = function() return "player-one" end,
}

PNC = {
    Core = {
        Now = function() return 1234 end,
        GenerateID = function(prefix) return tostring(prefix) .. ":one" end,
    },
    Network = { ClientState = state },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
    Registry = {
        Get = function(id) return id == target.id and target or nil end,
        GetLiveZombie = function() return nil end,
    },
    Client = {
        ExecutePlayerEmoteInteraction = function(emoteID, context)
            executed = { emoteID = emoteID, context = context }
            return true
        end,
    },
    CompanionTargetResolver = {
        SCOPE_SOCIAL = "social",
        ResolveRecipients = function()
            return { targets = { target }, target = target }
        end,
    },
}

package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
package.preload["PNC/Commands/PNC_CompanionTargetResolver"] =
    function() return PNC.CompanionTargetResolver end

ISEmoteRadialMenu = {
    PNCCompanionCommandsInstalled = false,
    init = function() end,
    emote = function() return "vanilla-original" end,
    icons = {},
}
package.preload["ISUI/ISEmoteRadialMenu"] = function()
    return ISEmoteRadialMenu
end

T.load(SHARED .. "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticCompanionSpeech.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_VanillaEmoteInteractions.lua")
T.load(CLIENT .. "PNC/Commands/PNC_CompanionCommandPresentation.lua")
T.load(CLIENT .. "PNC/Commands/PNC_CompanionCommandEmotes.lua")

local presentation = PNC.CompanionCommandPresentation
presentation.EnqueueSpeech = function(speechEventID, speaker, actor, context,
    options)
    queued[#queued + 1] = {
        speechEventID = speechEventID,
        speaker = speaker,
        actor = actor,
        context = context,
        options = options,
    }
    return true
end

local result = ISEmoteRadialMenu:emote("wavehi")

T.equal(result, "vanilla-original",
    "vanilla emote animation remains on the native radial path")
T.truthy(executed, "player emote gameplay request remains dispatched")
T.truthy(executed.context.responsePlanID,
    "player emote context records semantic provenance")
T.equal(#queued, 1, "player emote speech is queued once")
T.equal(queued[1].speechEventID, "semantic.emote.player.wavehi",
    "player emote is queued by its semantic realization identity")
T.equal(queued[1].options.semanticRealization.responsePlanID,
    "semantic.emote.player",
    "queued player emote carries the semantic response plan")
T.equal(queued[1].options.semanticRealization.realizationFamily,
    "emote_player",
    "queued player emote carries the semantic realization family")
T.equal(queued[1].options.semanticRealization.realizationID,
    "semantic.emote.player.wavehi",
    "queued player emote carries the gesture realization identity")
T.equal(executed.emoteID, "wavehi",
    "player emote gameplay request keeps the canonical gesture")
T.equal(executed.context.responsePlanID, "semantic.emote.player",
    "player emote dispatch carries the semantic response plan")
T.equal(executed.context.realizationFamily, "emote_player",
    "player emote dispatch carries the semantic realization family")
T.equal(executed.context.realizationID, "semantic.emote.player.wavehi",
    "player emote dispatch carries the gesture realization identity")

T.finish("pnc_semantic_player_emote_realization_smoke")

