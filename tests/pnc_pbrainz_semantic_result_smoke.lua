local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {
    Semantics = {},
    PBrainZ = { Internal = {} },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticLLMResult.lua"
)

local dispatched
PNC.Semantics.DialogueInput = {
    Internal = {
        DispatchAction = function(view, result, rawText)
            dispatched = {
                view = view,
                result = result,
                rawText = rawText,
            }
            return { status = "accepted", accepted = true }
        end,
    },
}

local router = {
    ProcessIR = function(_, ir, context)
        return {
            accepted = true,
            ir = ir,
            context = context,
            decision = {
                actionIntent = {
                    intent = ir.intent,
                    action = ir.action,
                },
            },
        }
    end,
}
local session = {
    semanticDialogueRouter = router,
    semanticDialoguePending = {
        rawText = "Could you bring me water?",
        normalizedText = "could you bring me water",
    },
}
local view = {
    spec = { npcID = "npc:alice" },
    session = session,
}
local pending = {
    view = view,
    npcID = "npc:alice",
    requestID = "llm:1",
    packet = {
        conversation_context = {
            player_uuid = "player:one",
            world_context = { timeBand = "dusk" },
            current_topic = "resources",
            semantic_dialogue_state = {
                previousTopic = "weather",
            },
            semantic_entity_index = { byName = {} },
            semantic_fact_values = {
                LOCATION = { status = "unknown" },
            },
        },
    },
}

local Adapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Integrations/PBrainZ/PNC_PBrainZ_SemanticResult.lua"
)
local result, reason = Adapter.Apply(pending, {
    semantic_ir = {
        intent = "REQUEST",
        speech_act = "REQUEST",
        action = "FETCH",
        object = { category = "WATER" },
        confidence = 0.88,
    },
})
T.truthy(result, "structured LLM IR enters the conversation router")
T.equal(reason, nil, "valid structured LLM IR has no reason")
T.equal(result.ir.provenance.provider, "llm",
    "structured result retains LLM provenance")
T.equal(result.context.worldContext.timeBand, "dusk",
    "structured result reuses the bounded world context")
T.equal(result.context.currentTopic, "resources",
    "structured result reuses the current topic")
T.equal(result.context.previousTopic, "weather",
    "structured result reuses prior dialogue context")
T.equal(result.context.semanticFactValues.LOCATION.status, "unknown",
    "structured result reuses semantic fact projections")
T.equal(session.semanticDialoguePending, nil,
    "accepted structured result clears the pending handoff")
T.equal(session.semanticDialogueIR.object.category, "WATER",
    "session retains the canonical semantic IR")
T.equal(dispatched.rawText, "Could you bring me water?",
    "downstream action sees the original utterance")
T.equal(result.actionResult.status, "accepted",
    "action result remains downstream-owned")

local missing, missingReason = Adapter.Apply(pending, {
    response_text = "legacy prose",
})
T.falsy(missing, "legacy response has no structured semantic result")
T.equal(missingReason, "semantic_ir_missing",
    "legacy path is explicitly distinguishable")

T.finish("pnc_pbrainz_semantic_result_smoke")
