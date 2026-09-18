-- Local debug actions for unique-NPC and tactical-class spawning.
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local CompanionInitialization =
    require "PNC/Core/Companions/PNC_DebugCompanionInitialization"

local CONTINUE = "__pnc_debug_dispatch_continue"

return {
    spawn_unique_test = function(player, args)
        local uniqueAPI = PNC.API and PNC.API.UniqueNPCs
        local record
        local reason
        if not args.definitionId and not args.id then return false end
        if Core.IsClientOnly and Core.IsClientOnly() then
            if not sendClientCommand then
                return false, "network_unavailable"
            end
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
            return true, "request_sent"
        end
        if not uniqueAPI or not uniqueAPI.SpawnTest then
            return false, "unique_test_spawn_unavailable"
        end
        record, reason = uniqueAPI.SpawnTest(
            args.definitionId or args.id, player)
        ClientState.uniqueNPCTestSpawn = {
            success = record ~= nil,
            runtime = record and {
                id = tostring(record.id or ""),
                name = record.name,
                x = record.x,
                y = record.y,
                z = record.z,
            } or nil,
            reason = reason,
            at = Core.Now(),
        }
        return record ~= nil, reason, record
    end,

    spawn = function(player, args)
        if not PNC.API or not PNC.API.Spawn then
            return nil, CONTINUE
        end
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
        local ownerUsername = colonist and player and player.getUsername
            and player:getUsername() or nil
        local ownerOnlineID = colonist and player and player.getOnlineID
            and player:getOnlineID() or nil
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
        local record = PNC.API.Spawn({
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
        })
        if record and colonist then
            local gameTime = getGameTime and getGameTime() or nil
            local worldAgeHours = gameTime
                and gameTime.getWorldAgeHours
                and gameTime:getWorldAgeHours() or 0
            local initialized, initializationResult =
                CompanionInitialization.ApplyKnownCompanion(
                    player, record.id, worldAgeHours
                )
            if initialized and type(initializationResult) == "table"
                and initializationResult.relationshipApplied ~= true
                and Core.LogWarn
            then
                Core.LogWarn(
                    "PNC debug companion relationship initialization failed npc="
                        .. tostring(record.id) .. " reason="
                        .. tostring(initializationResult.relationshipReason)
                )
            elseif not initialized and Core.LogWarn then
                Core.LogWarn(
                    "PNC debug companion initialization failed npc="
                        .. tostring(record.id) .. " reason="
                        .. tostring(initializationResult)
                )
            end
            if initialized and type(initializationResult) == "table"
                and initializationResult.knowledgeApplied ~= true
                and Core.LogWarn
            then
                Core.LogWarn(
                    "PNC debug companion knowledge initialization failed npc="
                        .. tostring(record.id)
                )
            end
        end
        return record ~= nil
    end,
}
