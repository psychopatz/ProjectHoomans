-- Flow, engine catalog, quest replay, and commitment commands.

local Authoring = {}

function Authoring.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "FLOW_CATALOG" then
        return context.FlowEditor.catalog(context)
    elseif command == "BEAT_CATALOG" then
        return context.InteractionEditor.catalog(context)
    elseif command == "BEAT_VALIDATE" then
        if type(payload) ~= "table" then
            return nil, "beat_definition_must_be_object"
        end
        return context.InteractionEditor.validateBeat(context, payload)
    elseif command == "BEAT_REGISTER" then
        if type(payload) ~= "table" then
            return nil, "beat_definition_must_be_object"
        end
        return context.InteractionEditor.registerBeat(context, payload)
    elseif command == "BEAT_PREVIEW" then
        if type(payload) ~= "table" then
            return nil, "beat_preview_must_be_object"
        end
        return context.InteractionEditor.previewBeat(context, payload)
    elseif command == "INTERACTION_PREVIEW" then
        if type(payload) ~= "table" then
            return nil, "interaction_stimulus_must_be_object"
        end
        return context.InteractionEditor.previewInteraction(context, payload)
    elseif command == "BEHAVIOR_VALIDATE" then
        if type(payload) ~= "table" then
            return nil, "behavior_definition_must_be_object"
        end
        return context.InteractionEditor.validateBehavior(context, payload)
    elseif command == "BEHAVIOR_REGISTER" then
        if type(payload) ~= "table" then
            return nil, "behavior_definition_must_be_object"
        end
        return context.InteractionEditor.registerBehavior(context, payload)
    elseif command == "RESPONSE_KEY_LOOKUP" then
        return context.FlowEditor.responseKeyLookup(context, payload)
    elseif command == "RESPONSE_POOL_LIST" then
        return context.FlowEditor.responsePoolList(context, payload)
    elseif command == "RESPONSE_SELECTION_SAMPLE" then
        return context.FlowEditor.sampleResponseSelection(context, payload)
    elseif command == "RESPONSE_SELECTION_EXPLAIN" then
        return context.FlowEditor.explainResponseSelection(context, payload)
    elseif command == "RESPONSE_POOL_DETAIL" then
        return context.FlowEditor.responsePoolDetail(context, payload)
    elseif command == "FLOW_VALIDATE" then
        if type(payload) ~= "table" then
            return nil, "flow_definition_must_be_object"
        end
        return context.FlowEditor.validate(context, payload)
    elseif command == "FLOW_REGISTER" then
        if type(payload) ~= "table" then
            return nil, "flow_definition_must_be_object"
        end
        return context.FlowEditor.register(context, payload)
    elseif command == "FLOW_GENERATE" or command == "FLOW_COVERAGE" then
        return context.FlowEditor.generate(context)
    elseif command == "REPLAY_SEMANTIC_QUEST" then
        if type(payload) ~= "table" then
            return nil, "quest_request_must_be_object"
        end
        local router = PNC.ServerCommandRouter
        local handled = router and type(router.Handle) == "function"
            and router.Handle(
                PNC.Const.CMD_SEMANTIC_QUEST_REQUEST,
                context.player,
                payload
            ) or false
        return { ok = true, type = "semantic_quest_replay", handled = handled }
    elseif command == "COMMITMENT" then
        if type(payload) ~= "table" then
            return nil, "commitment_request_must_be_object"
        end
        return context.Commitments.dispatch(context, payload)
    elseif command == "FACT_CATALOG" then
        return {
            ok = true,
            type = "fact_catalog",
            facts = context.EngineFacts and context.EngineFacts.List
                and context.EngineFacts.List() or {},
        }
    elseif command == "EVENT_CATALOG" then
        return {
            ok = true,
            type = "event_catalog",
            events = context.EngineEvents and context.EngineEvents.ListTypes
                and context.EngineEvents.ListTypes() or {},
        }
    end
    return false
end

return Authoring
