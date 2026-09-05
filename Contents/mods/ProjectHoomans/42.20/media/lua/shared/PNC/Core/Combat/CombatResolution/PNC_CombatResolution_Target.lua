local Resolution = PNC.CombatResolution
local Core = PNC.Core

function Resolution.ApplyTargetDamage(attackerRecord, attackerBody, target, options)
    local registry = PNC.Registry
    local hit
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    if attackerRecord
        and (attackerRecord.alive == false
            or attackerRecord.health
                and attackerRecord.health.state == "dead"
            or PNC.Const
                and attackerRecord.presenceState == PNC.Const.PRESENCE_CORPSE)
    then
        return false, "attacker_dead"
    end
    if attackerBody and attackerBody.isDead
        and attackerBody:isDead()
    then
        return false, "attacker_body_dead"
    end
    if not target then return false, "missing_target" end
    if target.kind == "player" then
        if not target.player then
            return false, "missing_player_target"
        end
        if target.player.isDead and target.player:isDead() then
            return false, "player_target_dead"
        end
        if PNC.Stealth then
            if PNC.Stealth.ShouldSuppressCompanionCombat
                and PNC.Stealth.ShouldSuppressCompanionCombat(attackerRecord)
            then
                return false, "player_target_hidden"
            end
            if PNC.Stealth.ShouldSuppressZombieAggro
                and PNC.Stealth.ShouldSuppressZombieAggro(attackerRecord)
            then
                return false, "player_target_hidden"
            end
        end
        if PNC.Factions and PNC.Factions.CanNPCTargetPlayer
            and PNC.Factions.CanNPCTargetPlayer(
                attackerRecord,
                target.player
            ) ~= true
        then
            -- Revalidate at damage time. A committed attack may outlive a
            -- stealth/faction transition and must not hit from stale intent.
            return false, "player_target_not_allowed"
        end
    end
    hit = Resolution.BuildHitEvent(attackerRecord, target, options)
    if hit.amount <= 0 then return false, "invalid_damage", hit end
    if target.kind == "player" then
        local applied = Resolution.ApplyPlayerDamage(target.player, hit.amount, hit.attackType, hit.weaponItem, hit)
        if applied == true
            and attackerRecord
            and PNC.Factions
            and PNC.Factions.OnNPCAttackPlayer
        then
            local at = getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
            PNC.Factions.OnNPCAttackPlayer(
                attackerRecord,
                target.player,
                at,
                {
                    severe = hit.amount >= (
                        PNC.FactionBalance
                        and PNC.FactionBalance.Get(
                            "severeAttackDamageThreshold"
                        ) or 25
                    ),
                    damage = hit.amount,
                    callback = "npc_attack_player",
                    killed = target.player.isDead
                        and target.player:isDead() == true,
                }
            )
        end
        if applied == true
            and attackerRecord
            and PNC.SocialEventHooksInternal
            and PNC.SocialEventHooksInternal.RecordNPCDamagedPlayer
        then
            pcall(
                PNC.SocialEventHooksInternal.RecordNPCDamagedPlayer,
                target.player,
                attackerRecord,
                attackerBody,
                hit
            )
        end
        return applied == true, applied == true and "hit_player" or "invalid_player_target", hit
    end
    if target.kind == "npc" then
        local targetRecord = registry and registry.Get and registry.Get(target.id) or nil
        local targetBody = registry and registry.GetLiveZombie and registry.GetLiveZombie(target.id) or nil
        return Resolution.ApplyNPCDamage(targetRecord, targetBody, hit)
    end
    if target.kind == "zombie" then
        return Resolution.ApplyZombieDamage(attackerRecord, attackerBody, target, hit)
    end
    return false, "unknown_target", hit
end

return Resolution
