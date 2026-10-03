-- Group-camp application, coordinator integration, and compatibility fallback.
-- Validation, bounded details, and recipient admission are separate providers.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core
local OrderSystem = PNC.OrderSystem
local Network = PNC.Network
if type(Commands) ~= "table" then return false end

Commands.Internal = Commands.Internal or {}

local copyTable = Commands.Internal.CopyTable
local validateCampSite = Commands.Internal.ValidateCampSite
local campCommandDetails = Commands.Internal.CampCommandDetails
local collectGroupCampRecipients =
    Commands.Internal.CollectGroupCampRecipients

local function nextGroupCampID(player)
    local ownerKey
    local revision
    Commands.GroupCampRevision = (tonumber(Commands.GroupCampRevision) or 0) + 1
    revision = Commands.GroupCampRevision
    ownerKey = player and player.getOnlineID and player:getOnlineID()
    ownerKey = ownerKey ~= nil and tostring(ownerKey)
        or player and player.getUsername and player:getUsername()
        or "player"
    return "camp:group:" .. tostring(ownerKey) .. ":"
        .. tostring(Core.Now()) .. ":" .. tostring(revision)
end

function Commands.ApplyGroupCamp(player, commandContext)
    local definition = Commands.Get("camp")
    local allowed
    local reason
    local campID
    local campSite
    local recipients
    local directory
    local assignments
    local zoneService
    local coordinator
    local ownerKey
    local coordinated
    local coordinatedReason
    local coordinatedTargets
    local details
    local affected = 0
    local affectedTargets = {}
    if not Core.IsAuthority() then return 0, "not_authority", affectedTargets end
    if not definition then return 0, "unknown_command", affectedTargets end
    if not player or (player.isDead and player:isDead()) then
        return 0, "invalid_player", affectedTargets
    end
    if not player.getX or not player.getY or not player.getZ then
        return 0, "position_missing", affectedTargets
    end
    if Commands.CanCampAtPlayer then
        allowed, reason = Commands.CanCampAtPlayer(player)
        if not allowed then return 0, reason, affectedTargets end
    end
    campSite, reason = validateCampSite(nil, player, commandContext)
    if not campSite then return 0, reason, affectedTargets end
    campID = nextGroupCampID(player)
    recipients = collectGroupCampRecipients(player,
        tonumber(commandContext and commandContext.radius)
            or tonumber(Const.COMPANION_COMMAND_RADIUS) or 20,
        commandContext)
    if #recipients == 0 then
        return 0, "no_targets", affectedTargets
    end

    -- A group camp is one authoritative placement session. The coordinator
    -- installs the durable camp order for every accepted live recipient, but
    -- starts only one movement owner; the rest remain queued until the
    -- previous member arrives or fails. The first phase deliberately does
    -- not build the full room/need directory: root arrival must succeed
    -- before any adjacent-zone distribution work is admitted.
    coordinator = PNC.CampMovementCoordinator
    if coordinator and type(coordinator.StartGroupCamp) == "function" then
        ownerKey = "player"
        if player.getOnlineID then
            local onlineID = player:getOnlineID()
            if onlineID ~= nil then ownerKey = tostring(onlineID) end
        end
        if ownerKey == "player" and player.getUsername then
            local username = player:getUsername()
            if username ~= nil and tostring(username) ~= "" then
                ownerKey = tostring(username)
            end
        end
        local ok
        ok, coordinated, coordinatedReason, coordinatedTargets = pcall(
            coordinator.StartGroupCamp,
            campSite,
            recipients,
            directory,
            {
                campId = campID,
                ownerKey = ownerKey,
                player = player,
                now = Core.Now(),
            }
        )
        if ok then
            details = campCommandDetails(
                campID,
                campSite,
                recipients,
                "group_command",
                coordinated or 0
            )
            return coordinated or 0,
                coordinatedReason or "camp_coordinator_rejected",
                coordinatedTargets or affectedTargets,
                details
        end
        if Core.LogWarn then
            Core.LogWarn("group camp coordinator failed reason="
                .. tostring(coordinated))
        end
        return 0, "camp_coordinator_failed", affectedTargets
    end

    -- Compatibility fallback for builds without the coordinator. Keep the
    -- old bounded root-only directory here; normal coordinator builds never
    -- pay this scan during camp admission.
    zoneService = PNC.CampZoneService
    if zoneService and type(zoneService.BuildGroup) == "function" then
        local ok
        ok, directory = pcall(zoneService.BuildGroup, campSite, recipients, {
            campId = campID,
            player = player,
            commandContext = commandContext,
            rootOnly = true,
        })
        if not ok or type(directory) ~= "table" then directory = nil end
    end
    assignments = directory and directory.assignments or nil

    for index = 1, #recipients do
        local record = recipients[index]
        local orderSpec
        local assignment = assignments
            and assignments[tostring(record.id or "")] or nil
        local assignedSite = assignment and assignment.zone or campSite
        local options = copyTable(commandContext)
        if type(definition.buildOrder) == "function" then
            options.x = assignedSite and assignedSite.x or campSite.x
            options.y = assignedSite and assignedSite.y or campSite.y
            options.z = assignedSite and assignedSite.z or campSite.z
            options.campId = campID
            options.campSite = assignedSite
            options.campRoot = campSite
            options.zone = assignedSite
            options.zoneAssignment = assignment
            options.campDirectoryRevision = directory
                and directory.revision or nil
            orderSpec = definition.buildOrder(record, player, options)
        end
        if type(orderSpec) == "table" then
            OrderSystem.SetOrder(record, orderSpec)
            record.runtime = record.runtime or {}
            record.runtime.lastCompanionCommand = "camp"
            record.runtime.lastCompanionCommandAt = Core.Now()
            record.runtime.lastCompanionCommandRevision =
                (tonumber(record.runtime.lastCompanionCommandRevision) or 0) + 1
            record.runtime.lastCompanionCommandOwner = player.getUsername
                and tostring(player:getUsername() or "") or nil
            if assignment then
                record.runtime.campZoneAssignment = {
                    zoneID = assignment.zoneID,
                    zoneLabel = assignment.zoneLabel,
                    needKind = assignment.needKind,
                    reason = assignment.reason,
                    score = assignment.score,
                    revision = assignment.assignmentRevision,
                }
            else
                record.runtime.campZoneAssignment = nil
            end
            Network.BroadcastRecord(record, "companion_command_camp")
            affected = affected + 1
            affectedTargets[#affectedTargets + 1] = tostring(record.id)
        end
    end
    details = campCommandDetails(
        campID,
        campSite,
        recipients,
        "group_legacy",
        affected
    )
    return affected, affected > 0 and "commanded" or "no_targets",
        affectedTargets, details
end

return true
