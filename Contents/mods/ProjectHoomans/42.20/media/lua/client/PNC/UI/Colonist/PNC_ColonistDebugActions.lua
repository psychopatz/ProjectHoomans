local ProvisionDiagnostics = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_ProvisionDiagnosticsModal"
local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"

local Actions = {}

local DEFINITIONS = {
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
    { id = "force_world_water", key = "UI_PNC_ColonyDebug_NearbyWater",
        fallback = "FORCE DRINK NEARBY WATER" },
    { id = "inspect_provision", key = "UI_PNC_ColonyDebug_InspectProvision",
        fallback = "PROVISION DIAGNOSTICS" },
    { id = "facility_work", key = "UI_PNC_ColonyDebug_FacilityWork",
        fallback = "SEND TO WORK FACILITY" },
    { id = "facility_stop", key = "UI_PNC_ColonyDebug_StopFacilityWork",
        fallback = "STOP FACILITY TEST" },
}

Actions.Definitions = DEFINITIONS

local function canUseDebug()
    local client = PNC and PNC.Client
    return client and type(client.CanUseDebug) == "function"
        and client.CanUseDebug() == true
end

function Actions.IsAvailable()
    return canUseDebug()
end

local function getComponent(window, component)
    if component then return component end
    if window and window.tabComponents then
        component = window.tabComponents.debug
    end
    return component or (window and window.debugComponent)
end

function Actions.SyncControls(window, component)
    component = getComponent(window, component)
    local person = Shared.ListValue(window.people)
    local enabled = canUseDebug() and person ~= nil
        and person.alive ~= false
    for _, button in ipairs(component and component.controls or {}) do
        if button.setEnable then button:setEnable(enabled) end
    end
end

function Actions.OnControl(window, button, component)
    if not canUseDebug() then return false end
    local person = Shared.ListValue(window.people)
    local client = PNC and PNC.Client
    if not person or not client or not client.RequestColonyAction then
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
    elseif id == "force_world_water" then
        options.operation = "force_world_water"
        return client.RequestColonyAction("debug_need", options)
    elseif id == "force_provision" then
        options.operation = "force_provision"
    elseif id == "inspect_provision" then
        return ProvisionDiagnostics.Open(person) ~= nil
    elseif id == "facility_work" then
        component = getComponent(window, component)
        local combo = component and component.facilityCombo
        local selection = combo and combo:getOptionData(combo.selected) or nil
        if not selection or not selection.facility then return false end
        return client.RequestColonyAction("debug_facility_work", {
            npcID = person.id,
            facilityId = selection.facilityId,
            componentId = selection.componentId,
            operation = "start",
        })
    elseif id == "facility_stop" then
        return client.RequestColonyAction("debug_facility_work", {
            npcID = person.id, operation = "stop",
        })
    else
        return false
    end
    return client.RequestColonyAction("debug_need", options)
end

return Actions
