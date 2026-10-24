-- Conversation and interaction commands for the semantic worker router.

local Conversation = {}

function Conversation.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "INPUT" then
        if payload == nil then return nil, "input_required" end
        return context.Conversation.turn(context, tostring(payload))
    elseif command == "PREVIEW" then
        if payload == nil then return nil, "input_required" end
        return context.Conversation.preview(context, tostring(payload))
    elseif command == "RELATIONSHIP_PROPOSAL" then
        local npcID = type(payload) == "table" and payload.npcID
            or context.npcData.npcID
        local propose = PNC.Relationships
            and PNC.Relationships.Propose
        if type(propose) ~= "function" then
            return nil, "relationship_proposal_unavailable"
        end
        local applied, reason, details = propose(npcID)
        details = type(details) == "table" and details or {}
        return {
            ok = true,
            type = "relationship_proposal",
            action = PNC.RelationshipProposalPolicy
                and PNC.RelationshipProposalPolicy.ActionID()
                or "RELATIONSHIP_PROPOSAL",
            accepted = details.accepted == true,
            applied = applied == true,
            reason = reason,
            proposal = context.Values.copy(details),
            simulationProjection = context.ScenarioSession
                .simulationProjection(context),
        }
    elseif command == "APPLY_RUNTIME_RELATIONSHIP_BASELINE" then
        if type(payload) ~= "table" then
            return nil, "relationship_baseline_required"
        end
        local response, reason = context.ProductionRehydration
            .applyRuntimeRelationshipBaseline(context, payload)
        if not response then return nil, reason end
        return context.ScenarioSession.compactTransportResponse(
            context, response
        )
    elseif command == "RELATIONSHIP_PREVIEW" then
        local npcID = type(payload) == "table" and payload.npcID
            or context.npcData.npcID
        local values = type(payload) == "table" and payload.relationship
            or payload
        local preview = PNC.Relationships
            and PNC.Relationships.Preview
        if type(preview) ~= "function" then
            return nil, "relationship_preview_unavailable"
        end
        local result = preview(npcID, values)
        if type(result) ~= "table" then
            return nil, "relationship_preview_unavailable"
        end
        local relationship = result.relationship or {}
        return {
            ok = true,
            type = "relationship_preview",
            schema = "semantic.relationship.preview.v1",
            action = result.action or "RELATIONSHIP_PROPOSAL",
            standing = result.standing or relationship.state or "unknown",
            reason = result.standingReason,
            approval = relationship.approval or 0,
            respect = relationship.respect or 0,
            familiarity = relationship.familiarity or 0,
            bond = context.Values.copy(result.bond or relationship.bond),
            proposal = context.Values.copy(result),
            persisted = false,
        }
    elseif command == "SUGGESTION_PREDICATE" then
        local predicates = PNC.Semantics
            and PNC.Semantics.SuggestionPredicates or nil
        local view = context.Runtime and context.Runtime.view or nil
        if not predicates or type(predicates.Evaluate) ~= "function" then
            return nil, "suggestion_predicates_unavailable"
        end
        if type(payload) ~= "table" or type(payload.predicate) ~= "table" then
            return nil, "suggestion_predicate_required"
        end
        return {
            ok = true,
            type = "suggestion_predicate",
            result = predicates.Evaluate(
                payload.predicate,
                view and view.spec and view.spec.context or {}
            ),
        }
    elseif command == "SUGGESTION_CLICK" then
        local view = context.Runtime and context.Runtime.view or nil
        if type(payload) ~= "table" or type(payload.frame) ~= "table" then
            return nil, "suggestion_frame_required"
        end
        if not view or not view.session then
            return nil, "conversation_unavailable"
        end
        local suggestions = PNC.Semantics
            and PNC.Semantics.DialogueSuggestions or nil
        if suggestions
            and (
                (type(suggestions.IsConversationCategoryFrame) == "function"
                    and suggestions.IsConversationCategoryFrame(payload.frame))
                or (type(suggestions.IsConversationChoiceFrame) == "function"
                    and suggestions.IsConversationChoiceFrame(payload.frame))
                or (type(suggestions.IsConversationRootChoiceFrame)
                    == "function"
                    and suggestions.IsConversationRootChoiceFrame(payload.frame))
                or (type(suggestions.IsShortcutFrame) == "function"
                    and suggestions.IsShortcutFrame(payload.frame))
                or (type(suggestions.IsBackFrame) == "function"
                    and suggestions.IsBackFrame(payload.frame))
                or (type(suggestions.IsGroupFrame) == "function"
                    and suggestions.IsGroupFrame(payload.frame))
            )
        then
            return context.Conversation.semanticClick(
                context,
                Values.copy(payload.frame)
            )
        end
        context.Runtime.semanticClickFrame = Values.copy(payload.frame)
        return context.Conversation.turn(
            context,
            tostring(payload.frame.textFallback or payload.frame.candidateID or "")
        )
    elseif command == "LANGUAGE" then
        if payload == nil then return nil, "language_required" end
        local response = context.Translations.setLanguage(context,
            type(payload) == "table" and payload.language or payload)
        context.Conversation.refreshViewContext(context)
        local view = context.Runtime.view
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        local suggestions
        if view and view.lastSemanticDialogueResult
            and internal and type(internal.RefreshSuggestions) == "function"
        then
            suggestions = internal.RefreshSuggestions(
                view, view.lastSemanticDialogueResult
            )
        elseif internal
            and type(internal.RefreshRootSuggestions) == "function"
        then
            suggestions = internal.RefreshRootSuggestions(view)
        end
        response.suggestions = context.Values.copy(suggestions)
        return response
    elseif command == "TOOL_REPLY" then
        return context.OutputProjection.toolReply(context, payload)
    elseif command == "CONVERSATION_GRAPH" then
        return {
            ok = true,
            type = "conversation_graph",
            graph = context.Conversation.graphProjection(
                context.Runtime and context.Runtime.view
            ),
        }
    elseif command == "CONVERSATION_PROJECTION"
        or command == "TALK_PROJECTION"
    then
        local projection = context.Conversation.presentationProjection(
            context,
            context.Runtime and context.Runtime.view
        )
        if type(projection) ~= "table" then
            return nil, "conversation_projection_unavailable"
        end
        return {
            ok = true,
            type = "conversation_projection",
            presentation = Values.copy(projection),
        }
    end
    return false
end

return Conversation
