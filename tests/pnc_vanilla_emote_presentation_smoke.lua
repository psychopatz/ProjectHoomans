local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local spoken = {}
local diaryEntries = {}
local received = {}
local state = {
    snapshots = {
        ["npc-one"] = { id = "npc-one", name = "Mara" },
    },
    relationshipDebug = {
        observer = { npcID = "npc-one" },
        target = { kind = "player" },
        relationship = { approval = 20, respect = 20 },
    },
}

local player = {
    getUsername = function() return "player-one" end,
}

local body = {
    isDead = function() return false end,
    Say = function(_, value) spoken[#spoken + 1] = value end,
}

PNC = {
    Core = { Now = function() return 1234 end },
    Network = { ClientState = state },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
    Conversation = {
        Diary = {
            Append = function(npcID, entry)
                diaryEntries[#diaryEntries + 1] = {
                    npcID = npcID,
                    entry = entry,
                }
                return true
            end,
        },
        Relationship = {
            ReceiveAfter = function(npcID, after, delta, metadata)
                received[#received + 1] = {
                    npcID = npcID,
                    after = after,
                    delta = delta,
                    metadata = metadata,
                }
                return true
            end,
        },
    },
    Registry = {
        Get = function(id) return state.snapshots[id] end,
        GetLiveZombie = function(id)
            return id == "npc-one" and body or nil
        end,
    },
}

package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
getSpecificPlayer = function() return player end

T.load(SHARED .. "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticCompanionSpeech.lua")
T.load(CLIENT .. "PNC/Commands/PNC_CompanionCommandPresentation.lua")

local playerEmoteRealization =
    PNC.CompanionCommandPresentation.ResolvePlayerEmoteRealization(
        "wavehi",
        { requestID = "player-realization-one", playerActor = player }
    )
T.equal(playerEmoteRealization.responsePlanID, "semantic.emote.player",
    "player emote presentation selects a semantic response plan")
T.equal(playerEmoteRealization.realizationID,
    "semantic.emote.player.wavehi",
    "player emote presentation selects a gesture realization")
T.equal(playerEmoteRealization.compatibilityFlavorID, nil,
    "player emote no longer carries a wording-registry alias")

local unknownTarget = {
    id = "npc-unknown",
    name = "Unknown survivor",
    relationshipKind = "neutral",
}
local knownTarget = { id = "npc-one", name = "Mara" }
state.semanticAddressHistory = nil
local unknownAddressContext =
    PNC.CompanionCommandPresentation.BuildSpeechContext(
        player,
        { targets = { unknownTarget, knownTarget } }
    )
T.equal(unknownAddressContext.names, "stranger and Mara",
    "player emote replaces the internal unknown identity placeholder")
T.equal(string.find(
    unknownAddressContext.names,
    "Unknown survivor",
    1,
    true
), nil, "player emote target addresses do not leak the placeholder")
local unknownAddressLine = PNC.Semantics.CompanionSpeech.ResolvePlayerEmote(
    "wavehi",
    {
        npcID = "player:one",
        requestID = "unknown-address",
        renderTokens = unknownAddressContext,
    }
).fallback
T.truthy(string.find(unknownAddressLine, "stranger and Mara", 1, true),
    "rendered emote speech uses semantic target addresses")
T.truthy(state.semanticAddressHistory
    and state.semanticAddressHistory["npc-unknown"],
    "unknown target address history is bounded per NPC")
T.equal(state.semanticAddressHistory["npc-unknown"][1], "stranger",
    "first unknown target address is recorded")
local nextUnknownAddress =
    PNC.CompanionCommandPresentation.BuildSpeechContext(
        player,
        { targets = { unknownTarget } }
    )
T.equal(nextUnknownAddress.names, "mate",
    "unknown target address advances within the bounded semantic family")

local result = PNC.CompanionCommandPresentation
    .HandlePlayerEmoteInteractionResult({
        requestID = "request-one",
        eventID = "event-one",
        emote = "insult",
        targets = {
            {
                npcID = "npc-one",
                accepted = true,
                eventID = "event-one",
                realizationID = "semantic.emote.reply.insult",
                relationshipBefore = { approval = 20, respect = 20 },
                relationshipAfter = {
                    approval = 16,
                    respect = 17,
                    familiarity = 4,
                },
                relationshipDelta = {
                    approval = -4,
                    respect = -3,
                    familiarity = 0,
                },
                memoryID = "memory-one",
                memoryType = "player_insulted",
                interactionType = "player_emote_insult",
            },
        },
    })

T.equal(result, true, "emote result was presented")
T.equal(#received, 1, "authoritative relationship result was received")
T.equal(received[1].after.approval, 16,
    "relationship presentation uses the authoritative after state")
T.equal(state.lastConversationDelta.npcID, "npc-one",
    "legacy conversation delta points to the affected NPC")
T.equal(state.lastConversationDeltas["npc-one"].after.respect, 17,
    "per-NPC conversation delta stores the affected NPC")
T.equal(state.relationshipDebug.relationship.approval, 16,
    "open relationship inspector receives the authoritative state")
T.equal(#diaryEntries, 1, "emote result is written to the interaction diary")
T.equal(diaryEntries[1].entry.kind, "player_emote",
    "diary identifies the vanilla emote interaction")
T.truthy(diaryEntries[1].entry.playerText,
    "diary contains dynamic player flavor text")
T.truthy(diaryEntries[1].entry.npcText,
    "diary contains dynamic NPC reply text")
T.truthy(#spoken > 0, "NPC reply flavor is spoken when the body is live")

local dogGreetingResult =
    PNC.CompanionCommandPresentation.HandleSocialGreeting({
        eventID = "dog-event-one",
        npcID = "npc-one",
        poolID = "semantic.compat.companion_dogs.greeting",
        eventType = "companion_dog_greeting",
        interactionType = "companion_dog_greeting",
        resolvedText = "Who's a good boy?",
        responsePlanID = "semantic.compat.companion_dogs.greeting",
        realizationFamily = "semantic.compat.companion_dogs.greeting",
        realizationID = "semantic.compat.companion_dogs.greeting.male",
        semanticOwned = true,
    })
T.equal(dogGreetingResult, true,
    "Companion Dogs greeting reaches the canonical presenter")

PNC.RelationshipPresentation = {
    Summarize = function(relationship) return relationship end,
    BuildEvaluation = function(summary) return summary end,
}
T.load(CLIENT .. "PNC/UI/Relationships/PNC_RelationshipDebugModel.lua")
local evaluation = PNC.RelationshipDebugModel.BuildGraph({
    observer = { npcID = "npc-two" },
    relationship = { approval = 40, respect = 40 },
}, "inspect", {
    conversationDeltas = {
        ["npc-two"] = {
            after = { approval = -12, respect = -8 },
        },
    },
})
T.equal(evaluation.approval, -12,
    "relationship inspector selects the affected NPC delta")
T.equal(evaluation.respect, -8,
    "relationship inspector selects the affected NPC respect")

return T.finish("pnc_vanilla_emote_presentation_smoke")
