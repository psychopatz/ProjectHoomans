local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Presentation = {}

local WORK_OPERATION_LABELS = {
    CONSTRUCT = "BUILD",
    RECONSTRUCT = "RECONSTRUCT",
    DECONSTRUCT = "DECONSTRUCT",
    BUILD_OBJECT = "BUILD",
    CRAFT = "CRAFT",
    DISASSEMBLE = "DISASSEMBLE",
    RESEARCH = "RESEARCH",
    CORPSE_HAUL = "CORPSE HAUL",
    PROVISION_PICKUP = "PROVISION",
    LUMBER = "LUMBER",
    FISHING = "FISHING",
    FARMING = "FARMING",
    SCAVENGE = "SCAVENGE",
    MEDICAL_CARE = "MEDICAL CARE",
}

function Presentation.Current(person)
    local info = person and person.actionInformation or nil
    if type(info) ~= "table" then
        return Shared.Text(person and person.activity, "IDLE")
    end
    if info.kind == "work_order" then
        local operation = tostring(info.operation or "")
        local label = WORK_OPERATION_LABELS[operation]
            or string.upper(string.gsub(operation, "_", " "))
        if label == "" then
            label = string.upper(Shared.Tr("UI_PNC_Action_WorkOrder",
                "Work Order"))
        end
        local phase = tostring(info.phase or info.status or "")
        return phase ~= "" and label .. " (" .. phase .. ")" or label
    end
    if info.kind == "return_home" then
        return Shared.Tr("UI_PNC_Action_ReturningHome", "Returning Home")
    end
    if info.kind == "at_home" then
        return Shared.Tr("UI_PNC_Action_Idle", "Idle")
    end
    if info.kind == "treatment" then
        local label = Shared.Tr("UI_PNC_Task_MedicalCare", "MEDICAL CARE")
        local phase = tostring(info.phase or "")
        return phase ~= "" and label .. " (" .. phase .. ")" or label
    end
    local label = Shared.Text(info.fallback or info.activityId,
        Shared.Text(person.activity, "IDLE"))
    if tostring(info.activityId or "") == "job:GuardAnchor" then
        return Shared.Tr("UI_PNC_Action_Idle", "Idle")
            .. " (" .. label .. ")"
    end
    return label
end

return Presentation
