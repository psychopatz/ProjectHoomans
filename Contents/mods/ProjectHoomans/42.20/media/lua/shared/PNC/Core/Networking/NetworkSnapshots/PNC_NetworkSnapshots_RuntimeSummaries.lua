--[[
    PNC Network Snapshots - Runtime Summaries
    Serializes AI, combat, and short-lived feedback state.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
local Const = PNC.Const
local Equipment = PNC.Equipment

function Parts.BuildActionInformation(record)
    return PNC.WorkService and PNC.WorkService.BuildActionInformation
        and PNC.WorkService.BuildActionInformation(record) or nil
end

function Parts.ResolveAIState(record)
    local healthState = record.health and tostring(record.health.state or "normal") or "normal"
    local hasTarget = record.runtime and record.runtime.target ~= nil
    local inCombat = hasTarget
        or ((tonumber(record.runtime and record.runtime.inCombatUntil or 0) or 0) > Core.Now())
    if record.alive == false then
        return "Dead", false
    end
    if healthState == "incapacitated" then
        return "Downed", true
    end
    if record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        return "VehiclePassenger", false
    end
    if record.presenceState == Const.PRESENCE_ABSTRACT then
        return "Abstract", false
    end
    if inCombat then
        return "Combat", true
    end
    if record.activeBehavior and record.activeBehavior ~= "" then
        return tostring(record.activeBehavior), false
    end
    return "Idle", false
end

function Parts.BuildCombatSummary(record, equipmentInfo)
    local target = record.runtime and record.runtime.target or nil
    local tactical = record.runtime and record.runtime.combatTactical or {}
    local aim = record.runtime and record.runtime.combatAim or {}
    local fireLane = record.runtime and record.runtime.combatFireLane or {}
    equipmentInfo = equipmentInfo or Equipment and Equipment.Describe and Equipment.Describe(record) or {}
    return {
        targetKind = target and target.kind or "none",
        combatModeResolved = equipmentInfo.combatModeResolved or record.weaponMode,
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        combatBlockReason = record.runtime and record.runtime.combatBlockReason or nil,
        tacticalDecision = tactical.decision,
        pressureCount = tactical.pressure,
        visiblePressureCount = tactical.visiblePressure,
        hordeCount = tactical.horde,
        visibleHordeCount = tactical.visibleHorde,
        pressureTolerance = tactical.pressureTolerance,
        aimConfidence = aim.confidence,
        aimReadyAt = aim.readyAt,
        fireLaneSafe = fireLane.safe,
        fireLaneBlockerKind = fireLane.blockerKind,
    }
end

function Parts.BuildCommandFeedback(record)
    local runtime = record and record.runtime or nil
    local revision = tonumber(runtime and runtime.lastCompanionCommandRevision)
    if not runtime or not runtime.lastCompanionCommand or revision == nil then
        return false
    end
    if Core.Now() - (tonumber(runtime.lastCompanionCommandAt) or 0)
        > (tonumber(Const.COMPANION_COMMAND_FEEDBACK_MS) or 5000)
    then
        return false
    end
    return {
        id = tostring(runtime.lastCompanionCommand),
        revision = revision,
        issuedAt = tonumber(runtime.lastCompanionCommandAt) or 0,
        ownerUsername = runtime.lastCompanionCommandOwner,
    }
end

function Parts.BuildBandageFeedback(record)
    local runtime = record and record.runtime or nil
    local revision = tonumber(runtime and runtime.bandageCompletionRevision)
    local completedAt = tonumber(runtime and runtime.bandageCompletionAt) or 0
    if not runtime or revision == nil then return false end
    if Core.Now() - completedAt
        > (tonumber(Const.BANDAGE_COMPLETION_FEEDBACK_MS) or 5000)
    then
        return false
    end
    return {
        revision = revision,
        completedAt = completedAt,
        partId = runtime.bandageCompletionPartId,
        sound = tostring(
            Const.BANDAGE_COMPLETION_SOUND or "PNC_BandageComplete"
        ),
    }
end

return Parts
