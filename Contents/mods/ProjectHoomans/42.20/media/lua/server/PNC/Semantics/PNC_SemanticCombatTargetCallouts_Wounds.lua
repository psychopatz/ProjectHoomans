-- Event-driven entrypoints for combat wound Beats, fighting callouts, and injury/physiology transitions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundDelivery"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_PainReaction"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local teamInjuryCalloutAt = {}

local function invalidActor(r)
    if type(r) ~= "table" or r.alive == false or r.id == nil then return "invalid_target" end
    local h = r.health
    if type(h) == "table" and (h.state == "dead" or h.state == "incapacitated") then return "target_incapacitated" end
end

function S.OnNPCWoundReceived(record, hitSpec, now, opts)
    local bad = invalidActor(record)
    if bad then return false, bad end
    local profile = S.ClassifyActorWoundProfile(record, hitSpec)
    if not profile then return false, "no_wound_profile" end
    now = I.SituationNow(now)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}

    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local woundTier = (profile.isBite == true or profile.woundType == "bullet") and 4
        or math.max(1, tonumber(S.SeverityRank(profile.physicalSeverityBand or profile.severityBand)) or 1)
    local scopeKey = "wound:" .. tostring(record.id)
    local perc = PNC.Perception
    local teamKey = tostring(perc and perc.GetTeamKey and perc.GetTeamKey(record) or "__default__")
    if Dir and type(Dir.EvaluateCandidate) == "function" and not (opts and opts.ignoreCooldown == true) then
        local dirOk, dirInfo = Dir.EvaluateCandidate({
            speaker = record,
            scopeKey = scopeKey,
            groupKey = teamKey,
            topic = "combat_wound",
            tier = woundTier,
            urgency = woundTier >= 3 and 86 or 58,
            salience = profile.isBite and 85 or (46 + woundTier * 12),
            saturationWindowMs = 35000,
            silenceThreshold = 42,
            markOnAdmit = false,
            now = now,
        })
        if not dirOk then
            return false, tostring(dirInfo and dirInfo.reason or "director_suppressed")
        end
    end

    local okPain, painReason = false, "pain_skipped"
    if not (opts and opts.skipPainBeat == true) and type(S.EmitImmediatePainReaction) == "function" then
        okPain, painReason = S.EmitImmediatePainReaction(record, hitSpec, profile, now, opts)
        if not okPain and not (opts and opts.ignoreCooldown == true) then
            return false, painReason
        end
    end

    local allowed, isPreempt = S.ShouldPreemptWoundBeat(record, profile, now, 4500)
    if not (opts and opts.ignoreCooldown == true) and not allowed then
        if okPain then
            if Dir and type(Dir.MarkSpoken) == "function" then
                Dir.MarkSpoken(scopeKey, "combat_wound", woundTier, now, record.id)
            end
            return true, painReason
        end
        return false, "wound_beat_cooldown"
    end
    local hitDesc = {
        semanticClass = "human_hostile",
        enemyType = (hitSpec and hitSpec.attackerKind == "zombie") and "zombie" or "hostile",
        x = record.x, y = record.y, z = record.z,
    }
    local ref = "wound:" .. tostring(record.id) .. ":" .. tostring(math.floor(now)) .. ":" .. tostring(profile.injuryRevision or 1)
    local pri = profile.isBite and 78 or (profile.woundTierPriority >= 4 and 74 or 66)
    local callOpts = isPreempt and { isPreempt = true, skipReplies = opts and opts.skipReplies } or opts
    local ok, reason = I.EmitWoundDialogue(
        record, "combat_wound_received_beat", profile.effectiveWoundTier,
        profile, hitDesc, now, pri, ref, callOpts
    )
    if ok then
        record.runtime.lastWoundBeatAt = now
        record.runtime.lastWoundBeatPriority = profile.woundTierPriority
        record.runtime.lastWoundBeatSeverityRank = S.SeverityRank(profile.physicalSeverityBand or profile.severityBand)
        record.runtime.lastWoundBeatRegion = tostring(profile.bodyRegion or "torso")
        if Dir then
            if type(Dir.MarkSpoken) == "function" then
                Dir.MarkSpoken(scopeKey, "combat_wound", woundTier, now, record.id)
            end
            if type(Dir.RecordStoryMoment) == "function" then
                Dir.RecordStoryMoment(teamKey, {
                    kind = "teammate_wounded",
                    topic = "post_fight",
                    actorId = record.id,
                    salience = woundTier >= 3 and 78 or 60,
                    valence = -1,
                    ttlMs = 240000,
                }, now)
            end
        end
        return ok, reason
    end
    if okPain then
        if Dir and type(Dir.MarkSpoken) == "function" then
            Dir.MarkSpoken(scopeKey, "combat_wound", woundTier, now, record.id)
        end
        return true, painReason
    end
    return ok, reason
end

function S.OnFightingWhileInjured(record, desc, now, opts)
    local bad = invalidActor(record)
    if bad then return false, bad end
    local profile = S.ClassifyActorWoundProfile(record, opts and opts.hitSpec)
    if not profile then return false, "not_injured" end
    now = I.SituationNow(now)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local sev = profile.physicalSeverityBand or profile.severityBand
    local stateChanged = (record.runtime.lastFightingInjuredPatchState ~= nil and record.runtime.lastFightingInjuredPatchState ~= profile.patchState)
        or (record.runtime.lastFightingInjuredKnox ~= nil and record.runtime.lastFightingInjuredKnox ~= profile.knoxExposure)
    local escalated = (sev == "critical" and record.runtime.lastFightingInjuredSeverity ~= "critical")
        or (profile.treatmentState == "dirty_dressing" and record.runtime.lastFightingInjuredTreatment ~= "dirty_dressing")
    local elapsed = now - (tonumber(record.runtime.lastFightingInjuredCalloutAt) or -99999)
    local perc = PNC.Perception
    local teamKey = tostring(perc and perc.GetTeamKey and perc.GetTeamKey(record) or "__default__")
    local teamElapsed = now - (tonumber(teamInjuryCalloutAt[teamKey]) or -99999)
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local fightTier = sev == "critical" and 3 or (sev == "severe" and 2 or 1)
    local fightScope = "fight_inj:" .. tostring(record.id)
    if not (opts and opts.ignoreCooldown == true) and not stateChanged and not escalated then
        if elapsed < 9000 or teamElapsed < 4500 then
            return false, "fighting_injured_cooldown"
        end
        if Dir and type(Dir.EvaluateCandidate) == "function" then
            local dirOk, dirInfo = Dir.EvaluateCandidate({
                speaker = record,
                scopeKey = fightScope,
                groupKey = teamKey,
                topic = "fighting_injured",
                tier = fightTier,
                urgency = (sev == "critical" or profile.knoxExposure == "confirmed") and 80 or 40,
                salience = 46,
                saturationWindowMs = 45000,
                silenceThreshold = 50,
                markOnAdmit = false,
                now = now,
            })
            if not dirOk then
                return false, tostring(dirInfo and dirInfo.reason or "director_suppressed")
            end
        end
    end
    local variant = S.ResolveFightingInjuredVariant(profile)
    local hitDesc = type(desc) == "table" and desc
        or { semanticClass = "human_hostile", enemyType = "hostile", x = record.x, y = record.y, z = record.z }
    local ref = (opts and opts.threadID) or ("injfight:" .. tostring(record.id) .. ":" .. tostring(math.floor(now)))
    local pri = (sev == "critical" or profile.knoxExposure == "confirmed") and 74 or 66
    local ok, reason = I.EmitWoundDialogue(
        record, "combat_fighting_injured_callout", variant,
        profile, hitDesc, now, pri, ref, opts
    )
    if ok then
        record.runtime.lastFightingInjuredCalloutAt = now
        record.runtime.lastFightingInjuredPatchState = profile.patchState
        record.runtime.lastFightingInjuredSeverity = sev
        record.runtime.lastFightingInjuredTreatment = profile.treatmentState
        record.runtime.lastFightingInjuredKnox = profile.knoxExposure
        teamInjuryCalloutAt[teamKey] = now
        if Dir and type(Dir.MarkSpoken) == "function" then
            Dir.MarkSpoken(fightScope, "fighting_injured", fightTier, now, record.id)
        end
    end
    return ok, reason
end

function S.OnInjuryStateTransition(record, transitionSpec, now, opts)
    local bad = invalidActor(record)
    if bad then return false, bad end
    transitionSpec = type(transitionSpec) == "table" and transitionSpec or { kind = tostring(transitionSpec or "severity_escalation") }
    local kind = tostring(transitionSpec.kind or "severity_escalation")
    now = I.SituationNow(now)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime.transitionBeatAt = type(record.runtime.transitionBeatAt) == "table" and record.runtime.transitionBeatAt or {}
    local lastAt = tonumber(record.runtime.transitionBeatAt[kind]) or -99999
    if not (opts and opts.ignoreCooldown == true) and (now - lastAt) < 15000 then
        return false, "transition_cooldown"
    end
    local profile = S.BuildTransitionProfile(record, transitionSpec)
    local variant = S.ResolveTransitionBeatVariant(profile, kind)
    local hitDesc = { semanticClass = "environment", enemyType = "condition", x = record.x, y = record.y, z = record.z }
    local ref = "injury-trans:" .. tostring(record.id) .. ":" .. kind .. ":" .. tostring(math.floor(now))
    local pri = (kind == "knox_symptom_onset" or kind == "hypothermia_onset" or kind == "severity_escalation") and 74 or 64
    local ok, reason = I.EmitWoundDialogue(record, "combat_wound_received_beat", variant, profile, hitDesc, now, pri, ref, opts)
    if ok then
        record.runtime.transitionBeatAt[kind] = now
    end
    return ok, reason
end

function S.TryPostCombatInjuryCheck(record, now)
    local wounds = PNC.NPCWounds
    local proj = wounds and type(wounds.GetOrBuildProjection) == "function" and wounds.GetOrBuildProjection(record) or nil
    if proj and proj.injured == true then
        return S.OnInjuryStateTransition(record, { kind = "post_combat_injury_check", partId = proj.partId, woundType = proj.woundType }, now)
    end
    return false
end

function S.ResetWoundCallouts()
    teamInjuryCalloutAt = {}
end

return S
