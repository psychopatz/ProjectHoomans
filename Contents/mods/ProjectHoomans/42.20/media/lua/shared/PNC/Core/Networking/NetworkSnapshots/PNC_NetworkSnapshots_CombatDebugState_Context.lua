--[[
    PNC Network Snapshots - Combat Debug State Context
    Gathers the bounded state used by the combat diagnostics payload.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core

if not Parts.BuildCombatDebugTemporalState then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_Temporal"
end

if not Parts.BuildCombatDebugObservations then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugObservations"
end

local buildCombatDebugTemporalState = Parts.BuildCombatDebugTemporalState

function Parts.BuildCombatDebugContext(record, combat, firearmState)
    local runtime = record.runtime or {}
    local npcIdentity = Parts.BuildIdentitySummary(record)
    local target = runtime.target
    local tactical = runtime.combatTactical or {}
    local aim = runtime.combatAim or {}
    local fireLane = runtime.combatFireLane or {}
    local retreat = runtime.combatRetreat or {}
    local defense = runtime.combatDefense or {}
    local action = runtime.attackAction
    local now = Core.Now()
    local attackLane = runtime.zombieAttackLane
    local temporalState
    if type(buildCombatDebugTemporalState) == "function" then
        temporalState = buildCombatDebugTemporalState(
            record,
            runtime,
            now,
            npcIdentity
        )
    else
        temporalState = {}
    end
    local viewZombies, visibleZombieCount, nearbyZombieCount =
        Parts.BuildCombatDebugObservations(record, target)

    return {
        record = record,
        combat = combat,
        firearmState = firearmState,
        runtime = runtime,
        target = target,
        tactical = tactical,
        aim = aim,
        fireLane = fireLane,
        retreat = retreat,
        defense = defense,
        action = action,
        now = now,
        attackLane = attackLane,
        temporalState = temporalState,
        viewZombies = viewZombies,
        visibleZombieCount = visibleZombieCount,
        nearbyZombieCount = nearbyZombieCount,
    }
end

return Parts
