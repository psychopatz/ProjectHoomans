local Provider = {}

function Provider.configure(deps)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local runtime = deps.runtime
    local player = deps.player
    local PNC = _G.PNC

    local function serverResult(command, payload)
        local mode = runtime.mode or "singleplayer"
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = mode,
            command = command,
            payload = Values.copy(payload),
        }
        if mode == "multiplayer" then
            sendServerCommand(
                player, "ProjectHoomans", command, payload
            )
        else
            triggerEvent(
                "OnServerCommand", "ProjectHoomans", command, payload
            )
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
            direction = "server_to_client",
            module = module,
            command = command,
            payload = Values.copy(payload),
        }
        if PNC.Client and PNC.Client.HandleServerCommand then
            PNC.Client.HandleServerCommand(command, payload)
        end
    end
    sendClientCommand = function(_, module, command, payload)
        -- PZ exposes both (module, command, payload) and player-prefixed forms.
        if payload == nil and type(command) == "table" then
            payload, command, module = command, module, _
        end
        if module == PNC.Const.MODULE
            and command == PNC.Const.CMD_SEMANTIC_INTERACTION_LIFECYCLE then
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server", module = module,
                command = command, payload = Values.copy(payload),
            }
            return PNC.ServerCommandRouter.Handle(command, player, payload)
        end
        local questRequest = module == PNC.Const.MODULE
            and command == PNC.Const.CMD_SEMANTIC_QUEST_REQUEST
        local knowledgeRequest = module == PNC.Const.MODULE
            and command == PNC.Const.CMD_KNOWLEDGE_DISCLOSURE_REQUEST
        local bootstrapRequest = module == PNC.Const.MODULE
            and command == PNC.Const.CMD_PLAYER_BOOTSTRAP_REQUEST
        if questRequest then
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                module = module,
                command = command,
                payload = Values.copy(payload),
            }
        end
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
        if knowledgeRequest then
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = runtime.mode,
                command = command,
                payload = Values.copy(payload),
            }
            local callback = PNC.PlayerKnowledgeCommands
                and PNC.PlayerKnowledgeCommands.HandleDisclosure
            if type(callback) == "function" then
                callback(player, payload)
                return true
            end
            return false
        end
        if bootstrapRequest then
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = runtime.mode,
                command = command,
                payload = Values.copy(payload),
            }
            local callback = PNC.PlayerKnowledgeCommands
                and PNC.PlayerKnowledgeCommands.HandleBootstrap
            if type(callback) == "function" then
                callback(player, payload)
                return true
            end
            return false
        end
        if questRequest and runtime.mode == "multiplayer" then
            local router = PNC.ServerCommandRouter
            if router and type(router.Handle) == "function" then
                return router.Handle(command, player, payload)
            end
            return false
        end
        if not questRequest then
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_command",
                module = module,
                command = command,
                payload = Values.copy(payload),
            }
        end
        return true
    end

    PNC.Network.Internal.SendIdentityPayload = function(_, command, payload)
        return serverResult(command, payload)
    end

    PNC.PBrainZ = {
        IsProviderAvailable = function()
            return runtime.llmEnabled == true and runtime.providerAvailable == true
        end,
        IsBridgeEnabled = function() return runtime.llmEnabled == true end,
        GetProviderStatus = function()
            return {
                ready = runtime.llmEnabled == true
                    and runtime.providerAvailable == true,
                status = runtime.providerAvailable == true
                    and "ready" or "unavailable",
            }
        end,
        Submit = function()
            Runtime.llmCalls = Runtime.llmCalls + 1
            return false, "harness_llm_disabled"
        end,
    }
end

return Provider
