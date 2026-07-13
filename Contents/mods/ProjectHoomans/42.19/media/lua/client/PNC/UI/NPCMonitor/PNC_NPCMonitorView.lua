require "PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"

PNC.NPCMonitorView = PNC.NPCMonitorView or {}

local View = PNC.NPCMonitorView
local Support = PNC.NPCMonitorSupport
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

View.Filters = { "All", "Live", "Abstract", "Corpse", "Problems" }

function View.DrawRosterItem(list, y, entry, alternate)
    local item = entry.item
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, list.selected == entry.index, alternate)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    UI.DrawBadge(list, item.presenceState or "unknown", list:getWidth() - 10, y + 5, Support.PresenceColor(item))
    local name = Layout.Ellipsize(item.name or item.id or "Unknown NPC", UIFont.Medium, math.max(40, list:getWidth() - 126))
    list:drawText(name, 11, y + 5, text.r, text.g, text.b, text.a, UIFont.Medium)
    local summary = string.format("%s  •  %s  •  HP %d/%d",
        string.upper(tostring(item.faction or "?")),
        tostring(item.bodyState or "unknown"),
        math.floor(tonumber(item.hpCurrent) or 0),
        math.floor(tonumber(item.hpMax) or 0))
    summary = Layout.Ellipsize(summary, UIFont.Small, list:getWidth() - 22)
    list:drawText(summary, 11, y + 28, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + height
end

function View.DrawDetailItem(list, y, entry, alternate)
    local item = entry.item
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, false, alternate)
    local muted = Theme.colors.textMuted
    local text = Theme.colors[item.tone or "text"] or Theme.colors.text
    local labelWidth = math.min(128, math.floor(list:getWidth() * 0.31))
    local valueX = 12 + labelWidth
    local valueWidth = math.max(30, list:getWidth() - valueX - 12)
    list:drawText(tostring(item.label or ""), 12, y + 7, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(item.value, UIFont.Small, valueWidth), valueX, y + 7, text.r, text.g, text.b, text.a, UIFont.Small)
    return y + height
end

local function createToolbarButton(window, definition, collection)
    local button = UI.CreateButton(window, definition)
    collection[#collection + 1] = button
    return button
end

function View.CreateChildren(window)
    window.filterButtons = {}
    window.topControls = {}
    window.footerControls = {}
    for _, filter in ipairs(View.Filters) do
        local button = createToolbarButton(window, {
            id = filter, title = filter, target = window, onclick = ISPNCNPCMonitor.onFilter,
            variant = filter == window.filter and "selected" or "quiet",
        }, window.topControls)
        window.filterButtons[filter] = button
    end
    window.focus = createToolbarButton(window, {
        id = "focus", title = Support.Tr("UI_PNC_MonitorFocus", "Focus"), target = window,
        onclick = ISPNCNPCMonitor.onFocus,
    }, window.topControls)
    window.teleport = createToolbarButton(window, {
        id = "teleport", title = Support.Tr("UI_PNC_MonitorTeleport", "Teleport"), target = window,
        onclick = ISPNCNPCMonitor.onTeleport,
    }, window.topControls)
    window.list = UI.CreateList(window, { itemHeight = Layout.Pixels(50, window.uiScale), doDrawItem = View.DrawRosterItem })
    window.details = UI.CreateList(window, { itemHeight = Layout.Pixels(28, window.uiScale), doDrawItem = View.DrawDetailItem })

    local actions = {
        { "force_live", "UI_PNC_MonitorForceLive", "Force Live", ISPNCNPCMonitor.onAction, "success" },
        { "force_abstract", "UI_PNC_MonitorForceAbstract", "Force Abstract", ISPNCNPCMonitor.onAction, "warning" },
        { "heal", "UI_PNC_MonitorHeal", "Heal", ISPNCNPCMonitor.onAction, "success" },
        { "damage", "UI_PNC_MonitorDamage", "Damage", ISPNCNPCMonitor.onAction, "danger" },
        { "toggle_debug", "UI_PNC_MonitorRecordDebug", "Record Debug", ISPNCNPCMonitor.onAction, "default" },
        { "audit", "UI_PNC_MonitorAuditBodies", "Audit Bodies", ISPNCNPCMonitor.onAudit, "warning" },
        { "refresh", "UI_PNC_MonitorRefresh", "Refresh", ISPNCNPCMonitor.onRefresh, "quiet" },
        { "overlay", "UI_PNC_MonitorToggleOverlay", "Toggle Overlay", ISPNCNPCMonitor.onOverlay, "quiet" },
        { "paths", "UI_PNC_MonitorTogglePaths", "Toggle Paths", ISPNCNPCMonitor.onPathOverlay, "quiet" },
    }
    window.selectionControls = {}
    for _, action in ipairs(actions) do
        local variant = action[5]
        if action[1] == "paths"
            and PNC.Nameplates
            and PNC.Nameplates.IsPathDebugEnabled
            and PNC.Nameplates.IsPathDebugEnabled()
        then
            variant = "selected"
        end
        local button = createToolbarButton(window, {
            id = action[1], title = Support.Tr(action[2], action[3]), target = window,
            onclick = action[4], variant = variant,
        }, window.footerControls)
        if action[1] == "paths" then window.pathOverlayButton = button end
        if action[1] ~= "audit" and action[1] ~= "refresh" and action[1] ~= "overlay" and action[1] ~= "paths" then
            window.selectionControls[#window.selectionControls + 1] = button
        end
    end
end

function View.Layout(window)
    if not window.list or not window.details then return end
    local rect = window:getContentRect({ top = 34, bottom = 12 })
    local top = Layout.Flow(window.topControls, { x = rect.x, y = rect.y, width = rect.width }, { scale = window.uiScale, minWidth = 62 })
    local footer = Layout.Flow(window.footerControls, { x = rect.x, y = 0, width = rect.width }, { scale = window.uiScale, minWidth = 62 })
    local footerY = rect.y + rect.height - footer.height
    Layout.Flow(window.footerControls, { x = rect.x, y = footerY, width = rect.width }, { scale = window.uiScale, minWidth = 62 })
    local mainY = top.bottom + Layout.Pixels(24, window.uiScale)
    local split = Layout.Split({
        x = rect.x, y = mainY, width = rect.width,
        height = math.max(80, footerY - Layout.Pixels(10, window.uiScale) - mainY),
    }, { scale = window.uiScale, firstRatio = 0.4, topRatio = 0.4, breakpoint = 800 })
    window.mainLayout = split
    Layout.SetBounds(window.list, split.first.x, split.first.y, split.first.width, split.first.height)
    Layout.SetBounds(window.details, split.second.x, split.second.y, split.second.width, split.second.height)
end

function View.Render(window, roster, selected)
    if not window.mainLayout then return end
    local suffix = tostring(window.visibleRosterCount or 0) .. " / " .. tostring(#(roster or {}))
    UI.DrawSectionTitle(window, "NPC roster", window.mainLayout.first.x, window.mainLayout.first.y - Layout.Pixels(21, window.uiScale), window.mainLayout.first.width, suffix)
    UI.DrawSectionTitle(window, "Lifecycle details", window.mainLayout.second.x, window.mainLayout.second.y - Layout.Pixels(21, window.uiScale), window.mainLayout.second.width, selected and tostring(selected.name or selected.id) or "")
end

return View
