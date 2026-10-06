local Shared = require
    "PNC/UI/Shared/PNC_ColonyUIShared"

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

local WORK_REASON_LABELS = {
    storage_full = "storage full",
    lumber_travel_stalled = "navigation stalled",
    native_no_goal_progress = "navigation stalled",
    no_approach_point = "no reachable work point",
    lumber_tool_missing = "missing lumber tool",
    tool_cannot_chop = "invalid lumber tool",
    physical_inventory_unavailable = "inventory unavailable",
    LUMBER_STORAGE_NOT_FOUND = "stockpile unavailable",
    LUMBER_STOCKPILE_NOT_FOUND = "stockpile unavailable",
    TREE_CHUNK_LOADING = "tree area loading",
}

local function workReason(info)
    local reason = info and (info.blockedReason or info.waitingReason) or nil
    if not reason or tostring(reason) == "" then return nil end
    reason = tostring(reason)
    return WORK_REASON_LABELS[reason]
        or string.lower(string.gsub(reason, "_", " "))
end

local function fishingItemName(fullType)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil end
    if type(getItemNameFromFullType) == "function" then
        local resolved = getItemNameFromFullType(fullType)
        if resolved and tostring(resolved) ~= "" then
            return tostring(resolved)
        end
    end
    local shortType = string.match(fullType, "([^%.]+)$") or fullType
    return string.gsub(shortType, "_", " ")
end

local function isFishingInformation(info)
    local behaviorID = string.lower(tostring(info and info.behaviorId or ""))
    local orderKind = string.lower(tostring(info and info.orderKind or ""))
    return info and info.kind == "behavior"
        and (orderKind == "fishing"
            or string.find(behaviorID, "fishing", 1, true) == 1)
end

function Presentation.Fishing(info)
    local label = Shared.Tr("UI_PNC_Job_Fishing", "FISHING")
    local phase = string.upper(tostring(info and info.phase or ""))
    local text = phase ~= "" and label .. " (" .. phase .. ")" or label
    local attempts = tonumber(info and info.attemptIndex) or 0
    local catches = tonumber(info and info.catches) or 0
    local lastCatch = fishingItemName(info and info.lastCatchItemType)
    if info and info.lastSuccess == false and attempts > 0 then
        text = text .. " - "
            .. Shared.Tr("UI_PNC_Fishing_NoCatch", "NO CATCH")
    end
    if lastCatch then
        text = text .. " - "
            .. Shared.Tr("UI_PNC_Fishing_LastCatch", "LAST CATCH")
            .. ": " .. lastCatch .. " x" .. tostring(catches)
    end
    return text
end

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
        local reason = workReason(info)
        if reason and (phase == "BLOCKED" or info.waitingFor) then
            phase = phase .. ": " .. reason
        end
        return phase ~= "" and label .. " (" .. phase .. ")" or label
    end
    if info.kind == "return_home" then
        return Shared.Tr("UI_PNC_Action_ReturningHome", "Returning Home")
    end
    if info.kind == "at_home" then
        return Shared.Tr("UI_PNC_Action_Idle", "Idle")
    end
    if isFishingInformation(info) then
        return Presentation.Fishing(info)
    end
    if info.kind == "treatment" then
        local label = Shared.Tr("UI_PNC_Task_MedicalCare", "MEDICAL CARE")
        local phase = tostring(info.phase or "")
        return phase ~= "" and label .. " (" .. phase .. ")" or label
    end
    local label
    if tostring(info.activityConsumptionMode or "") == "dual" then
        label = Shared.Tr("UI_PNC_Activity_Consuming", "CONSUMING")
    else
        label = Shared.Text(info.fallback or info.activityId,
            Shared.Text(person.activity, "IDLE"))
    end
    if tostring(info.activityId or "") == "job:GuardAnchor" then
        return Shared.Tr("UI_PNC_Action_Idle", "Idle")
            .. " (" .. label .. ")"
    end
    return label
end

return Presentation
