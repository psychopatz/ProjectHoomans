local Activities = require "PNC/UI/Colonist/PNC_ColonistActivities_Core"
local Internal = Activities.Internal or {}
local Presentation = Internal.Presentation
local Selector = Internal.Selector
local Shared = Internal.Shared
local UI = Internal.UI
local Layout = Internal.Layout
local DEFINITIONS = Internal.Definitions
local active = Internal.active

local function getComponent(window, component)
    if component then return component end
    if window and window.tabComponents then
        component = window.tabComponents.activities
    end
    return component or (window and window.activityComponent)
end

local function syncControls(window, component)
    component = getComponent(window, component)
    if not component then return end
    local person = Selector.GetSelected(window.people)
    for _, definition in ipairs(DEFINITIONS) do
        local button = component.controls[definition.id]
        local state
        if definition.presentation then
            state = definition.presentation(person, definition)
        else
            local isActive = active(definition, person)
            local title = Shared.Tr(definition.key, definition.fallback)
            if definition.id == "manual_sleep" then
                title = title .. ": " .. Shared.Tr(
                    isActive and "UI_PNC_MonitorOn" or "UI_PNC_MonitorOff",
                    isActive and "ON" or "OFF")
            elseif isActive then
                title = title .. " (" .. Shared.Tr(
                    "UI_PNC_MonitorActive", "active") .. ")"
            end
            state = {
                title = title,
                enabled = person ~= nil and person.alive ~= false,
                variant = isActive and "selected" or "default",
            }
        end
        -- setEnable snapshots the enabled colours, so it has to run before any
        -- variant restyle; otherwise ISButton restores stale colours on the next
        -- enable and the button keeps looking disabled.
        button:setEnable(state.enabled == true)
        if definition.toggle and type(button.setToggleState) == "function" then
            -- The core toggle control owns the label swap and each state's
            -- variant; the panel only feeds it the current state. Labels are
            -- re-resolved here so a language change reaches the button too.
            if type(button.setToggleLabels) == "function" then
                button:setToggleLabels(
                    Shared.Tr(definition.offTitleKey,
                        definition.offTitleFallback),
                    Shared.Tr(definition.onTitleKey,
                        definition.onTitleFallback))
            end
            button:setToggleState(state.toggleState == true)
        else
            if button.setTitle then
                button:setTitle(state.title)
            else
                button.title = state.title
            end
            UI.SetButtonVariant(button, state.variant or "default")
        end
        -- A disabled toggle always reads as unavailable, whichever variant its
        -- own state setter just applied.
        if definition.toggle and state.enabled ~= true then
            UI.SetButtonVariant(button, "quiet")
        end
        if button.setTooltip then
            button:setTooltip(state.tooltip)
        else
            button.tooltip = state.tooltip
        end
    end
end

local function gridOptions(window, width)
    local scale = window.uiScale or Layout.Scale()
    local available = math.max(1, tonumber(width) or 1)
    return {
        scale = scale,
        columns = available >= Layout.Pixels(460, scale) and 2 or 1,
        gap = 8,
        rowGap = 8,
        height = 34,
        stretchLastRow = true,
    }
end

-- The inventory control sits outside the command grid so it can be full width
-- and taller than a command cell, which keeps it visually separate from the
-- orders above it.
local SEPARATE_CONTROL_HEIGHT = 48
local SEPARATE_CONTROL_GAP = 8

local function separateControls(component)
    return component and component.separateList or nil
end

local function separateHeight(component, options)
    local list = separateControls(component)
    local count = list and #list or 0
    if count <= 0 then return 0 end
    local height = Layout.Pixels(SEPARATE_CONTROL_HEIGHT, options.scale)
    local gap = Layout.Pixels(SEPARATE_CONTROL_GAP, options.scale)
    return (count * height) + ((count - 1) * gap)
end

--[[
    Places the standalone controls below the grid. `gridTop` plus the grid's own
    height gives the first available row.
]]
local function layoutSeparateControls(component, options, width, gridBottom)
    local list = separateControls(component)
    if not list or #list == 0 then return end
    local scale = options.scale
    local height = Layout.Pixels(SEPARATE_CONTROL_HEIGHT, scale)
    local gap = Layout.Pixels(SEPARATE_CONTROL_GAP, scale)
    local y = gridBottom + gap
    for index = 1, #list do
        Layout.SetBounds(list[index], 0, y, math.max(1, width), height)
        y = y + height + gap
    end
end

local function controlsHeight(window, width, component)
    component = getComponent(window, component)
    if not component then return 0 end
    local options = gridOptions(window, width)
    local header = Layout.Pixels(25, options.scale)
    local top = header + Layout.Pixels(8, options.scale)
    local result = Layout.Grid(component.controlList, {
        x = 0,
        y = top,
        width = math.max(1, tonumber(width) or 1),
        height = 1,
    }, options) or {}
    local gridHeight = tonumber(result.height) or 0
    local extra = separateHeight(component, options)
    if extra > 0 then
        extra = extra + Layout.Pixels(SEPARATE_CONTROL_GAP, options.scale)
    end
    return top + gridHeight + extra
end


Internal.getComponent = getComponent
Internal.syncControls = syncControls
Internal.gridOptions = gridOptions
Internal.separateControls = separateControls
Internal.separateHeight = separateHeight
Internal.layoutSeparateControls = layoutSeparateControls
Internal.controlsHeight = controlsHeight

return Activities
