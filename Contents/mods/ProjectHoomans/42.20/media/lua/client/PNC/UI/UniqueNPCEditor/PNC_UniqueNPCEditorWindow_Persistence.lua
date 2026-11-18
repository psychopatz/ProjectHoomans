local Window = ISPNCNPCAuthoringEditor
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
    self.savedDraftEntries = Storage.List()
    for _, entry in ipairs(self.savedDraftEntries) do
        self.fileCombo:addOptionWithData(
            tostring(entry.label or entry.fileName), entry.fileName)
    end
    selectCombo(self.fileCombo, previous)
    if self.refreshDebugRoster then self:refreshDebugRoster() end
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
    self.textEdits = {}
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

function Window:browseSavedCharacters()
    if self:pullForm() == false then return end
    local portraitProviders = {}
    local function entries()
        local items = {}
        for _, entry in ipairs(Storage.List()) do
            local label = entry.label or entry.fileName
            items[#items + 1] = { id = entry.fileName, label = label, search = string.lower(label .. ' ' .. entry.fileName) }
        end
        return items
    end
    self.itemExplorer:Show({ mode = 'preset', title = tr('UI_PNC_Authoring_Presets', 'Presets...'), items = entries(), reloadItems = entries,
        applyLabel = tr('UI_PNC_StartingCompanion_Load', 'Load'),
        preview = function(item, index)
            if not portraitProviders[item.id] then
                local draft = Storage.LoadFile(item.id)
                if not draft then return nil end
                local previews = require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringPresetPreview'
                portraitProviders[item.id] = previews.Draft(draft)
            end
            return portraitProviders[item.id](index)
        end,
        onChoose = function(item)
            selectCombo(self.fileCombo, item.id)
            local previous = self.debugRosterID
            self.debugRosterID = item.id
            local ok = self:loadSelected()
            if not ok then self.debugRosterID = previous end
            return ok
        end,
        onDelete = function(item)
            local ok, reason = Storage.Delete(item.id)
            if ok then
                if self.draftRoster then self.draftRoster[item.id] = nil end
                if self.draftRosterPreviews then self.draftRosterPreviews[item.id] = nil end
                if self.debugRosterID == item.id then self.debugRosterID = 'current' end
                self:refreshFiles()
            end
            return ok, reason
        end })
end

