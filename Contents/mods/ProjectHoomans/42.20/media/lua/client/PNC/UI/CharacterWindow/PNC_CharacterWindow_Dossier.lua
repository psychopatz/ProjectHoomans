-- Player-learned NPC knowledge lives inside the existing character window.
-- This deliberately draws the compact fact list directly: character tabs
-- already provide scrolling, so a second native scrolling-list is redundant.

require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Knowledge/PNC_KnowledgePresentation"

PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Presentation = PNC.KnowledgePresentation
local ClientState = PNC.Network.ClientState

local function canDebug()
    return PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
end

local function rebuildModel(view)
    local snapshot = ClientState.npcKnowledge and ClientState.npcKnowledge[view.npcId] or nil
    view.dossierModel = Presentation.BuildDossierModel(snapshot)
end

function Tabs.CreateDossierChildren(view)
    view.discoverTraitsButton = UI.CreateButton(view, {
        id = "discover_traits", title = "DEBUG: Discover traits", target = view,
        onclick = function(target)
            if canDebug() and PNC.Client and PNC.Client.SendDebug then
                PNC.Client.SendDebug("knowledge_debug_action", {
                    knowledgeAction = "reveal_all", npcID = target.npcId,
                    showTruth = false,
                })
            end
        end, variant = "default",
    })
    view.refreshDossierButton = UI.CreateButton(view, {
        id = "refresh_dossier", title = "Refresh", target = view,
        onclick = function(target)
            if PNC.Client and PNC.Client.RequestNPCKnowledge then
                PNC.Client.RequestNPCKnowledge(target.npcId)
            end
        end, variant = "quiet",
    })
end

function Tabs.SetDossierContext(view)
    rebuildModel(view)
end

function Tabs.LayoutDossier(view)
    local pad = Layout.Pixels(12, view.uiScale)
    local height = Layout.Pixels(26, view.uiScale)
    local refreshWidth = Layout.Pixels(82, view.uiScale)
    local discoverWidth = Layout.Pixels(148, view.uiScale)
    local right = view.width - pad
    local debugAllowed = canDebug()
    view.discoverTraitsButton:setVisible(debugAllowed)
    Layout.SetBounds(view.refreshDossierButton, right - refreshWidth, pad, refreshWidth, height)
    if debugAllowed then
        Layout.SetBounds(view.discoverTraitsButton, right - refreshWidth - pad - discoverWidth, pad, discoverWidth, height)
    end
end

function Tabs.RenderDossier(view, _, _, topY)
    rebuildModel(view)
    local model = view.dossierModel or {}
    local pad = Layout.Pixels(12, view.uiScale)
    local y = topY + Layout.Pixels(42, view.uiScale)
    local contentWidth = math.max(80, view.width - pad * 2)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    local sections = model.sections or {}
    if #sections == 0 then
        view:drawText("NO OBSERVATIONS YET", pad, y, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        y = y + Layout.Pixels(24, view.uiScale)
        view:drawText("Talk to, watch, or spend time with this NPC to build their dossier.", pad, y, color.r, color.g, color.b, color.a, UIFont.Small)
        return y + Layout.Pixels(30, view.uiScale)
    end
    view:drawText("KNOWN INFORMATION", pad, y, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    y = y + Layout.Pixels(24, view.uiScale)
    for _, section in ipairs(sections) do
        view:drawText(string.upper(tostring(section.title)), pad, y, color.r, color.g, color.b, color.a, UIFont.Small)
        y = y + Layout.Pixels(20, view.uiScale)
        for _, row in ipairs(section.rows or {}) do
            local labelWidth = math.min(Layout.Pixels(150, view.uiScale), math.floor(contentWidth * .42))
            view:drawText(Layout.Ellipsize(row.label, UIFont.Small, labelWidth), pad + Layout.Pixels(12, view.uiScale), y, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
            view:drawText(Layout.Ellipsize(row.value, UIFont.Small, contentWidth - labelWidth - Layout.Pixels(28, view.uiScale)), pad + labelWidth + Layout.Pixels(18, view.uiScale), y, color.r, color.g, color.b, color.a, UIFont.Small)
            y = y + Layout.Pixels(22, view.uiScale)
        end
        y = y + Layout.Pixels(8, view.uiScale)
    end
    return y + pad
end

return Tabs
