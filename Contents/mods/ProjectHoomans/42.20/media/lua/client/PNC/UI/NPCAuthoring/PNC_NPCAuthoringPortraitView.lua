-- Preview framing is presentation state, never an authored NPC mutation.
local Window = ISPNCNPCAuthoringEditor
function Window:syncPortraitView(force)
    local panel, source = self.portraitPanel, self.portraitSourceSpec
    if not panel or not source then return false end
    local face = self.tabPanel and self.tabPanel:getActiveView() == self.appearanceTab
    local mode = face and 'face' or 'body'
    self.portraitZooms = self.portraitZooms or { face = 14, body = -3 }
    if self.portraitMode and self.portraitMode ~= mode then self.portraitZooms[self.portraitMode] = panel.zoom end
    if self.portraitMode ~= mode then panel.zoom = self.portraitZooms[mode] end
    self.portraitMode, panel.yOffset = mode, face and -.85 or 0
    local spec = PNC.NPCAuthoring.Registry.Copy(source)
    spec.faceOnly, spec.includeCurrentClothing = face == true, false
    spec.key = tostring(source.key or source.id) .. ':' .. mode
    if face then
        spec.equipment = {}
        spec.appearance = spec.appearance or {}
        spec.appearance.outfit, spec.appearance.outfitItems, spec.appearance.outfitItemSpecs = nil, {}, {}
    end
    self.portraitTarget, self.previewSpecKey = spec, spec.key
    local rendered = panel:setTarget(nil, spec, force == true)
    if panel.applyViewState then panel:applyViewState() end
    return rendered == true
end
function Window:update()
    if ISPanel.update then ISPanel.update(self) end
    local voice = self.appearanceTab and self.appearanceTab.voicePreview
    if voice then voice:Update() end
end
return Window
