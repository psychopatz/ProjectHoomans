require "ISUI/ISPanel"
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
    { id = "hydration", key = "UI_PNC_ColonyDebug_AddThirst",
        fallback = "INCREASE THIRST +25%" },
    { id = "fatigue", key = "UI_PNC_ColonyDebug_AddFatigue",
        fallback = "INCREASE FATIGUE +25%" },
    { id = "reset", key = "UI_PNC_ColonyDebug_Reset",
        fallback = "RESET NEEDS" },
    { id = "force_provision", key = "UI_PNC_ColonyDebug_Provision",
        fallback = "FORCE GRAB PROVISIONS" },
    { id = "inspect_provision", key = "UI_PNC_ColonyDebug_InspectProvision",
        fallback = "PROVISION DIAGNOSTICS" },
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
    if not active then return end
    local rect = window.layout.details
    local gap = Layout.Pixels(8, window.uiScale)
    local height = Layout.Pixels(84, window.uiScale)
    local detailHeight = math.max(80, rect.height - height - gap)
    window:layoutPane(window.detailsPane, rect.x, rect.y,
        rect.width, detailHeight)
    Layout.SetBounds(pane, rect.x, rect.y + detailHeight + gap,
        rect.width, height)
    Layout.Flow(window.debugControls, {
        x = Layout.Pixels(8, window.uiScale),
        y = Layout.Pixels(8, window.uiScale),
        width = math.max(1, rect.width - Layout.Pixels(16, window.uiScale)),
    }, { scale = window.uiScale, minWidth = 132, gap = 6 })
end

function DebugTab.BuildRows(person, snapshot)
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
    if result and result.action == "debug_need" then
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
    if id == "hunger" or id == "hydration" or id == "fatigue" then
        options.operation = "modify"
        options.needType = id
        options.amount = 0.25
    elseif id == "reset" then
        options.operation = "reset"
    elseif id == "force_provision" then
        options.operation = "force_provision"
    elseif id == "inspect_provision" then
        ProvisionDiagnostics.Open(person)
        return true
    else
        return false
    end
    return PNC.Client.RequestColonyAction("debug_need", options)
end

return DebugTab
