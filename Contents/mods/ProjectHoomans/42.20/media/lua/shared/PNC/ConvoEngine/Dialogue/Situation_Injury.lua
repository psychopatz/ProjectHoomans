-- Semantic situation injury and knox-exposure projection helper.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Situation = PNC.ConvoEngine.DialogueSituation
local Internal = Situation.Internal or {}
Situation.Internal = Internal
local fromSource = Internal.FromSource
local healthState = Internal.HealthState

local function resolveSalivaTransmissible(explicit, proj)
    if type(explicit) == "boolean" then return explicit end
    if type(proj) == "table" and type(proj.salivaTransmissible) == "boolean" then
        return proj.salivaTransmissible
    end
    local sb = PNC.Sandbox
    if sb and type(sb.IsKnoxSalivaTransmissible) == "function" then
        local ok, val = pcall(sb.IsKnoxSalivaTransmissible)
        if ok and type(val) == "boolean" then return val end
    end
    return true
end

function Internal.ResolveInjuryState(context)
    context = type(context) == "table" and context or {}
    local existing = type(context.npcState) == "table" and context.npcState or {}
    local record = context.npcRecord or context.record
    local proj = nil
    local woundsApi = PNC.NPCWounds
    if type(record) == "table" and woundsApi and type(woundsApi.GetOrBuildProjection) == "function" then
        local ok, res = pcall(woundsApi.GetOrBuildProjection, record)
        if ok and type(res) == "table" then proj = res end
    end
    local lifecycle = type(context.interactionLifecycle) == "table"
        and context.interactionLifecycle or nil
    local beat = lifecycle and type(lifecycle.activeBeat) == "table"
        and lifecycle.activeBeat or nil
    local beatCtx = beat and type(beat.context) == "table" and beat.context or nil
    local profile = context.injuryProfile
        or (beatCtx and beatCtx.injuryProfile)
        or nil
    local bodyHealth = fromSource(context, "bodyHealth")
        or (type(record) == "table" and ((record.health and record.health.body) or record.body))
        or nil

    local openCount = (proj and tonumber(proj.openWoundCount))
        or (profile and tonumber(profile.openCount))
        or (type(bodyHealth) == "table" and tonumber(bodyHealth.openWoundCount))
        or 0
    local patchedCount = (proj and tonumber(proj.patchedWoundCount))
        or (profile and tonumber(profile.patchedCount))
        or (type(bodyHealth) == "table" and (
            (tonumber(bodyHealth.bandagedWoundCount) or 0)
            + (tonumber(bodyHealth.stitchedWoundCount) or 0)
            + (tonumber(bodyHealth.splintedWoundCount) or 0)
        ))
        or 0
    local isBitten = existing.isBitten
    if isBitten == nil then
        local hasRawBite = false
        if type(bodyHealth) == "table" and type(bodyHealth.wounds) == "table" then
            for _, wEntry in pairs(bodyHealth.wounds) do
                if type(wEntry) == "table" then
                    if tostring(wEntry.type or "") == "bite" then
                        hasRawBite = true
                        break
                    end
                    for i = 1, #wEntry do
                        local w = wEntry[i]
                        if type(w) == "table" and tostring(w.type or "") == "bite" then
                            hasRawBite = true
                            break
                        end
                    end
                end
                if hasRawBite then break end
            end
        end
        isBitten = (proj and proj.hasBite == true)
            or hasRawBite
            or (profile and (profile.isBite == true or profile.woundType == "bite"))
            or (beatCtx and (beatCtx.combatWoundType == "bite_lethal"
                or beatCtx.combatWoundType == "bite_possible_exposure"
                or beatCtx.combatWoundType == "bite_confirmed_symptomatic"
                or beatCtx.combatWoundType == "bite_non_transmissible"))
            or false
    end
    local hasOpenWounds = existing.hasOpenWounds
    if hasOpenWounds == nil then
        hasOpenWounds = openCount > 0
            or (profile and profile.patchState == "with_wounds")
            or (beatCtx and beatCtx.woundPatchState == "with_wounds")
            or false
    end
    local hState = existing.healthState or healthState(context)
    local hasActiveInjury = existing.hasActiveInjury
    if hasActiveInjury == nil then
        hasActiveInjury = hasOpenWounds == true
            or patchedCount > 0
            or isBitten == true
            or (proj and (tonumber(proj.totalWoundCount) or 0) > 0)
            or (profile ~= nil)
            or hState == "injured"
            or hState == "wounded"
            or hState == "critical"
            or false
    end
    local saliva = resolveSalivaTransmissible(
        existing.salivaTransmissible
            ~= nil and existing.salivaTransmissible
            or (profile and profile.salivaTransmissible)
            or (beatCtx and beatCtx.salivaTransmissible)
            or (context.worldKnowledge and context.worldKnowledge.salivaTransmissible),
        proj
    )
    local knoxExposure = existing.knoxExposure
        or (proj and proj.knoxExposure)
        or (profile and profile.knoxExposure)
        or (isBitten and (saliva and "possible" or "impossible") or "impossible")
    local knoxStage = existing.knoxStage
        or (proj and proj.knoxStage)
        or (profile and profile.knoxStage)
        or "none"
    local patchState = existing.patchState
        or (proj and proj.patchState)
        or (profile and profile.patchState)
        or (beatCtx and beatCtx.woundPatchState)
        or (hasOpenWounds and "with_wounds" or (patchedCount > 0 and "patched_up" or "none"))
    local treatmentState = existing.treatmentState
        or (proj and proj.treatmentState)
        or (profile and profile.treatmentState)
        or (hasOpenWounds and "untreated_open" or (patchedCount > 0 and "bandaged_clean" or "none"))
    local physicalSeverityBand = existing.physicalSeverityBand
        or (proj and proj.physicalSeverityBand)
        or (profile and profile.severityBand)
        or (beatCtx and beatCtx.woundSeverityBand)
        or "none"
    local bodyRegion = existing.bodyRegion
        or (proj and proj.primaryBodyRegion)
        or (profile and profile.bodyRegion)
        or (beatCtx and beatCtx.woundPartRegion)
        or nil
    local biteThreat = existing.hasBiteExecutionThreat
    if biteThreat == nil then
        local rt = type(record) == "table" and record.runtime or nil
        biteThreat = (rt and (rt.biteConflictFacts ~= nil or rt.biteExecutionThreat ~= nil))
            or (beatCtx and beatCtx.biteExecutionThreat ~= nil)
            or false
    end

    return {
        healthState = hState,
        activeBehavior = existing.activeBehavior or context.activeBehavior,
        hasActiveInjury = hasActiveInjury == true,
        hasOpenWounds = hasOpenWounds == true,
        isBitten = isBitten == true,
        knoxExposure = knoxExposure,
        knoxStage = knoxStage,
        salivaTransmissible = saliva,
        hasBiteExecutionThreat = biteThreat == true,
        patchState = patchState,
        treatmentState = treatmentState,
        physicalSeverityBand = physicalSeverityBand,
        bodyRegion = bodyRegion,
        openWoundCount = openCount,
        patchedWoundCount = patchedCount,
        physiology = proj and proj.physiology or existing.physiology,
    }
end

return Situation
