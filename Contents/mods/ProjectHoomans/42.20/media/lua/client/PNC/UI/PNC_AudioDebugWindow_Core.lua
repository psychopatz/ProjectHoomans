require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PNC_AudioDebugModel"

PNC = PNC or {}
PNC.AudioDebugUI = PNC.AudioDebugUI or {}

local AudioUI = PNC.AudioDebugUI
local Model = PNC.AudioDebug
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function resolveText(value, key, fallback)
    if value and value ~= "" and value ~= key then
        return value
    end
    return fallback
end

local TEXT = {
    title = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Title"),
        "UI_PNC_AudioDebug_Title", "AUDIO DEBUG"),
    dialogues = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Dialogues"),
        "UI_PNC_AudioDebug_Dialogues", "Dialogues"),
    sfx = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_SFX"),
        "UI_PNC_AudioDebug_SFX", "SFX"),
    style = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Style"),
        "UI_PNC_AudioDebug_Style", "VOICE STYLE"),
    voiceType = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_VoiceType"),
        "UI_PNC_AudioDebug_VoiceType", "VOICE TYPE"),
    pitch = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Pitch"),
        "UI_PNC_AudioDebug_Pitch", "PITCH"),
    searchVoice = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_SearchVoice"),
        "UI_PNC_AudioDebug_SearchVoice", "SEARCH VOICE"),
    searchSFX = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_SearchSFX"),
        "UI_PNC_AudioDebug_SearchSFX", "SEARCH SFX"),
    category = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Category"),
        "UI_PNC_AudioDebug_Category", "CATEGORY"),
    play = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Play"),
        "UI_PNC_AudioDebug_Play", "PLAY"),
    stop = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Stop"),
        "UI_PNC_AudioDebug_Stop", "STOP"),
    reset = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Reset"),
        "UI_PNC_AudioDebug_Reset", "RESET"),
    refresh = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Refresh"),
        "UI_PNC_AudioDebug_Refresh", "REFRESH"),
    localPlayer = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_LocalPlayer"),
        "UI_PNC_AudioDebug_LocalPlayer", "LOCAL PLAYER"),
    noPlayer = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_NoPlayer"),
        "UI_PNC_AudioDebug_NoPlayer", "NO LOCAL PLAYER"),
    noSelection = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_NoSelection"),
        "UI_PNC_AudioDebug_NoSelection", "NO AUDIO SELECTED"),
    playFailed = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_PlayFailed"),
        "UI_PNC_AudioDebug_PlayFailed", "PLAY FAILED"),
    stopped = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_Stopped"),
        "UI_PNC_AudioDebug_Stopped", "STOPPED"),
    resetDone = resolveText(getText and PNC.Translation.GetKey("UI_PNC_AudioDebug_ResetDone"),
        "UI_PNC_AudioDebug_ResetDone", "RESET TO PLAYER"),
}

local function makeLabel(parent, value, colorName)
    local color = Theme.colors[colorName or "text"] or Theme.colors.text
    local label = ISLabel:new(0, 0, 20, tostring(value or ""),
        color.r, color.g, color.b, color.a, UIFont.Small, true)
    label:initialise()
    label.psychopatzThemeColorName = colorName or "text"
    parent:addChild(label)
    return label
end

local function setLabel(label, value)
    UI.SetLabelText(label, value)
end

local function makeCombo(parent, target, callback)
    local combo = ISComboBox:new(0, 0, 1, 26, target, callback)
    combo:initialise()
    combo:instantiate()
    parent:addChild(combo)
    return combo
end

local function selectedItem(list)
    local row = list and list:getItem() or nil
    return row and row.item or nil
end

local function drawVoiceItem(list, y, row, alternate)
    local event = row.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == row.index, alternate)
    local title = tostring(event.suffix or "")
    local detail = tostring(event.category or "Voice")
    if event.semanticID then
        detail = detail .. " | " .. tostring(event.semanticID)
    end
    list:drawText(Layout.Ellipsize(title, UIFont.Small,
        list:getWidth() - 14), 8, y + 4,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(detail, UIFont.Small,
        list:getWidth() - 14), 8, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function drawSFXItem(list, y, row, alternate)
    local sound = row.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == row.index, alternate)
    list:drawText(Layout.Ellipsize(tostring(sound.name or ""), UIFont.Small,
        list:getWidth() - 14), 8, y + 4,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(tostring(sound.category or ""),
        UIFont.Small, list:getWidth() - 14), 8, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCAudioDebugDialoguesTab = ISPanel:derive("ISPNCAudioDebugDialoguesTab")

AudioUI.Internal = AudioUI.Internal or {}
local Internal = AudioUI.Internal
Internal.TEXT = TEXT
Internal.Model = Model
Internal.UI = UI
Internal.Theme = Theme
Internal.Layout = Layout
Internal.resolveText = resolveText
Internal.makeLabel = makeLabel
Internal.setLabel = setLabel
Internal.makeCombo = makeCombo
Internal.selectedItem = selectedItem
Internal.drawVoiceItem = drawVoiceItem
Internal.drawSFXItem = drawSFXItem

return AudioUI
