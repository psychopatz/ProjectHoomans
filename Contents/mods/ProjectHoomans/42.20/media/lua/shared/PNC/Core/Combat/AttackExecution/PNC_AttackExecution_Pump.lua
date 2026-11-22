-- Per-tick processing for committed attacks and reloads.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Core = PNC.Core
local Firearms = PNC.Firearms
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function shouldEmitFailedHitAudit(record, target, reason, detailReason, now)
    local detailStr = detailReason ~= nil and tostring(detailReason) or ""
    local normalizedReason = detailStr ~= "" and detailStr or tostring(reason or "")
    local expected = normalizedReason == "npc_damage_rejected"
        or normalizedReason == "npc_target_not_allowed"
        or normalizedReason == "alert_missing_or_expired"
        or normalizedReason == "alert_sequence_mismatch"
        or normalizedReason == "target_not_visible"
        or normalizedReason == "target_out_of_range_at_hit"
        or normalizedReason == "invalid_zombie_target"
    local runtime
    local key
    local lastAt
    local kind
    local targetKey
    local windowMs
    if not expected then
        return true
    end
    runtime = record and record.runtime
    if not runtime then return true end
    runtime.npcHitAuditThrottle = runtime.npcHitAuditThrottle or {}
    kind = target and target.kind or "unknown"
    targetKey = target and (target.id or target.zombieId or target.onlineID) or ""
    key = tostring(kind) .. ":" .. tostring(targetKey) .. "|" .. normalizedReason
    windowMs = kind == "zombie" and 3000 or 1000
    lastAt = tonumber(runtime.npcHitAuditThrottle[key])
    if lastAt ~= nil and now - lastAt < windowMs then
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
            local detail = type(action.lastDetail) == "table" and action.lastDetail or nil
            local detailReasonRaw = detail and detail.reason or nil
            local npcAuditEnabled = target and target.kind == "npc"
                and Diagnostics
                and Diagnostics.NPCThreatAuditEnabled == true
                and Diagnostics.LogNPCThreatAudit ~= nil
            local emitFailureAudit = shouldEmitFailedHitAudit(
                record,
                target,
                action.lastReason,
                detailReasonRaw,
                now
            )
            if emitFailureAudit then
                local detailOutcome = detail and tostring(detail.outcome or "") or ""
                local detailPart = detail and tostring(detail.partId or "") or ""
                local detailReason = detailReasonRaw ~= nil and tostring(detailReasonRaw) or ""
                local detailHealthState = detail and tostring(detail.healthState or "") or ""
                local detailHealthCurrent = detail and tostring(detail.healthCurrent or "") or ""
                local detailHealthMax = detail and tostring(detail.healthMax or "") or ""
                local detailBodyState = detail and tostring(
                    detail.bodyState or detail.targetBodyState or ""
                ) or ""
                local detailAuthorization = detail and tostring(detail.ownerDefenseReason or "") or ""
                local detailAttackType = detail and tostring(detail.attackType or "") or ""
                local detailAttackKind = detail and tostring(detail.attackKind or "") or ""
                local detailWoundType = detail and tostring(detail.woundType or "") or ""
                local detailWeaponFullType = detail and tostring(detail.weaponFullType or "") or ""
                local targetId = target and (
                    target.id or target.onlineID or target.zombieId
                ) or "nil"
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
                if npcAuditEnabled then
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
