local Resolution = PNC.CombatResolution
local Core = PNC.Core

local function sameID(left, right)
    return left ~= nil
        and right ~= nil
        and tostring(left) == tostring(right)
end

local function bodyState(body)
    local ok
    local dead
    if not body then
        return "missing"
    end
    if not body.isDead then
        return "unknown"
    end
    ok, dead = pcall(body.isDead, body)
    if not ok then
        return "unknown"
    end
    return dead == true and "dead" or "live"
end

local function attachTargetState(detail, targetRecord, targetBody)
    if type(detail) ~= "table" then
        detail = {
            outcome = tostring(detail or "damage_rejected"),
        }
    end
    if detail.targetBodyState == nil then
        detail.targetBodyState = bodyState(targetBody)
    end
    if detail.healthState == nil then
        detail.healthState = targetRecord and targetRecord.health
            and tostring(targetRecord.health.state or "") or ""
    end
    if detail.healthCurrent == nil then
        detail.healthCurrent = targetRecord and targetRecord.health
            and tonumber(targetRecord.health.current) or nil
    end
    if detail.healthMax == nil then
        detail.healthMax = targetRecord and targetRecord.health
            and tonumber(targetRecord.health.max) or nil
    end
    if detail.targetAlive == nil then
        detail.targetAlive = targetRecord
            and targetRecord.alive ~= false or false
    end
    return detail
end

local function resolveOwnerDefense(attackerRecord, targetRecord, hit)
    local perception = PNC.Perception
    local radius
    local alert
    if not hit
        or hit.groupAlert ~= true
        or hit.ownerDefense ~= true
    then
        return false, "not_owner_defense_alert"
    end
    if not attackerRecord
        or not perception
        or type(perception.FindNPCGroupAlert) ~= "function"
    then
        return false, "alert_service_unavailable"
    end
    radius = tonumber(hit.alertRadius)
        or PNC.Const and tonumber(PNC.Const.NPC_GROUP_ALERT_RADIUS)
        or 8
    alert = perception.FindNPCGroupAlert(attackerRecord, radius, true)
    if not alert then
        return false, "alert_missing_or_expired"
    end
    if alert.groupAlert ~= true or alert.ownerDefense ~= true then
        return false, "alert_not_owner_defense"
    end
    if alert.alertOnly == true then
        return false, "alert_not_actionable"
    end
    if not sameID(alert.id, targetRecord and targetRecord.id) then
        return false, "alert_target_mismatch"
    end
    if hit.alertSequence == nil
        or alert.alertSequence == nil
        or tostring(hit.alertSequence) ~= tostring(alert.alertSequence)
    then
        return false, "alert_sequence_mismatch"
    end
    return true, "owner_defense_alert"
end

function Resolution.ApplyNPCDamage(targetRecord, targetBody, hit)
    local wounds = PNC.NPCWounds
    local network = PNC.Network
    local relationships = PNC.Relationships
    local attackerRecord
    local applied
    local result
    local relationOk
    local enemy
    local ownerDefenseAllowed
    local ownerDefenseReason
    if not targetRecord or not wounds or not wounds.ApplyCombatDamage then
        return false, "invalid_npc_target", attachTargetState({
            outcome = "invalid_npc_target",
            reason = not targetRecord
                and "missing_target_record"
                or "wound_service_unavailable",
        }, targetRecord, targetBody)
    end
    if hit and hit.attackerKind == "npc" and hit.attackerID
        and PNC.Registry and PNC.Registry.Get
        and relationships and relationships.AreNPCsEnemies
    then
        attackerRecord = PNC.Registry.Get(hit.attackerID)
        if attackerRecord then
            relationOk, enemy = pcall(
                relationships.AreNPCsEnemies,
                attackerRecord,
                targetRecord
            )
            if not relationOk or enemy ~= true then
                ownerDefenseAllowed, ownerDefenseReason =
                    resolveOwnerDefense(attackerRecord, targetRecord, hit)
            end
            if (not relationOk or enemy ~= true)
                and hit.immediateSelfDefense ~= true
                and ownerDefenseAllowed ~= true
            then
                return false, "npc_target_not_allowed", attachTargetState({
                    outcome = "authorization_rejected",
                    reason = "npc_target_not_allowed",
                    relationOk = relationOk == true,
                    enemy = enemy == true,
                    immediateSelfDefense = hit.immediateSelfDefense == true,
                    groupAlert = hit.groupAlert == true,
                    ownerDefense = hit.ownerDefense == true,
                    ownerDefenseReason = ownerDefenseReason,
                }, targetRecord, targetBody)
            end
        end
    end
    if attackerRecord
        and hit
        and hit.attackerKind == "npc"
        and PNC.Perception
        and PNC.Perception.PublishNPCGroupAlert
    then
        PNC.Perception.PublishNPCGroupAlert(
            attackerRecord,
            {
                kind = "npc",
                id = targetRecord.id,
                x = targetRecord.x,
                y = targetRecord.y,
                z = targetRecord.z,
            },
            Core and Core.Now and Core.Now() or 0
        )
    end
    applied, result = wounds.ApplyCombatDamage(targetRecord, targetBody, hit)
    result = attachTargetState(result, targetRecord, targetBody)
    if not applied then
        return false, "npc_damage_rejected", result
    end
    if hit and hit.attackerKind == "npc"
        and hit.attackerID
        and PNC.SocialEventHooksInternal
        and PNC.SocialEventHooksInternal.RecordNPCDamagedByNPC
    then
        pcall(
            PNC.SocialEventHooksInternal.RecordNPCDamagedByNPC,
            targetRecord,
            targetBody,
            PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(hit.attackerID) or nil,
            hit
        )
    end
    if hit and hit.attackerKind == "npc"
        and hit.attackerID
        and PNC.Factions
        and PNC.Factions.OnNPCAggression
    then
        attackerRecord = PNC.Registry
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
    if network then
        if targetRecord.alive == false and network.BroadcastRemoval then
            targetRecord.runtime.forceSyncEvent = nil
            network.BroadcastRemoval(targetRecord.id, "death")
            targetRecord.lastSyncAt = targetRecord.presenceRevision
        elseif targetRecord.runtime.forceSyncEvent == nil then
            -- Damage is committed locally immediately, but the full snapshot
            -- is flushed by the server record loop.  Several combat systems
            -- can touch the same target in one tick; coalescing here keeps
            -- each hit from rebuilding and broadcasting a separate payload.
            -- The existing force-sync event still carries the updated health.
            targetRecord.runtime.forceSyncEvent = "combat_damage"
        end
    end
    return true, "hit_npc", result
end

return Resolution
