local Window = ISPNCNPCAuthoringEditor
local I = Window.Internal
local UI, Layout, tr = I.UI, I.Layout, I.tr

local function drawRoster(list, y, entry, alternate)
    local row = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local width = math.max(1, list:getWidth() - 24)
    list:drawText(Layout.Ellipsize(row.label or "", UIFont.Small, width),
        8, y + 6, 0.95, 0.95, 0.95, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.subtitle or "", UIFont.Small, width),
        8, y + list.itemheight / 2, row.error and 1 or 0.62,
        row.error and 0.4 or 0.72, 0.72, 1, UIFont.Small)
    return y + list.itemheight
end

function Window:buildRoster()
    self.rosterLabel = I.addLabel(self, tr("UI_PNC_Authoring_Roster", "Characters"))
    self.roster = UI.CreateList(self, { itemHeight = 52, doDrawItem = drawRoster })
    self.roster:setOnMouseDownFunction(self, function(target, row)
        if row and row.id ~= target.rosterSelection and target.onSelectRoster then
            target:pullForm()
            target.onSelectRoster(row.id)
        end
    end)
end

function Window:setRoster(rows, selected, onSelect)
    self.rosterSelection = selected
    self.onSelectRoster = onSelect or self.onSelectRoster
    if not self.roster then return end
    self.roster:clear()
    for _, row in ipairs(rows or {}) do
        self.roster:addItem(row.label or "", row)
        if row.id == selected then self.roster.selected = #self.roster.items end
    end
end

function Window:refreshDebugRoster()
    if self.presentationMode == "companion" then return end
    self.draftRoster = self.draftRoster or {}
    if not self.debugRosterID or self.debugRosterID == "current" then
        self.draftRoster.current = self.draft
    end
    local rows = { { id = "current", label = tr("UI_PNC_Authoring_CurrentDraft", "Working draft"),
        subtitle = self.draftRoster.current and self.draftRoster.current.displayName or "" } }
    for _, entry in ipairs(self.savedDraftEntries or {}) do
        rows[#rows + 1] = { id = entry.fileName, label = entry.label or entry.fileName,
            subtitle = tr("UI_PNC_Authoring_SavedDraft", "Saved character") }
    end
    self:setRoster(rows, self.debugRosterID or "current", function(id)
        self.draftRoster[self.debugRosterID or "current"] = self.draft
        self.draftRosterPreviews = self.draftRosterPreviews or {}
        self.draftRosterPreviews[self.debugRosterID or "current"] = self.previewDraft
        local draft, reason = self.draftRoster[id]
        if not draft then draft, reason = I.Storage.LoadFile(id) end
        if not draft then self:setStatus(tostring(reason)); return end
        self.debugRosterID = id
        self.draft = draft
        self.previewDraft = self.draftRosterPreviews[id]
        self.appearanceTab.draft = draft
        self:syncControls()
        self.appearanceTab:syncFromDraft()
        self:refreshPreview(self.previewDraft == nil)
        self:refreshDebugRoster()
    end)
end

return Window
