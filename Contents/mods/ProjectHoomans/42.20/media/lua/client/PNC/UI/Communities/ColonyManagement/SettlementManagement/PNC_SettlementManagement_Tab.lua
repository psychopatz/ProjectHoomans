require "PsychopatzCore/UI/PsychopatzUI"

local Actions = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Actions"
local Browser = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityBrowser"
local LayoutOverlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"

local Tab = {}
local UI = PsychopatzCore.UI

local TOOLBAR = {
    { "claim", "UI_PNC_Base_ClaimAction", "CLAIM TERRITORY", "success" },
    { "overlay", "UI_PNC_Base_ShowLayout", "SHOW BASE LAYOUT", "selected" },
    { "fishing_zone", "UI_PNC_Fishing_ZoneAction", "CREATE FISHING ZONE", "primary" },
    { "build_facility", "UI_PNC_Facility_BuildAction", "BUILD A BUILDING", "success" },
    { "expand", "UI_PNC_Base_ExpandAction", "EXPAND", "primary" },
    { "shrink", "UI_PNC_Base_ShrinkAction", "SHRINK", "warning" },
    { "barricade", "UI_PNC_Base_BarricadeAction", "REINFORCE", "primary" },
    { "hq", "UI_PNC_Base_UpgradeAction", "UPGRADE HQ", "primary" },
}

local CONTEXT = {
    { "facility_upgrade", "UI_PNC_Facility_Upgrade", "UPGRADE BUILDING", "success" },
    { "facility_cancel_construction", "UI_PNC_Work_CancelConstruction", "CANCEL CONSTRUCTION", "danger" },
    { "facility_destroy", "UI_PNC_Facility_Destroy", "DECONSTRUCT", "danger" },
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function createButtons(window, definitions, destination)
    local index
    for index = 1, #definitions do
        local definition = definitions[index]
        local button = UI.CreateButton(window, {
            id = definition[1],
            title = tr(definition[2], definition[3]),
            target = window,
            onclick = ISPNCColonyManagementWindow.onBaseControl,
            variant = definition[4],
        })
        destination[#destination + 1] = button
        destination[definition[1]] = button
        window.baseControls[#window.baseControls + 1] = button
        window.baseControls[definition[1]] = button
    end
end

local function updateOverlayButton(window)
    local button = window.baseControls and window.baseControls.overlay
    if not button then return end
    local enabled = LayoutOverlay.IsEnabled()
    button:setTitle(enabled
        and tr("UI_PNC_Base_HideLayout", "HIDE BASE LAYOUT")
        or tr("UI_PNC_Base_ShowLayout", "SHOW BASE LAYOUT"))
    UI.SetButtonVariant(button, enabled and "warning" or "selected")
end

function Tab.UpdateContextControls(window)
    local facility = Browser.GetSelected(window)
    local active = window.tab == "base" and facility ~= nil
    local built = active and (facility.constructionState == nil
        or facility.constructionState == "BUILT")
    local index
    for index = 1, #(window.baseContextControls or {}) do
        local button = window.baseContextControls[index]
        local visible = active and ((built
            and button.internal ~= "facility_cancel_construction")
            or (not built
                and button.internal == "facility_cancel_construction"
                and facility.constructionWorkOrderId ~= nil))
        if active and facility.definitionId == "stockpile"
            and button.internal == "facility_destroy"
        then
            visible = false
        end
        if button.internal == "facility_anchor" then
            local role = active and Actions.NextAnchorRole
                and Actions.NextAnchorRole(facility) or nil
            visible = visible and role ~= nil
            if visible then button:setTitle(Actions.AnchorAssignLabel(role)) end
        elseif button.internal == "facility_area" then
            visible = visible and Actions.AreaRole
                and Actions.AreaRole(facility) ~= nil
        end
        button:setVisible(visible)
    end
end

function Tab.Create(window)
    window.baseControls = {}
    window.baseToolbarControls = {}
    window.baseContextControls = {}
    createButtons(window, TOOLBAR, window.baseToolbarControls)
    createButtons(window, CONTEXT, window.baseContextControls)
    Browser.Create(window)
    window.onBaseComponentAction = function(self, action)
        return Actions.HandleComponent(self, action,
            Browser.GetSelected(self))
    end
    window.updateBaseContextControls = function(self)
        Tab.UpdateContextControls(self)
    end
end

local function layoutButtonRow(buttons, content, y)
    local gap = 6
    local minimum = 118
    local columns = math.max(2,
        math.min(#buttons, math.floor((content.width + gap) / (minimum + gap))))
    local width = math.floor((content.width - gap * (columns - 1)) / columns)
    local index
    for index = 1, #buttons do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local button = buttons[index]
        button:setX(content.x + column * (width + gap))
        button:setY(y + row * 33)
        button:setWidth(width)
        button:setHeight(27)
    end
    return y + math.ceil(#buttons / columns) * 33
end

function Tab.Layout(window, _, content)
    local browserTop = layoutButtonRow(window.baseToolbarControls, content, content.y) + 3
    local contextY = content.y + content.height - 29
    local count = #window.baseContextControls
    local gap = 6
    local width = math.floor((content.width - gap * (count - 1)) / count)
    local index
    for index = 1, count do
        local button = window.baseContextControls[index]
        button:setX(content.x + (index - 1) * (width + gap))
        button:setY(contextY)
        button:setWidth(width)
        button:setHeight(27)
    end
    Browser.Layout(window, content, browserTop, contextY - 8)
end

function Tab.Apply(window, active)
    local established = window.snapshot and window.snapshot.settlement ~= nil
    local index
    for index = 1, #window.baseToolbarControls do
        local button = window.baseToolbarControls[index]
        button:setVisible(active and (
            button.internal == "claim" and not established
            or button.internal ~= "claim" and established))
        if active and established and button.internal == "hq"
        then
            local current = math.max(1,
                tonumber(window.snapshot.settlement.hqLevel) or 1)
            local maximum = math.max(current, tonumber(
                window.snapshot.settlement.maxHQLevel) or current)
            local technologyId = button.internal .. ":" .. tostring(current + 1)
            local learned = false
            for _, entry in ipairs(window.snapshot.research
                and window.snapshot.research.entries or {})
            do
                if entry.id == technologyId and entry.known == true then
                    learned = true; break
                end
            end
            button:setEnable(current < maximum and learned)
        end
        if active and established and button.internal == "fishing_zone" then
            button:setEnable(window.selectedPersonID ~= nil)
        end
    end
    Browser.Apply(window, active and established)
    Tab.UpdateContextControls(window)
end

function Tab.Rebuild(window, snapshot)
    LayoutOverlay.SetSettlement(snapshot.settlement)
    Browser.Rebuild(window, snapshot)
    updateOverlayButton(window)
    Tab.UpdateContextControls(window)
    return true
end

function Tab.OnControl(window, button)
    local handled = Actions.Handle(window, button and button.internal,
        Browser.GetSelected(window))
    updateOverlayButton(window)
    return handled
end

return Tab
