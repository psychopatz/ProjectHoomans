require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Presentation = {}
local ViewModel = require "PNC/UI/Communities/PNC_ColonyStorageViewModel"
local ActivityPresentation = require
    "PNC/UI/Communities/PNC_ColonyStorageActivityPresentation"

function Presentation.DrawActivityRow(list, y, entry, alternate)
    local item = entry.item or {}
    local UI = PsychopatzCore.UI
    local Theme = UI.Theme
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local timeWidth = Theme.TextWidth(UIFont.Small, item.time or "")
    local maximum = math.max(40, list:getWidth() - timeWidth - 28)
    list:drawText(UI.Layout.Ellipsize(item.message, UIFont.Small, maximum),
        8, y + 5, Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Small)
    list:drawTextRight(item.time or "", list:getWidth() - 8, y + 5,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

function Presentation.BuildInventoryRows(storage, search, sort, collapsed)
    return ViewModel.BuildInventoryRows(storage, search, sort, collapsed)
end

function Presentation.BuildActivityRows(storage, tr)
    local rows = ActivityPresentation.Rows(storage and storage.activity or {})
    if #rows == 0 then
        rows[1] = {
            message = tr("UI_PNC_Storage_NoActivity",
                "No inventory activity yet"),
            time = "",
        }
    end
    return rows
end

function Presentation.DrawSummary(window, Theme)
    local storage = window.snapshot and window.snapshot.storage or nil
    if not storage or not window.layout or not window.layout.summary then return end
    local summary = window.layout.summary
    window:drawTextRight(
        string.format("TIER %d  |  %.1f / %.1f  |  FREE %.1f%s",
            storage.tier or 1, storage.usedWeight or 0,
            storage.capacity or 0, storage.freeWeight or 0,
            storage.overCapacity and "  OVER CAPACITY" or ""),
        summary.x + summary.width - 14, summary.y + summary.height - 23,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
end

return Presentation
