require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/Knowledge/PNC_KnowledgePresentation"

PNC = PNC or {}
PNC.KnowledgeDebugUI = PNC.KnowledgeDebugUI or {}

local DebugUI = PNC.KnowledgeDebugUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Presentation = PNC.KnowledgePresentation
local ClientState = PNC.Network.ClientState

local function clearList(list)
    list:clear()
    if list.setScrollHeight then list:setScrollHeight(0) end
    if list.setYScroll then list:setYScroll(0) end
    list.smoothScrollY = nil
    list.smoothScrollTargetY = nil
end

local function drawRow(list, y, entry, alternate)
    local row = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local color, muted = Theme.colors.text, Theme.colors.textMuted
    local width = list:getWidth()
    local columns = { 8, math.floor(width * .31), math.floor(width * .45), math.floor(width * .59), math.floor(width * .75), math.floor(width * .86) }
    list:drawText(Layout.Ellipsize(row.descriptorID, UIFont.Small, columns[2] - 14), columns[1], y + 4, color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.category, UIFont.Small, columns[3] - columns[2] - 6), columns[2], y + 4, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.truth, UIFont.Small, columns[4] - columns[3] - 6), columns[3], y + 4, color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.known, UIFont.Small, columns[5] - columns[4] - 6), columns[4], y + 4, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText(string.format("%d%%", math.floor(row.confidence * 100)), columns[5], y + 4, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.status, UIFont.Small, width - columns[6] - 8), columns[6], y + 4, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText("Provider: " .. tostring(row.providerID) .. "   Privacy: " .. tostring(row.privacy) .. "   Evidence: " .. tostring(row.evidenceCount), 8, y + 23, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCKnowledgeDebugWindow = PsychopatzWindow:derive("ISPNCKnowledgeDebugWindow")
function ISPNCKnowledgeDebugWindow:initialise() PsychopatzWindow.initialise(self) end
function ISPNCKnowledgeDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.rows = UI.CreateList(self, { itemHeight = Layout.Pixels(43, self.uiScale), doDrawItem = drawRow })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = 145,
        valueRightPadding = 5,
    })
    self.statusCombo = ISComboBox:new(0, 0, 140, Layout.Pixels(26, self.uiScale), self, ISPNCKnowledgeDebugWindow.onFilter)
    self.statusCombo:initialise(); self.statusCombo:instantiate(); self:addChild(self.statusCombo)
    for _, status in ipairs({ "all", "unknown", "suspected", "known", "confirmed" }) do self.statusCombo:addOptionWithData(status, status) end
    self.statusCombo:selectData("all")
    self.categoryCombo = ISComboBox:new(0, 0, 150, Layout.Pixels(26, self.uiScale), self, ISPNCKnowledgeDebugWindow.onFilter)
    self.categoryCombo:initialise(); self.categoryCombo:instantiate(); self:addChild(self.categoryCombo)
    self.providerCombo = ISComboBox:new(0, 0, 160, Layout.Pixels(26, self.uiScale), self, ISPNCKnowledgeDebugWindow.onFilter)
    self.providerCombo:initialise(); self.providerCombo:instantiate(); self:addChild(self.providerCombo)
    self.controls = {}
    for _, definition in ipairs({
        { "refresh", "Refresh", "quiet" }, { "truth", "Hide Truth", "quiet" }, { "reveal", "Reveal", "success" },
        { "forget", "Forget", "danger" }, { "force_disclosure", "Force Disclosure", "default" }, { "positive", "Add + Evidence", "success" },
        { "negative", "Add - Evidence", "danger" }, { "clear", "Clear Evidence", "danger" }, { "recalculate", "Recalculate", "quiet" }, { "validate", "Validate", "quiet" },
    }) do
        local button = UI.CreateButton(self, { id = definition[1], title = definition[2], target = self, onclick = ISPNCKnowledgeDebugWindow.onControl, variant = definition[3] })
        self.controls[#self.controls + 1] = button
    end
    self.showTruth = true
    self:requestResponsiveLayout(true)
end
function ISPNCKnowledgeDebugWindow:onResponsiveLayout()
    local pad, top, controlsHeight = Layout.Pixels(10, self.uiScale), Layout.Pixels(42, self.uiScale), Layout.Pixels(62, self.uiScale)
    local split = math.floor(self:getWidth() * .59)
    Layout.SetBounds(self.statusCombo, pad, Layout.Pixels(7, self.uiScale), Layout.Pixels(140, self.uiScale), Layout.Pixels(26, self.uiScale))
    Layout.SetBounds(self.categoryCombo, pad + Layout.Pixels(146, self.uiScale), Layout.Pixels(7, self.uiScale), Layout.Pixels(150, self.uiScale), Layout.Pixels(26, self.uiScale))
    Layout.SetBounds(self.providerCombo, pad + Layout.Pixels(302, self.uiScale), Layout.Pixels(7, self.uiScale), Layout.Pixels(160, self.uiScale), Layout.Pixels(26, self.uiScale))
    for index, button in ipairs(self.controls) do
        local width, x = Layout.Pixels(112, self.uiScale), pad + ((index - 1) % 5) * Layout.Pixels(118, self.uiScale)
        local y = self:getHeight() - controlsHeight + math.floor((index - 1) / 5) * Layout.Pixels(28, self.uiScale)
        Layout.SetBounds(button, x, y, width, Layout.Pixels(24, self.uiScale))
    end
    Layout.SetBounds(self.rows, pad, top, split - pad * 2, self:getHeight() - top - controlsHeight - pad)
    Layout.SetBounds(self.details, split + pad, top, self:getWidth() - split - pad * 2, self:getHeight() - top - controlsHeight - pad)
end
function ISPNCKnowledgeDebugWindow:getStatusFilter()
    return self.statusCombo:getOptionData(self.statusCombo.selected) or "all"
end
function ISPNCKnowledgeDebugWindow:getFilter()
    return { status = self:getStatusFilter(),
        category = self.categoryCombo and self.categoryCombo:getOptionData(self.categoryCombo.selected) or "all",
        providerID = self.providerCombo and self.providerCombo:getOptionData(self.providerCombo.selected) or "all",
        showTruth = self.showTruth }
end
function ISPNCKnowledgeDebugWindow:rebuildFilters(snapshot)
    local categories, providers = { all = true }, { all = true }
    for _, row in ipairs(snapshot and snapshot.rows or {}) do categories[row.category or "other"] = true; providers[row.providerID or "unknown"] = true end
    for _, spec in ipairs({ { combo = self.categoryCombo, values = categories }, { combo = self.providerCombo, values = providers } }) do
        local current = spec.combo:getOptionData(spec.combo.selected) or "all"
        spec.combo:clear()
        local values = {}; for value in pairs(spec.values) do values[#values + 1] = value end; table.sort(values)
        for _, value in ipairs(values) do spec.combo:addOptionWithData(value, value) end
        spec.combo:selectData(spec.values[current] and current or "all")
    end
end
function ISPNCKnowledgeDebugWindow:getSelected()
    local selected = self.rows:getItem()
    return selected and selected.item or nil
end
function ISPNCKnowledgeDebugWindow:refresh()
    local snapshot = ClientState.knowledgeDebug
    self:rebuildFilters(snapshot)
    self.currentRows = Presentation.BuildDebugRows(snapshot, self:getFilter())
    clearList(self.rows)
    for _, row in ipairs(self.currentRows) do self.rows:addItem(row.descriptorID, row) end
    if #self.currentRows > 0 then self.rows.selected = 1 end
    self:refreshDetails()
end
function ISPNCKnowledgeDebugWindow:refreshDetails()
    local row = self:getSelected()
    clearList(self.details)
    if not row then return end
    local raw = row.raw or {}
    for _, item in ipairs({
        { "Descriptor", row.descriptorID }, { "Category", row.category }, { "Provider", row.providerID }, { "Resolver", raw.resolverID or "unknown" },
        { "Value type", raw.valueType or "unknown" }, { "Privacy", row.privacy }, { "Truth", self.showTruth and row.truth or "Hidden" },
        { "Player knows", row.known }, { "Status", row.status }, { "Evidence", tostring(row.evidenceCount) },
        { "Familiarity minimum", tostring(raw.discovery and raw.discovery.minimumFamiliarity or 0) },
        { "Capabilities", table.concat((function() local keys = {}; for key, enabled in pairs(raw.capabilities or {}) do if enabled then keys[#keys + 1] = key end end; table.sort(keys); return keys end)(), ", ") },
    }) do self.details:addItem(item[1], { label = item[1], value = item[2] }) end
    for _, evidence in ipairs(raw.evidence or {}) do
        local direction = (tonumber(evidence.direction) or 0) > 0 and "+" or (tonumber(evidence.direction) or 0) < 0 and "-" or "0"
        self.details:addItem("Evidence", { label = tostring(evidence.sourceType) .. " " .. direction,
            value = string.format("s %.2f / r %.2f", tonumber(evidence.strength) or 0, tonumber(evidence.reliability) or 0) })
        self.details:addItem("  event", { label = "  event", value = tostring(evidence.sourceEventID or evidence.id) })
    end
end
function ISPNCKnowledgeDebugWindow:prerender()
    PsychopatzWindow.prerender(self)
    local selected = self.rows and self.rows.selected or nil
    if selected ~= self.lastRowSelection then
        self.lastRowSelection = selected
        self:refreshDetails()
        local row = self:getSelected()
        local snapshot = ClientState.knowledgeDebug or {}
        if row and snapshot.detailDescriptorID ~= row.descriptorID
            and self.lastDetailRequest ~= row.descriptorID .. ":" .. tostring(snapshot.revision)
        then
            self.lastDetailRequest = row.descriptorID .. ":" .. tostring(snapshot.revision)
            PNC.Client.RequestKnowledgeDebug(self.npcID, self.showTruth, row.descriptorID)
        end
    end
end
function ISPNCKnowledgeDebugWindow:onFilter() self:refresh() end
function ISPNCKnowledgeDebugWindow:onControl(button)
    if button.internal == "refresh" then return PNC.Client.RequestKnowledgeDebug(self.npcID, self.showTruth) end
    if button.internal == "truth" then self.showTruth = not self.showTruth; button:setTitle(self.showTruth and "Hide Truth" or "Show Truth"); return PNC.Client.RequestKnowledgeDebug(self.npcID, self.showTruth) end
    local row = self:getSelected()
    if not row then return end
    local action = ({ reveal = "reveal", forget = "forget", force_disclosure = "force_disclosure", positive = "add_evidence", negative = "add_evidence", clear = "clear_evidence", recalculate = "recalculate", validate = "validate" })[button.internal]
    if action and PNC.Client and PNC.Client.SendDebug then
        PNC.Client.SendDebug("knowledge_debug_action", { knowledgeAction = action, npcID = self.npcID, descriptorID = row.descriptorID,
            direction = button.internal == "negative" and -1 or 1, strength = .55, reliability = 1, showTruth = self.showTruth })
    end
end
function DebugUI.ReceiveSnapshot(snapshot)
    if DebugUI.instance and snapshot and tostring(snapshot.npcID) == tostring(DebugUI.instance.npcID) then DebugUI.instance:refresh() end
end
function DebugUI.Open(npcID)
    if not PNC.Client or not PNC.Client.CanUseDebug or not PNC.Client.CanUseDebug() then return nil end
    if not DebugUI.instance then
        DebugUI.instance = UI.NewWindow(ISPNCKnowledgeDebugWindow, { title = "NPC Knowledge Laboratory", resizable = true, responsiveSpec = { width = 980, height = 620, minWidth = 720, minHeight = 420 } })
        DebugUI.instance:initialise(); DebugUI.instance:instantiate()
    end
    DebugUI.instance.npcID = tostring(npcID or "")
    DebugUI.instance:addToUIManager(); DebugUI.instance:setVisible(true); DebugUI.instance:bringToTop()
    DebugUI.instance:refresh()
    PNC.Client.RequestKnowledgeDebug(DebugUI.instance.npcID, DebugUI.instance.showTruth)
    return DebugUI.instance
end

return DebugUI
