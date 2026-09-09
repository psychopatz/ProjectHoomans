require "PsychopatzCore/UI/PsychopatzUI"

local Rows = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

function Rows.Material(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    if row.texture and list.drawTextureScaledAspect then
        list:drawTextureScaledAspect(row.texture, 8, y + 5, 30, 30,
            0.95, 1, 1, 1)
    end
    local tint = row.ready and Theme.colors.success or Theme.colors.warning
    list:drawText(Layout.Ellipsize(row.name or "ITEM", UIFont.Small,
        math.max(80, list:getWidth() - 330)), 48, y + 6,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(row.source or "STOCKPILE", 48, y + 25,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    list:drawTextRight(tostring(row.available) .. " / "
        .. tostring(row.required), list:getWidth() - 118, y + 14,
        tint.r, tint.g, tint.b, tint.a or 1, UIFont.Small)
    list:drawTextRight(row.ready and "READY" or "MISSING",
        list:getWidth() - 12, y + 14, tint.r, tint.g, tint.b,
        tint.a or 1, UIFont.Small)
    return y + list.itemheight
end

function Rows.NativeQueue(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    list:drawText(Layout.Ellipsize(row.title or "BLUEPRINT", UIFont.Small,
        math.max(80, list:getWidth() - 190)), 12, y + 7,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.worker or "UNASSIGNED", UIFont.Small,
        math.max(60, list:getWidth() - 190)), 12, y + 27,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    list:drawTextRight(tostring(row.percent or 0) .. "% "
        .. tostring(row.status or "QUEUED"), list:getWidth() - 112,
        y + 17, Theme.colors.accent.r, Theme.colors.accent.g,
        Theme.colors.accent.b, Theme.colors.accent.a, UIFont.Small)
    list:drawTextRight("CANCEL", list:getWidth() - 10, y + 17,
        Theme.colors.warning.r, Theme.colors.warning.g,
        Theme.colors.warning.b, Theme.colors.warning.a, UIFont.Small)
    return y + list.itemheight
end

return Rows
