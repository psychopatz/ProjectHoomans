PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
-- Final semantic action router.

return function(Input, Internal, Support)
    local CommandAdapter = PNC.Semantics.CommandAdapter
    local WorldTargetHints = PNC.Semantics.ClientWorldTargetHints
    local CampSiteHints = PNC.Semantics.ClientCampSiteHints
    local CampSite = PNC.Semantics.CampSite
    local ActionTargetHints = PNC.ConvoEngine.DialogueInputActionTargetHints
    local QuestResponses = Internal.QuestResponses
    local S11PolicyEvaluator = require "PsychopatzCore/ConvoEngine/S11PolicyEvaluator"

    local function findActionPolicyPlan(actionName)
        local reg = PNC and PNC.ConvoEngine and PNC.ConvoEngine.Registry or nil
        local plans = reg and reg.CONVO_PLANS or nil
        if type(plans) ~= "table" or actionName == "" then
            return nil
        end
        local normalized = actionName == "GO_HOME" and "RETURN_HOME" or (actionName == "RETURN" and "RETURN_HOME" or actionName)
        for _, plan in pairs(plans) do
            if type(plan) == "table" and type(plan.payload) == "table"
                and type(plan.payload.invoke) == "table"
                and tostring(plan.payload.invoke.action or "") == normalized
                and type(plan.payload.statePolicy) == "table"
            then
                return plan
            end
        end
        return nil
    end

    local function buildPolicyEvalContext(view, context)
        local shallow = type(Internal.ShallowContext) == "function"
            and Internal.ShallowContext(view) or {}
        local record = context.npcID and PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(context.npcID) or nil
        local baseRoles = type(shallow.roles) == "table" and shallow.roles
            or (type(record) == "table" and type(record.roles) == "table" and record.roles)
            or {}
        local isRecruited = (type(record) == "table" and record.recruited == true)
            or (type(shallow) == "table" and shallow.recruited == true)
        local roles = {
            companion = baseRoles.companion == true or isRecruited,
            owned = baseRoles.owned == true or isRecruited,
            hostile = baseRoles.hostile == true,
            authorityEligible = baseRoles.authorityEligible,
        }
        local rel = type(shallow.relationship) == "table" and shallow.relationship
            or (type(record) == "table" and type(record.relationship) == "table" and record.relationship)
            or {}
        local bondClass = type(rel.bond) == "table" and tostring(rel.bond.class or "") or ""
        local relState = tostring(rel.state or rel.relationshipState or "")
        if bondClass == "lover" or bondClass == "partner" or bondClass == "spouse" then
            relState = bondClass
        end
        local activeBehavior = tostring(
            (type(shallow.npcState) == "table" and shallow.npcState.activeBehavior)
            or (type(shallow.situation) == "table" and shallow.situation.activeBehavior)
            or (type(record) == "table" and record.activeBehavior)
            or ""
        )
        local orderKind = tostring(
            shallow.orderKind
            or (type(record) == "table" and record.orderKind)
            or (type(shallow.followState) == "table" and shallow.followState.mode)
            or (type(record) == "table" and type(record.followState) == "table" and record.followState.mode)
            or ""
        )
        return {
            roles = roles,
            relationship = {
                state = relState,
            },
            npcState = {
                activeBehavior = activeBehavior,
                orderKind = orderKind,
            },
            situation = {
                activeBehavior = activeBehavior,
            },
            followState = type(shallow.followState) == "table" and shallow.followState
                or (type(record) == "table" and type(record.followState) == "table" and record.followState)
                or {},
        }
    end

    local function evaluateCanonicalPolicyBlock(view, context, actionName, result, generatedFlow)
        local actionPlan = findActionPolicyPlan(tostring(actionName or ""))
        if not actionPlan then
            return nil
        end
        local evalRes = S11PolicyEvaluator.EvaluateStatePolicy(
            actionPlan,
            buildPolicyEvalContext(view, context)
        )
        if type(evalRes) == "table"
            and (evalRes.admission == "no_op" or evalRes.admission == "reject")
        then
            if type(generatedFlow) == "table" then
                generatedFlow.dispatchCount = 0
            end
            local projectedReply = evalRes.replyOutcome
                and S11PolicyEvaluator.ProjectReply
                and S11PolicyEvaluator.ProjectReply(actionPlan, evalRes.replyOutcome)
                or nil
            if type(result) == "table" and type(projectedReply) == "table" then
                result.response = {
                    templateID = projectedReply.templateID,
                    fallback = projectedReply.fallback,
                }
            end
            local blocked = Support.blockedDispatch(evalRes.reason or "state_policy_blocked")
            if type(projectedReply) == "table" then
                blocked.templateID = projectedReply.templateID
                blocked.fallback = projectedReply.fallback
                blocked.replyOutcome = projectedReply.replyOutcome
            end
            return blocked
        end
        return nil
    end

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
        local context = Support.actionContext(view, result, value)
        context.generatedFlow = generatedFlow
        local actionIntent = ActionTargetHints.AttachCampSiteHint(
            decision.actionIntent, context, CampSite, CampSiteHints, Support.audit)
        local campTarget = actionIntent and actionIntent.target
        local campHint = campTarget and campTarget.clientHint
        if actionIntent and actionIntent.action == "CAMP"
            and type(campTarget) == "table"
            and type(campHint) ~= "table"
            and campTarget.kind == "camp_site"
        then
            -- A selected primitive is already bounded by the semantic
            -- suggestion frame. If the client-only resolver is unavailable
            -- (as in the headless worker) or reports a stale observation,
            -- preserve it as a non-authoritative hint so the server can
            -- reject or resolve it explicitly instead of silently choosing a
            -- different destination.
            campHint = campTarget
        end
        if actionIntent and actionIntent.action == "CAMP"
            and type(campHint) == "table"
        then
            -- Reuse the already-bounded observation for the command adapter.
            -- This avoids a second client scan in the same dialogue tick.
            context.campSiteHint = campHint
        end
        actionIntent = ActionTargetHints.AttachWorldTargetHint(
            actionIntent, context, WorldTargetHints, Support.audit)
        local policyAction = (actionIntent and actionIntent.action)
            or decision.actionIntent.action
        local blocked = policyAction and evaluateCanonicalPolicyBlock(
            view,
            context,
            policyAction,
            result,
            generatedFlow
        )
        if blocked then return blocked end
        if decision.actionIntent.action == "RELATIONSHIP_PROPOSAL" then
            return Internal.DispatchRelationshipProposal(view, result, value)
        end
        if decision.actionIntent.action == "RECRUIT" then
            return Internal.DispatchRecruitment(view, result, value)
        end
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
