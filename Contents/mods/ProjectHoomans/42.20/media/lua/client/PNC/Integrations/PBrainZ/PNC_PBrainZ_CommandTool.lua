-- LLM companion-command tool handler.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local ToolFlow = Internal.ToolFlow
local Handlers = Internal.ToolHandlers

Handlers.order = function(result, packet, npcID, arguments, callID)
    local name = result.name
    if not ToolFlow.Exposed(packet, name) then
        result.reason = "tool_not_exposed"
        return
    end
    local commandID = Runtime.Trim(arguments.command_id)
    local definition = PNC.CompanionCommands
        and PNC.CompanionCommands.Get(commandID) or nil
    local execute = PNC.Client and PNC.Client.ExecuteCompanionCommand
    if definition and execute then
        local accepted
        local reason
        local targets
        accepted, reason, targets = execute(
            commandID,
            npcID,
            "conversation",
            {
                origin = "llm_tool",
                requestID = packet and packet.request_id,
                callID = callID,
            }
        )
        result.accepted = accepted == true
        result.reason = reason or (result.accepted
            and "submitted" or "rejected_by_game")
        result.commandID = commandID
        result.targets = targets
    else
        result.reason = "unknown_command"
    end
end

return Handlers.order
