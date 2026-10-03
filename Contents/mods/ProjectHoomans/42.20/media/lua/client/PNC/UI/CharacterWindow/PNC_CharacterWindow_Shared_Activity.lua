PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

local function activityPhase(state)
    if type(state) ~= "table" or state.phase == nil then return nil end
    local phase = string.lower(tostring(state.phase))
    return phase ~= "" and phase or nil
end

local function activityLabel(source, phase)
    if source == "self" then
        if phase == "bandaging" then
            return Shared.Text("UI_PNC_Medical_Self_Bandaging", "Self-bandaging")
        end
        if phase == "abstract" then
            return Shared.Text("UI_PNC_Medical_Self_Treatment", "Self-treatment")
        end
        return Shared.Text("UI_PNC_Medical_Self_Care", "Self-care")
    end
    if phase == "traveling" or phase == "travel" then
        return Shared.Text("UI_PNC_Medical_Doctor_Traveling", "Doctor traveling")
    end
    if phase == "at_patient" then
        return Shared.Text("UI_PNC_Medical_Doctor_At_Patient", "Doctor at patient")
    end
    if phase == "treating" or phase == "working" then
        return Shared.Text("UI_PNC_Medical_Doctor_Treating", "Doctor treating")
    end
    if phase == "waiting" or phase == "waiting_for_doctor" then
        return Shared.Text("UI_PNC_Medical_Waiting", "Medical care waiting")
    end
    return Shared.Text("UI_PNC_Medical_Activity", "Medical care")
end

local function nowMillis()
    if PNC.Core and PNC.Core.Now then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function activityProgress(startedAt, finishAt)
    startedAt = tonumber(startedAt) or 0
    finishAt = tonumber(finishAt) or 0
    if startedAt <= 0 or finishAt <= startedAt then return nil end
    local now = nowMillis()
    if now <= 0 then return nil end
    return Shared.Clamp((now - startedAt) / (finishAt - startedAt), 0, 1)
end

function Shared.GetMedicalActivity(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local medical = resolved.medicalCareState
    local treatment = resolved.treatmentState
    local phase = activityPhase(medical)
    local source = "medical"
    local state = medical
    if not phase or phase == "idle" then
        phase = activityPhase(treatment)
        source = "self"
        state = treatment
    end
    if not phase or phase == "idle" then return nil end
    return {
        source = source,
        phase = phase,
        label = activityLabel(source, phase),
        taskId = state.taskId,
        patientId = state.patientId,
        partId = state.partId,
        bandageType = state.bandageType,
        bandageName = state.bandageName,
        startedAt = state.startedAt,
        finishAt = state.finishAt,
        progress = activityProgress(state.startedAt, state.finishAt),
        blockedReason = state.blockedReason,
        interruptedReason = state.interruptedReason,
        lastResult = state.lastResult,
    }
end

function Shared.BuildActivitySignature(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local treatment = resolved.treatmentState or {}
    local medical = resolved.medicalCareState or {}
    local feedback = resolved.bandageFeedback or {}
    local body = resolved.bodyHealth or {}
    return table.concat({
        tostring(resolved.activeBehavior or ""),
        tostring(resolved.activeJob or ""),
        tostring(resolved.healthState or ""),
        tostring(resolved.hpCurrent or ""),
        tostring(resolved.hpMax or ""),
        tostring(body.revision or 0),
        tostring(treatment.phase or ""),
        tostring(treatment.partId or ""),
        tostring(treatment.startedAt or 0),
        tostring(treatment.finishAt or 0),
        tostring(treatment.lastResult or ""),
        tostring(treatment.interruptedReason or ""),
        tostring(medical.phase or ""),
        tostring(medical.taskId or ""),
        tostring(medical.patientId or ""),
        tostring(medical.partId or ""),
        tostring(medical.startedAt or 0),
        tostring(medical.finishAt or 0),
        tostring(medical.revision or 0),
        tostring(feedback.revision or 0),
        tostring(feedback.completedAt or 0),
    }, "|")
end

return Shared
