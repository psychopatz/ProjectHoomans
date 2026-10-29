local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {
    Semantics = {
        UtterancePlan = {
            New = function(spec)
                return spec
            end,
            Realize = function(plan)
                local name = plan.slots and plan.slots.name
                return {
                    text = name and ("I'm " .. tostring(name) .. ".")
                        or tostring(plan.strategy or plan.dialogueAct or "response"),
                }
            end,
        },
    },
}

package.loaded["PNC/Semantics/PNC_SemanticInteractionProviders"] = {
    EvidenceQueryForStimulus = function() return nil end,
    QueryEvidence = function()
        return { rows = { { relation = "test", confidence = 1 } } }
    end,
}
package.loaded["PNC/Semantics/PNC_SemanticPragmaticResolver"] = {
    ResolveEvidence = function()
        return { status = "resolved", confidence = 1 }
    end,
}
package.loaded["PNC/Semantics/PNC_SemanticInteractionStimulus"] = {
    FromIR = function(ir)
        local output = {}
        for key, value in pairs(ir or {}) do output[key] = value end
        output.type = output.type or "DIALOGUE"
        return output
    end,
}
package.loaded["PNC/Semantics/PNC_SemanticInteractionRelations"] = {
    ContextualActs = function() return {} end,
    GetAct = function() return nil end,
}

local Provider = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_GeneratedAffordanceProvider.lua"
)

local legacyRows = Provider.collect({
    playerName = "Patrick Patz",
    playerTraits = { Brave = true },
    dialogueIR = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "IDENTITY",
    },
    semanticDialogueContext = {
        pendingFollowUp = {
            status = "open",
            kind = "QUESTION",
            flowID = "identity",
            topic = "identity",
        },
    },
})
T.equal(#legacyRows, 2, "legacy player identity frontier stays bounded")
T.equal(legacyRows[1].providerID, "projecthoomans.generated_affordances",
    "historical provider id remains stable")
T.equal(legacyRows[1].strategy, "DISCLOSE_NAME",
    "legacy identity disclosure remains first")
T.equal(legacyRows[1].visibility, "player",
    "legacy candidate remains player-visible")
T.equal(legacyRows[1].utterancePlan.speaker, "player",
    "legacy utterance plan remains player-authored")
T.equal(legacyRows[1].frame.slots.identityClaim.name, "Patrick Patz",
    "legacy identity claim keeps player name")

local npcRows = Provider.collectForResponder({
    affordanceRecipientRef = "npc-percy",
    dialogueIR = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "IDENTITY",
    },
    semanticDialogueContext = {
        pendingFollowUp = {
            status = "open",
            kind = "QUESTION",
            flowID = "identity",
            topic = "identity",
        },
    },
}, {
    actorID = "npc-aaron",
    turnSpeaker = "npc-aaron",
    name = "Aaron Hitchcock",
    traits = { Brave = true },
    visibility = "semantic",
})
T.equal(#npcRows, 2, "NPC uses the same bounded identity frontier")
T.equal(npcRows[1].providerID, "projecthoomans.generated_affordances",
    "NPC reuses the existing provider authority")
T.equal(npcRows[1].id, "generated.disclose_name",
    "NPC candidate id matches the player semantic vocabulary")
T.equal(npcRows[1].strategy, "DISCLOSE_NAME",
    "NPC receives the same disclosure strategy")
T.equal(npcRows[1].visibility, "semantic",
    "NPC candidate is semantic rather than UI visibility")
T.equal(npcRows[1].utterancePlan.speaker, "npc-aaron",
    "NPC utterance plan is authored by the responder")
T.equal(npcRows[1].frame.slots.identityClaim.name, "Aaron Hitchcock",
    "NPC identity disclosure uses responder identity")
T.equal(npcRows[2].frame.target.ref, "npc-percy",
    "directed NPC response targets the explicit recipient")

local hostileContext = {
    affordanceRecipientRef = "npc-percy",
    dialogueIR = {
        intent = "THREATEN",
        speechAct = "THREATEN",
        subject = "RECIPIENT",
        extensions = {
            socialFeatures = { hostility = 0.9 },
        },
    },
}

local braveRows = Provider.collectForResponder(hostileContext, {
    actorID = "npc-aaron",
    turnSpeaker = "npc-aaron",
    name = "Aaron Hitchcock",
    traits = { Brave = true },
    visibility = "semantic",
})
local braveByStrategy = {}
for _, row in ipairs(braveRows) do braveByStrategy[row.strategy] = row end
T.equal(#braveRows, Provider.MAX_CANDIDATES,
    "NPC hostility frontier keeps the existing hard cap")
T.truthy(braveByStrategy.CALL_BLUFF,
    "NPC Brave trait unlocks the shared challenge affordance")
T.equal(braveByStrategy.CALL_BLUFF.contextReason, "responder_trait:Brave",
    "NPC trait provenance is actor-neutral")
T.equal(braveByStrategy.CALL_BLUFF.frame.target.ref, "npc-percy",
    "NPC hostile response keeps explicit recipient")

local kindRows = Provider.collectForResponder(hostileContext, {
    actorID = "npc-aaron",
    turnSpeaker = "npc-aaron",
    name = "Aaron Hitchcock",
    traits = { Kind = true },
    visibility = "semantic",
})
local kindByStrategy = {}
for _, row in ipairs(kindRows) do kindByStrategy[row.strategy] = row end
T.truthy(kindByStrategy.COMFORT,
    "NPC Kind trait unlocks the shared comfort affordance")
T.equal(kindByStrategy.COMFORT.contextReason, "responder_trait:Kind",
    "NPC empathy provenance is actor-neutral")

T.finish("pnc_semantic_actor_neutral_affordance_frontier_smoke")
