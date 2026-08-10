local Resolution = PNC.CombatResolution
local Core = PNC.Core

function Resolution.ApplyNPCDamage(targetRecord, targetBody, hit)
    local wounds = PNC.NPCWounds
    local network = PNC.Network
    local relationships = PNC.Relationships
    local applied
    local result
    if not targetRecord or not wounds or not wounds.ApplyCombatDamage then
        return false, "invalid_npc_target"
    end
    applied, result = wounds.ApplyCombatDamage(targetRecord, targetBody, hit)
    if not applied then return false, "npc_damage_rejected", result end
    if hit and hit.attackerKind == "npc"
        and hit.attackerID
        and PNC.Factions
        and PNC.Factions.OnNPCAggression
    then
        local attackerRecord = PNC.Registry
            and PNC.Registry.Get
            and PNC.Registry.Get(hit.attackerID) or nil
        local at = getGameTime and getGameTime()
            and getGameTime().getWorldAgeHours
            and getGameTime():getWorldAgeHours() or 0
        if attackerRecord then
            PNC.Factions.OnNPCAggression(
                attackerRecord,
                targetRecord,
                at,
                {
                    killed = targetRecord.alive == false,
                    severe = hit and (
                        tonumber(hit.amount) or 0
                    ) >= (
                        PNC.FactionBalance
                        and PNC.FactionBalance.Get(
                            "severeAttackDamageThreshold"
                        ) or 25
                    ),
                    damage = hit and tonumber(hit.amount) or 0,
                    callback = "npc_damage",
                }
            )
        end
    end
    if hit and hit.attackerKind == "player"
        and relationships and relationships.ProvokeNeutralByPlayer
    then
        relationships.ProvokeNeutralByPlayer(targetRecord)
    end
    targetRecord.runtime = targetRecord.runtime or {}
    targetRecord.runtime.forceSyncEvent = nil
    if network then
        if targetRecord.alive == false and network.BroadcastRemoval then
            network.BroadcastRemoval(targetRecord.id, "death")
            targetRecord.lastSyncAt = targetRecord.presenceRevision
        elseif network.BroadcastRecord then
            network.BroadcastRecord(targetRecord, "combat_damage")
            targetRecord.lastSyncAt = Core and Core.Now and Core.Now() or targetRecord.lastSyncAt
        end
    end
    return true, "hit_npc", result
end

return Resolution
