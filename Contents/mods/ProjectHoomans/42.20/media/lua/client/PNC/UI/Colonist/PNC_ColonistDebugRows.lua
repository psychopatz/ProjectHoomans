local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Rows = {}

local function facilityLabel(facility)
    local definitions = PNC and PNC.FacilityDefinitions
    local definition = definitions and definitions.Get
        and definitions.Get(facility and facility.definitionId)
    return Shared.Tr(definition and definition.displayNameKey or "",
        facility and facility.definitionId or "facility")
end

local function getComponent(window, component)
    if component then return component end
    if window and window.tabComponents then
        component = window.tabComponents.debug
    end
    return component or (window and window.debugComponent)
end

function Rows.SyncFacilities(window, snapshot, component)
    component = getComponent(window, component)
    local combo = component and component.facilityCombo
    if not combo then return end
    local previous = combo:getOptionData(combo.selected)
    local previousID = previous and previous.key
    combo:clear()
    local selected = 1
    local facilities = snapshot and snapshot.settlement
        and snapshot.settlement.facilities or {}
    local optionIndex = 0
    for _, facility in ipairs(facilities) do
        local label = facilityLabel(facility)
        local state = facility.cachedState or facility.constructionState
            or "UNKNOWN"
        local components = {}
        for _, component in ipairs(facility.components or {}) do
            components[#components + 1] = component
        end
        table.sort(components, function(left, right)
            return tostring(left.id or "") < tostring(right.id or "")
        end)
        for _, component in ipairs(components) do
            optionIndex = optionIndex + 1
            local key = tostring(facility.id or "") .. ":"
                .. tostring(component.id or "")
            local role = tostring(component.role or component.kind or "component")
            combo:addOptionWithData(label .. " • " .. role .. " • "
                .. tostring(component.id or "") .. " • " .. tostring(state), {
                    key = key,
                    facility = facility,
                    component = component,
                    facilityId = facility.id,
                    componentId = component.id,
                })
            if key == previousID then selected = optionIndex end
        end
        if #components == 0 then
            optionIndex = optionIndex + 1
            local key = tostring(facility.id or "") .. ":none"
            combo:addOptionWithData(label .. " • no live components • "
                .. tostring(state), {
                    key = key,
                    facility = facility,
                    component = nil,
                    facilityId = facility.id,
                })
            if key == previousID then selected = optionIndex end
        end
    end
    if #facilities == 0 then
        combo:addOptionWithData(Shared.Tr(
            "UI_PNC_Facility_None", "NO FACILITIES"), false)
    end
    combo.selected = selected
end

function Rows.Build(person, snapshot, window, component)
    Rows.SyncFacilities(window, snapshot, component)
    if not person then
        return {{
            key = "debug_select",
            label = Shared.Tr("UI_PNC_ColonyDebug_Select", "SELECT A COLONIST"),
            detail = Shared.Tr("UI_PNC_ColonyDebug_SelectHelp",
                "Choose a colonist to inspect storage and provisions."),
        }}
    end

    local rows = {}
    if person.facilityDebugWork then
        local work = person.facilityDebugWork
        local target = work.target or {}
        rows[#rows + 1] = {
            key = "debug_facility_work",
            label = Shared.Tr("UI_PNC_ColonyDebug_FacilityWork",
                "Facility test job"),
            detail = string.format("%s | %s | %s | %.0f, %.0f, %.0f",
                Shared.Tr(work.facilityName,
                    tostring(work.facilityId or "facility")),
                tostring(work.componentRole or work.role or "work") .. " / "
                    .. tostring(work.componentId or ""),
                tostring(work.phase or "QUEUED"),
                tonumber(target.x) or 0, tonumber(target.y) or 0,
                tonumber(target.z) or 0),
            colorName = work.phase == "WORKING" and "success" or "accent",
        }
    end

    local storage = snapshot and snapshot.provisionStorage or {}
    local foodStorage = storage.food or {}
    local hydrationStorage = storage.hydration or {}
    local medicineStorage = storage.bandage or {}
    rows[#rows + 1] = {
        key = "debug_storage_food",
        label = Shared.Tr("UI_PNC_ProvisionDebug_StorageFood",
            "Colony storage food"),
        detail = string.format("hunger utility %.3f | calories %.0f | types %d",
            tonumber(foodStorage.amount) or 0,
            tonumber(foodStorage.calories) or 0,
            tonumber(foodStorage.candidateTypes) or 0),
        colorName = (tonumber(foodStorage.amount) or 0) > 0
            and "success" or "danger",
    }
    rows[#rows + 1] = {
        key = "debug_storage_hydration",
        label = Shared.Tr("UI_PNC_ProvisionDebug_StorageHydration",
            "Colony storage hydration"),
        detail = string.format("thirst utility %.3f | types %d",
            tonumber(hydrationStorage.amount) or 0,
            tonumber(hydrationStorage.candidateTypes) or 0),
    }
    rows[#rows + 1] = {
        key = "debug_storage_medicine",
        label = Shared.Tr("UI_PNC_ProvisionDebug_StorageMedicine",
            "Colony storage medicine"),
        detail = string.format("usable bandages %.0f | types %d",
            tonumber(medicineStorage.amount) or 0,
            tonumber(medicineStorage.candidateTypes) or 0),
    }

    local evaluations = person.provision and person.provision.evaluations or {}
    local provisionLabel = Shared.Tr(
        "UI_PNC_ColonyDebug_ProvisionState", "Provision")
    for _, ruleID in ipairs({ "food", "hydration", "bandage" }) do
        local value = evaluations[ruleID]
        if value then
            rows[#rows + 1] = {
                key = "debug_provision_" .. ruleID,
                label = provisionLabel .. ": " .. string.upper(ruleID),
                detail = string.format("%.2f / %.2f  |  %s",
                    tonumber(value.onHand) or 0,
                    tonumber(value.target) or 0,
                    value.refilling and "REFILLING" or "READY"),
            }
        end
    end

    local result = snapshot and snapshot.actionResult
    if result and (result.action == "debug_need"
        or result.action == "debug_facility_work")
    then
        rows[#rows + 1] = {
            key = "debug_result",
            label = Shared.Tr("UI_PNC_ColonyDebug_LastAction", "Last action"),
            detail = tostring(result.reason or "unknown"),
            colorName = result.ok and "success" or "danger",
        }
        local grabLabel = Shared.Tr("UI_PNC_ProvisionDebug_Grab", "GRAB")
        for index, forceResult in ipairs(
            result.details and result.details.forceResults or {}) do
            rows[#rows + 1] = {
                key = "debug_force_result_" .. tostring(index),
                label = grabLabel .. " " .. string.upper(
                    tostring(forceResult.ruleId or "unknown")),
                detail = tostring(forceResult.reason or "unknown"),
                colorName = forceResult.ok and "success" or "danger",
            }
        end
    end
    return rows
end

return Rows
