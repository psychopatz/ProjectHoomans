-- Faction debug window list rendering helpers.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local UI = Internal.UI
local Theme = Internal.Theme
local Layout = Internal.Layout
function Internal.DrawEntity(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(
        list, y, list.itemheight,
        list.selected == entry.index, alternate
    )
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(
            item.label,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 5,
        text.r, text.g, text.b, text.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.detail or item.id,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 24,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

function Internal.DrawMobileEntity(list, y, entry, alternate)
    local item = entry.item or {}
    local height = list.itemheight
    UI.DrawListSelection(
        list, y, height, list.selected == entry.index, alternate
    )
    local font = Theme.Font(list.uiScale)
    local textColor = Theme.colors.text
    local muted = Theme.colors.textMuted
    local badgeWidth = UI.DrawBadge(
        list,
        item.categoryLabel or "UNKNOWN",
        list:getWidth() - 10,
        y + 5,
        item.categoryTone or "accent"
    )
    local available = math.max(80, list:getWidth() - badgeWidth - 28)
    list:drawText(
        Layout.Ellipsize(
            item.name or item.id or "Unknown mobile group",
            font,
            available
        ),
        12, y + 5,
        textColor.r, textColor.g, textColor.b, textColor.a,
        font
    )
    list:drawText(
        Layout.Ellipsize(
            item.listDetail or item.detail or item.id,
            font,
            list:getWidth() - 24
        ),
        12, y + 28,
        muted.r, muted.g, muted.b, muted.a,
        font
    )
    return y + height
end
