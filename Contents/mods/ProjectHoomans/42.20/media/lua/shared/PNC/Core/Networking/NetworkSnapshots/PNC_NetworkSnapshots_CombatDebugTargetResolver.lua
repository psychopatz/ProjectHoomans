-- Combat-debug target adapter.
-- Converts engine and aggro-lease targets into the normalized target fields
-- consumed by the observation payload without owning observation iteration.

local Network = PNC.Network
local Internal = Network.Internal
local Parts = Internal.SnapshotParts
local H = Internal.CombatDebugTarget
if not H then return Network end

local Core = H.Core
local Registry = H.Registry

function Parts.ResolveCombatDebugTarget(zombie, modData)
    local engineTarget
    local targetRecord
    local targetKind
    local targetId
    local targetName
    local targetSource
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
    return targetKind, targetId, targetName, targetSource
end

return Network
