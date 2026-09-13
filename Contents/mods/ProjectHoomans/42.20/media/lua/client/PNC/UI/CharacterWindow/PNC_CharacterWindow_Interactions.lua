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
local Relationship = PNC.Conversation and PNC.Conversation.Relationship
local Graph = PNC.RelationshipGraph

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

local INTERACTION_TITLE_KEYS = {
    player_insulted = {
        key = "UI_PNC_Interaction_PlayerInsulted",
        fallback = "PLAYER INSULTED",
    },
    player_praised = {
        key = "UI_PNC_Interaction_PlayerPraised",
        fallback = "PLAYER PRAISED",
    },
    player_admired = {
        key = "UI_PNC_Interaction_PlayerAdmired",
        fallback = "PLAYER ADMIRED",
    },
    player_comforted = {
        key = "UI_PNC_Interaction_PlayerComforted",
        fallback = "PLAYER COMFORTED",
    },
    player_apologized = {
        key = "UI_PNC_Interaction_PlayerApologized",
        fallback = "PLAYER APOLOGIZED",
    },
    player_flirted = {
        key = "UI_PNC_Interaction_PlayerFlirted",
        fallback = "PLAYER FLIRTED",
    },
}

local REACTION_INTERACTION_TYPES = {
    insult = "player_insulted",
    praise = "player_praised",
    admire = "player_admired",
    comfort = "player_comforted",
    apologize = "player_apologized",
    flirt = "player_flirted",
}

local function interactionLabel(entry)
    entry = type(entry) == "table" and entry or {}
    local interactionType = tostring(entry.interactionType or "")
    local descriptor = INTERACTION_TITLE_KEYS[interactionType]
    if not descriptor and entry.kind == "llm_social_reaction" then
        local reaction = tostring(entry.reaction or entry.choiceID or "")
        local mappedType = REACTION_INTERACTION_TYPES[reaction]
        descriptor = mappedType and INTERACTION_TITLE_KEYS[mappedType] or nil
        if not descriptor and reaction ~= "" then
            return kindLabel("player_" .. reaction)
        end
    end
    if descriptor then
        return translated(descriptor.key, descriptor.fallback)
    end
    return kindLabel(entry.kind)
end

-- Kept public for focused UI tests and for callers that need the same
-- presentation label without duplicating the event-to-title mapping.
Tabs.FormatInteractionTitle = interactionLabel

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
    local current = ClientState.conversationRelationships
        and ClientState.conversationRelationships[tostring(view.npcId)]
        or Relationship and Relationship.GetPresentation
        and Relationship.GetPresentation(view.npcId) or nil
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
    if current then
        local attitude = Graph and Graph.ResolveAttitude
            and Graph.ResolveAttitude(current.approval, current.respect)
            or current.state or "indifferent"
        view:drawText(translated(
            "UI_PNC_CurrentRelationship",
            "CURRENT RELATION"
        ), pad, y, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        y = y + lineHeight + 4
        view:drawText(relationshipLabel(attitude), pad, y,
            color.r, color.g, color.b, color.a, UIFont.Small)
        y = y + lineHeight
        view:drawText(
            translated("UI_PNC_RelationshipApproval", "Approval")
                .. " " .. signed(current.approval)
                .. "   "
                .. translated("UI_PNC_RelationshipRespect", "Respect")
                .. " " .. signed(current.respect),
            pad + Layout.Pixels(10, view.uiScale), y,
            muted.r, muted.g, muted.b, muted.a, UIFont.Small
        )
        y = y + lineHeight
        view:drawText(
            translated("UI_PNC_RelationshipFamiliarity", "Familiarity")
                .. " " .. signed(current.familiarity),
            pad + Layout.Pixels(10, view.uiScale), y,
            muted.r, muted.g, muted.b, muted.a, UIFont.Small
        )
        y = y + lineHeight + Layout.Pixels(12, view.uiScale)
    end
    if #entries == 0 then
        if established then return y + pad end
        view:drawText(translated(
            "UI_PNC_NoPlayerInteractions",
            "NO PLAYER INTERACTIONS RECORDED"
        ), pad, y,
            muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        y = y + lineHeight * 2
        view:drawText(translated(
            "UI_PNC_InteractionHistoryHint",
            "Conversation choices, gifts, and recruitment attempts"
        ),
            pad, y, color.r, color.g, color.b, color.a, UIFont.Small)
        return y + lineHeight + pad
    end

    view:drawText(translated(
        "UI_PNC_PlayerNPCInteractions",
        "PLAYER / NPC INTERACTIONS"
    ), pad, y,
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
        local title = interactionLabel(entry)
        if entry.kind ~= "llm_social_reaction" and entry.choiceID then
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
