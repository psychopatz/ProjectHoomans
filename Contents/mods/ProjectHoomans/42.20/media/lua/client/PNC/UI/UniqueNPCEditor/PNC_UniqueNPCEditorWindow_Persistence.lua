local Window = ISPNCUniqueNPCEditorWindow
local Internal = Window.Internal or {}
local Storage = Internal.Storage
local tr = Internal.tr
local comboData = Internal.comboData
local clearCombo = Internal.clearCombo
local selectCombo = Internal.selectCombo

function Window:refreshFiles()
    if not self.fileCombo then return end
    local previous = comboData(self.fileCombo)
    clearCombo(self.fileCombo)
    for _, entry in ipairs(Storage.List()) do
        self.fileCombo:addOptionWithData(
            tostring(entry.label or entry.fileName), entry.fileName)
    end
    selectCombo(self.fileCombo, previous)
end

function Window:loadSelected()
    local fileName = comboData(self.fileCombo)
    local draft
    local reason
    if not fileName then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_SelectFile",
            "Choose a saved draft first"))
        return false
    end
    draft, reason = Storage.LoadFile(fileName)
    if not draft then
        self:setStatus(tostring(reason or "load failed"))
        return false
    end
    self.draft = draft
    self.previewDraft = nil
    if self.appearanceTab then self.appearanceTab.draft = self.draft end
    self:syncControls()
    if self.appearanceTab and self.appearanceTab.syncFromDraft then
        self.appearanceTab:syncFromDraft()
    end
    self:refreshPreview(true)
    return true
end

