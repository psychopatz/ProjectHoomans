-- Single-record command application and gameplay-side effects.
-- Registry, authority, group-camp, and protocol execution stay in separate
-- providers around this application boundary.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Network = PNC.Network
local Equipment = PNC.Equipment
if type(Commands) ~= "table" then return false end

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

local function prepareFollowOrder(record, player)
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

    -- A stationary facility lease (sleep or a seat) owns the body: MoveRecord
    -- resolves it ahead of any movement and halts the request with
    -- sleep_hold/seated_hold. The order system's facility abort is the
    -- authoritative release; stop it here first as a best effort so the follow
    -- order is not installed behind a presentation that is on its way out.
    local activity = record.runtime.facilityActivity
    if activity
        and (tostring(activity.capability or "") == "sleep"
            or activity.seating == true)
    then
        local jobs = PNC.FacilityJobs
        if jobs and type(jobs.Stop) == "function" then
            jobs.Stop(record, "companion_follow_requested")
        end
        -- If a stationary lease survived the stop, the follower's movement
        -- request will be refused by the presentation guard. Report it here
        -- instead of installing a follow order that cannot move.
        local remaining = record.runtime and record.runtime.facilityActivity
        if remaining
            and (tostring(remaining.capability or "") == "sleep"
                or remaining.seating == true)
            and PNC.Core and PNC.Core.LogWarn
        then
            PNC.Core.LogWarn(
                "follow_hold_lease_present npc=" .. tostring(record.id)
                    .. " capability=" .. tostring(remaining.capability)
                    .. " phase=" .. tostring(remaining.phase)
            )
        end
    end

    -- Resolve the owner identity at command time. The abstract follower lane can
    -- only repair a missing record field from the order, so both copies must
    -- exist before the order is normalized.
    if player then
        local username = player.getUsername and player:getUsername() or nil
        local onlineID = player.getOnlineID and player:getOnlineID() or nil
        if username ~= nil and tostring(username) ~= "" then
            record.ownerUsername = tostring(username)
        end
        if onlineID ~= nil then
            record.ownerOnlineID = onlineID
        end
    end
    if record.ownerUsername == nil and record.ownerOnlineID == nil
        and PNC.Core and PNC.Core.LogWarn
    then
        -- Without an identity the bodyless follower can only retry resolution
        -- and then walk to its anchor, which for a colonist is the base it may
        -- already occupy. Surface the impossible state instead of freezing.
        PNC.Core.LogWarn(
            "follow_owner_identity_missing npc=" .. tostring(record.id))
    end

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
    local relayedViaRadio = false
    if not Core.IsAuthority() then return false, "not_authority" end
    if not definition then return false, "unknown_command" end
    if definition.clientOnly == true then
        return false, "client_action_required"
    end
    allowed, reason = Commands.CanPlayerCommand(record, player, radius)
    if not allowed then
        -- Out of earshot is not the same as out of contact: a relay-eligible
        -- command may still be accepted over the radio. When the relay path
        -- itself is unavailable the original proximity reason is kept, because
        -- "relay is missing" explains nothing about why the order failed.
        local directReason = reason
        local relayed, relayReason = Commands.CanRelayCommand(
            record, player, definition)
        if relayed ~= true then
            if relayReason == "relay_unavailable"
                or relayReason == "relay_not_allowed"
            then
                return false, directReason
            end
            return false, relayReason or directReason
        end
        reason = relayReason
        relayedViaRadio = relayReason == (PNC.CommandRelayGate
            and PNC.CommandRelayGate.RELAY or "radio_relay")
    end
    allowed, reason = Commands.CanApply(record, player, commandID)
    if not allowed then return false, reason end
    if tostring(commandID or "") == "camp" then
        campSite, reason = Commands.Internal.ValidateCampSite(
            record, player, commandContext)
        if not campSite then return false, reason end
        orderOptions = Commands.Internal.CopyTable(commandContext)
        orderOptions.campSite = campSite
    end
    if type(definition.buildOrder) == "function" then
        orderSpec = definition.buildOrder(record, player, orderOptions)
        if type(orderSpec) ~= "table" then return false, "invalid_order" end
        if tostring(orderSpec.kind or "")
            == tostring(Const.ORDER_FOLLOW or "follow")
        then
            local prepared, prepareReason = prepareFollowOrder(
                record, player)
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
    record.runtime.lastCompanionCommandRelay = relayedViaRadio == true
    Network.BroadcastRecord(
        record,
        "companion_command_" .. tostring(definition.id)
    )
    if tostring(commandID or "") == "camp" then
        details = Commands.Internal.CampCommandDetails(
            orderSpec and orderSpec.campId,
            campSite,
            { record },
            "single_command",
            1
        )
    end
    return true, "commanded", details
end

return true
