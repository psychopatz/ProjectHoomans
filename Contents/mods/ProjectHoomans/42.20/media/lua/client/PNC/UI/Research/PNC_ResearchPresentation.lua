require "PsychopatzCore/UI/PsychopatzUI"

local Presentation = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local STATUS = {
    known = { key = "UI_PNC_Research_Status_Learned", fallback = "LEARNED",
        color = "success" },
    active = { key = "UI_PNC_Research_Status_Active", fallback = "ACTIVE",
        color = "accent" },
    locked = { key = "UI_PNC_Research_Status_Locked", fallback = "LOCKED",
        color = "warning" },
    unavailable = { key = "UI_PNC_Research_Status_Unavailable",
        fallback = "NO RESEARCH TABLE", color = "warning" },
    available = { key = "UI_PNC_Research_Status_Available", fallback = "AVAILABLE",
        color = "accent" },
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function color(name)
    return Theme.colors[name] or Theme.colors.text
end

local function sourceLabel(source)
    if source == "blueprint" then
        return tr("UI_PNC_Research_Source_Blueprint", "BLUEPRINT")
    end
    if source == "book" then
        return tr("UI_PNC_Research_Source_Book", "BOOK")
    end
    return tr("UI_PNC_Research_Source_Technology", "TECHNOLOGY")
end

local function statusLabel(item)
    local definition = STATUS[item.status] or STATUS.unavailable
    local value = tr(definition.key, definition.fallback)
    if item.status == "active" and item.progress ~= nil then
        value = value .. " " .. tostring(item.progress) .. "%"
    end
    return value, definition.color
end

local function drawRight(list, value, right, y, colorName)
    local font = Theme.Font(list.uiScale)
    local text = tostring(value or "")
    local width = Theme.TextWidth(font, text)
    local colour = color(colorName)
    list:drawText(text, math.max(8, right - width), y,
        colour.r, colour.g, colour.b, colour.a, font)
    return width
end

function Presentation.DrawCatalogRow(list, y, entry, alternate)
    local row = entry.item or {}
    local font = Theme.Font(list.uiScale)
    local height = list.itemheight
    if row.kind == "group" then
        local group = row.group or {}
        local background = Theme.colors.surfaceRaised
        list:drawRect(0, y, list:getWidth(), height, 0.62,
            background.r, background.g, background.b)
        local accent = Theme.colors.accent
        list:drawRect(0, y, 3, height, 1, accent.r, accent.g, accent.b)
        local marker = group.collapsed and ">" or "v"
        list:drawText(marker .. "  " .. tostring(group.title or ""),
            12, y + 8, accent.r, accent.g, accent.b, accent.a, font)
        local count = tostring(group.knownCount or 0) .. "/"
            .. tostring(group.totalCount or 0)
        local suffix = group.activeCount and group.activeCount > 0
            and (count .. "  |  " .. tostring(group.activeCount) .. " ACTIVE")
            or count
        drawRight(list, suffix, list:getWidth() - 10, y + 8, "textMuted")
        return y + height
    end

    UI.DrawListSelection(list, y, height, row.selected == true, alternate)
    local status, statusColor = statusLabel(row)
    local badgeWidth = UI.DrawBadge(list, status,
        list:getWidth() - 8, y + 6, statusColor)
    local right = list:getWidth() - badgeWidth - 18
    local name = Layout.Ellipsize(row.name, font, math.max(90, right - 16))
    local textColor = row.status == "known" and Theme.colors.textMuted
        or Theme.colors.text
    list:drawText(name, 14, y + 6, textColor.r, textColor.g,
        textColor.b, textColor.a, font)
    local detail = sourceLabel(row.source)
    if row.quantity and row.source ~= "technology" then
        detail = detail .. "  |  x" .. tostring(row.quantity)
    elseif row.requiredWork and row.requiredWork > 0 then
        detail = detail .. "  |  " .. tostring(row.requiredWork) .. " WORK"
    end
    list:drawText(Layout.Ellipsize(detail, font, list:getWidth() - 28),
        14, y + 27, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, font)
    return y + height
end

function Presentation.DrawQueueRow(list, y, entry, alternate)
    local row = entry.item or {}
    local queue = row.queue or {}
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, row.selected == true, alternate)
    local font = Theme.Font(list.uiScale)
    local progress = tostring(queue.progress or 0) .. "%"
    local progressWidth = drawRight(list, progress, list:getWidth() - 10,
        y + 7, "accent")
    local available = math.max(80, list:getWidth() - progressWidth - 28)
    list:drawText(Layout.Ellipsize(queue.name, font, available), 12, y + 7,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, font)
    local worker = queue.workerName or queue.workerId
        and tostring(queue.workerId)
        or tr("UI_PNC_Research_Unassigned", "UNASSIGNED")
    list:drawText(Layout.Ellipsize(sourceLabel(queue.source) .. "  |  " .. worker,
        font, list:getWidth() - 24), 12, y + 26,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, font)
    return y + height
end

function Presentation.DrawSummary(window, view)
    if not window.layout or not view then return end
    local rect = window.layout.summary
    UI.DrawSurface(window, rect.x, rect.y, rect.width, rect.height,
        true, window.contentOpacity)
    local summary = view.summary or {}
    local title = tr("UI_PNC_Research_WindowTitle", "COLONY RESEARCH")
    window:drawText(title, rect.x + 14, rect.y + 10,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, Theme.Font(window.uiScale, "title"))
    -- PZ's getText formatter is not safe for Java-style numeric placeholders
    -- in this runtime. Keep the numbers in Lua and translate only the labels.
    local subtitle = tostring(summary.known or 0) .. " / "
        .. tostring(summary.total or 0) .. " "
        .. tr("UI_PNC_Research_Status_Learned", "LEARNED") .. "  |  "
        .. tostring(summary.available or 0) .. " "
        .. tr("UI_PNC_Research_Status_Available", "AVAILABLE") .. "  |  "
        .. tostring(summary.active or 0) .. " "
        .. tr("UI_PNC_Research_Status_Active", "ACTIVE")
    window:drawText(Layout.Ellipsize(subtitle, Theme.Font(window.uiScale),
        math.max(100, rect.width - 28)), rect.x + 14, rect.y + 34,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a,
        Theme.Font(window.uiScale))
    local status = view.stationAvailable
        and tr("UI_PNC_Research_TableReady", "RESEARCH TABLE READY")
        or tr("UI_PNC_Research_TableMissing", "RESEARCH TABLE REQUIRED")
    drawRight(window, status, rect.x + rect.width - 14, rect.y + 20,
        view.stationAvailable and "success" or "warning")
end

return Presentation
