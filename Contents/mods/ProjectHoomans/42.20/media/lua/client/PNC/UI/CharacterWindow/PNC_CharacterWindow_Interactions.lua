-- Conversation diary tab for the existing NPC character window.
-- It presents the player's exchanges and committed relationship deltas; it
-- does not mutate relationship state or replace the conversation transcript.

require "PNC/Conversation/PNC_ConversationDiary"

PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Diary = PNC.Conversation.Diary
local Layout = PsychopatzCore.UI.Layout
local Theme = PsychopatzCore.UI.Theme
local ClientState = PNC.Network.ClientState
local Shared = PNC.CharacterWindowShared

local function translated(key, fallback)
    return Shared and Shared.Text and Shared.Text(key, fallback) or fallback
end

local function relationshipLabel(value)
    local text = tostring(value or "companion")
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local function signed(value)
    return string.format("%+.1f", tonumber(value) or 0)
end

local function kindLabel(value)
    local text = tostring(value or "conversation")
    text = string.gsub(text, "_", " ")
    return string.upper(text)
end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or "-"
end

function Tabs.CreateInteractionsChildren(view)
    view.clearInteractionsButton = PsychopatzCore
        and PsychopatzCore.UI.CreateButton
        and PsychopatzCore.UI.CreateButton(view, {
            id = "clear_interactions",
            title = "Clear",
            target = view,
            onclick = function(target)
                Diary.Clear(target.npcId)
                target.scrollY = 0
            end,
            variant = "quiet",
        }) or nil
end

function Tabs.SetInteractionsContext(view)
    view.interactionsRevision = tonumber(
        ClientState.conversationDiaryRevision
    ) or 0
end

function Tabs.LayoutInteractions(view)
    local pad = Layout.Pixels(12, view.uiScale)
    local height = Layout.Pixels(26, view.uiScale)
    local width = Layout.Pixels(70, view.uiScale)
    if view.clearInteractionsButton then
        Layout.SetBounds(
            view.clearInteractionsButton,
            view.width - pad - width,
            pad,
            width,
            height
        )
    end
end

function Tabs.RenderInteractions(view, _, _, topY)
    local entries = Diary.Get(view.npcId)
    local pad = Layout.Pixels(12, view.uiScale)
    local lineHeight = Layout.Pixels(18, view.uiScale)
    local width = math.max(100, view.width - pad * 2)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    local y = topY + Layout.Pixels(6, view.uiScale)
    local established = view.snapshot and view.snapshot.startingRelationship
        or view.payload and view.payload.startingRelationship
    if established then
        view:drawText(translated(
            "UI_PNC_EstablishedRelationship",
            "ESTABLISHED RELATIONSHIP"
        ), pad, y, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        y = y + lineHeight + 4
        view:drawText(relationshipLabel(established.kind), pad, y,
            color.r, color.g, color.b, color.a, UIFont.Small)
        y = y + lineHeight
        view:drawText(translated(
            "UI_PNC_KnownBeforeOutbreak",
            "Known since before the outbreak • Lifelong familiarity"
        ), pad + Layout.Pixels(10, view.uiScale), y,
            muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        y = y + lineHeight + Layout.Pixels(12, view.uiScale)
    end
    if #entries == 0 then
        if established then return y + pad end
        view:drawText("NO PLAYER INTERACTIONS RECORDED", pad, y,
            muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        y = y + lineHeight * 2
        view:drawText("Conversation choices, gifts, and recruitment attempts",
            pad, y, color.r, color.g, color.b, color.a, UIFont.Small)
        return y + lineHeight + pad
    end

    view:drawText("PLAYER / NPC INTERACTIONS", pad, y,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    y = y + lineHeight + 4
    for index = #entries, 1, -1 do
        local entry = entries[index] or {}
        local delta = entry.delta or {}
        local deltaText = table.concat({
            "Approval " .. signed(delta.approval),
            "Respect " .. signed(delta.respect),
            "Familiarity " .. signed(delta.familiarity),
        }, "   ")
        local deltaPositive = (tonumber(delta.approval) or 0)
            + (tonumber(delta.respect) or 0)
            + (tonumber(delta.familiarity) or 0) >= 0
        local title = kindLabel(entry.kind)
        if entry.choiceID then
            title = title .. "  " .. tostring(entry.choiceID)
        end
        view:drawRect(pad, y - 3, width, 1, 0.55, 0.45, 0.45, 0.45)
        view:drawText(title, pad, y,
            color.r, color.g, color.b, color.a, UIFont.Small)
        y = y + lineHeight
        if entry.playerText then
            view:drawText(
                Layout.Ellipsize("YOU: " .. text(entry.playerText), UIFont.Small, width),
                pad + Layout.Pixels(10, view.uiScale), y,
                0.35, 0.92, 0.72, 1, UIFont.Small
            )
            y = y + lineHeight
        end
        if entry.npcText then
            view:drawText(
                Layout.Ellipsize("NPC: " .. text(entry.npcText), UIFont.Small, width),
                pad + Layout.Pixels(10, view.uiScale), y,
                color.r, color.g, color.b, color.a, UIFont.Small
            )
            y = y + lineHeight
        end
        if entry.itemSummary then
            view:drawText(
                Layout.Ellipsize("Items: " .. text(entry.itemSummary), UIFont.Small, width),
                pad + Layout.Pixels(10, view.uiScale), y,
                muted.r, muted.g, muted.b, muted.a, UIFont.Small
            )
            y = y + lineHeight
        end
        view:drawText(
            Layout.Ellipsize("Reputation: " .. deltaText, UIFont.Small, width),
            pad + Layout.Pixels(10, view.uiScale), y,
            deltaPositive and 0.42 or 0.92,
            deltaPositive and 0.88 or 0.42,
            deltaPositive and 0.58 or 0.42,
            1, UIFont.Small
        )
        y = y + lineHeight + 8
    end
    return y + pad
end

return Tabs
