require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Browser = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local TextLayout = UI.Layout

local STATE_COLORS = {
    OPERATIONAL = "success",
    NEEDS_ASSIGNMENT = "warning",
    UNDERSIZED = "warning",
    INVALID_COMPONENT = "danger",
    DISABLED = "textMuted",
    PLANNED = "accent",
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function stateText(state)
    return string.gsub(tostring(state or "PLANNED"), "_", " ")
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
    list:drawText(stateText(facility.cachedState), 18, y + 31,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(tostring(#(facility.components or {})) .. " COMPONENTS",
        18, y + 48, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function drawComponent(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local color = Theme.colors[row.complete and "success" or "warning"]
    local indent = row.child and 26 or 10
    if not row.child then
        list:drawRect(8, y + 9, 3, list.itemheight - 18,
            color.a, color.r, color.g, color.b)
    end
    list:drawText(TextLayout.Ellipsize(row.label or "COMPONENT", UIFont.Small,
        list:getWidth() - indent - 18), indent, y + 8,
        row.child and Theme.colors.textMuted.r or Theme.colors.text.r,
        row.child and Theme.colors.textMuted.g or Theme.colors.text.g,
        row.child and Theme.colors.textMuted.b or Theme.colors.text.b,
        1, UIFont.Small)
    list:drawText(TextLayout.Ellipsize(row.detail or "", UIFont.Small,
        list:getWidth() - indent - 18), indent, y + 29,
        row.child and Theme.colors.accent.r or color.r,
        row.child and Theme.colors.accent.g or color.g,
        row.child and Theme.colors.accent.b or color.b,
        1, UIFont.Small)
    return y + list.itemheight
end

local function roleLabel(role)
    local labels = {
        ["sleep.area"] = "SLEEPING AREA",
        ["sleep.bed"] = "SLEEP SPOTS",
        ["farm.field"] = "CULTIVATED FIELDS",
        ["work.research"] = "RESEARCH STATION",
        ["work.craft"] = "CRAFT STATION",
        ["work.disassemble"] = "DISASSEMBLY STATION",
    }
    return labels[role] or string.upper(string.gsub(role, "[%.]", " "))
end

local function componentDetail(component)
    if component.kind == "anchor" then
        return roleLabel(component.role) .. "  •  " .. tostring(component.x) .. ", "
            .. tostring(component.y) .. "  FLOOR " .. tostring(component.z)
    end
    return tostring(component.tileCount or 0) .. " TILES  •  ZONED AREA"
end

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
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local roles = {}
    local role
    for role, _ in pairs(level and level.componentLimits or {}) do
        roles[#roles + 1] = role
    end
    table.sort(roles)
    local roleIndex
    for roleIndex = 1, #roles do
        role = roles[roleIndex]
        local limit = level.componentLimits[role]
        local assigned = {}
        local index
        for index = 1, #(facility.components or {}) do
            local component = facility.components[index]
            if component.role == role then assigned[#assigned + 1] = component end
        end
        local minimum = tonumber(limit.minCount) or 0
        list:addItem(role, {
            label = roleLabel(role),
            detail = tostring(#assigned) .. " / "
                .. tostring(limit.maxCount or math.max(minimum, #assigned))
                .. (#assigned >= minimum and "  READY" or "  REQUIRED"),
            complete = #assigned >= minimum,
        })
        for index = 1, #assigned do
            list:addItem(assigned[index].id, {
                label = "- " .. roleLabel(role) .. " #" .. tostring(index),
                detail = componentDetail(assigned[index]),
                child = true,
                complete = true,
            })
        end
    end
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
        facility.displayName = tr(definition and definition.displayNameKey or "",
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
