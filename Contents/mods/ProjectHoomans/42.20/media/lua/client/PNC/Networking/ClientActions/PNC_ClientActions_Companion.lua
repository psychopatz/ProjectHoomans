-- Companion command transport and local command orchestration.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local Internal = Client.Internal

function Client.SendCompanionCommand(commandID, npcId, scope, context)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args
    local localReason
    local campSiteHint
    if not player or not PNC.CompanionCommands
        or not PNC.CompanionCommands.Get(commandID)
    then
        Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
            status = "rejected",
            reason = "invalid_player_or_command",
        })
        return false, "invalid_player_or_command"
    end
    if tostring(commandID or "") == "camp" then
        local rejected
        rejected, localReason, campSiteHint = Internal.RejectUnsafeCampLocally(
            player, npcId, scope, context)
        if rejected then
            Internal.RecordCampClient("REJECTED", localReason
                or "camp_no_visible_site", commandID, npcId, scope, context)
            Internal.PublishLLMCommandResult(
                commandID,
                npcId,
                context,
                false,
                localReason or "camp_no_visible_site"
            )
            Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
                status = "rejected",
                reason = localReason or "camp_no_visible_site",
            })
            return false, localReason or "camp_no_visible_site"
        end
    end
    args = {
        commandID = tostring(commandID),
        id = npcId and tostring(npcId) or nil,
        scope = scope and tostring(scope) or nil,
        radius = tonumber(Const.COMPANION_COMMAND_RADIUS) or 20,
        requestID = type(context) == "table" and context.requestID or nil,
        callID = type(context) == "table" and context.callID or nil,
        commandSource = type(context) == "table"
            and (context.commandSource or context.source or context.origin)
            or nil,
        dialogueID = type(context) == "table" and context.dialogueID or nil,
        campSiteHint = campSiteHint,
        targetIDs = Internal.GroupTargetIDs(scope, context),
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            Internal.RecordCampClient("REJECTED", "network_api_unavailable",
                commandID, npcId, scope, context)
            Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
                status = "rejected",
                reason = "network_api_unavailable",
            })
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_COMPANION_COMMAND,
            args
        )
        Internal.RecordCampClient("PENDING", "network_queued", commandID, npcId,
            scope, context, campSiteHint)
        Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
            status = "network_queued",
        })
        return true, "network_queued"
    end
    local affected, reason, affectedTargets, details =
        PNC.CompanionCommands.Execute(player, args)
    local succeeded = (tonumber(affected) or 0) > 0
    Internal.RecordCampServer(commandID, npcId, scope, context, succeeded, reason,
        campSiteHint, details)
    Internal.PublishLLMCommandResult(
        commandID,
        npcId,
        context,
        succeeded,
        reason,
        affectedTargets
    )
    if not succeeded and Internal.IsCampRejectionReason(reason)
        and not Internal.IsCampEmoteContext(context)
    then
        Internal.ShowCampRejection(
            player,
            npcId,
            reason,
            context,
            Internal.CommandRecord(npcId, context)
        )
    end
    Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
        status = succeeded and "applied" or "rejected",
        affected = tonumber(affected) or 0,
        reason = reason,
    })
    return succeeded, reason, affectedTargets, details
end
function Client.ExecuteCompanionCommand(commandID, npcId, scope, context)
    local definition = PNC.CompanionCommands
        and PNC.CompanionCommands.Get(commandID) or nil
    if not definition then return false end
    if definition.clientOnly == true then
        if commandID == "scavenge_nearby" then
            if not PNC.ScavengeController then
                require "PNC/Scavenge/PNC_ScavengeController"
            end
            local opened = PNC.ScavengeController
                and PNC.ScavengeController.Open
                and PNC.ScavengeController.Open(npcId, context) or false
            Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
                status = opened and "opened" or "rejected",
                reason = opened and nil or "client_action_rejected",
            })
            return opened
        end
        Internal.TraceCompanionCommand(commandID, npcId, scope, context, {
            status = "rejected",
            reason = "unsupported_client_action",
        })
        return false
    end
    return Client.SendCompanionCommand(commandID, npcId, scope, context)
end

return Client

