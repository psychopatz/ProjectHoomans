-- Runtime authority, persistence, and disclosure seams for the harness.

return function(deps, Provider)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local npcData = deps.npcData
    local runtime = deps.runtime
    local PNC = _G.PNC

    -- The server-side semantic validators and client result router stay real.
    PNC.Client = PNC.Client or {}
    PNC.Client.Internal = PNC.Client.Internal or {}
    if type(Runtime.productionQuestRequest) == "function" then
        Provider.productionQuestRequest = Runtime.productionQuestRequest
    elseif #Runtime.loadedModules > 0
        and type(PNC.Client.RequestSemanticQuest) == "function"
    then
        Provider.productionQuestRequest = PNC.Client.RequestSemanticQuest
    end
    PNC.Core.IsClientOnly = function()
        return runtime.mode == "multiplayer"
    end
    -- The worker is a dual-role production boundary: multiplayer client
    -- calls are queued through the client transport, while the same worker
    -- hosts the canonical server handlers for the authoritative leg. Keep
    -- the server-side Core predicate explicit instead of inheriting the
    -- native headless runtime role, which has no game server process.
    PNC.Core.IsAuthority = function()
        return true
    end
    -- Exercise the real Knowledge commit path while keeping the worker
    -- independent from the native world-save coordinator. This is a bounded
    -- persistence seam, not a second journal or a replacement authority.
    PNC.PersistenceCoordinator = PNC.PersistenceCoordinator or {}
    PNC.PersistenceCoordinator.Commit = function(reason)
        Runtime.persistenceCommits = Runtime.persistenceCommits or {}
        Runtime.persistenceCommits[#Runtime.persistenceCommits + 1] =
            tostring(reason or "worker")
        local knowledge = PNC.NPCKnowledge
        if not knowledge or type(knowledge.Save) ~= "function" then
            return false, "knowledge_persistence_unavailable"
        end
        local saved, saveReason = knowledge.Save(false)
        if saved == false and saveReason == "not_dirty" then
            return true, "not_dirty"
        end
        return saved, saveReason
    end
    PNC.MedicalCareService = PNC.MedicalCareService or {}
    PNC.MedicalCareService.List = function()
        if runtime.questEligible == false then return {} end
        return {
            {
                id = "medical-supply-task-1",
                status = "WAITING_FOR_SUPPLY",
                blockedReason = "missing_bandage",
                supplyRequesterId = npcData.npcID,
            },
        }
    end
    PNC.Tasking = PNC.Tasking or {}
    PNC.Tasking.Events = PNC.Tasking.Events or {}
    if type(PNC.Tasking.Events.Emit) ~= "function" then
        PNC.Tasking.Events.Emit = function() return true end
    end
    local productionKnowledgeRequest = Runtime.productionKnowledgeRequest
    PNC.Client.RequestNPCKnowledgeTopic = function(npcID, topicID, options)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "KnowledgeDisclosureRequest",
            payload = {
                npcID = npcID,
                topicID = topicID,
                options = Values.copy(options),
            },
        }
        if type(productionKnowledgeRequest) == "function" then
            return productionKnowledgeRequest(npcID, topicID, options)
        end
        return true
    end
    local Commands = PNC.PlayerKnowledgeCommands
    if not Commands.__semanticIdentityHarnessBridge then
        local handleIdentity = Commands.HandleSemanticIdentity
        if type(handleIdentity) == "function" then
            Commands.HandleSemanticIdentity = function(
                dispatchPlayer, args
            )
                Runtime.transport[#Runtime.transport + 1] = {
                    direction = "client_to_server",
                    mode = (Runtime.scenario
                        and Runtime.scenario.runtime or {}).mode,
                    command = PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST,
                    payload = Values.copy(args),
                }
                return handleIdentity(dispatchPlayer, args)
            end
            Commands.__semanticIdentityHarnessBridge = true
        end
    end
end
