--[[
    PNC Client Actions
    Owns outbound debug, map, health, companion, and inventory commands.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local ClientState = PNC.Network.ClientState

local function traceCompanionCommand(commandID, npcId, scope, context, result)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if not trace or not trace.IsEnabled or not trace.IsEnabled() then
        return
    end
    local requestID = type(context) == "table" and context.requestID or nil
    trace.Record({
        source = "ProjectHoomans",
        event = "game.companion_command",
        requestID = requestID,
        data = {
            commandID = tostring(commandID or ""),
            npcID = npcId and tostring(npcId) or nil,
            scope = scope and tostring(scope) or nil,
            origin = type(context) == "table" and context.origin or nil,
            result = result,
        },
    })
end

local function teleportLocalPlayerNear(record, player)
    if not record or not player then
        return false
    end
    local body = Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    local x = body and body:getX() or tonumber(record.x) or 0
    local y = body and body:getY() or tonumber(record.y) or 0
    local z = body and body:getZ() or tonumber(record.z) or 0
    return Teleport.ToCoordinates(player, x + 1.5, y + 1.5, z)
end

function Client.SendDebug(action, payload)
    local player = getSpecificPlayer(0)
    local args = payload or {}
    args.action = action
    if action == "set_map_known" and player then
        args.playerKey = player.getUsername and player:getUsername()
            or player.getOnlineID and tostring(player:getOnlineID())
            or nil
    end
    if not Client.CanUseDebug() then
        return false
    end
    if Core.IsClientOnly and Core.IsClientOnly() and player then
        sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
        return true
    end
    if action == "conversation_debug_recruit" then
        local ok
        local reason
        if not PNC.DebugCompanionRecruit
            or not PNC.DebugCompanionRecruit.Try
        then
            return false, "debug_recruit_service_unavailable"
        end
        ok, reason = PNC.DebugCompanionRecruit.Try(player, args)
        if ok and Client.RequestColonyManagement then
            Client.RequestColonyManagement()
            if PNC.ColonyNamePrompt
                and PNC.ColonyNamePrompt.OpenIfNeeded
            then
                PNC.ColonyNamePrompt.OpenIfNeeded(
                    ClientState.colonyManagement
                )
            end
        end
        return ok, reason
    end
    if action == "audit_bodies" and PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
        PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
        Client.RequestDebugRoster(false)
        return true
    end
    if action == "teleport_to_npc" and args.id then
        return teleportLocalPlayerNear(Registry.Get(args.id), player)
    end
    if action == "social_trigger_event" then
        local snapshot
        local reason
        if not PNC.RelationshipDebug
            or not PNC.RelationshipDebug.TriggerSocialEvent
        then
            return false
        end
        snapshot, reason =
            PNC.RelationshipDebug.TriggerSocialEvent(player, args)
        ClientState.relationshipDebugAuthorized = true
        ClientState.relationshipDebug = snapshot
        ClientState.relationshipDebugReason = reason
        ClientState.lastRelationshipDebugReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceiveDebugSnapshot then
            relationship.ReceiveDebugSnapshot(snapshot)
        end
        return snapshot ~= nil, reason
    end
    if action == "conversation_relationship_standing" then
        local summary
        local reason
        if not PNC.RelationshipDebug
            or not PNC.RelationshipDebug.SetConversationStanding
        then
            return false
        end
        summary, reason = PNC.RelationshipDebug.SetConversationStanding(
            player,
            args
        )
        if summary then
            ClientState.conversationRelationships =
                ClientState.conversationRelationships or {}
            ClientState.conversationRelationships[
                tostring(summary.npcID)
            ] = summary
            ClientState.lastConversationRelationshipReceiveAt = Core.Now()
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceivePresentation then
                relationship.ReceivePresentation(summary)
            end
        end
        return summary ~= nil, reason
    end
    if action == "relationship_debug_baseline" then
        local snapshot
        local reason
        if not PNC.RelationshipDebug
            or not PNC.RelationshipDebug.ApplyDebugBaseline
        then
            return false
        end
        snapshot, reason = PNC.RelationshipDebug.ApplyDebugBaseline(
            player,
            args
        )
        ClientState.relationshipDebugAuthorized = true
        ClientState.relationshipDebug = snapshot
        ClientState.relationshipDebugReason = reason
        ClientState.lastRelationshipDebugReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceiveDebugSnapshot then
            relationship.ReceiveDebugSnapshot(snapshot)
        end
        return snapshot ~= nil, reason
    end
    if action == "knowledge_debug_action" then
        if not PNC.NPCKnowledge or not PNC.NPCKnowledge.ExecuteDebugForPlayer then return false end
        local snapshot, reason = PNC.NPCKnowledge.ExecuteDebugForPlayer(player, args)
        ClientState.knowledgeDebugAuthorized = true
        ClientState.knowledgeDebug, ClientState.knowledgeDebugReason = snapshot, reason
        if PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.ReceiveSnapshot then PNC.KnowledgeDebugUI.ReceiveSnapshot(snapshot) end
        if PNC.NPCDossierUI and PNC.NPCDossierUI.ReceiveDebugSnapshot then PNC.NPCDossierUI.ReceiveDebugSnapshot(snapshot) end
        return snapshot ~= nil, reason
    end
    if action == "faction_debug_action" then
        local snapshot
        if not PNC.FactionDebug
            or not PNC.FactionDebug.PerformAction
        then
            return false
        end
        snapshot = PNC.FactionDebug.PerformAction(player, args)
        ClientState.factionDebugAuthorized = true
        ClientState.factionDebug = snapshot
        ClientState.factionDebugReason = nil
        ClientState.lastFactionDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end
    if action == "community_debug_action" then
        local snapshot
        if not PNC.CommunityDebug
            or not PNC.CommunityDebug.PerformAction
        then
            return false
        end
        snapshot = PNC.CommunityDebug.PerformAction(
            player,
            args
        )
        ClientState.communityDebugAuthorized = true
        ClientState.communityDebug = snapshot
        ClientState.communityDebugReason = nil
        ClientState.lastCommunityDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end
    if action == "needs_debug_action" then
        if not PNC.NeedsDebug or not PNC.NeedsDebug.PerformAction then return false end
        local snapshot = PNC.NeedsDebug.PerformAction(args)
        ClientState.needsDebugAuthorized = true
        ClientState.needsDebug = snapshot
        ClientState.needsDebugReason = nil
        ClientState.lastNeedsDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end
    if action == "director_debug_action" then
        if not PNC.AbstractDirectorDebug then return false end
        local snapshot = PNC.AbstractDirectorDebug.PerformAction(args)
        ClientState.directorDebugAuthorized = true
        ClientState.directorDebug = snapshot
        ClientState.directorDebugReason = nil
        ClientState.lastDirectorDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end
    if action == "spawn" and PNC.API and PNC.API.Spawn then
        local variant = tostring(args.variant or "companion")
        local tacticalClass = tostring(args.tacticalClass or "")
        if tacticalClass ~= "colonist" and tacticalClass ~= "neutral"
            and tacticalClass ~= "hostile"
        then
            return false
        end
        local colonist = tacticalClass == "colonist"
        local hostile = tacticalClass == "hostile"
        local playerFaction
        local playerFactionID
        local ownerUsername = colonist and player and player.getUsername and player:getUsername() or nil
        local ownerOnlineID = colonist and player and player.getOnlineID and player:getOnlineID() or nil
        local x = tonumber(args.x) or (player and player:getX()) or 0
        local y = tonumber(args.y) or (player and player:getY()) or 0
        local z = tonumber(args.z) or (player and player:getZ()) or 0
        if colonist and PNC.Factions
            and PNC.Factions.EnsurePlayerFaction
        then
            local factionOK
            local factionReason
            factionOK, factionReason, playerFaction =
                PNC.Factions.EnsurePlayerFaction(player, {})
            if not factionOK or not playerFaction then
                return false
            end
            playerFactionID = playerFaction.id
        end
        return PNC.API.Spawn({
            tacticalClass = tacticalClass,
            x = x, y = y, z = z,
            ownerUsername = ownerUsername,
            ownerOnlineID = ownerOnlineID,
            recruited = colonist,
            factionID = playerFactionID,
            membershipStatus = colonist and "member" or nil,
            factionRole = colonist and "civilian" or nil,
            factionRank = colonist and "member" or nil,
            orderSpec = colonist and {
                kind = Const.ORDER_FOLLOW,
                ownerUsername = ownerUsername,
                ownerOnlineID = ownerOnlineID,
            } or hostile and {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = x, y = y, z = z,
            } or {
                kind = Const.ORDER_ROAM,
                roamMode = Const.ROAM_MODE_AREA,
                x = x, y = y, z = z,
                radius = Const.ROAM_DEFAULT_RADIUS,
            },
            equipmentSpawnMode = PNC.Inventory.GetDebugEquipmentSpawnMode(
                variant,
                args.equipmentSpawnMode
            ),
            forceLive = true,
            debug = true,
        }) ~= nil
    end
    if PNC.API and args.id then
        return PNC.API.DebugCommand(args.id, action, args)
    end
    return false
end

function Client.SendFactionMemberAction(
    memberAction,
    playerKey
)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    if not player then return false end
    local args = {
        memberAction = tostring(memberAction or ""),
        playerKey = playerKey
            and tostring(playerKey) or nil,
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_FACTION_MEMBER_ACTION,
            args
        )
        return true
    end
    if not PNC.FactionMembership
        or not PNC.FactionMembership.PerformAction
    then
        return false
    end
    local snapshot
    local reason
    snapshot, reason =
        PNC.FactionMembership.PerformAction(
            player,
            args
        )
    ClientState.factionMembers = snapshot
    ClientState.factionMembersReason = reason
    ClientState.lastFactionMembersReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.SendMapCommand(commandID, npcIds, target, options)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = {
        requestId = Core.GenerateID
            and Core.GenerateID("map_command") or tostring(Core.Now()),
        commandID = tostring(commandID or ""),
        npcIds = Core.DeepCopy(npcIds or {}),
        target = Core.DeepCopy(target or {}),
        options = Core.DeepCopy(options or {}),
    }
    if args.commandID == "" or #args.npcIds <= 0 then return false end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_MAP_COMMAND,
            args
        )
        return true
    end
    local result = PNC.MapCommandService
        and PNC.MapCommandService.Execute
        and PNC.MapCommandService.Execute(player, args, {
            debugAuthorized = Client.CanUseDebug(),
            source = "local",
        }) or {
            requestId = args.requestId,
            commandID = args.commandID,
            ok = false,
            reason = "map_commands_unavailable",
        }
    if PNC.MapCommands and PNC.MapCommands.HandleResult then
        PNC.MapCommands.HandleResult(result)
    end
    return result.ok == true, result
end

function Client.SendRevive(npcId)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId then
        return false
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false
        end
        sendClientCommand(player, Const.MODULE, Const.CMD_REVIVE, { id = npcId })
        return true
    end
    return PNC.Revive and PNC.Revive.Try and PNC.Revive.Try(player, npcId) or false
end

function Client.CompleteBandage(npcId, partId, debugFree, bandageType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId or not partId then return false end
    debugFree = debugFree == true and Client.CanUseDebug()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_BANDAGE, {
            id = npcId,
            partId = tostring(partId),
            debugFree = debugFree,
            bandageType = bandageType,
        })
        return true
    end
    return PNC.Treatment and PNC.Treatment.TryBandage
        and PNC.Treatment.TryBandage(player, npcId, partId, {
            consumeItem = not debugFree,
            bandageType = bandageType,
        }) or false
end

function Client.SendBandage(npcId, partId, debugFree, bandageType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId or not partId then return false end
    debugFree = debugFree == true and Client.CanUseDebug()
    if not PNCBandageAction or not PNCBandageAction.Queue then return false end
    return PNCBandageAction.Queue(player, npcId, partId, debugFree, bandageType)
end

function Client.SendCompanionCommand(commandID, npcId, scope, context)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args
    if not player or not PNC.CompanionCommands
        or not PNC.CompanionCommands.Get(commandID)
    then
        traceCompanionCommand(commandID, npcId, scope, context, {
            status = "rejected",
            reason = "invalid_player_or_command",
        })
        return false
    end
    args = {
        commandID = tostring(commandID),
        id = npcId and tostring(npcId) or nil,
        scope = scope and tostring(scope) or nil,
        radius = tonumber(Const.COMPANION_COMMAND_RADIUS) or 20,
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            traceCompanionCommand(commandID, npcId, scope, context, {
                status = "rejected",
                reason = "network_api_unavailable",
            })
            return false
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_COMPANION_COMMAND,
            args
        )
        traceCompanionCommand(commandID, npcId, scope, context, {
            status = "network_queued",
        })
        return true
    end
    local affected = PNC.CompanionCommands.Execute(player, args)
    local succeeded = (tonumber(affected) or 0) > 0
    traceCompanionCommand(commandID, npcId, scope, context, {
        status = succeeded and "applied" or "rejected",
        affected = tonumber(affected) or 0,
    })
    return succeeded
end

function Client.ExecuteLLMSocialReaction(npcID, kind, intensity, context)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local tools = PNC.ConversationLLMTools
    local reaction = tools and tools.NormalizeReaction
        and tools.NormalizeReaction(kind) or nil
    local normalizedIntensity = tools and tools.NormalizeIntensity
        and tools.NormalizeIntensity(intensity) or "normal"
    local subtype
    local args
    local result
    if not player or not reaction then
        return false, "invalid_social_reaction"
    end
    context = type(context) == "table" and context or {}
    subtype = tools and tools.NormalizeSubtypeForReaction
        and tools.NormalizeSubtypeForReaction(context.subtype, reaction) or nil
    args = {
        npcID = tostring(npcID or ""),
        token = tostring(context.token or ""),
        requestID = tostring(context.requestID or ""),
        callID = tostring(context.callID or ""),
        kind = reaction,
        intensity = normalizedIntensity,
        subtype = subtype,
    }
    if args.npcID == "" or args.requestID == "" or args.callID == "" then
        return false, "social_reaction_identity_missing"
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_LLM_SOCIAL_REACTION,
            args
        )
        traceCompanionCommand("social_react", npcID, "conversation", context, {
            status = "network_queued",
            reaction = reaction,
            intensity = normalizedIntensity,
            callID = args.callID,
        })
        return true, "network_queued"
    end
    local authority = PNC.Conversation and PNC.Conversation.Authority
    if not authority or not authority.HandleLLMSocialReaction then
        return false, "social_reaction_authority_unavailable"
    end
    result = authority.HandleLLMSocialReaction(player, args)
    traceCompanionCommand("social_react", npcID, "conversation", context, result)
    if type(result) == "table" then
        return result.accepted == true, result.reason, result
    end
    return result == true, result and "applied" or "rejected"
end

function Client.ExecutePlayerEmoteInteraction(emote, context)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local interactions = PNC.VanillaEmoteInteractions
    local definition = interactions and interactions.Get(emote) or nil
    local requestID
    local args
    local result
    local authority
    if not player or not definition then
        return false, "unsupported_emote"
    end
    context = type(context) == "table" and context or {}
    requestID = tostring(context.requestID or "")
    if requestID == "" then
        requestID = Core.GenerateID and Core.GenerateID("emote")
            or tostring(Core.Now())
    end
    args = {
        requestID = requestID,
        emote = definition.id,
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_PLAYER_EMOTE_INTERACTION,
            args
        )
        traceCompanionCommand("vanilla_emote", definition.id, "social", {
            requestID = requestID,
            origin = context.origin or "vanilla_emote_radial",
        }, { status = "network_queued" })
        return true, "network_queued", args
    end
    authority = PNC.PlayerEmoteInteractionAuthority
    if not authority or not authority.Handle then
        return false, "emote_interaction_authority_unavailable"
    end
    result = authority.Handle(player, args)
    if PNC.CompanionCommandPresentation
        and PNC.CompanionCommandPresentation.HandlePlayerEmoteInteractionResult
    then
        PNC.CompanionCommandPresentation.HandlePlayerEmoteInteractionResult(
            result
        )
    end
    traceCompanionCommand("vanilla_emote", definition.id, "social", {
        requestID = requestID,
        origin = context.origin or "vanilla_emote_radial",
    }, result)
    if type(result) == "table" then
        return result.accepted == true, result.reason, result
    end
    return result == true, result and "applied" or "rejected", result
end

function Client.ReserveLLMRequest(npcID, token, requestID)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local authority
    local internal
    local record
    local accepted
    local reason
    local args = {
        npcID = tostring(npcID or ""),
        token = tostring(token or ""),
        requestID = tostring(requestID or ""),
    }
    if not player or args.npcID == "" or args.token == ""
        or args.requestID == ""
    then
        return false, "llm_request_identity_missing"
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_LLM_REQUEST_RESERVE,
            args
        )
        traceCompanionCommand("llm_request_reserve", npcID, "conversation", {
            requestID = requestID,
            origin = "llm_request",
        }, { status = "network_queued" })
        return true, "network_queued"
    end
    authority = PNC.Conversation and PNC.Conversation.Authority
    internal = authority and authority.Internal or nil
    record = Registry and Registry.Get and Registry.Get(args.npcID) or nil
    if not internal or not internal.ReserveLLMRequest or not record then
        return false, "llm_request_authority_unavailable"
    end
    accepted, reason = internal.ReserveLLMRequest(
        player,
        record,
        args.token,
        args.requestID
    )
    traceCompanionCommand("llm_request_reserve", npcID, "conversation", {
        requestID = requestID,
        origin = "llm_request",
    }, { accepted = accepted == true, reason = reason })
    return accepted == true, reason or (
        accepted and "reserved" or "rejected"
    )
end

function Client.ReleaseLLMRequest(npcID, token, requestID, reason)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local authority
    local internal
    local record
    local accepted
    local releaseReason
    local args = {
        npcID = tostring(npcID or ""),
        token = tostring(token or ""),
        requestID = tostring(requestID or ""),
    }
    if not player or args.npcID == "" or args.token == ""
        or args.requestID == ""
    then
        return false, "llm_request_identity_missing"
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_LLM_REQUEST_RELEASE,
            args
        )
        traceCompanionCommand("llm_request_release", npcID, "conversation", {
            requestID = requestID,
            origin = "llm_request",
        }, { status = "network_queued" })
        return true, "network_queued"
    end
    authority = PNC.Conversation and PNC.Conversation.Authority
    internal = authority and authority.Internal or nil
    record = Registry and Registry.Get and Registry.Get(args.npcID) or nil
    if not internal or not internal.ReleaseLLMRequest or not record then
        return false, "llm_request_authority_unavailable"
    end
    accepted, releaseReason = internal.ReleaseLLMRequest(
        player,
        record,
        args.token,
        args.requestID,
        tostring(reason or "request_completed")
    )
    traceCompanionCommand("llm_request_release", npcID, "conversation", {
        requestID = requestID,
        origin = "llm_request",
    }, { accepted = accepted == true, reason = releaseReason })
    return accepted == true, releaseReason or (
        accepted and "released" or "rejected"
    )
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
            traceCompanionCommand(commandID, npcId, scope, context, {
                status = opened and "opened" or "rejected",
                reason = opened and nil or "client_action_rejected",
            })
            return opened
        end
        traceCompanionCommand(commandID, npcId, scope, context, {
            status = "rejected",
            reason = "unsupported_client_action",
        })
        return false
    end
    return Client.SendCompanionCommand(commandID, npcId, scope, context)
end

local SCAVENGE_LOCAL_METHODS = {
    start_search = "StartSearch",
    cancel_search = "CancelSearch",
    queue_pickup = "QueuePickup",
    queue_multiple = "QueueMultiple",
    start_collection = "StartCollection",
    cancel_collection = "CancelCollection",
    pause = "Pause",
    disband = "Disband",
    set_auto_grab = "SetAutoGrab",
    remove_auto_grab = "RemoveAutoGrab",
    set_preferences = "SetSearchPreferences",
    request_policy = "RequestPolicy",
    request_snapshot = "RequestSnapshot",
}

function Client.SendScavengeRequest(action, payload)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return false, "player_unavailable" end
    local args = Core.DeepCopy(payload or {})
    args.action = tostring(action or "")
    local method = SCAVENGE_LOCAL_METHODS[args.action]
    if args.action == "debug_dump" then
        if not Client.CanUseDebug() then return false, "debug_denied" end
        if Core.IsClientOnly and Core.IsClientOnly() then
            if not sendClientCommand then return false, "network_unavailable" end
            sendClientCommand(player, Const.MODULE, Const.CMD_SCAVENGE_REQUEST,
                args)
            return true, "request_sent"
        end
        local service = PNC.ScavengeService
        local session = service and service.GetSession(args.sessionId)
        if not session then return false, "session_not_found" end
        local snapshot = service.BuildSnapshot(session)
        snapshot.debugDiagnostics = service.GetDiagnostics()
        snapshot.scavengeDebug = service.BuildSessionDiagnostics(session)
        Client.Internal.ApplyScavengeSnapshot(snapshot)
        return true, "debug_snapshot", snapshot
    end
    if not method then return false, "scavenge_action_invalid" end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false, "network_unavailable" end
        sendClientCommand(player, Const.MODULE, Const.CMD_SCAVENGE_REQUEST,
            args)
        return true, "request_sent"
    end
    local service = PNC.ScavengeService
    if not service or type(service[method]) ~= "function" then
        return false, "scavenge_service_unavailable"
    end
    local ok, reason, snapshot = service[method](player, args)
    -- Session services publish through SendSnapshot, including local games.
    -- Applying their return value here would duplicate every UI rebuild and
    -- bypass server-side snapshot throttling. Policy-only replies are not
    -- published by the service and still need direct delivery.
    if snapshot and snapshot.policyOnly == true
        and Client.Internal.ApplyScavengeSnapshot
    then
        Client.Internal.ApplyScavengeSnapshot(snapshot)
    end
    return ok == true, reason, snapshot
end

local function nextInventoryRequestID()
    ClientState.inventoryRequestSerial = (tonumber(ClientState.inventoryRequestSerial) or 0) + 1
    return table.concat({
        tostring(getTimeInMillis and getTimeInMillis() or Core.Now()),
        tostring(ClientState.inventoryRequestSerial),
    }, ":")
end

function Client.SendInventoryTransfer(args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or type(args) ~= "table" or not args.id then return false end
    args.requestId = args.requestId or nextInventoryRequestID()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_INVENTORY_TRANSFER, args)
        return true
    end
    if PNC.ServerInventory and PNC.ServerInventory.Transfer then
        local success, reason, result = PNC.ServerInventory.Transfer(player, args)
        if result and result.relationshipDelta then
            ClientState.lastConversationDelta = {
                npcID = result.npcId or args.id,
                source = result.giftEffect and "gift" or "inventory",
                delta = Core.DeepCopy(result.relationshipDelta),
                before = Core.DeepCopy(result.relationshipBefore),
                after = Core.DeepCopy(result.relationshipAfter),
                itemTypes = Core.DeepCopy(result.itemTypes),
                at = Core.Now(),
            }
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceiveAfter then
                relationship.ReceiveAfter(
                    result.npcId or args.id,
                    result.relationshipAfter,
                    result.relationshipDelta,
                    {
                        source = result.giftEffect and "gift"
                            or "inventory",
                        eventID = result.eventID or args.requestId,
                        revision = result.relationshipAfter
                            and result.relationshipAfter.revision,
                    }
                )
            end
        end
        Client.RequestCharacterPayload(args.id)
        if PNC.InventoryWindow and PNC.InventoryWindow.OnResult then
            result = result or {}
            result.success = success == true
            result.reason = reason
            result.npcId = args.id
            result.requestId = args.requestId
            PNC.InventoryWindow.OnResult(result)
        end
        return success == true
    end
    return false
end

function Client.SendInventoryAction(args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or type(args) ~= "table" or not args.id
        or not args.itemID or not args.actionID
    then
        return false
    end
    args.requestId = args.requestId or nextInventoryRequestID()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_INVENTORY_ACTION, args)
        return true
    end
    if PNC.ServerInventory and PNC.ServerInventory.Action then
        local success, reason = PNC.ServerInventory.Action(player, args)
        Client.RequestCharacterPayload(args.id)
        if PNC.InventoryWindow and PNC.InventoryWindow.OnResult then
            PNC.InventoryWindow.OnResult({
                success = success == true,
                reason = reason,
                npcId = args.id,
                requestId = args.requestId,
            })
        end
        return success == true
    end
    return false
end
