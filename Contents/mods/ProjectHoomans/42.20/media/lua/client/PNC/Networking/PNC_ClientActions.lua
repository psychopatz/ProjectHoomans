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
    if action == "spawn" and PNC.API and PNC.API.Spawn then
        local variant = tostring(args.variant or "colonist")
        local legacyFaction = (variant == "hostile_melee" or variant == "hostile_ranged")
            and "hostile" or variant
        local faction = PNC.Types.NormalizeFaction(args.faction or legacyFaction)
        if faction ~= "colonist" and faction ~= "neutral" and faction ~= "hostile" then
            faction = "colonist"
        end
        local colonist = faction == "colonist"
        local hostile = faction == "hostile"
        local ownerUsername = colonist and player and player.getUsername and player:getUsername() or nil
        local ownerOnlineID = colonist and player and player.getOnlineID and player:getOnlineID() or nil
        local x = tonumber(args.x) or (player and player:getX()) or 0
        local y = tonumber(args.y) or (player and player:getY()) or 0
        local z = tonumber(args.z) or (player and player:getZ()) or 0
        return PNC.API.Spawn({
            faction = faction,
            x = x, y = y, z = z,
            ownerUsername = ownerUsername,
            ownerOnlineID = ownerOnlineID,
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

function Client.SendCompanionCommand(commandID, npcId, scope)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args
    if not player or not PNC.CompanionCommands
        or not PNC.CompanionCommands.Get(commandID)
    then
        return false
    end
    args = {
        commandID = tostring(commandID),
        id = npcId and tostring(npcId) or nil,
        scope = scope and tostring(scope) or nil,
        radius = tonumber(Const.COMPANION_COMMAND_RADIUS) or 20,
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_COMPANION_COMMAND,
            args
        )
        return true
    end
    local affected = PNC.CompanionCommands.Execute(player, args)
    return (tonumber(affected) or 0) > 0
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
        local success, reason = PNC.ServerInventory.Transfer(player, args)
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
