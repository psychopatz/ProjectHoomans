-- Quest request boundary: production delegation or bounded scenario replies.

local function configureProductionBoundary(deps, Provider)
    local Runtime = deps.Runtime
    local runtime = deps.runtime
    local PNC = _G.PNC

    if runtime.mode == "multiplayer"
        and type(Provider.productionQuestRequest) == "function"
    then
        Runtime.questBoundary = "production"
        local productionRequest = Provider.productionQuestRequest
        local productionWrapper = function(request, context)
            return productionRequest(request, context)
        end
        Runtime.questProductionWrapper = productionWrapper
        PNC.Client.RequestSemanticQuest = productionWrapper
    else
        Runtime.questBoundary = "harness"
        PNC.Client.RequestSemanticQuest = deps.harnessRequestSemanticQuest
    end
end

local function buildHarnessRequest(deps)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local runtime = deps.runtime

    return function(request, context)
        request = type(request) == "table" and request or {}
        context = type(context) == "table" and context or {}
        local operation = string.lower(tostring(request.operation or ""))
        local configured = runtime.questResponses
            and runtime.questResponses[operation]
        local accepted = true
        local status = operation == "offer" and "available"
            or operation == "accept" and "accepted"
            or operation == "status" and "active"
            or operation == "turn_in" and "rewarded" or "failed"
        local reason = operation == "offer" and "available"
            or operation == "accept" and "accepted"
            or operation == "status" and "status_returned"
            or operation == "turn_in" and "rewarded" or "quest_operation_invalid"
        local details = {}
        if configured == false then
            accepted = false
            status = "rejected"
            reason = "mock_quest_rejected"
        elseif type(configured) == "table" then
            if configured.accepted ~= nil then
                accepted = configured.accepted == true
            end
            status = tostring(configured.status or status)
            reason = tostring(configured.reason
                or (accepted and reason or "mock_quest_rejected"))
            details = Values.copy(configured)
        end
        local result = details.result and Values.copy(details.result)
            or details
        result.accepted = accepted
        result.status = status
        result.reason = reason
        result.requestID = result.requestID or request.requestID
        result.npcID = result.npcID or request.npcID or context.npcID
        result.giverNPCID = result.giverNPCID or result.npcID
        result.questID = result.questID
            or request.questID or "pnc.quest.clinic_supplies"
        result.operation = result.operation or operation
        result.responsePoolID = result.responsePoolID
            or "semantic.quest.clinic_supplies." .. operation
        result.objective = result.objective or {
            id = "deliver_bandage",
            required = 1,
            delivered = (status == "ready" or status == "rewarded") and 1 or 0,
            itemFullType = "Base.Bandage",
            direction = "player_to_npc",
        }
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "SemanticQuestRequest",
            payload = Values.copy(request),
        }
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = runtime.mode,
            command = "SemanticQuestResult",
            payload = Values.copy(result),
        }
        return accepted, reason, result
    end
end

return function(deps, Provider)
    local questDeps = {
        Runtime = deps.Runtime,
        Values = deps.Values,
        runtime = deps.runtime,
    }
    questDeps.harnessRequestSemanticQuest = buildHarnessRequest(questDeps)
    configureProductionBoundary(questDeps, Provider)
end
