-- Inventory-query and quest-action dispatchers.

return function(Input, Internal, Support)
    local InventoryPending = require
        "PNC/Semantics/PNC_SemanticDialogueInput_InventoryPending"
    local CommandAdapter = PNC.Semantics.CommandAdapter
    local InventoryQueryAdapter = PNC.Semantics.InventoryQueryAdapter

    function Internal.DispatchInventoryQuery(view, result, value)
        local decision = result and result.decision or {}
        if type(decision.inventoryQuery) ~= "table"
            or type(InventoryQueryAdapter) ~= "table"
            or type(InventoryQueryAdapter.Dispatch) ~= "function"
        then
            return nil
        end
        local context = Support.actionContext(view, result, value)
        local requestID = context.requestID
        local registered, registrationReason = InventoryPending.Register(
            view, requestID, {
                rawText = value,
                query = decision.inventoryQuery,
                at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            })
        local dispatched
        if registered then
            -- Register before transport because local-server responses can
            -- arrive synchronously from inside Dispatch.
            dispatched = InventoryQueryAdapter.Dispatch(
                decision.inventoryQuery, context)
        else
            dispatched = {
                status = "rejected",
                accepted = false,
                reason = registrationReason,
            }
        end
        dispatched = type(dispatched) == "table" and dispatched or {
            status = "rejected", accepted = false,
        }
        dispatched.requestID = dispatched.request
            and dispatched.request.requestID or requestID
        dispatched.query = decision.inventoryQuery
        Support.audit("semantic.inventory.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = dispatched.requestID,
            status = dispatched.status,
            accepted = dispatched.accepted == true,
            pending = dispatched.pending == true,
            reason = dispatched.reason,
            query = decision.inventoryQuery,
        }, { requestID = dispatched.requestID })
        local resultStatus = type(dispatched.result) == "table"
            and dispatched.result.status or nil
        if dispatched.result and dispatched.result.status
            and dispatched.result.status ~= "pending"
            and Input.ReceiveInventoryQueryResult
        then
            Input.ReceiveInventoryQueryResult(dispatched.result)
        end
        if registered and dispatched.pending ~= true
            and resultStatus ~= "pending"
        then
            InventoryPending.Remove(view, requestID)
        end
        return dispatched
    end

    function Internal.DispatchQuestAction(view, actionIntent, context, value)
        local session = view and view.session
        local provisionalID = context.requestID
        if session and provisionalID then
            session.semanticQuestRequests = session.semanticQuestRequests or {}
            -- Register before transport because a host-mode service may answer
            -- synchronously and multiplayer may deliver the result in the same
            -- tick through the normal command router.
            session.semanticQuestRequests[tostring(provisionalID)] = {
                action = actionIntent.action,
                rawText = value,
            }
        end
        local questResult = CommandAdapter.Dispatch(actionIntent, context)
        questResult = type(questResult) == "table" and questResult or {
            status = "failed",
            accepted = false,
            reason = "quest_dispatch_failed",
        }
        local request = questResult.request or {}
        local requestID = tostring(request.requestID or provisionalID or "")
        local resultWasConsumed = session and requestID ~= ""
            and session.semanticQuestRequests
            and session.semanticQuestRequests[requestID] == nil
            and type(questResult.result) == "table"
            and tostring(questResult.result.status or "") == "pending"
        if session and requestID ~= "" then
            session.semanticQuestRequests = session.semanticQuestRequests or {}
            if provisionalID and tostring(provisionalID) ~= requestID then
                session.semanticQuestRequests[tostring(provisionalID)] = nil
            end
            if not resultWasConsumed then
                session.semanticQuestRequests[requestID] = {
                    action = actionIntent.action,
                    rawText = value,
                    request = request,
                }
            end
        end
        local authoritative = questResult.result
        if type(authoritative) == "table"
            and tostring(authoritative.status or "") ~= "pending"
        then
            authoritative.requestID = authoritative.requestID or requestID
            authoritative.npcID = authoritative.npcID or context.npcID
            authoritative.questID = authoritative.questID
                or request.questID or "pnc.quest.clinic_supplies"
            authoritative.operation = authoritative.operation
                or request.operation
            if Input.ReceiveSemanticQuestResult then
                Input.ReceiveSemanticQuestResult(authoritative)
            end
        elseif questResult.accepted ~= true
            and Input.ReceiveSemanticQuestResult
        then
            Input.ReceiveSemanticQuestResult({
                requestID = requestID,
                npcID = context.npcID,
                questID = request.questID or "pnc.quest.clinic_supplies",
                operation = request.operation,
                accepted = false,
                status = tostring(questResult.status or "") ~= ""
                    and questResult.status or "failed",
                reason = questResult.reason or "quest_dispatch_failed",
            })
        end
        Support.audit("semantic.quest.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = requestID,
            action = actionIntent.action,
            status = questResult.status,
            accepted = questResult.accepted == true,
            reason = questResult.reason,
        }, { requestID = requestID })
        return questResult
    end
end
