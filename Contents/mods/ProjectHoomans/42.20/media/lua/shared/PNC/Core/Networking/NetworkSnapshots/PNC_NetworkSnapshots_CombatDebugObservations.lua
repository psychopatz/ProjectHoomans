--[[
    PNC Network Snapshots - Combat Debug Observations
    Collects engine-facing zombie observations for combat diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
local Const = PNC.Const
local Perception = PNC.Perception
local Registry = PNC.Registry

function Parts.BuildCombatDebugObservations(record, target)
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
    local engineTarget
    local targetRecord
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
            targetKind = nil
            targetId = nil
            targetName = nil
            targetSource = nil
            if modData
                and modData.PNC_AggroNPCId ~= nil
                and Core.Now() < (
                    tonumber(modData.PNC_AggroNPCUntil) or 0
                )
            then
                targetKind = "npc"
                targetId = modData.PNC_AggroNPCId
                targetSource = "aggro_lease"
                targetRecord = Registry and Registry.Get
                    and Registry.Get(targetId) or nil
                targetName = targetRecord and (
                    targetRecord.displayName or targetRecord.name
                ) or nil
            else
                engineTarget = zombie.getTarget
                    and zombie:getTarget() or nil
                if engineTarget
                    and Core.IsManagedNPCBody
                    and Core.IsManagedNPCBody(engineTarget)
                then
                    targetKind = "npc"
                    targetSource = "engine"
                    targetRecord = Registry
                        and Registry.FindRecordByZombie
                        and Registry.FindRecordByZombie(engineTarget)
                        or nil
                    targetId = targetRecord and targetRecord.id or nil
                    targetName = targetRecord and (
                        targetRecord.displayName or targetRecord.name
                    ) or nil
                elseif engineTarget and instanceof
                    and instanceof(engineTarget, "IsoPlayer")
                then
                    targetKind = "player"
                    targetSource = "engine"
                    targetId = engineTarget.getOnlineID
                        and engineTarget:getOnlineID() or nil
                    targetName = engineTarget.getUsername
                        and engineTarget:getUsername() or nil
                end
            end
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
    return output, #entries, frame and nearbyCount or #entries
end

return Parts
