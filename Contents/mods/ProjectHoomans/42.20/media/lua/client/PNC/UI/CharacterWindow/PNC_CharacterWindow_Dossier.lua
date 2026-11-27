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
local requestSequence = 0
local FAMILY_REFRESH_MS = 5000

local function text(key, fallback)
    return PNC.Translation.GetKey("UI_PNC_Character_Dossier_" .. key, fallback)
end

local function canDebug()
    return PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
end

local function clearDebug(view)
    view.debugProfileRequest = nil
    view.debugProfilePending = false
    view.debugProfileSnapshot = nil
end

local function requestFullProfile(view)
    requestSequence = requestSequence + 1
    view.debugProfileRequest = requestSequence
    view.debugProfilePending = true
    if not PNC.Client.RequestKnowledgeDebug(view.npcId, true, nil, requestSequence) then
        view.debugProfilePending = false
    end
end

function Tabs.CreateDossierChildren(view)
    view.refreshDossierButton = UI.CreateButton(view, {
        id = "refresh_dossier", title = text("Refresh", "Refresh"), target = view,
        onclick = function(target)
            if target.debugProfileRequest and canDebug() then
                requestFullProfile(target)
            elseif PNC.Client and PNC.Client.RequestNPCKnowledge then
                PNC.Client.RequestNPCKnowledge(target.npcId)
            end
        end, variant = "quiet",
    })
    view.fullProfileButton = UI.CreateButton(view, {
        id = "full_profile", title = text("ShowFull", "Show full profile"), target = view,
        onclick = function(target)
            if not canDebug() then return end
            if target.debugProfileRequest then
                clearDebug(target)
            elseif target.npcId and PNC.Client.RequestKnowledgeDebug then
                requestFullProfile(target)
            end
            target:setYScroll(0)
        end, variant = "quiet",
    })
    view.fullProfileButton:setVisible(canDebug() == true)
end

function Tabs.SetDossierContext(view)
    if view.dossierNPC ~= view.npcId then
        clearDebug(view)
        view.dossierNPC = view.npcId
        view.nextFamilyRefresh = nil
        view:setYScroll(0)
    end
end

function Tabs.LayoutDossier(view)
    local pad = Layout.Pixels(12, view.uiScale)
    local height = Layout.Pixels(26, view.uiScale)
    local refreshWidth = Layout.Pixels(88, view.uiScale)
    local fullWidth = Layout.Pixels(190, view.uiScale)
    local scrollWidth = view.vscroll and view.vscroll:getWidth() or 0
    local right = view.width - pad - scrollWidth
    Layout.SetBounds(view.refreshDossierButton, right - refreshWidth, pad, refreshWidth, height)
    Layout.SetBounds(view.fullProfileButton, right - refreshWidth - pad - fullWidth, pad, fullWidth, height)
end

function Tabs.RenderDossier(view, _, _, topY)
    local authorized = canDebug() == true
    if not authorized then clearDebug(view) end
    local full = view.debugProfileRequest ~= nil
    view.fullProfileButton:setVisible(authorized)
    view.fullProfileButton:setTitle(full and text("ShowKnown", "Show known profile")
        or text("ShowFull", "Show full profile"))

    local snapshot = ClientState.npcKnowledge and ClientState.npcKnowledge[view.npcId] or nil
    local sections = full and Presentation.BuildFullProfileRows(view.debugProfileSnapshot)
        or Presentation.BuildDossierRows(snapshot)
    local family = snapshot and snapshot.startingFamily
    if family then
        local value = family.name
        if family.deceased then
            value = PNC.Translation.TrFormat("UI_PNC_Character_Dossier_FamilyDeceased",
                "%1 (deceased)", value)
        elseif PNC.Client and PNC.Client.RequestNPCKnowledge then
            local now = PNC.Core.Now()
            view.nextFamilyRefresh = view.nextFamilyRefresh or (now + FAMILY_REFRESH_MS)
            if now >= view.nextFamilyRefresh then
                view.nextFamilyRefresh = now + FAMILY_REFRESH_MS
                PNC.Client.RequestNPCKnowledge(view.npcId)
            end
        end
        table.insert(sections, 1, {
            title = text("Family", "Family"),
            rows = { { label = text("Family" .. family.kind, family.kind), value = value } },
        })
    end
    local pad = Layout.Pixels(12, view.uiScale)
    local inset = Layout.Pixels(10, view.uiScale)
    local scrollWidth = view.vscroll and view.vscroll:getWidth() or 0
    local contentWidth = view.width - pad * 2 - scrollWidth
    local y = topY + Layout.Pixels(36, view.uiScale)
    local font = UIFont.Small
    local rowHeight = getTextManager():getFontHeight(font) + Layout.Pixels(6, view.uiScale)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    local labelX = pad + inset
    local valueX = pad + math.min(Layout.Pixels(210, view.uiScale), math.floor(contentWidth * .43))

    if #sections == 0 then
        local message
        if full then
            message = view.debugProfilePending and text("LoadingFull", "Loading full profile…")
                or text("FullUnavailable", "Full profile unavailable")
        else
            message = text("NoObservations", "NO OBSERVATIONS YET")
        end
        view:drawText(message, pad, y, muted.r, muted.g, muted.b, muted.a, font)
        y = y + rowHeight
        if not full then
            local hint = text("Hint", "Talk to, watch, or spend time with this NPC to build their dossier.")
            view:drawText(Layout.Ellipsize(hint, font, contentWidth), pad, y, color.r, color.g, color.b, color.a, font)
            y = y + rowHeight
        end
        return y + pad
    end

    for _, section in ipairs(sections) do
        view:drawText(section.title, pad, y, color.r, color.g, color.b, color.a, font)
        y = y + rowHeight
        view:drawRect(pad, y - 3, contentWidth, 1, 0.35, muted.r, muted.g, muted.b)
        for _, row in ipairs(section.rows) do
            view:drawText(Layout.Ellipsize(row.label, font, valueX - labelX - inset),
                labelX, y, muted.r, muted.g, muted.b, muted.a, font)
            local availableWidth = pad + contentWidth - valueX
            if row.bar then
                local barWidth = math.min(Layout.Pixels(170, view.uiScale), math.floor(availableWidth * .65))
                local barHeight = Layout.Pixels(10, view.uiScale)
                local barY = y + math.floor((getTextManager():getFontHeight(font) - barHeight) / 2)
                view:drawRect(valueX, barY, barWidth, barHeight, .65, .12, .15, .17)
                view:drawRect(valueX + 1, barY + 1, math.floor((barWidth - 2) * row.bar),
                    barHeight - 2, row.qualifier and .55 or .95, .38, .66, .69)
                view:drawRectBorder(valueX, barY, barWidth, barHeight, .7, .39, .47, .51)
                if row.qualifier then
                    local gap = Layout.Pixels(8, view.uiScale)
                    view:drawText(Layout.Ellipsize(row.qualifier, font, availableWidth - barWidth - gap),
                        valueX + barWidth + gap, y, muted.r, muted.g, muted.b, muted.a, font)
                end
            else
                view:drawText(Layout.Ellipsize(row.value, font, availableWidth),
                    valueX, y, color.r, color.g, color.b, color.a, font)
            end
            y = y + rowHeight
        end
        y = y + pad
    end
    return y
end

return Tabs
