require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Knowledge/PNC_KnowledgePresentation"

PNC = PNC or {}
PNC.NPCDossierUI = PNC.NPCDossierUI or {}

local Dossier = PNC.NPCDossierUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Presentation = PNC.KnowledgePresentation
local ClientState = PNC.Network.ClientState

local function drawCategory(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local color = Theme.colors.text
    list:drawText(item.title, 10, y + 7, color.r, color.g, color.b, color.a, UIFont.Small)
    return y + list.itemheight
end

local function drawFact(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local muted, color = Theme.colors.textMuted, Theme.colors.text
    list:drawText(item.label, 10, y + 5, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText(item.value, math.floor(list:getWidth() * .42), y + 5, color.r, color.g, color.b, color.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCNPCDossierWindow = PsychopatzWindow:derive("ISPNCNPCDossierWindow")
function ISPNCNPCDossierWindow:initialise() PsychopatzWindow.initialise(self) end
function ISPNCNPCDossierWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.categories = UI.CreateList(self, { itemHeight = Layout.Pixels(28, self.uiScale), doDrawItem = drawCategory })
    self.facts = UI.CreateList(self, { itemHeight = Layout.Pixels(26, self.uiScale), doDrawItem = drawFact })
    self.refreshButton = UI.CreateButton(self, { id = "refresh", title = "Refresh", target = self, onclick = ISPNCNPCDossierWindow.onRefresh, variant = "quiet" })
    self:requestResponsiveLayout(true)
end
function ISPNCNPCDossierWindow:onResponsiveLayout()
    local pad, top = Layout.Pixels(10, self.uiScale), Layout.Pixels(40, self.uiScale)
    local left = math.floor(self:getWidth() * .28)
    Layout.SetBounds(self.categories, pad, top, left - pad * 2, self:getHeight() - top - pad)
    Layout.SetBounds(self.facts, left + pad, top, self:getWidth() - left - pad * 2, self:getHeight() - top - pad)
    Layout.SetBounds(self.refreshButton, self:getWidth() - Layout.Pixels(100, self.uiScale), Layout.Pixels(6, self.uiScale), Layout.Pixels(90, self.uiScale), Layout.Pixels(26, self.uiScale))
end
function ISPNCNPCDossierWindow:refresh()
    local snapshot = ClientState.npcKnowledge and ClientState.npcKnowledge[self.npcID] or nil
    self.sections = Presentation.BuildDossierRows(snapshot)
    self.categories:clear()
    for _, section in ipairs(self.sections) do self.categories:addItem(section.title, section) end
    if #self.sections > 0 then self.categories.selected = 1 end
    self:refreshFacts()
end
function ISPNCNPCDossierWindow:refreshFacts()
    local selected = self.categories:getItem()
    local section = selected and selected.item or nil
    self.facts:clear()
    for _, row in ipairs(section and section.rows or {}) do self.facts:addItem(row.label, row) end
end
function ISPNCNPCDossierWindow:prerender()
    PsychopatzWindow.prerender(self)
    local selected = self.categories and self.categories.selected or nil
    if selected ~= self.lastCategorySelection then
        self.lastCategorySelection = selected
        self:refreshFacts()
    end
end
function ISPNCNPCDossierWindow:onRefresh()
    if PNC.Client and PNC.Client.RequestNPCKnowledge then PNC.Client.RequestNPCKnowledge(self.npcID) end
end
function Dossier.ReceiveSnapshot(snapshot)
    if Dossier.instance and snapshot and tostring(snapshot.npcID) == tostring(Dossier.instance.npcID) then Dossier.instance:refresh() end
end
function Dossier.Open(npcID)
    if not Dossier.instance then
        Dossier.instance = UI.NewWindow(ISPNCNPCDossierWindow, { title = "NPC Dossier", resizable = true, responsiveSpec = { width = 620, height = 460, minWidth = 440, minHeight = 300 } })
        Dossier.instance:initialise(); Dossier.instance:instantiate()
    end
    Dossier.instance.npcID = tostring(npcID or "")
    Dossier.instance:addToUIManager(); Dossier.instance:setVisible(true); Dossier.instance:bringToTop()
    Dossier.instance:refresh()
    if PNC.Client and PNC.Client.RequestNPCKnowledge then PNC.Client.RequestNPCKnowledge(Dossier.instance.npcID) end
    return Dossier.instance
end

return Dossier
