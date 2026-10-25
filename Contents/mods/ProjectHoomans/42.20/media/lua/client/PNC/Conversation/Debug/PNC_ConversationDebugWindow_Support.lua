-- Shared presentation helpers for the conversation debug window spokes.

local DebugUI = PNC.ConversationDebugUI
local Internal = DebugUI.Internal
local UI = Internal.UI
local Theme = Internal.Theme
local Layout = Internal.Layout

local DEBUG_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/debugger.json",
    domain = "pnc.system.shared.debugger",
}

local function tr(key, args)
    PNC.Conversation.TextLoader.EnsureSource(DEBUG_SOURCE, { key })
    return PsychopatzCore.Conversation.Text.Resolve({
        key = key, domain = DEBUG_SOURCE.domain, args = args,
    })
end

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function drawBlock(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local color = item.valid and Theme.colors.text or Theme.colors.danger
    list:drawText(Layout.Ellipsize(item.id, UIFont.Small,
        list:getWidth() - 16), 8, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    local detail = table.concat({
        item.block.category or "?",
        table.concat(item.block.audiences or {}, ","),
        item.translationFallback and tr("status.text_fallback")
            or item.translationValid and tr("status.text_ok")
            or tr("status.text_missing"),
        item.eligible and tr("status.eligible")
            or tostring(item.eligibilityReason or tr("status.unknown")),
    }, " | ")
    list:drawText(Layout.Ellipsize(detail, UIFont.Small,
        list:getWidth() - 16), 8, y + 24,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function booleanText(value)
    if value == true then return tr("status.yes") end
    if value == false then return tr("status.no") end
    return tr("status.unknown")
end

local function statusTone(value)
    return value == true and "success" or value == false and "danger" or "warning"
end

local function textValue(value)
    if value == nil or value == "" then return "-" end
    return tostring(value)
end

DebugUI.Text = tr
Internal.tr = tr
Internal.selected = selected
Internal.drawBlock = drawBlock
Internal.booleanText = booleanText
Internal.statusTone = statusTone
Internal.textValue = textValue
