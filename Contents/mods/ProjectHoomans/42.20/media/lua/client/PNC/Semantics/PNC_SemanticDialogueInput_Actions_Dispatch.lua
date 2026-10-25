-- Final semantic action router.

return function(Input, Internal, Support)
    local CommandAdapter = PNC.Semantics.CommandAdapter
    local WorldTargetHints = PNC.Semantics.ClientWorldTargetHints
    local CampSiteHints = PNC.Semantics.ClientCampSiteHints
    local CampSite = PNC.Semantics.CampSite
    local ActionTargetHints = PNC.Semantics.DialogueInputActionTargetHints
    local QuestResponses = Internal.QuestResponses

    function Internal.DispatchAction(view, result, value)
        local decision = result and result.decision or {}
        local generatedFlow = result and result.flow or nil
        if type(generatedFlow) == "table"
            and generatedFlow.generated == true
            and generatedFlow.gate
            and generatedFlow.gate.status ~= "PASS"
        then
            return Support.blockedDispatch(
                "flow_gate_" .. tostring(generatedFlow.gate.status or "UNKNOWN")
            )
        end
        if decision.giftConsent then
            if decision.giftConsent.status ~= "granted" then return nil end
            local allowed, blockReason = Support.dispatchBranchEligibility(
                decision, Support.GIFT_DISPATCH_BRANCHES)
            if not allowed then return Support.blockedDispatch(blockReason) end
            if type(Internal.DispatchGiftConsent) == "function" then
                return Internal.DispatchGiftConsent(view, result, value)
            end
            return {
                status = "gift_dispatch_unavailable",
                accepted = false,
                reason = "gift_dispatch_unavailable",
            }
        end
        if decision.giftOffer then
            local allowed, blockReason = Support.dispatchBranchEligibility(
                decision, Support.GIFT_DISPATCH_BRANCHES)
            if not allowed then return Support.blockedDispatch(blockReason) end
            if type(Internal.DispatchGiftOffer) == "function" then
                return Internal.DispatchGiftOffer(view, result, value)
            end
            return {
                status = "gift_dispatch_unavailable",
                accepted = false,
                reason = "gift_dispatch_unavailable",
            }
        end
        if decision.inventoryQuery then
            local allowed, blockReason = Support.dispatchBranchEligibility(
                decision, Support.INVENTORY_DISPATCH_BRANCHES)
            if not allowed then return Support.blockedDispatch(blockReason) end
            return Internal.DispatchInventoryQuery(view, result, value)
        end
        local socialResult = Internal.DispatchSocialIntent
            and Internal.DispatchSocialIntent(view, result, value) or nil
        if socialResult then return socialResult end
        if not decision.actionIntent then return nil end
        local actionAllowed, actionBlockReason =
            Support.dispatchBranchEligibility(
                decision, Support.EXECUTABLE_ACTION_BRANCHES)
        if not actionAllowed then
            return Support.blockedDispatch(actionBlockReason)
        end
        if decision.actionIntent.action == "RELATIONSHIP_PROPOSAL" then
            return Internal.DispatchRelationshipProposal(view, result, value)
        end
        if decision.actionIntent.action == "RECRUIT" then
            return Internal.DispatchRecruitment(view, result, value)
        end
        local context = Support.actionContext(view, result, value)
        context.generatedFlow = generatedFlow
        local actionIntent = ActionTargetHints.AttachCampSiteHint(
            decision.actionIntent, context, CampSite, CampSiteHints, Support.audit)
        if actionIntent and actionIntent.action == "CAMP"
            and actionIntent.target
            and type(actionIntent.target.clientHint) == "table"
        then
            -- Reuse the already-bounded observation for the command adapter.
            -- This avoids a second client scan in the same dialogue tick.
            context.campSiteHint = actionIntent.target.clientHint
        end
        actionIntent = ActionTargetHints.AttachWorldTargetHint(
            actionIntent, context, WorldTargetHints, Support.audit)
        if QuestResponses
            and type(QuestResponses.IsQuestAction) == "function"
            and QuestResponses.IsQuestAction(nil, actionIntent.action)
        then
            return Internal.DispatchQuestAction(view, actionIntent, context, value)
        end
        local commandResult = CommandAdapter.Dispatch(
            actionIntent, context)
        if commandResult.status ~= "unmapped" then
            Support.audit("semantic.command.dispatch", {
                npcID = context.npcID,
                conversationID = context.conversationID,
                requestID = context.requestID,
                action = actionIntent.action,
                status = commandResult.status,
                accepted = commandResult.accepted == true,
                reason = commandResult.reason,
            }, { requestID = context.requestID })
            return commandResult
        end
        local taskDispatch = Internal.DispatchTaskAction
        if type(taskDispatch) ~= "function" then
            return {
                status = "task_dispatch_unavailable",
                accepted = false,
                reason = "task_dispatch_unavailable",
            }
        end
        return taskDispatch(view, actionIntent, context, value)
    end
end
