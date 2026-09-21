-- Data-driven, authority-owned companion commands. Client adapters render the
-- same definitions in the emote radial and NPC context menu.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Network = PNC.Network
local Equipment = PNC.Equipment

Commands.Definitions = Commands.Definitions or {}
Commands.DefinitionOrder = Commands.DefinitionOrder or {}
Commands.Groups = Commands.Groups or {}
Commands.GroupOrder = Commands.GroupOrder or {}

local function appendDefinitionID(commandID)
    local i
    for i = 1, #Commands.DefinitionOrder do
        if Commands.DefinitionOrder[i] == commandID then return end
    end
    Commands.DefinitionOrder[#Commands.DefinitionOrder + 1] = commandID
end

function Commands.RegisterGroup(definition)
    local groupID
    if type(definition) ~= "table" then return false end
    groupID = tostring(definition.id or "")
    if groupID == "" then return false end
    definition.id = groupID
    Commands.Groups[groupID] = definition
    local i
    for i = 1, #Commands.GroupOrder do
        if Commands.GroupOrder[i] == groupID then return true end
    end
    Commands.GroupOrder[#Commands.GroupOrder + 1] = groupID
    return true
end

function Commands.GetGroup(groupID)
    return Commands.Groups[tostring(groupID or "")]
end

function Commands.ListGroups()
    local output = {}
    local i
    local definition
    for i = 1, #Commands.GroupOrder do
        definition = Commands.Groups[Commands.GroupOrder[i]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

function Commands.Register(definition)
    local commandID
    if type(definition) ~= "table" then return false end
    commandID = tostring(definition.id or "")
    if commandID == "" or (
        type(definition.buildOrder) ~= "function"
        and definition.attackType == nil
        and type(definition.apply) ~= "function"
        and definition.clientOnly ~= true
    ) then
        return false
    end
    definition.id = commandID
    Commands.Definitions[commandID] = definition
    appendDefinitionID(commandID)
    return true
end

function Commands.NormalizeAttackType(value)
    if PNC.Types and PNC.Types.NormalizeAttackType then
        return PNC.Types.NormalizeAttackType(value)
    end
    value = string.lower(tostring(value or "auto"))
    if value == "auto" or value == "melee"
        or value == "ranged" or value == "none"
    then
        return value
    end
    return "auto"
end

function Commands.GetCurrentAttackType(record)
    return Commands.NormalizeAttackType(record and record.attackType)
end

function Commands.IsCurrent(record, commandID)
    local definition = Commands.Get(commandID)
    if not definition or definition.attackType == nil then return false end
    return Commands.GetCurrentAttackType(record)
        == Commands.NormalizeAttackType(definition.attackType)
end

function Commands.GetAttackTypeDefinition(attackType)
    local normalized = Commands.NormalizeAttackType(attackType)
    local definitions = Commands.List()
    local i
    local definition
    for i = 1, #definitions do
        definition = definitions[i]
        if definition.attackType ~= nil
            and Commands.NormalizeAttackType(definition.attackType) == normalized
        then
            return definition
        end
    end
    return nil
end

function Commands.Get(commandID)
    return Commands.Definitions[tostring(commandID or "")]
end

-- Command-specific eligibility stays at the player-command authority
-- boundary. Faction behavior and other server-owned order producers call
-- OrderSystem directly and intentionally do not inherit player restrictions.
function Commands.CanApply(record, player, commandID)
    local definition = Commands.Get(commandID)
    local allowed
    local reason
    if not definition then return false, "unknown_command" end
    if type(definition.canApply) ~= "function" then
        return true, "commandable"
    end
    allowed, reason = definition.canApply(record, player)
    if allowed ~= true then
        return false, reason or "command_rejected"
    end
    return true, reason or "commandable"
end

function Commands.List()
    local output = {}
    local i
    local definition
    for i = 1, #Commands.DefinitionOrder do
        definition = Commands.Definitions[Commands.DefinitionOrder[i]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

function Commands.IsCompanion(record)
    if not record or record.alive == false then return false end
    if PNC.Identity and PNC.Identity.Verifier
        and PNC.Identity.Verifier.IsCompanion
    then
        return PNC.Identity.Verifier.IsCompanion(record)
    end
    return record.recruited == true
end

function Commands.IsOwnedByPlayer(record, player, ownershipContext)
    local organizationID
    local organization
    local uuid
    local playerKey
    if not record or not player then return false end
    if PNC.Identity and PNC.Identity.Verifier
        and PNC.Identity.Verifier.IsOwnedByPlayer
    then
        return PNC.Identity.Verifier.IsOwnedByPlayer(
            record, player, ownershipContext)
    end
    organizationID = record.affiliation
        and record.affiliation.factionID or nil
    organization = organizationID
        and PNC.Factions
        and PNC.Factions.Get
        and PNC.Factions.Get(organizationID)
        or nil
    if organization then
        if type(ownershipContext) == "table"
            and ownershipContext.unavailable == true
        then
            return false
        end
        if type(ownershipContext) == "table" then
            playerKey = ownershipContext.playerKey
                or ownershipContext.entityKey
        end
        uuid = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetCharacterUUID
            and not playerKey
            and PNC.PlayerCharacters.GetCharacterUUID(player)
            or nil
        if not playerKey then
            local context = PNC.PlayerContext and PNC.PlayerContext.Peek
                and PNC.PlayerContext.Peek(player) or nil
            local character = uuid and PNC.PlayerCharacters.Registry
                and PNC.PlayerCharacters.Registry.byUUID
                and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
            playerKey = context and context.entityKey
                or uuid and character and PNC.EntityRef
                    and PNC.EntityRef.ForPlayerIdentity(
                        character.accountKey or character.accountIdentity,
                        uuid
                    ) or nil
        end
        if playerKey then
            return organization.ownerPlayerKey == playerKey
                or organization.playerMemberKeys
                    and organization.playerMemberKeys[playerKey] == true
        end
        -- Organizational ownership is character-UUID scoped. If the stable
        -- key cannot be resolved, never fall back to account name or online
        -- ID and accidentally grant a replacement survivor authority.
        return false
    end
    return false
end

local function livePosition(record)
    local zombie = record and record.id and Registry.GetLiveZombie(record.id) or nil
    if zombie and (not zombie.isDead or not zombie:isDead()) then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    return tonumber(record and record.x),
        tonumber(record and record.y),
        tonumber(record and record.z)
end

local function copyTable(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, child in pairs(value) do output[key] = child end
    return output
end

-- CAMP diagnostics cross the network boundary, so keep them primitive and
-- bounded. In particular, never serialize live Java objects or an entire zone
-- directory just to explain why a member has not started walking yet.
local function detailText(value, maximum)
    local valueType = type(value)
    local result
    if value == nil then return nil end
    if valueType ~= "string" and valueType ~= "number"
        and valueType ~= "boolean"
    then
        return nil
    end
    result = tostring(value)
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function detailNumber(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function compactCampSite(site)
    local output
    local bounds
    if type(site) ~= "table" then return nil end
    output = {
        kind = detailText(site.kind, 32),
        scope = detailText(site.scope or site.siteScope, 32),
        siteID = detailText(site.siteID, 128),
        roomID = detailText(site.roomID, 128),
        buildingID = detailText(site.buildingID, 128),
        roomType = detailText(site.roomType, 48),
        roomName = detailText(site.roomName, 64),
        campfireID = detailText(site.campfireID, 128),
        label = detailText(site.label, 64),
        risk = detailText(site.risk, 32),
        x = detailNumber(site.x),
        y = detailNumber(site.y),
        z = detailNumber(site.z),
        radius = detailNumber(site.radius),
        resourceRadius = detailNumber(site.resourceRadius),
        stopDistance = detailNumber(site.stopDistance),
    }
    bounds = site.roomBounds
    if type(bounds) == "table" then
        output.roomBounds = {
            minX = detailNumber(bounds.minX or bounds.x),
            minY = detailNumber(bounds.minY or bounds.y),
            maxX = detailNumber(bounds.maxX or bounds.x2),
            maxY = detailNumber(bounds.maxY or bounds.y2),
            z = detailNumber(bounds.z),
        }
    end
    return output
end

local function campLeaseFor(record)
    local leases = PNC.TaskLeaseService
    local ok
    local lease
    if not leases or type(leases.ForNPC) ~= "function" then return nil end
    ok, lease = pcall(leases.ForNPC, record and record.id)
    return ok and type(lease) == "table" and lease or nil
end

local function campCommandDetails(campID, site, records, route,
    acceptedCount)
    local output = {
        version = 1,
        route = detailText(route, 32) or "command",
        campID = detailText(campID, 128),
        placementMode = "root_only",
        site = compactCampSite(site),
        targetCount = 0,
        acceptedCount = tonumber(acceptedCount) or 0,
        targets = {},
    }
    local maximum = math.min(type(records) == "table" and #records or 0, 32)
    for index = 1, maximum do
        local record = records[index]
        if record and record.id ~= nil then
            local runtime = record.runtime or {}
            local placement = runtime.campPlacement or {}
            local order = record.orderSpec or {}
            local lease = campLeaseFor(record)
            local activity = runtime.facilityActivity or {}
            local assignment = runtime.campZoneAssignment or {}
            local state = detailText(placement.state, 24)
                or detailText(order.placementState, 24)
                or "arrived"
            local target = {
                npcID = detailText(record.id, 128),
                state = state,
                reason = detailText(placement.reason, 64)
                    or detailText(order.zoneReason, 64),
                orderKind = detailText(order.kind, 32),
                activeJob = detailText(record.activeJob, 64),
                activeBehavior = detailText(record.activeBehavior, 96),
                taskLeaseID = detailText(lease and lease.leaseId, 128)
                    or detailText(activity.taskLeaseId, 128),
                leaseDomain = detailText(lease and lease.sourceDomain, 48),
                leasePhase = detailText(lease and lease.phase, 32),
                facilityCapability = detailText(activity.capability, 48),
                facilityPhase = detailText(activity.phase, 32),
                sleepWakePending = activity.sleepWakePending == true,
                zoneID = detailText(assignment.zoneID or order.zoneID, 128),
                zoneLabel = detailText(
                    assignment.zoneLabel or order.zoneLabel, 64),
                zoneNeedKind = detailText(
                    assignment.needKind or order.zoneNeedKind, 32),
            }
            output.targets[#output.targets + 1] = target
            output.targetCount = output.targetCount + 1
            if output.placementState == nil then
                output.placementState = state
            end
            if state == "moving" and output.activeNPCID == nil then
                output.activeNPCID = target.npcID
            end
        end
    end
    return output
end

local function campValidationOrigin(record, player)
    local zombie = record and record.id and Registry.GetLiveZombie(record.id)
        or nil
    -- Player-issued "here" commands use the same origin as the client hint
    -- search. The companion's live body is still passed separately for world
    -- validation, but must not move the requested camp location.
    return player or record, zombie
end

local function validateCampSite(record, player, commandContext)
    local resolver = PNC.Semantics
        and PNC.Semantics.CampSiteResolver or nil
    local hint = commandContext and commandContext.campSiteHint
    local origin
    local body
    local validationContext
    local target
    if not resolver or type(resolver.ValidateClientSite) ~= "function" then
        return nil, "camp_site_validation_unavailable"
    end
    if type(hint) ~= "table" then return nil, "camp_site_hint_required" end
    origin, body = campValidationOrigin(record, player)
    validationContext = {
        selectionOrigin = origin,
        origin = origin,
        body = body,
        record = record,
        player = player,
        npcID = record and record.id or nil,
        requestID = commandContext and commandContext.requestID or nil,
    }
    target = {
        kind = "camp_site",
        scope = "here",
        clientHint = hint,
        -- commandContext.radius is the companion-command eligibility radius
        -- (normally 20), not the camp-site discovery radius. Keep site
        -- validation aligned with the client loaded-cell search limit.
        radius = tonumber(commandContext and commandContext.campSiteRadius)
            or tonumber(resolver.DEFAULT_RADIUS) or 32,
    }
    return resolver.ValidateClientSite(target, validationContext)
end

local function isOwnedCompanion(record, player)
    -- Group CAMP is a command to nearby owned companions, not a command
    -- restricted to records whose previous order happened to be FOLLOW.
    -- CAMP replaces that previous order, so checking it here made the
    -- server reject valid nearby companions that were guarding, roaming, or
    -- already finishing another compatible order.
    if not record or not player then
        return false
    end
    if not Commands.IsCompanion(record)
        or not Commands.IsOwnedByPlayer(record, player)
    then
        return false
    end
    -- Do not duplicate the ownership identity fields here. The authoritative
    -- verifier supports the current organization/character ownership model;
    -- requiring legacy order owner fields would reject valid companions even
    -- after the verifier has accepted them.
    return true
end

-- A logical LIVE record is not enough for this command. Group camp is a
-- nearby, materialized-world action: an abstract record has no body that can
-- walk to its assigned room and must remain outside this assignment pass.
local function materializedLive(record)
    local body
    if not record or record.alive == false
        or tostring(record.presenceState or Const.PRESENCE_LIVE)
            ~= tostring(Const.PRESENCE_LIVE)
    then
        return false
    end
    body = record.id and Registry
        and type(Registry.GetLiveZombie) == "function"
        and Registry.GetLiveZombie(record.id) or nil
    if not body
        or type(body.getX) ~= "function"
        or type(body.getY) ~= "function"
        or type(body.getZ) ~= "function"
    then
        return false
    end
    if body.isDead and body:isDead() then return false end
    return true, body
end

local function requestedTargetIDs(commandContext)
    local values = commandContext and commandContext.targetIDs
    local output
    local seen
    local value
    local id
    local maximum
    if type(values) ~= "table" then return nil, false end
    output = {}
    seen = {}
    maximum = math.min(#values, 32)
    for index = 1, maximum do
        value = values[index]
        id = type(value) == "table" and value.id or value
        if id ~= nil and tostring(id) ~= "" then
            id = tostring(id)
            if not seen[id] then
                seen[id] = true
                output[#output + 1] = id
            end
        end
    end
    return output, true
end

local function collectGroupCampRecipients(player, radius, commandContext)
    local requested
    local explicit
    local output = {}
    local seen = {}

    requested, explicit = requestedTargetIDs(commandContext)

    local function consider(record)
        local live
        local allowed
        local id = record and record.id and tostring(record.id) or ""
        if id == "" or seen[id] or not isOwnedCompanion(record, player)
        then
            return
        end
        allowed, live = materializedLive(record)
        if not allowed or not live then return end
        allowed = Commands.CanPlayerCommand(record, player, radius)
        if allowed ~= true then return end
        seen[id] = true
        output[#output + 1] = record
    end

    if explicit then
        for index = 1, #requested do
            consider(Registry.Get(requested[index]))
        end
    elseif Registry.ForEach then
        -- Compatibility for server-owned callers and older clients that do
        -- not yet send the nearby candidate list. The same live/radius gate
        -- still applies, so this fallback cannot revive the old distant or
        -- abstract group-camp behavior.
        Registry.ForEach(consider)
    end
    table.sort(output, function(left, right)
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return output, explicit
end

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

function Commands.CanPlayerCommand(record, player, radius)
    local x
    local y
    local z
    if not player or (player.isDead and player:isDead()) then
        return false, "invalid_player"
    end
    if not Commands.IsCompanion(record) then
        return false, "not_companion"
    end
    if not Commands.IsOwnedByPlayer(record, player) then
        return false, "not_owner"
    end
    if tostring(record.presenceState or Const.PRESENCE_LIVE)
        ~= tostring(Const.PRESENCE_LIVE)
    then
        return false, "not_live"
    end
    x, y, z = livePosition(record)
    if x == nil or y == nil or z == nil then
        return false, "position_missing"
    end
    if math.floor(tonumber(player:getZ()) or 0) ~= math.floor(z) then
        return false, "different_floor"
    end
    radius = math.max(
        1,
        math.min(
            tonumber(Const.COMPANION_COMMAND_RADIUS) or 20,
            tonumber(radius) or tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
        )
    )
    if Core.DistanceSq(player:getX(), player:getY(), x, y) > radius * radius then
        return false, "too_far"
    end
    return true, "commandable"
end

local function refreshEquipmentState(record)
    local equipmentInfo
    if not Equipment or not Equipment.Describe then return end
    equipmentInfo = Equipment.Describe(record)
    record.runtime = record.runtime or {}
    record.runtime.combatModeResolved = equipmentInfo.combatModeResolved
    record.runtime.weaponStatus = equipmentInfo.weaponStatus
end

local function applyAttackType(record, definition)
    local attackType = Commands.NormalizeAttackType(definition.attackType)
    local zombie
    if definition.attackType == nil then return false end
    record.attackType = attackType
    if attackType == (Const.ATTACK_TYPE_AUTO or "auto") then
        record.weaponMode = "mixed"
    elseif attackType == (Const.ATTACK_TYPE_MELEE or "melee") then
        record.weaponMode = "melee"
    elseif attackType == (Const.ATTACK_TYPE_RANGED or "ranged") then
        record.weaponMode = "ranged"
    end
    if attackType == (Const.ATTACK_TYPE_NONE or "none") then
        zombie = record.id and Registry.GetLiveZombie(record.id) or nil
        if PNC.Combat and PNC.Combat.Internal
            and PNC.Combat.Internal.finishAttackAction
        then
            PNC.Combat.Internal.finishAttackAction(record, zombie)
        elseif record.runtime then
            record.runtime.attackAction = nil
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.ClearCombatTarget then
            PNC.BehaviorCommon.ClearCombatTarget(
                record,
                "attack_type_none",
                zombie
            )
        end
    end
    refreshEquipmentState(record)
    if attackType == (Const.ATTACK_TYPE_NONE or "none") then
        record.runtime = record.runtime or {}
        record.runtime.combatModeResolved = "none"
        record.runtime.weaponStatus = "holstered"
        record.runtime.combatBlockReason = "attack_type_none"
    end
    Registry.MarkDirty(record, "equipment")
    Registry.MarkDirty(record, "combat")
    return true
end

local function prepareFollowOrder(record)
    if not record then return false, "npc_not_found" end
    local runtime = record.runtime
    local workOrderId = runtime and runtime.workOrderId or nil
    if workOrderId then
        local work = PNC.WorkService
        local order = work and work.Queries
            and type(work.Queries.Get) == "function"
            and work.Queries.Get(workOrderId) or nil
        local operation = tostring(order and order.operation or "")
        if not order or (operation ~= "PROVISION_PICKUP"
            and operation ~= "CORPSE_HAUL")
        then
            return false, "WORK_ORDER_IN_PROGRESS"
        end
        if not work.Commands
            or type(work.Commands.Cancel) ~= "function"
        then
            return false, "WORK_ORDER_IN_PROGRESS"
        end
        local cancelled, cancelResult = work.Commands.Cancel(
            order.id, "companion_follow_requested")
        if not cancelled then
            return false, cancelResult or "WORK_ORDER_CANCELLATION_FAILED"
        end
        if cancelResult == "CANCELLATION_DEFERRED" then
            return false, "WORK_ORDER_CANCELLING"
        end
    end

    local travel = PNC.Travel
    if travel and travel.Service and travel.Model
        and type(travel.Service.Cancel) == "function"
        and type(travel.Model.IsActive) == "function"
        and travel.Model.IsActive(record.travel)
    then
        local cancelled, cancelReason = travel.Service.Cancel(
            record, "companion_follow_requested")
        if cancelled == false and cancelReason ~= "journey_inactive" then
            return false, cancelReason or "TRAVEL_CANCELLATION_FAILED"
        end
    end

    record.runtime = record.runtime or {}
    record.runtime.homeState = "AWAY"
    record.runtime.homeJourneyId = nil
    return true
end

function Commands.Apply(record, player, commandID, radius, commandContext)
    local definition = Commands.Get(commandID)
    local allowed
    local reason
    local orderSpec
    local orderOptions = commandContext
    local campSite
    local details
    if not Core.IsAuthority() then return false, "not_authority" end
    if not definition then return false, "unknown_command" end
    if definition.clientOnly == true then
        return false, "client_action_required"
    end
    allowed, reason = Commands.CanPlayerCommand(record, player, radius)
    if not allowed then return false, reason end
    allowed, reason = Commands.CanApply(record, player, commandID)
    if not allowed then return false, reason end
    if tostring(commandID or "") == "camp" then
        campSite, reason = validateCampSite(record, player, commandContext)
        if not campSite then return false, reason end
        orderOptions = copyTable(commandContext)
        orderOptions.campSite = campSite
    end
    if type(definition.buildOrder) == "function" then
        orderSpec = definition.buildOrder(record, player, orderOptions)
        if type(orderSpec) ~= "table" then return false, "invalid_order" end
        if tostring(orderSpec.kind or "")
            == tostring(Const.ORDER_FOLLOW or "follow")
        then
            local prepared, prepareReason = prepareFollowOrder(record)
            if not prepared then
                return false, prepareReason or "FOLLOW_PREPARATION_FAILED"
            end
        end
        OrderSystem.SetOrder(record, orderSpec)
    end
    applyAttackType(record, definition)
    if type(definition.apply) == "function" then
        local applied
        local applyReason
        applied, applyReason = definition.apply(record, player, commandContext)
        if applied == false then
            return false, applyReason or "command_rejected"
        end
    end
    record.runtime = record.runtime or {}
    record.runtime.lastCompanionCommand = tostring(definition.id)
    record.runtime.lastCompanionCommandAt = Core.Now()
    record.runtime.lastCompanionCommandRevision =
        (tonumber(record.runtime.lastCompanionCommandRevision) or 0) + 1
    record.runtime.lastCompanionCommandOwner = player.getUsername
        and tostring(player:getUsername() or "") or nil
    Network.BroadcastRecord(
        record,
        "companion_command_" .. tostring(definition.id)
    )
    if tostring(commandID or "") == "camp" then
        details = campCommandDetails(
            orderSpec and orderSpec.campId,
            campSite,
            { record },
            "single_command",
            1
        )
    end
    return true, "commanded", details
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
            local ok, onlineID = pcall(player.getOnlineID, player)
            if ok and onlineID ~= nil then ownerKey = tostring(onlineID) end
        end
        if ownerKey == "player" and player.getUsername then
            local ok, username = pcall(player.getUsername, player)
            if ok and username ~= nil and tostring(username) ~= "" then
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
    if scope == "group" and definition.attackType ~= nil then
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
            x, y, z = livePosition(record)
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
            affectedTargets[1] = tostring(closestRecord.id)
        end
        return applied and 1 or 0, reason, affectedTargets, details
    end
    if targetID ~= nil then
        applied, reason, details = Commands.Apply(
            Registry.Get(targetID),
            player,
            commandID,
            radius,
            args
        )
        if applied then affectedTargets[1] = tostring(targetID) end
        return applied and 1 or 0, reason, affectedTargets, details
    end
    if definition.attackType ~= nil then
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

return Commands
