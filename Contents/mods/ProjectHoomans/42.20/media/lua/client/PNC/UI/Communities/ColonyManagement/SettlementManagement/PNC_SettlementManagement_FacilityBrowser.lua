require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local ComponentRows = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityComponentRows"

local Browser = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local TextLayout = UI.Layout
local ACTION_WIDTH = 92
local ACTION_HEIGHT = 27
local ACTION_RIGHT = 20
local SECONDARY_ACTION_WIDTH = 112
local RESUME_ACTION_WIDTH = 98
local ACTION_GAP = 6

local STATE_COLORS = {
    OPERATIONAL = "success",
    NEEDS_ASSIGNMENT = "warning",
    UNDERSIZED = "warning",
    INVALID_COMPONENT = "danger",
    DISABLED = "textMuted",
    PLANNED = "accent",
    UNDER_CONSTRUCTION = "warning",
    RECONSTRUCTING = "warning",
    DECONSTRUCTING = "danger",
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function stateText(state)
    return string.gsub(tostring(state or "PLANNED"), "_", " ")
end

local function progressText(task)
    if not task then return nil end
    return tostring(math.max(0, math.min(100,
        math.floor(tonumber(task.percent) or 0)))) .. "%"
end

local function drawFacility(list, y, entry, alternate)
    local facility = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local color = Theme.colors[STATE_COLORS[facility.cachedState] or "accent"]
    list:drawRect(6, y + 8, 4, list.itemheight - 16,
        color.a, color.r, color.g, color.b)
    list:drawText(TextLayout.Ellipsize(facility.displayName or "Facility",
        UIFont.Medium, list:getWidth() - 76), 18, y + 8,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Medium)
    list:drawText("L" .. tostring(facility.level or 1), list:getWidth() - 38,
        y + 9, Theme.colors.accent.r, Theme.colors.accent.g,
        Theme.colors.accent.b, Theme.colors.accent.a, UIFont.Small)
    local state = stateText(facility.cachedState)
    local progress = progressText(facility.activeTask)
    if progress then state = state .. "  •  " .. progress end
    list:drawText(state, 18, y + 31,
        color.r, color.g, color.b, color.a, UIFont.Small)
    local detail = tostring(#(facility.components or {})
        + #(facility.discoveredComponents or {})) .. " COMPONENTS"
    if facility.activeTask then
        detail = (facility.activeTask.funded
            and tr("UI_PNC_Work_MaterialsSupplied", "MATERIALS SUPPLIED")
                .. "  •  " or "")
            .. tostring(facility.activeTask.workerName
            or tr("UI_PNC_Tasks_Unassigned", "UNASSIGNED")) .. "  •  "
            .. stateText(facility.activeTask.executionMode
                or facility.activeTask.status)
    end
    list:drawText(detail,
        18, y + 48, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function drawComponent(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local color = Theme.colors[row.complete and "success" or "warning"]
    local iconSize = row.child and 28 or 34
    local iconX = row.child and 8 or 5
    local iconY = y + math.floor((list.itemheight - iconSize) / 2)
    if row.iconPath and getTexture then
        local icon = getTexture(row.iconPath)
        if icon then
            list:drawTextureScaledAspect(icon, iconX, iconY, iconSize,
                iconSize, 0.92, 1, 1, 1)
        end
    end
    local indent = row.child and 42 or 46
    local actionWidth = (row.componentAction and ACTION_WIDTH or 0)
        + (row.secondaryAction and SECONDARY_ACTION_WIDTH or 0)
        + (row.resumeAction and RESUME_ACTION_WIDTH or 0)
        + (row.componentAction and row.secondaryAction and ACTION_GAP or 0)
        + ((row.resumeAction and (row.componentAction or row.secondaryAction))
            and ACTION_GAP or 0)
        + ((row.componentAction or row.secondaryAction)
            and ACTION_RIGHT + 4 or 0)
        + (row.resumeAction and not (row.componentAction or row.secondaryAction)
            and ACTION_RIGHT + 4 or 0)
    if not row.child then
        list:drawRect(8, y + 9, 3, list.itemheight - 18,
            color.a, color.r, color.g, color.b)
    end
    list:drawText(TextLayout.Ellipsize(row.label or "COMPONENT", UIFont.Small,
        list:getWidth() - indent - 18 - actionWidth), indent, y + 8,
        row.child and Theme.colors.textMuted.r or Theme.colors.text.r,
        row.child and Theme.colors.textMuted.g or Theme.colors.text.g,
        row.child and Theme.colors.textMuted.b or Theme.colors.text.b,
        1, UIFont.Small)
    list:drawText(TextLayout.Ellipsize(row.detail or "", UIFont.Small,
        list:getWidth() - indent - 18 - actionWidth), indent, y + 29,
        row.child and Theme.colors.accent.r or color.r,
        row.child and Theme.colors.accent.g or color.g,
        row.child and Theme.colors.accent.b or color.b,
        1, UIFont.Small)
    local right = list:getWidth() - ACTION_RIGHT
    if row.resumeAction then
        local buttonX = right - RESUME_ACTION_WIDTH
        local buttonY = y + math.floor((list.itemheight - ACTION_HEIGHT) / 2)
        local accent = Theme.colors.success
        list:drawRect(buttonX, buttonY, RESUME_ACTION_WIDTH, ACTION_HEIGHT,
            0.72, 0.04, 0.08, 0.10)
        list:drawRectBorder(buttonX, buttonY, RESUME_ACTION_WIDTH,
            ACTION_HEIGHT, 0.95, accent.r, accent.g, accent.b)
        list:drawTextCentre(row.resumeActionLabel or "RESUME",
            buttonX + RESUME_ACTION_WIDTH / 2, buttonY + 6,
            accent.r, accent.g, accent.b, 1, UIFont.Small)
        right = buttonX - ((row.componentAction or row.secondaryAction)
            and ACTION_GAP or 0)
    end
    if row.secondaryAction then
        local buttonX = right - SECONDARY_ACTION_WIDTH
        local accent = Theme.colors.danger
        list:drawRect(buttonX, y + math.floor((list.itemheight - ACTION_HEIGHT) / 2),
            SECONDARY_ACTION_WIDTH, ACTION_HEIGHT, 0.72, 0.04, 0.08, 0.10)
        list:drawRectBorder(buttonX,
            y + math.floor((list.itemheight - ACTION_HEIGHT) / 2),
            SECONDARY_ACTION_WIDTH, ACTION_HEIGHT, 0.95,
            accent.r, accent.g, accent.b)
        list:drawTextCentre(row.secondaryActionLabel or "DECONSTRUCT",
            buttonX + SECONDARY_ACTION_WIDTH / 2,
            y + math.floor((list.itemheight - ACTION_HEIGHT) / 2) + 6,
            accent.r, accent.g, accent.b, 1, UIFont.Small)
        right = buttonX - (row.componentAction and ACTION_GAP or 0)
    end
    if row.componentAction then
        local buttonX = right - ACTION_WIDTH
        local buttonY = y + math.floor((list.itemheight - ACTION_HEIGHT) / 2)
        local accent = Theme.colors.accent
        list:drawRect(buttonX, buttonY, ACTION_WIDTH, ACTION_HEIGHT,
            0.72, 0.04, 0.08, 0.10)
        list:drawRectBorder(buttonX, buttonY, ACTION_WIDTH, ACTION_HEIGHT,
            0.95, accent.r, accent.g, accent.b)
        list:drawTextCentre(row.actionLabel or "ASSIGN",
            buttonX + ACTION_WIDTH / 2, buttonY + 6,
            accent.r, accent.g, accent.b, 1, UIFont.Small)
    end
    return y + list.itemheight
end

Browser.BuildComponentRows = ComponentRows.Build

function Browser.GetSelected(window)
    local list = window.baseFacilityList
    local entry = list and list.items and list.items[list.selected] or nil
    return entry and entry.item or nil
end

function Browser.RebuildComponents(window)
    local facility = Browser.GetSelected(window)
    local list = window.baseComponentList
    Components.SetRows(list, {})
    if not facility then
        list:addItem("empty", {
            label = tr("UI_PNC_Facility_NoSelection", "NO BUILDING SELECTED"),
            detail = tr("UI_PNC_Facility_NoSelectionHelp",
                "Build a facility to begin defining its rooms and stations."),
        })
        return
    end
    if facility.constructionState ~= nil
        and facility.constructionState ~= "BUILT"
    then
        local task = facility.activeTask
        if task then
            list:addItem("construction_progress", {
                label = tr("UI_PNC_Facility_ConstructionProgress",
                    "CONSTRUCTION PROGRESS") .. "  " .. progressText(task),
                detail = (tostring(task.workerName
                    or tr("UI_PNC_Tasks_Unassigned", "UNASSIGNED"))
                    .. "  •  " .. stateText(task.status)
                    .. "  •  " .. stateText(task.executionMode
                        or "EMULATED")
                    .. (task.funded and "  •  "
                        .. tr("UI_PNC_Work_MaterialsSupplied",
                            "MATERIALS SUPPLIED") or "")
                    .. (task.refundPercent and "  •  "
                        .. tostring(task.refundPercent) .. "% "
                        .. tr("UI_PNC_Work_Refundable",
                            "RECOVERABLE") or "")),
                complete = false,
                resumeAction = (task.status == "BLOCKED"
                    or task.status == "PAUSED"
                    or task.status == "WAITING_FOR_WORKER") and {
                        kind = "resume_work", workOrderId = task.id,
                    } or nil,
                resumeActionLabel = tr("UI_PNC_Work_Resume", "RESUME"),
                secondaryAction = { kind = "cancel_work", workOrderId = task.id,
                    refundPercent = task.refundPercent },
                secondaryActionLabel = tr("UI_PNC_Work_CancelConstruction",
                    "CANCEL CONSTRUCTION"),
            })
        end
        list:addItem("construction_locked", {
            label = tr("UI_PNC_Facility_ComponentsLocked",
                "COMPONENTS LOCKED"),
            detail = tr("UI_PNC_Facility_ComponentsLockedHelp",
                "Finish construction before assigning rooms or stations."),
            complete = false,
        })
        window.baseComponentPane:setHeader(
            string.upper(facility.displayName or facility.definitionId),
            stateText(facility.cachedState)
                .. (task and "  •  " .. progressText(task) or ""))
        return
    end
    Components.SetRows(list, Browser.BuildComponentRows(
        facility, window.snapshot and window.snapshot.storage))
    window.baseComponentPane:setHeader(
        string.upper(facility.displayName or facility.definitionId),
        stateText(facility.cachedState))
end

function Browser.Create(window)
    window.baseFacilityPane, window.baseFacilityList =
        Components.CreatePane(window, 70, drawFacility)
    window.baseComponentPane, window.baseComponentList =
        Components.CreatePane(window, 54, drawComponent)
    window.baseFacilityPane:setHeader("BUILDINGS", "0")
    window.baseComponentPane:setHeader("FACILITY INSPECTOR", "")
    window.baseFacilityList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        Browser.RebuildComponents(window)
        if window.updateBaseContextControls then
            window:updateBaseContextControls()
        end
    end
    window.baseComponentList.onMouseDown = function(list, x, y)
        local rowIndex = list:rowAt(x, y)
        local entry = rowIndex > 0 and list.items[rowIndex] or nil
        local row = entry and entry.item or nil
        if row then
            local right = list:getWidth() - ACTION_RIGHT
            if row.resumeAction then
                local resumeX = right - RESUME_ACTION_WIDTH
                if x >= resumeX and x <= right then
                    if window.onBaseComponentAction then
                        window:onBaseComponentAction(row.resumeAction)
                    end
                    return
                end
                right = resumeX - ((row.componentAction or row.secondaryAction)
                    and ACTION_GAP or 0)
            end
            if row.secondaryAction then
                local secondaryX = right - SECONDARY_ACTION_WIDTH
                if x >= secondaryX and x <= right then
                    if window.onBaseComponentAction then
                        window:onBaseComponentAction(row.secondaryAction)
                    end
                    return
                end
                right = secondaryX - (row.componentAction and ACTION_GAP or 0)
            end
            if row.componentAction and x >= right - ACTION_WIDTH
                and x <= right
            then
                if window.onBaseComponentAction then
                    window:onBaseComponentAction(row.componentAction)
                end
                return
            end
        end
        ISScrollingListBox.onMouseDown(list, x, y)
    end
end

function Browser.Layout(window, content, top, bottom)
    local gap = 10
    local width = math.max(210, math.floor(content.width * 0.34))
    local height = math.max(80, bottom - top)
    window:layoutPane(window.baseFacilityPane,
        content.x, top, width, height)
    window:layoutPane(window.baseComponentPane,
        content.x + width + gap, top,
        math.max(120, content.width - width - gap), height)
end

function Browser.Apply(window, active)
    window.baseFacilityPane:setVisible(active)
    window.baseComponentPane:setVisible(active)
end

function Browser.Rebuild(window, snapshot)
    local previous = Browser.GetSelected(window)
    local previousId = previous and previous.id or window.baseSelectedFacilityId
    local facilities = snapshot.settlement and snapshot.settlement.facilities or {}
    local rows = {}
    local selected = 1
    local index
    for index = 1, #facilities do
        local facility = facilities[index]
        local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
        facility.displayName = tr(facility.roomLabelKey
            or definition and definition.displayNameKey or "",
            facility.definitionId)
        rows[#rows + 1] = facility
        if facility.id == previousId then selected = index end
    end
    Components.SetRows(window.baseFacilityList, rows)
    window.baseFacilityList.selected = #rows > 0 and selected or 0
    window.baseFacilityPane:setHeader("BUILDINGS", tostring(#rows))
    Browser.RebuildComponents(window)
end

return Browser
