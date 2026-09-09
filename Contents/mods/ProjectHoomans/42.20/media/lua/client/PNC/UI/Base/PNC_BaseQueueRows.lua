require "PsychopatzCore/UI/PsychopatzUI"

local QueueRows = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function stateText(value)
    return string.upper(string.gsub(tostring(value or "QUEUED"), "_", " "))
end

local function progressText(task)
    if not task then return "0%" end
    return tostring(math.max(0, math.min(100,
        math.floor(tonumber(task.percent) or 0)))) .. "%"
end

function QueueRows.ActionWidth(row)
    if row.kind == "native" then return 105 end
    local task = row.task or {}
    local resume = task.status == "BLOCKED"
        or task.status == "PAUSED"
        or task.status == "WAITING_FOR_WORKER"
    return resume and 216 or 112
end

function QueueRows.Draw(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local accent = row.kind == "native" and Theme.colors.accent
        or Theme.colors.warning
    local titleWidth = math.max(80, list:getWidth()
        - QueueRows.ActionWidth(row) - 24)
    list:drawText(Layout.Ellipsize(row.title or tr(
        "UI_PNC_Base_BuildingProject", "BUILDING PROJECT"),
        UIFont.Small, titleWidth), 16, y + 7,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.worker or
        tr("UI_PNC_Tasks_Unassigned", "UNASSIGNED"),
        UIFont.Small, titleWidth), 16, y + 28,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    local right = list:getWidth() - 12
    local actionWidth = QueueRows.ActionWidth(row)
    local actionX = right - actionWidth
    local progress = progressText(row.task or row.order)
        .. "  " .. stateText((row.task or row.order or {}).status)
    list:drawTextRight(progress, actionX - 8, y + 18,
        accent.r, accent.g, accent.b, accent.a or 1, UIFont.Small)
    if row.kind ~= "native" and row.task then
        local resumable = row.task.status == "BLOCKED"
            or row.task.status == "PAUSED"
            or row.task.status == "WAITING_FOR_WORKER"
        if resumable then
            local resumeWidth = 98
            local resumeX = right - 105 - resumeWidth
            list:drawRectBorder(resumeX, y + 8, resumeWidth, 27,
                0.9, Theme.colors.success.r, Theme.colors.success.g,
                Theme.colors.success.b)
            list:drawTextCentre(tr("UI_PNC_Work_Resume", "RESUME"),
                resumeX + resumeWidth / 2, y + 14,
                Theme.colors.success.r, Theme.colors.success.g,
                Theme.colors.success.b, 1, UIFont.Small)
        end
    end
    list:drawRectBorder(actionX, y + 8, actionWidth, 27, 0.9,
        Theme.colors.danger.r, Theme.colors.danger.g,
        Theme.colors.danger.b)
    list:drawTextCentre(row.kind == "native"
        and tr("UI_PNC_Building_CancelOrder", "CANCEL ORDER")
        or tr("UI_PNC_Work_CancelConstruction", "CANCEL CONSTRUCTION"),
        actionX + actionWidth / 2, y + 14,
        Theme.colors.danger.r, Theme.colors.danger.g,
        Theme.colors.danger.b, 1, UIFont.Small)
    return y + list.itemheight
end

return QueueRows
