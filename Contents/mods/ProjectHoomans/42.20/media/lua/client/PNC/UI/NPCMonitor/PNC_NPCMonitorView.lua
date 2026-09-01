require "PsychopatzCore/UI/PsychopatzUI"
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
    local name = Layout.Ellipsize(item.name or item.id or "Unknown NPC", UIFont.Medium, math.max(40, list:getWidth() - 190))
    list:drawText(name, 11, y + 5, text.r, text.g, text.b, text.a, UIFont.Medium)
    local summary = string.format("%s  •  %s  •  HP %d/%d",
        string.upper(tostring(item.tacticalClass or "?")),
        tostring(item.bodyState or "unknown"),
        math.floor(tonumber(item.hpCurrent) or 0),
        math.floor(tonumber(item.hpMax) or 0))
    summary = Layout.Ellipsize(summary, UIFont.Small, list:getWidth() - 22)
    list:drawText(summary, 11, y + 28, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + height
end

function View.DrawRosterContent(list, y, entry)
    local item = entry.item
    local right = list:getWidth() - 10
    local presenceWidth = UI.DrawBadge(list, item.presenceState or "unknown", right, y + 5, Support.PresenceColor(item))
    if Support.IsRecording(item) then
        UI.DrawBadge(list, "REC", right - presenceWidth - 6, y + 5, "danger")
    end
end

local function createToolbarButton(window, definition, collection)
    local button = UI.CreateButton(window, definition)
    collection[#collection + 1] = button
    return button
end

local function overlayButtonTitle(id)
    local label = PNC.Nameplates
        and PNC.Nameplates.GetOverlayLabel
        and PNC.Nameplates.GetOverlayLabel(id)
        or tostring(id)
    local enabled = PNC.Nameplates
        and PNC.Nameplates.IsOverlayEnabled
        and PNC.Nameplates.IsOverlayEnabled(id)
    return tostring(label) .. ": " .. (enabled and "ON" or "OFF")
end

function View.RefreshOverlayControls(window)
    if not window or not window.overlayButtons then return end
    local id
    local button
    local enabled
    for id, button in pairs(window.overlayButtons) do
        enabled = PNC.Nameplates
            and PNC.Nameplates.IsOverlayEnabled
            and PNC.Nameplates.IsOverlayEnabled(id)
            or false
        if button.setTitle then
            button:setTitle(overlayButtonTitle(id))
        else
            button.title = overlayButtonTitle(id)
        end
        UI.SetButtonVariant(
            button,
            enabled and "selected" or "quiet"
        )
    end
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
    window.track = createToolbarButton(window, {
        id = "track", title = Support.Tr("UI_PNC_MonitorTrack", "Track"), target = window,
        onclick = ISPNCNPCMonitor.onTrack, variant = "quiet",
    }, window.topControls)
    window.commandMap = createToolbarButton(window, {
        id = "command_map",
        title = Support.Tr(
            "UI_PNC_MonitorCommandMap",
            "Command Map"
        ),
        target = window,
        onclick = ISPNCNPCMonitor.onCommandMap,
        variant = "selected",
    }, window.topControls)
    window.teleport = createToolbarButton(window, {
        id = "teleport", title = Support.Tr("UI_PNC_MonitorTeleport", "Teleport"), target = window,
        onclick = ISPNCNPCMonitor.onTeleport,
    }, window.topControls)
    window.list = UI.CreateList(window, {
        itemHeight = Layout.Pixels(50, window.uiScale),
        doDrawItem = View.DrawRosterItem,
        drawItemContent = View.DrawRosterContent,
    })
    window.details = UI.CreateKeyValueList(window, {
        itemHeight = Layout.Pixels(28, window.uiScale),
        labelX = 12,
        labelY = 7,
        valueY = 7,
        labelWidth = 128,
        labelWidthRatio = 0.31,
        valueXOffset = 0,
        valueRightPadding = 12,
        valueMinimumWidth = 30,
        labelColor = "textMuted",
        valueColor = "text",
    })

    local actions = {
        { "force_live", "UI_PNC_MonitorForceLive", "Force Live", ISPNCNPCMonitor.onAction, "success" },
        { "force_abstract", "UI_PNC_MonitorForceAbstract", "Force Abstract", ISPNCNPCMonitor.onAction, "warning" },
        { "heal", "UI_PNC_MonitorHeal", "Heal", ISPNCNPCMonitor.onAction, "success" },
        { "damage", "UI_PNC_MonitorDamage", "Damage", ISPNCNPCMonitor.onAction, "danger" },
        { "toggle_debug", "UI_PNC_MonitorRecordDebug", "Record Debug", ISPNCNPCMonitor.onAction, "default" },
        { "map_marker", "UI_PNC_MonitorMapMarker", "Map Marker", ISPNCNPCMonitor.onMapMarker, "default" },
        { "equipment", "UI_PNC_MonitorEquipment", "Equipment", ISPNCNPCMonitor.onEquipment, "default" },
        { "relationships", "UI_PNC_MonitorRelationships", "Relationships", ISPNCNPCMonitor.onRelationships, "default" },
        { "provision_stats", "UI_PNC_MonitorProvisionStats", "Provision Stats", ISPNCNPCMonitor.onProvisionDiagnostics, "selected" },
        { "audit", "UI_PNC_MonitorAuditBodies", "Audit Bodies", ISPNCNPCMonitor.onAudit, "warning" },
        { "refresh", "UI_PNC_MonitorRefresh", "Refresh", ISPNCNPCMonitor.onRefresh, "quiet" },
        { "overlay_ai", nil, overlayButtonTitle("ai"), ISPNCNPCMonitor.onOverlayType, "quiet", "ai" },
        { "overlay_camp", nil, overlayButtonTitle("camp"), ISPNCNPCMonitor.onOverlayType, "quiet", "camp" },
        { "overlay_path", nil, overlayButtonTitle("path"), ISPNCNPCMonitor.onOverlayType, "quiet", "path" },
        { "overlay_combat", nil, overlayButtonTitle("combat"), ISPNCNPCMonitor.onOverlayType, "quiet", "combat" },
        { "overlay_animation", nil, overlayButtonTitle("animation"), ISPNCNPCMonitor.onOverlayType, "quiet", "animation" },
        { "overlay_scenes", nil, overlayButtonTitle("scenes"), ISPNCNPCMonitor.onOverlayType, "quiet", "scenes" },
        { "overlay_faction", nil, overlayButtonTitle("faction"), ISPNCNPCMonitor.onOverlayType, "quiet", "faction" },
        { "overlay_community", nil, overlayButtonTitle("community"), ISPNCNPCMonitor.onOverlayType, "quiet", "community" },
    }
    window.selectionControls = {}
    window.overlayButtons = {}
    for _, action in ipairs(actions) do
        local variant = action[5]
        if action[6]
            and PNC.Nameplates
            and PNC.Nameplates.IsOverlayEnabled
            and PNC.Nameplates.IsOverlayEnabled(action[6])
        then
            variant = "selected"
        end
        local button = createToolbarButton(window, {
            id = action[1],
            title = action[2]
                and Support.Tr(action[2], action[3])
                or action[3],
            target = window,
            onclick = action[4], variant = variant,
        }, window.footerControls)
        if action[6] then
            window.overlayButtons[action[6]] = button
        end
        if action[1] == "toggle_debug" then window.recordDebugButton = button end
        if action[1] ~= "audit"
            and action[1] ~= "refresh"
            and not action[6]
        then
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
    local overlaySummary = PNC.Nameplates
        and PNC.Nameplates.GetOverlaySummary
        and PNC.Nameplates.GetOverlaySummary()
        or "ON: none"
    if window.lastOverlaySummary ~= overlaySummary then
        window.lastOverlaySummary = overlaySummary
        View.RefreshOverlayControls(window)
    end
    UI.DrawSectionTitle(window, "NPC roster", window.mainLayout.first.x, window.mainLayout.first.y - Layout.Pixels(21, window.uiScale), window.mainLayout.first.width, suffix .. "  •  Overlays " .. overlaySummary)
    UI.DrawSectionTitle(window, "Lifecycle details", window.mainLayout.second.x, window.mainLayout.second.y - Layout.Pixels(21, window.uiScale), window.mainLayout.second.width, selected and tostring(selected.name or selected.id) or "")
end

return View
