-- Harness implementations of the production semantic/network boundaries.

local SemanticAdapters = {}

function SemanticAdapters.identityName(context, npc)
    local safeString = context.Values.safeString
    local first = safeString(npc and npc.forename)
    local last = safeString(npc and npc.surname)
    if first ~= "" and last ~= "" then return first .. " " .. last end
    return first ~= "" and first or last
end

function SemanticAdapters.playerName(context, player)
    local safeString = context.Values.safeString
    local first = safeString(player and player.forename)
    local last = safeString(player and player.surname)
    if first ~= "" and last ~= "" then return first .. " " .. last end
    return first ~= "" and first or last
end

function SemanticAdapters.relationshipFor(context, npcID)
    local Runtime = context.Runtime
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local relationship = npc.relationship or {}
    Runtime.relationships = Runtime.relationships or {}
    Runtime.relationships[npcID] = Runtime.relationships[npcID]
        or context.Values.copy(relationship)
    return Runtime.relationships[npcID]
end

function SemanticAdapters.relationshipSnapshotFor(context, npcID)
    return context.Values.copy(SemanticAdapters.relationshipFor(context, npcID))
end

function SemanticAdapters.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local number = Values.number
    local playerData = context.playerData
    local npcData = context.npcData
    local conversationData = context.scenario.conversation or {}
    local runtime = context.runtime
    local player = context.player
    local conversationToken = tostring(conversationData.token or "")

    npcData.id = npcData.id or npcData.npcID
    npcData.runtime = type(npcData.runtime) == "table"
        and npcData.runtime or {}
    if type(npcData.runtime.conversationLease) ~= "table" then
        npcData.runtime.conversationLease = {
            token = conversationToken,
            maximumDistance = 6,
            dangerRadius = 8,
        }
    end

    local function identityName(npc)
        return SemanticAdapters.identityName(context, npc)
    end
    local function relationshipFor(npcID)
        return SemanticAdapters.relationshipFor(context, npcID)
    end
    local function relationshipSnapshotFor(npcID)
        return SemanticAdapters.relationshipSnapshotFor(context, npcID)
    end

    PNC = PNC or {}
    PNC.Core = PNC.Core or {}
    PNC.Core.Now = function() return Runtime.now end
    PNC.Core.DeepCopy = function(value) return Values.copy(value) end
    PNC.Const = PNC.Const or {}
    PNC.Const.MODULE = "ProjectHoomans"
    PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST = "SemanticIdentityRequest"
    PNC.Const.CMD_SEMANTIC_IDENTITY_RESULT = "SemanticIdentityResult"
    PNC.Network = PNC.Network or {}
    PNC.Network.ClientState = PNC.Network.ClientState or {}
    Values.clearTable(PNC.Network.ClientState)
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.characterPayloads = {}
    PNC.Network.Internal = PNC.Network.Internal or {}
    PNC.Semantics = PNC.Semantics or {}
    PNC.Conversation = PNC.Conversation or {}
    PNC.Conversation.Registry = PNC.Conversation.Registry or {}
    PNC.Conversation.Relationship = {
        ReceivePresentation = function() return true end,
    }
    PNC.ConversationScene = PNC.ConversationScene or {}
    local function validateHarnessLease(record, leasePlayer, token)
        local lease = record and record.runtime
            and record.runtime.conversationLease or nil
        if leasePlayer ~= player then return false, "player_mismatch" end
        if type(lease) ~= "table" or tostring(lease.token or "") == "" then
            return false, "lease_missing"
        end
        if tostring(lease.token) ~= tostring(token or "") then
            return false, "invalid_lease"
        end
        return true, lease
    end
    PNC.ConversationScene.ValidateConversationLease = function(
        record, leasePlayer, token
    )
        return validateHarnessLease(record, leasePlayer, token)
    end
    PNC.ConversationScene.Begin = function(
        record, _, leasePlayer, token
    )
        local valid, leaseOrReason = validateHarnessLease(
            record, leasePlayer, token
        )
        if not valid then return false, leaseOrReason end
        return true
    end
    PNC.Registry = PNC.Registry or {}
    PNC.Registry.Get = function(id)
        return tostring(id) == tostring(npcData.npcID) and npcData or nil
    end
    PNC.Registry.GetLiveZombie = function(id)
        return tostring(id) == tostring(npcData.id) and {} or nil
    end
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerCharacters.GetRegistryRecord = function(characterUUID)
        if tostring(characterUUID) ~= tostring(playerData.characterUUID) then
            return nil
        end
        return {
            displayName = playerData.displayName,
            forename = playerData.forename,
            surname = playerData.surname,
        }
    end
    PNC.PlayerContext = PNC.PlayerContext or {}
    PNC.PlayerContext.Resolve = function()
        return {
            characterUUID = playerData.characterUUID,
            playerEntityKey = "player:" .. tostring(playerData.characterUUID),
        }, "harness_resolved"
    end
    PNC.PlayerContext.Peek = PNC.PlayerContext.Resolve
    PNC.Relationships = PNC.Relationships or {}
    PNC.Relationships.Get = function(npcID)
        return relationshipSnapshotFor(npcID)
    end
    PNC.Relationships.ApplyConversationEffect = function(npcID, _, effect, effectContext)
        local relationship = relationshipFor(npcID)
        relationship.approval = number(relationship.approval, 0)
            + number(effect.approval, 0)
        relationship.respect = number(relationship.respect, 0)
            + number(effect.respect, 0)
        relationship.familiarity = number(relationship.familiarity, 0)
            + number(effect.familiarity, 0)
        relationship.revision = number(relationship.revision, 0) + 1
        if effect.tags and effect.tags.untrustworthy then
            relationship.identityTrust = "untrustworthy"
        elseif effect.tags and effect.tags.truthful then
            relationship.identityTrust = "trusted"
        end
        local clientState = PNC.Network and PNC.Network.ClientState
        if clientState then
            clientState.conversationRelationships =
                clientState.conversationRelationships or {}
            clientState.conversationRelationships[tostring(npcID)] =
                Values.copy(relationship)
        end
        return true, "applied", {
            eventID = effectContext and effectContext.eventID,
            memoryID = effectContext and effectContext.eventID,
            memoryType = effect.memoryType,
        }
    end
    PNC.RelationshipPresentation = PNC.RelationshipPresentation or {}
    PNC.RelationshipPresentation.Summarize = function(value)
        return Values.copy(value)
    end
    PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
    PNC.NPCKnowledgeAPI.DiscloseForPlayer = function(_, options)
        npcData.identityState = "known"
        PNC.Network.ClientState.npcPresentations =
            PNC.Network.ClientState.npcPresentations or {}
        PNC.Network.ClientState.npcPresentations[npcData.npcID] = {
            state = "known",
            displayName = identityName(npcData),
        }
        if Runtime.view and Runtime.view.spec
            and Runtime.view.spec.context
        then
            Runtime.view.spec.context.identityState = "known"
        end
        Runtime.disclosures = number(Runtime.disclosures, 0) + 1
        Runtime.knowledge = options
        return { accepted = true, revealed = { "identity.name" } }
    end
    PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}
    PNC.PlayerKnowledgeCommands.Internal = PNC.PlayerKnowledgeCommands.Internal or {}
    PNC.PlayerKnowledgeCommands.Internal.SafeID = function(value)
        value = tostring(value or "")
        return value ~= "" and value or nil
    end
    PNC.PlayerKnowledgeCommands.Internal.ContextFor = function()
        return {
            characterUUID = playerData.characterUUID,
            playerEntityKey = "player:" .. tostring(playerData.characterUUID),
        }
    end
    PNC.PlayerKnowledgeCommands.Internal.IntroductionText = function()
        return "I'm " .. identityName(npcData) .. "."
    end

    local function serverResult(payload)
        local mode = runtime.mode or "singleplayer"
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = mode,
            command = "SemanticIdentityResult",
            payload = Values.copy(payload),
        }
        if mode == "multiplayer" then
            sendServerCommand(player, "ProjectHoomans", "SemanticIdentityResult", payload)
        else
            triggerEvent("OnServerCommand", "ProjectHoomans", "SemanticIdentityResult", payload)
        end
        return true
    end

    triggerEvent = function(eventName, module, command, payload)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "event",
            eventName = eventName,
            module = module,
            command = command,
            payload = Values.copy(payload),
        }
        if eventName == "OnServerCommand"
            and PNC.Client and PNC.Client.HandleServerCommand
        then
            PNC.Client.HandleServerCommand(command, payload)
        end
    end
    sendServerCommand = function(_, module, command, payload)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_command",
            module = module,
            command = command,
            payload = Values.copy(payload),
        }
        if PNC.Client and PNC.Client.HandleServerCommand then
            PNC.Client.HandleServerCommand(command, payload)
        end
    end
    sendClientCommand = function(_, module, command, payload)
        if module == PNC.Const.MODULE
            and command == PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST
        then
            local callback = PNC.PlayerKnowledgeCommands
                and PNC.PlayerKnowledgeCommands.HandleSemanticIdentity
            if type(callback) == "function" then
                callback(player, payload)
                return true
            end
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_command",
            module = module,
            command = command,
            payload = Values.copy(payload),
        }
        return true
    end

    PNC.Network.Internal.SendIdentityPayload = function(_, command, payload)
        return serverResult(payload)
    end

    PNC.PBrainZ = {
        IsProviderAvailable = function()
            return runtime.llmEnabled == true and runtime.providerAvailable == true
        end,
        IsBridgeEnabled = function() return runtime.llmEnabled == true end,
        GetProviderStatus = function()
            return {
                ready = runtime.llmEnabled == true and runtime.providerAvailable == true,
                status = runtime.providerAvailable == true and "ready" or "unavailable",
            }
        end,
        Submit = function()
            Runtime.llmCalls = Runtime.llmCalls + 1
            return false, "harness_llm_disabled"
        end,
    }

    -- The server-side semantic validators and client result router stay real.
    PNC.Client = PNC.Client or {}
    PNC.Client.Internal = PNC.Client.Internal or {}
    PNC.Core.IsClientOnly = function()
        return runtime.mode == "multiplayer"
    end
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

    PNC.Client.SendCompanionCommand = function(commandID, npcID, scope, commandContext)
        local responses = runtime.commandResponses or {}
        local configured = responses[tostring(commandID)]
        local accepted = true
        local reason = "network_queued"
        local targets = { tostring(npcID or "") }
        local details = {}
        if configured == false then
            accepted = false
            reason = "mock_command_rejected"
        elseif type(configured) == "table" then
            if configured.accepted ~= nil then
                accepted = configured.accepted == true
            end
            reason = tostring(configured.reason
                or (accepted and "network_queued" or "mock_command_rejected"))
            targets = Values.copy(configured.targets or targets)
            details = Values.copy(configured.details or {})
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "CompanionCommand",
            payload = {
                commandID = tostring(commandID or ""),
                id = tostring(npcID or ""),
                scope = tostring(scope or ""),
                requestID = commandContext and commandContext.requestID,
                commandSource = commandContext and commandContext.commandSource,
                campSiteHint = commandContext and Values.copy(commandContext.campSiteHint),
            },
        }
        return accepted, reason, targets, details
    end
end

return SemanticAdapters
