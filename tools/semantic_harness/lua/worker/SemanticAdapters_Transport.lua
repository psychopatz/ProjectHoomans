local Provider = {}

function Provider.configure(deps)
    local Runtime = deps.Runtime
    local Values = deps.Values
    local runtime = deps.runtime
    local player = deps.player
    local PNC = _G.PNC

    local function serverResult(payload)
        local mode = runtime.mode or "singleplayer"
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = mode,
            command = "SemanticIdentityResult",
            payload = Values.copy(payload),
        }
        if mode == "multiplayer" then
            sendServerCommand(
                player, "ProjectHoomans", "SemanticIdentityResult", payload
            )
        else
            triggerEvent(
                "OnServerCommand", "ProjectHoomans",
                "SemanticIdentityResult", payload
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
