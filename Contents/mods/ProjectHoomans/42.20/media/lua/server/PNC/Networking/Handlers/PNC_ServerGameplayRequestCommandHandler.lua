-- Gameplay request adapters. Domain services retain policy and mutation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local CompanionCommands = PNC.CompanionCommands
local MapCommandService = PNC.MapCommandService

local function isColonistActivityCommand(args)
    return tostring(args and args.commandSource or "")
            == "colonist_activities"
        or string.match(tostring(args and args.commandID or ""), "^manual_")
            ~= nil
end

Router.Register(Const.CMD_COMPANION_COMMAND, function(player, args)
    if not args.commandID then return end
    if CompanionCommands and CompanionCommands.Execute then
        local affected, reason, affectedTargets, details =
            CompanionCommands.Execute(player, args)
        if sendServerCommand
            and (tostring(args.commandID) == "camp"
                or tostring(args.commandSource or "") == "companion_emote"
                or tostring(args.commandSource or "") == "llm_tool"
                or isColonistActivityCommand(args))
        then
            sendServerCommand(
                player,
                Const.MODULE,
                Const.CMD_COMPANION_COMMAND_RESULT,
                {
                    commandID = tostring(args.commandID),
                    id = args.id,
                    dialogueID = args.dialogueID,
                    scope = args.scope,
                    affected = tonumber(affected) or 0,
                    accepted = (tonumber(affected) or 0) > 0,
                    reason = tostring(reason),
                    targets = affectedTargets,
                    details = details,
                    requestID = args.requestID,
                    callID = args.callID,
                    commandSource = args.commandSource,
                }
            )
        end
        if isColonistActivityCommand(args)
            and PNC.Core and PNC.Core.Log
        then
            PNC.Core.Log(tonumber(affected) and affected > 0
                    and "INFO" or "WARN",
                "manual_activity_command npc="
                    .. tostring(args.id or "group")
                    .. " command=" .. tostring(args.commandID or "")
                    .. " affected=" .. tostring(affected or 0)
                    .. " reason=" .. tostring(reason or "unknown")
                    .. " requestID=" .. tostring(args.requestID or "")
                    .. " source=" .. tostring(args.commandSource or "network"))
        end
        if tostring(args.commandID) == "manual_corpse_haul"
            and PNC.Core and PNC.Core.Log
        then
            PNC.Core.Log(tonumber(affected) and affected > 0
                    and "INFO" or "WARN",
                "manual_corpse_haul_command npc="
                    .. tostring(args.id or "group")
                    .. " affected=" .. tostring(affected or 0)
                    .. " reason=" .. tostring(reason or "unknown")
                    .. " requestID=" .. tostring(args.requestID or "")
                    .. " source=" .. tostring(args.commandSource or "network"))
        end
    end
end)

Router.Register(Const.CMD_MAP_COMMAND, function(player, args)
    local result = MapCommandService and MapCommandService.Execute
        and MapCommandService.Execute(player, args, {
            debugAuthorized = Router.CanUseDebug(player),
            source = "network",
        }) or {
            ok = false,
            reason = "map_commands_unavailable",
        }
    if sendServerCommand then
        sendServerCommand(
            player,
            Const.MODULE,
            Const.CMD_MAP_COMMAND_RESULT,
            result
        )
    end
end)

Router.Register(Const.CMD_FACTION_TOLL_RESPONSE, function(player, args)
    local tolls = PNC.FactionTolls
    if tolls and tolls.HandleResponse then
        tolls.HandleResponse(player, args)
    end
end)

Router.Register(Const.CMD_SCAVENGE_REQUEST, function(player, args)
    args = type(args) == "table" and args or {}
    local runtime = PNC.ScavengeRuntime
    if not runtime or type(runtime.HandleRequest) ~= "function" then
        return
    end
    local ok, reason, snapshot = runtime.HandleRequest(player, args)
    if ok and snapshot and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_SCAVENGE_STATE,
            snapshot)
    elseif not ok and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_SCAVENGE_STATE, {
            policyOnly = true,
            requestFailed = true,
            requestAction = tostring(args.action or ""),
            reason = tostring(reason or "scavenge_request_failed"),
            npcId = args.npcId,
        })
    end
end)
