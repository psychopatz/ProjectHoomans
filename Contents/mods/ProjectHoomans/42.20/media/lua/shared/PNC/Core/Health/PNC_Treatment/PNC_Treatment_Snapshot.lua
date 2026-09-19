-- Read-only projection of the active medical-care runtime state.

PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}

local Treatment = PNC.Treatment

function Treatment.BuildMedicalCareSnapshot(record)
    local state = record and record.runtime
        and record.runtime.medicalCare or nil
    if type(state) ~= "table" or state.phase == nil
        or tostring(state.phase) == "idle"
    then
        return nil
    end
    return {
        phase = tostring(state.phase),
        taskId = state.taskId,
        patientId = state.patientId,
        partId = state.partId,
        bump = state.bump,
        lootPosition = state.lootPosition,
        bandageType = state.bandageType,
        bandageName = state.bandageName,
        startedAt = state.startedAt,
        finishAt = state.finishAt,
        revision = state.revision,
    }
end
