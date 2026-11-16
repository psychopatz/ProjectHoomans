local Window = ISPNCNPCAuthoringEditor
local Internal = Window.Internal or {}
local Model = Internal.Model
local UI = Internal.UI
local tr = Internal.tr

function Window:setStatus(value)
    self.statusText = tostring(value or "")
    if self.statusLabel and UI.SetLabelText then
        UI.SetLabelText(self.statusLabel, self.statusText)
    end
end

function Window:effectiveDraft()
    return self.previewDraft or self.draft
end

function Window:refreshPreview(force)
    if not self.draft then
        if self.portraitPanel then
            self.portraitPanel:setVisible(false)
        end
        return false
    end
    if self.presentationAdapter and not self._skipAdapterCommit
        and not self._committingAdapter
    then
        self:commitAdapterDraft()
    end
    if self.presentationAdapter then
        local identity = self.presentationAdapter.PreviewIdentity
            and self.presentationAdapter:PreviewIdentity() or nil
        local generationIdentity = self.presentationAdapter.PreviewGenerationIdentity
            and self.presentationAdapter:PreviewGenerationIdentity() or identity
        if identity ~= self.previewIdentity then
            self.previewIdentity = identity
        end
        if generationIdentity ~= self.previewGenerationIdentity then
            self.previewGenerationIdentity = generationIdentity
            self.previewDraft = nil
        end
    end
    self.previewDraft = Model.UpdatePreviewDraft(self.previewDraft, self.draft)
    local valid, reason = Model.Validate(self.draft)
    local previewRecord, previewReason = Model.EnsureRuntimeRecord(
        self.previewDraft, force == true)
    local rendered = false
    if previewRecord then
        local spec = Model.BuildPortraitSpec(self.previewDraft)
        self.previewSpecKey = spec and spec.key or nil
        self.portraitTarget = spec
        self.portraitPanel:setVisible(true)
        rendered = self.portraitPanel:setTarget(
            nil, spec, force == true) == true
    elseif self.portraitPanel then
        self.portraitPanel:setVisible(false)
    end
    self:refreshDetails()
    if valid and rendered then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_Ready", "Draft ready"))
    elseif rendered then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_PreviewOnly",
            "Preview only - enter a first name and surname before saving"))
    else
        self:setStatus(tostring(previewReason or reason
            or "preview unavailable"):gsub("_", " "))
    end
    return rendered == true
end

function Window:onFormChanged(force)
    self:pullForm()
    self:refreshPreview(force == true)
end

function Window:onAppearanceChanged()
    self:syncControls()
    if self.appearanceTab then
        self.appearanceTab.draft = self.draft
        if self.appearanceTab.syncFromDraft then
            self.appearanceTab:syncFromDraft()
        end
    end
    self:refreshPreview(false)
end

function Window:adoptPreview()
    if self.previewDraft and self.previewDraft.runtimeRecord then
        self.draft.runtimeRecord = self.previewDraft.runtimeRecord
        self.draft.id = Model.BuildID(self.draft)
    end
end

