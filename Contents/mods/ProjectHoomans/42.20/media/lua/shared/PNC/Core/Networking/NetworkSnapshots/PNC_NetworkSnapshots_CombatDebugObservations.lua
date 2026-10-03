--[[
    PNC Network Snapshots - Combat Debug Observations
    Collects engine-facing zombie observations for combat diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Const = PNC.Const
local Perception = PNC.Perception
local Diagnostics = PNC.PerformanceScalingDiagnostics
if not Parts.ResolveCombatDebugTarget then
    Network.Internal.CombatDebugTarget = Network.Internal.CombatDebugTarget
        or {
            Core = PNC.Core,
            Registry = PNC.Registry,
        }
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugTargetResolver"
end
local ResolveCombatDebugTarget = Parts.ResolveCombatDebugTarget

function Parts.BuildCombatDebugObservations(record, target)
    local timingName
    local timingStart
    if Diagnostics and Diagnostics.BeginTiming then
        timingName, timingStart = Diagnostics.BeginTiming(
            "Network.Snapshot.Part.CombatDebugObservations"
        )
    end
    local radius = tonumber(Const.COMBAT_DEBUG_CONE_RADIUS) or 8.5
    local limit = math.max(
        1,
        math.floor(
            tonumber(Const.COMBAT_DEBUG_VISIBLE_ZOMBIE_LIMIT) or 6
        )
    )
    local frame = Perception
        and Perception.GetZombieFrame
        and Perception.GetZombieFrame(record, radius)
        or nil
    local entries = Perception
        and Perception.GetVisibleZombieEntries
        and Perception.GetVisibleZombieEntries(record, radius)
        or {}
    local output = {}
    local nearbyCount = 0
    local radiusSq = radius * radius
    local targetID = target and tostring(
        target.zombieId or target.id or ""
    ) or ""
    local i
    local entry
    local zombie
    local modData
    local zombieID
    local actionState
    local bumpType
    local intent
    local targetKind
    local targetId
    local targetName
    local targetSource
    if frame and type(frame.entries) == "table" then
        for i = 1, #frame.entries do
            if (tonumber(frame.entries[i].distSq) or math.huge)
                <= radiusSq
            then
                nearbyCount = nearbyCount + 1
            else
                break
            end
        end
    end
    for i = 1, math.min(#entries, limit) do
        entry = entries[i]
        zombie = entry and entry.zombie or nil
        if zombie then
            modData = zombie.getModData
                and zombie:getModData() or nil
            zombieID = modData and modData.PNC_ZombieID or nil
            if zombieID == nil and zombie.getOnlineID then
                zombieID = zombie:getOnlineID()
            end
            actionState = zombie.getActionStateName
                and tostring(zombie:getActionStateName() or "")
                or ""
            bumpType = zombie.getBumpType
                and tostring(zombie:getBumpType() or "")
                or ""
            targetKind, targetId, targetName, targetSource =
                ResolveCombatDebugTarget(zombie, modData)
            if targetID ~= ""
                and tostring(zombieID or "") == targetID
            then
                intent = "selected"
            elseif string.lower(actionState) == "bumped"
                and (
                    bumpType == "Bite"
                    or bumpType == "BiteLow"
                )
            then
                intent = "biting"
            elseif zombie.getPath2 and zombie:getPath2() ~= nil then
                intent = "pursuing"
            else
                intent = "visible"
            end
            output[#output + 1] = {
                id = zombieID,
                x = zombie:getX(),
                y = zombie:getY(),
                z = zombie:getZ(),
                distSq = entry.distSq,
                visibilityKind = entry.visibilityKind,
                actionState = actionState,
                bumpType = bumpType,
                intent = intent,
                targetKind = targetKind,
                targetId = targetId,
                targetName = targetName,
                targetSource = targetSource,
            }
        end
    end
    if Diagnostics and Diagnostics.EndTiming then
        Diagnostics.EndTiming(timingName, timingStart)
    end
    return output, #entries, frame and nearbyCount or #entries
end

return Parts
