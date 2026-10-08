-- Per-tick processing for committed attacks and reloads.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Core = PNC.Core
local Firearms = PNC.Firearms
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function shouldEmitFailedHitAudit(record, target, reason, detailReason, now)
    local normalizedReason = tostring(detailReason or reason or "")
    local expected = normalizedReason == "npc_damage_rejected"
        or normalizedReason == "npc_target_not_allowed"
        or normalizedReason == "alert_missing_or_expired"
        or normalizedReason == "alert_sequence_mismatch"
        or normalizedReason == "target_not_visible"
        or normalizedReason == "target_out_of_range_at_hit"
    local runtime
    local key
    local lastAt
    if not expected or not target or target.kind ~= "npc" then
        return true
    end
    runtime = record and record.runtime
    if not runtime then return true end
    runtime.npcHitAuditThrottle = runtime.npcHitAuditThrottle or {}
    key = tostring(target.id or "") .. "|" .. normalizedReason
    lastAt = tonumber(runtime.npcHitAuditThrottle[key]) or 0
    if now - lastAt < 1000 then
        return false
    end
    runtime.npcHitAuditThrottle[key] = now
    return true
end

function Combat.PumpAttackAction(record, zombie)
    local now = Core.Now()
    local action = record and record.runtime and record.runtime.attackAction or nil
    local target
    if not action then
        return false, "no_attack"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive and PNC.PathService.IsTraversalActive(record, zombie) then
        -- Traversal owns its separate special-animation lane. Ending the
        -- combat action only publishes an inactive attack snapshot.
        Internal.finishAttackAction(record, zombie)
        return false, "attack_cancelled_for_traversal"
    end
    if not zombie or record.alive == false then
        Internal.finishAttackAction(record, zombie)
        return false, "attack_cleared"
    end

    if action.attackType == "reload" then
        target = AttackExecution.resolveActionTarget(action.target)
        if target then
            Internal.faceTarget(zombie, target, record, 120, "reload_followthrough")
        end
        if now >= (tonumber(action.finishAt) or 0) then
            if Firearms and Firearms.CompleteReload then
                action.lastResult, action.lastReason = Firearms.CompleteReload(record, zombie, action)
            else
                action.lastResult, action.lastReason = false, "firearm_service_unavailable"
            end
            Internal.finishAttackAction(record, zombie)
            return false, action.lastReason or "reload_finished"
        end
        return true, "reloading"
    end

    target = AttackExecution.resolveActionTarget(action.target)
    if not target then
        Internal.finishAttackAction(record, zombie)
        return false, "target_lost_or_dead"
    end
    if target
        and not AttackExecution.isActionTargetVisible(record, target)
        and not (action.attackType == "melee" and AttackExecution.isCommittedMeleeTargetInRange(zombie, target))
    then
        Internal.finishAttackAction(record, zombie)
        return false, "target_not_visible"
    end
    if target then
        Internal.faceTarget(zombie, target, record, 120, "attack_followthrough")
    end
    if (not action.hitDone) and now >= (tonumber(action.hitAt) or 0) then
        action.hitDone = true
        if action.attackType == "melee" and not AttackExecution.isCommittedMeleeTargetInRange(zombie, target) then
            action.lastResult = false
            action.lastReason = "target_out_of_range_at_hit"
            action.lastDetail = nil
        else
            action.lastResult, action.lastReason, action.lastDetail =
                Internal.applyAttackActionHit(record, zombie, action, target)
        end
        if action.lastResult ~= true
            and action.lastReason ~= "ranged_miss"
            and action.lastReason ~= "melee_miss"
            and Core and Core.Log
        then
            local detailOutcome = ""
            local detailPart = ""
            local detailReason = ""
            local detailHealthState = ""
            local detailHealthCurrent = ""
            local detailHealthMax = ""
            local detailBodyState = ""
            local detailAuthorization = ""
            local detailAttackType = ""
            local detailAttackKind = ""
            local detailWoundType = ""
            local detailWeaponFullType = ""
            local emitFailureAudit
            local targetId = target and (
                target.id or target.onlineID or target.zombieId
            ) or "nil"
            if type(action.lastDetail) == "table" then
                detailOutcome = tostring(action.lastDetail.outcome or "")
                detailPart = tostring(action.lastDetail.partId or "")
                detailReason = tostring(action.lastDetail.reason or "")
                detailHealthState = tostring(
                    action.lastDetail.healthState or ""
                )
                detailHealthCurrent = tostring(
                    action.lastDetail.healthCurrent or ""
                )
                detailHealthMax = tostring(
                    action.lastDetail.healthMax or ""
                )
                detailBodyState = tostring(
                    action.lastDetail.bodyState
                        or action.lastDetail.targetBodyState or ""
                )
                detailAuthorization = tostring(
                    action.lastDetail.ownerDefenseReason or ""
                )
                detailAttackType = tostring(
                    action.lastDetail.attackType or ""
                )
                detailAttackKind = tostring(
                    action.lastDetail.attackKind or ""
                )
                detailWoundType = tostring(
                    action.lastDetail.woundType or ""
                )
                detailWeaponFullType = tostring(
                    action.lastDetail.weaponFullType or ""
                )
            end
            emitFailureAudit = shouldEmitFailedHitAudit(
                record,
                target,
                action.lastReason,
                detailReason,
                now
            )
            if emitFailureAudit then
                Core.Log(
                    "WARN",
                    "attack_hit_failed npc="
                        .. tostring(record and record.id or "nil")
                        .. " reason=" .. tostring(action.lastReason or "unknown")
                        .. " target=" .. tostring(target and target.kind or "nil")
                        .. " targetId=" .. tostring(targetId)
                        .. " detail=" .. detailOutcome
                        .. " part=" .. detailPart
                        .. " detailReason=" .. detailReason
                        .. " attackType=" .. detailAttackType
                        .. " attackKind=" .. detailAttackKind
                        .. " wound=" .. detailWoundType
                        .. " weapon=" .. detailWeaponFullType
                        .. " healthState=" .. detailHealthState
                        .. " health=" .. detailHealthCurrent
                        .. "/" .. detailHealthMax
                        .. " body=" .. detailBodyState
                        .. " authorization=" .. detailAuthorization
                )
            end
            if target and target.kind == "npc"
                and Diagnostics
                and Diagnostics.NPCThreatAuditEnabled == true
                and Diagnostics.LogNPCThreatAudit
                and emitFailureAudit
            then
                Diagnostics.LogNPCThreatAudit("npc_damage_rejected", {
                    "npc=" .. tostring(record and record.id or ""),
                    "targetId=" .. tostring(target.id or ""),
                    "reason=" .. tostring(action.lastReason or ""),
                    "outcome=" .. detailOutcome,
                    "detailReason=" .. detailReason,
                    "partId=" .. detailPart,
                    "attackType=" .. detailAttackType,
                    "attackKind=" .. detailAttackKind,
                    "woundType=" .. detailWoundType,
                    "weapon=" .. detailWeaponFullType,
                    "healthState=" .. detailHealthState,
                    "health=" .. detailHealthCurrent
                        .. "/" .. detailHealthMax,
                    "body=" .. detailBodyState,
                    "authorization=" .. detailAuthorization,
                    "damage=" .. tostring(action.damage or ""),
                    "targetX=" .. tostring(target.x or ""),
                    "targetY=" .. tostring(target.y or ""),
                })
            end
        end
        if action.lastResult == true
            and target
            and target.kind == "npc"
            and Diagnostics
            and Diagnostics.NPCThreatAuditEnabled == true
            and Diagnostics.LogNPCThreatAudit
        then
            local detail = type(action.lastDetail) == "table"
                and action.lastDetail or {}
            Diagnostics.LogNPCThreatAudit("npc_damage_applied", {
                "npc=" .. tostring(record and record.id or ""),
                "targetId=" .. tostring(target.id or ""),
                "outcome=" .. tostring(detail.outcome or ""),
                "reason=" .. tostring(action.lastReason or ""),
                "partId=" .. tostring(detail.partId or ""),
                "attackType=" .. tostring(detail.attackType or ""),
                "attackKind=" .. tostring(detail.attackKind or ""),
                "woundType=" .. tostring(detail.woundType or ""),
                "weapon=" .. tostring(detail.weaponFullType
                    or action.weaponFullType or ""),
                "healthState=" .. tostring(detail.healthState or ""),
                "health=" .. tostring(detail.healthCurrent or "")
                    .. "/" .. tostring(detail.healthMax or ""),
                "damage=" .. tostring(action.damage or ""),
            })
        end
    end

    if target == nil or now >= (tonumber(action.finishAt) or 0) then
        Internal.finishAttackAction(record, zombie)
        return false, action.lastReason or (target and "attack_finished" or "target_lost")
    end

    return true, action.attackType == "ranged" and "attack_anim_ranged" or "attack_anim_melee"
end
