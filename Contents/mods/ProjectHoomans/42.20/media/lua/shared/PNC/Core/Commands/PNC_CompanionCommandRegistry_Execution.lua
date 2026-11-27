-- Protocol-facing companion command execution and target-scope handling.
-- Command application remains owned by the parent registry entry.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
if type(Commands) ~= "table" then return false end

local function isGroupAttackAllowed(definition)
    return definition
        and (definition.allowGroupScope == true
            or definition.squadFollowerEffect == true)
end

local function isFollowingOrder(record)
    local order = record and record.orderSpec or nil
    return order ~= nil
        and tostring(order.kind or "") == tostring(Const.ORDER_FOLLOW or "follow")
end

local function applyToSquadFollowers(
    player,
    commandID,
    radius,
    args,
    excludeID,
    affectedTargets
)
    local count = 0
    local applied
    Registry.ForEach(function(record)
        if not record or tostring(record.id or "") == tostring(excludeID or "") then
            return
        end
        if not isFollowingOrder(record) then return end
        if not Commands.CanPlayerCommand(record, player, radius) then return end
        applied = Commands.Apply(record, player, commandID, radius, args)
        if applied then
            count = count + 1
            affectedTargets[#affectedTargets + 1] = tostring(record.id)
        end
    end)
    return count
end

function Commands.Execute(player, args)
    local commandID = tostring(args and args.commandID or "")
    local targetID = args and args.id or nil
    local scope = string.lower(tostring(args and args.scope or ""))
    local radius = tonumber(args and args.radius)
        or tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
    local definition = Commands.Get(commandID)
    local affected = 0
    local lastReason = "no_targets"
    local applied
    local reason
    local closestRecord
    local closestDistSq
    local closestID
    local x
    local y
    local z
    local distSq
    local affectedTargets = {}
    local details
    if commandID == "" or not definition then
        return 0, "unknown_command"
    end
    if scope == "group" and definition.attackType ~= nil
        and not isGroupAttackAllowed(definition)
    then
        return 0, "personalized_command"
    end
    if scope == "group" and definition.personalized == true then
        return 0, "personalized_command"
    end
    if scope == "group" and commandID == "camp" then
        return Commands.ApplyGroupCamp(player, args)
    end
    if scope == "closest" then
        Registry.ForEach(function(record)
            local allowed = Commands.CanPlayerCommand(record, player, radius)
            if not allowed then return end
            x, y, z = Commands.Internal.LivePosition(record)
            if x == nil or y == nil or z == nil then return end
            distSq = Core.DistanceSq(player:getX(), player:getY(), x, y)
            if closestRecord == nil or distSq < closestDistSq
                or (distSq == closestDistSq
                    and tostring(record.id) < tostring(closestID))
            then
                closestRecord = record
                closestDistSq = distSq
                closestID = record.id
            end
        end)
        if not closestRecord then return 0, "no_targets" end
        applied, reason, details = Commands.Apply(
            closestRecord,
            player,
            commandID,
            radius,
            args
        )
        if applied then
            affected = 1
            affectedTargets[1] = tostring(closestRecord.id)
            if definition.squadFollowerEffect == true then
                affected = affected + applyToSquadFollowers(
                    player,
                    commandID,
                    radius,
                    args,
                    closestRecord.id,
                    affectedTargets
                )
            end
        end
        return affected, reason, affectedTargets, details
    end
    if targetID ~= nil then
        applied, reason, details = Commands.Apply(
            Registry.Get(targetID),
            player,
            commandID,
            radius,
            args
        )
        if applied then
            affected = 1
            affectedTargets[1] = tostring(targetID)
            if definition.squadFollowerEffect == true then
                affected = affected + applyToSquadFollowers(
                    player,
                    commandID,
                    radius,
                    args,
                    targetID,
                    affectedTargets
                )
            end
        end
        return affected, reason, affectedTargets, details
    end
    if definition.attackType ~= nil and not isGroupAttackAllowed(definition) then
        return 0, "personalized_command"
    end
    Registry.ForEach(function(record)
        applied, reason, details = Commands.Apply(
            record, player, commandID, radius, args)
        if applied then
            affected = affected + 1
            affectedTargets[#affectedTargets + 1] = tostring(record.id)
        elseif reason ~= "not_companion" and reason ~= "not_owner" then
            lastReason = reason
        end
    end)
    return affected, affected > 0 and "commanded" or lastReason,
        affectedTargets, details
end

return true
