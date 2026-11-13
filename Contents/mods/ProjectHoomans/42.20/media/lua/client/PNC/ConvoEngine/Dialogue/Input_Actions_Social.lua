-- Directed social, recruitment, and relationship-proposal dispatchers.

return function(Input, Internal, Support)
    local ActionContext = Support.actionContext
    local function dispatchSocialIntent(view, result, value)
        local decision = result and result.decision or {}
        local ir = result and result.ir or nil
        local socialContext = ir and ir.socialContext or nil
        local speechAct = string.upper(tostring(
            ir and (ir.speechAct or ir.intent) or ""
        ))
        local context
        local submit
        local accepted
        local reason
        local details
        if not result or result.accepted ~= true then
            return nil
        end
        if decision.route == "llm_fallback"
            or not Support.DIRECTED_HOSTILITY_BRANCHES[decision.branch]
            or type(socialContext) ~= "table"
            or socialContext.directed ~= true
            or socialContext.selfDirected == true
            or not Support.DIRECTED_HOSTILITY_ACTS[speechAct]
        then
            return nil
        end
        context = ActionContext(view, result, value)
        context.speechAct = speechAct
        submit = PNC.Client
            and PNC.Client.RequestSemanticSocialInteraction or nil
        if type(submit) ~= "function" then
            return {
                status = "semantic_social_dispatch_unavailable",
                accepted = false,
                reason = "semantic_social_transport_unavailable",
            }
        end
        accepted, reason, details = submit({
            npcID = context.npcID,
            requestID = context.requestID,
            conversationID = context.conversationID,
            conversationToken = context.conversationToken,
            speechAct = speechAct,
        }, context)
        details = type(details) == "table" and details or {
            accepted = accepted == true,
            status = accepted == true and "dispatched" or "rejected",
            reason = accepted == true and nil or reason,
            requestID = context.requestID,
            npcID = context.npcID,
            speechAct = speechAct,
        }
        Support.audit("semantic.social.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = details.requestID or context.requestID,
            speechAct = speechAct,
            status = details.status,
            accepted = accepted == true,
            reason = details.reason or reason,
        }, { requestID = context.requestID })
        return details
    end

    local function dispatchRecruitment(view, result, value)
        local context = ActionContext(view, result, value)
        -- Resolve these at dispatch time. Native load order can assemble the
        -- conversation composer after the semantic input module has been
        -- loaded; the harness and the game must therefore observe the same
        -- live seam.
        local conversation = PNC.Conversation or {}
        local composer = conversation.Composer
        local relationship = conversation.Relationship
        local setPreviewRequirement = relationship
            and relationship.SetPreviewRequirement
        if type(setPreviewRequirement) == "function" then
            -- Match the native recruit-row hover/preflight state. The server
            -- still rechecks the target, audience, lease, relationship, and
            -- ownership.
            setPreviewRequirement(context.npcID, "recruit")
        end
        if not composer
            or type(composer.RequestRecruit) ~= "function"
        then
            return {
                status = "conversation_recruitment_unavailable",
                accepted = false,
                reason = "conversation_recruitment_unavailable",
            }
        end
        local sent, reason = composer.RequestRecruit(context.npcID)
        local requestID = view and view.spec and view.spec.context
            and view.spec.context.pendingConversationRequest or nil
        local output = {
            status = sent == true
                and "conversation_recruitment_pending"
                or "conversation_recruitment_rejected",
            accepted = sent == true,
            pending = sent == true,
            reason = sent == true and nil or reason,
            action = "RECRUIT",
            requestID = requestID,
            npcID = context.npcID,
        }
        Support.audit("semantic.conversation.recruitment.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = requestID,
            action = "RECRUIT",
            status = output.status,
            accepted = output.accepted,
            reason = output.reason,
        }, { requestID = requestID or context.requestID })
        return output
    end

    local function dispatchRelationshipProposal(view, result, value)
        local context = ActionContext(view, result, value)
        local relationships = PNC.Relationships or {}
        if type(relationships.Propose) ~= "function" then
            return {
                status = "relationship_proposal_unavailable",
                accepted = false,
                reason = "relationship_proposal_unavailable",
                action = "RELATIONSHIP_PROPOSAL",
                npcID = context.npcID,
            }
        end
        local applied, reason, details = relationships.Propose(context.npcID)
        details = type(details) == "table" and details or {}
        local output = {
            status = applied == true
                and "relationship_proposal_applied"
                or "relationship_proposal_rejected",
            accepted = applied == true,
            pending = false,
            reason = reason,
            action = "RELATIONSHIP_PROPOSAL",
            npcID = context.npcID,
            serverAuthoritative = true,
            proposal = details,
        }
        Support.audit("semantic.relationship.proposal.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = context.requestID,
            action = output.action,
            status = output.status,
            accepted = output.accepted,
            reason = output.reason,
            route = "production_relationship_service",
        }, { requestID = context.requestID })
        return output
    end

    Internal.DispatchSocialIntent = dispatchSocialIntent
    Internal.DispatchRecruitment = dispatchRecruitment
    Internal.DispatchRelationshipProposal = dispatchRelationshipProposal
end
