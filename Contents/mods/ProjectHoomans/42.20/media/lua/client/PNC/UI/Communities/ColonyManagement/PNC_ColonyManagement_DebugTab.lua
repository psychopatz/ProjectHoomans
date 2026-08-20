require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local ProvisionDiagnostics = require "PNC/UI/Communities/ColonyManagement/PNC_ProvisionDiagnosticsModal"

local DebugTab = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local ACTIONS = {
    { id = "hunger", key = "UI_PNC_ColonyDebug_AddHunger",
        fallback = "INCREASE HUNGER +25%" },
    { id = "thirst", key = "UI_PNC_ColonyDebug_AddThirst",
        fallback = "INCREASE THIRST +25%" },
    { id = "fatigue", key = "UI_PNC_ColonyDebug_AddFatigue",
        fallback = "INCREASE FATIGUE +25%" },
    { id = "reset", key = "UI_PNC_ColonyDebug_Reset",
        fallback = "RESET NEEDS" },
    { id = "force_provision", key = "UI_PNC_ColonyDebug_Provision",
        fallback = "FORCE GRAB PROVISIONS" },
    { id = "force_nearby_water", key = "UI_PNC_ColonyDebug_NearbyWater",
        fallback = "FORCE DRINK NEARBY WATER" },
    { id = "inspect_provision", key = "UI_PNC_ColonyDebug_InspectProvision",
        fallback = "PROVISION DIAGNOSTICS" },
    { id = "facility_work", key = "UI_PNC_ColonyDebug_FacilityWork",
        fallback = "SEND TO WORK FACILITY" },
    { id = "facility_stop", key = "UI_PNC_ColonyDebug_StopFacilityWork",
        fallback = "STOP FACILITY TEST" },
}

function DebugTab.Create(window)
    local pane = ISPanel:new(0, 0, 1, 1)
    pane:initialise()
    pane:instantiate()
    pane.background = true
    pane.backgroundColor = { r = 0.04, g = 0.055, b = 0.065, a = 0.95 }
    pane.borderColor = { r = 0.20, g = 0.35, b = 0.40, a = 0.85 }
    window:addChild(pane)
    window.debugControlsPane = pane
    window.debugControls = {}
    window.debugFacilityCombo = ISComboBox:new(0, 0, 220, 26, window, nil)
    window.debugFacilityCombo:initialise()
    window.debugFacilityCombo:instantiate()
    pane:addChild(window.debugFacilityCombo)
    for _, action in ipairs(ACTIONS) do
        local button = UI.CreateButton(pane, {
            id = action.id,
            title = Shared.Tr(action.key, action.fallback),
            target = window,
            onclick = ISPNCColonyManagementWindow.onDebugControl,
            variant = action.id == "force_provision" and "selected" or "quiet",
        })
        window.debugControls[#window.debugControls + 1] = button
    end
    pane:setVisible(false)
end

function DebugTab.Apply(window, active)
    local pane = window.debugControlsPane
    if not pane or not window.layout then return end
    pane:setVisible(active == true)
    window.debugFacilityCombo:setVisible(active == true)
    if not active then return end
    local rect = window.layout.details
    local gap = Layout.Pixels(8, window.uiScale)
    local height = Layout.Pixels(126, window.uiScale)
    local detailHeight = math.max(80, rect.height - height - gap)
    window:layoutPane(window.detailsPane, rect.x, rect.y,
        rect.width, detailHeight)
    Layout.SetBounds(pane, rect.x, rect.y + detailHeight + gap,
        rect.width, height)
    Layout.SetBounds(window.debugFacilityCombo,
        Layout.Pixels(8, window.uiScale), Layout.Pixels(8, window.uiScale),
        math.max(1, rect.width - Layout.Pixels(16, window.uiScale)),
        Layout.Pixels(27, window.uiScale))
    Layout.Flow(window.debugControls, {
        x = Layout.Pixels(8, window.uiScale),
        y = Layout.Pixels(42, window.uiScale),
        width = math.max(1, rect.width - Layout.Pixels(16, window.uiScale)),
    }, { scale = window.uiScale, minWidth = 132, gap = 6 })
end

local function syncFacilities(window, snapshot)
    local combo = window and window.debugFacilityCombo
    if not combo then return end
    local previous = combo:getOptionData(combo.selected)
    local previousId = previous and previous.key
    combo:clear()
    local selected = 1
    local facilities = snapshot and snapshot.settlement
        and snapshot.settlement.facilities or {}
    local optionIndex = 0
    for _, facility in ipairs(facilities) do
        local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
        local facilityLabel = Shared.Tr(
            definition and definition.displayNameKey or "",
            facility.definitionId)
        local state = facility.cachedState or facility.constructionState
            or "UNKNOWN"
        local components = facility.components or {}
        table.sort(components, function(a, b)
            return tostring(a.id or "") < tostring(b.id or "")
        end)
        for _, component in ipairs(components) do
            optionIndex = optionIndex + 1
            local key = tostring(facility.id or "") .. ":"
                .. tostring(component.id or "")
            local role = tostring(component.role or component.kind or "component")
            combo:addOptionWithData(facilityLabel .. " • " .. role
                .. " • " .. tostring(component.id or "")
                .. " • " .. tostring(state), {
                    key = key, facility = facility, component = component,
                    facilityId = facility.id, componentId = component.id,
                })
            if key == previousId then selected = optionIndex end
        end
        if #components == 0 then
            optionIndex = optionIndex + 1
            local key = tostring(facility.id or "") .. ":none"
            combo:addOptionWithData(facilityLabel .. " • no live components"
                .. " • " .. tostring(state), {
                    key = key, facility = facility, component = nil,
                    facilityId = facility.id,
                })
            if key == previousId then selected = optionIndex end
        end
    end
    if #facilities == 0 then
        combo:addOptionWithData(Shared.Tr(
            "UI_PNC_Facility_None", "NO FACILITIES"), false)
    end
    combo.selected = selected
end

function DebugTab.BuildRows(person, snapshot, window)
    syncFacilities(window, snapshot)
    if not person then
        local selectLabel = Shared.Tr(
            "UI_PNC_ColonyDebug_Select", "Select a colonist"
        )
        local selectHelp = Shared.Tr("UI_PNC_ColonyDebug_SelectHelp",
            "Choose a colonist to inspect and simulate their needs.")
        return {{
            key = "debug_select",
            label = selectLabel,
            detail = selectHelp,
        }}
    end
    local rows = {}
    if person.facilityDebugWork then
        local work = person.facilityDebugWork
        local target = work.target or {}
        rows[#rows + 1] = {
            key = "debug_facility_work",
            label = Shared.Tr("UI_PNC_ColonyDebug_FacilityWorkState",
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
    for _, needType in ipairs(Shared.NEED_TYPES) do
        rows[#rows + 1] = {
            key = "debug_need_" .. needType,
            label = Shared.Tr(Shared.NEED_LABEL_KEYS[needType], needType),
            meter = true,
            value = tonumber(person.needs and person.needs[needType]) or 0,
            minimum = 0,
            maximum = 1,
            needType = needType,
            thresholds = Shared.NEED_METER_THRESHOLDS[needType],
        }
    end
    local storage = snapshot and snapshot.provisionStorage or {}
    local foodStorage = storage.food or {}
    local hydrationStorage = storage.hydration or {}
    local bandageStorage = storage.bandage or {}
    local storageFoodLabel = Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageFood", "Colony storage food")
    local storageHydrationLabel = Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageHydration", "Colony storage hydration")
    local storageMedicineLabel = Shared.Tr(
        "UI_PNC_ProvisionDebug_StorageMedicine", "Colony storage medicine")
    rows[#rows + 1] = {
        key = "debug_storage_food",
        label = storageFoodLabel,
        detail = string.format("hunger utility %.3f | calories %.0f | types %d",
            tonumber(foodStorage.amount) or 0,
            tonumber(foodStorage.calories) or 0,
            tonumber(foodStorage.candidateTypes) or 0),
        colorName = (tonumber(foodStorage.amount) or 0) > 0
            and "success" or "danger",
    }
    rows[#rows + 1] = {
        key = "debug_storage_hydration",
        label = storageHydrationLabel,
        detail = string.format("thirst utility %.3f | types %d",
            tonumber(hydrationStorage.amount) or 0,
            tonumber(hydrationStorage.candidateTypes) or 0),
    }
    rows[#rows + 1] = {
        key = "debug_storage_medicine",
        label = storageMedicineLabel,
        detail = string.format("usable bandages %.0f | types %d",
            tonumber(bandageStorage.amount) or 0,
            tonumber(bandageStorage.candidateTypes) or 0),
    }
    local evaluations = person.provision and person.provision.evaluations or {}
    local provisionLabel = Shared.Tr(
        "UI_PNC_ColonyDebug_ProvisionState", "Provision"
    )
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
        local lastActionLabel = Shared.Tr(
            "UI_PNC_ColonyDebug_LastAction", "Last action"
        )
        rows[#rows + 1] = {
            key = "debug_result",
            label = lastActionLabel,
            detail = tostring(result.reason or "unknown"),
            colorName = result.ok and "success" or "danger",
        }
        local grabLabel = Shared.Tr("UI_PNC_ProvisionDebug_Grab", "GRAB")
        for index, forceResult in ipairs(
            result.details and result.details.forceResults or {}
        ) do
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

function DebugTab.OnControl(window, button)
    local person = Shared.ListValue(window.people)
    if not person or not PNC.Client or not PNC.Client.RequestColonyAction then
        return false
    end
    local id = tostring(button and button.internal or "")
    local options = { npcID = person.id }
    if id == "hunger" or id == "thirst" or id == "fatigue" then
        options.operation = "modify"
        options.needType = id
        options.amount = 0.25
    elseif id == "reset" then
        options.operation = "reset"
    elseif id == "force_nearby_water" then
        options.operation = "force_nearby_water"
        return PNC.Client.RequestColonyAction("debug_need", options)
    elseif id == "force_provision" then
        options.operation = "force_provision"
    elseif id == "inspect_provision" then
        ProvisionDiagnostics.Open(person)
        return true
    elseif id == "facility_work" then
        local selection = window.debugFacilityCombo
            and window.debugFacilityCombo:getOptionData(
                window.debugFacilityCombo.selected) or nil
        if not selection or not selection.facility then return false end
        return PNC.Client.RequestColonyAction("debug_facility_work", {
            npcID = person.id, facilityId = selection.facilityId,
            componentId = selection.componentId, operation = "start",
        })
    elseif id == "facility_stop" then
        return PNC.Client.RequestColonyAction("debug_facility_work", {
            npcID = person.id, operation = "stop",
        })
    else
        return false
    end
    return PNC.Client.RequestColonyAction("debug_need", options)
end

return DebugTab
