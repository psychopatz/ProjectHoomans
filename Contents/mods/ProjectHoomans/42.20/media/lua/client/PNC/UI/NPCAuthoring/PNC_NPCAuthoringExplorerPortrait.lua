-- Portrait selection/lifecycle for the shared browser, including roster members.
local Explorer, UI = ISPNCNPCAuthoringItemExplorer, PsychopatzCore.UI
local L = UI.Layout
local function tr(k, fallback) return PNC.Translation.GetKey(k, fallback) end
function Explorer:buildExplorerPortraitControls()
    local function change(delta)
        self.previewIndex = (self.previewIndex - 1 + delta) % math.max(1, self.previewCount) + 1
        self:refreshExplorerPortrait(self:currentSelection()); self:onResize()
    end
    self.portraitPrevious = UI.CreateButton(self, { title = '<', target = self, variant = 'quiet', onclick = function() change(-1) end })
    self.portraitNext = UI.CreateButton(self, { title = '>', target = self, variant = 'quiet', onclick = function() change(1) end })
    self.portraitPrevious.tooltip = tr('UI_PNC_Authoring_PreviousMember', 'Previous NPC in this roster')
    self.portraitNext.tooltip = tr('UI_PNC_Authoring_NextMember', 'Next NPC in this roster')
    self.portraitCaption = ISLabel:new(0, 0, 24, '', .9, .95, .95, 1, UIFont.Small, true)
    self.portraitCaption:initialise(); self:addChild(self.portraitCaption)
    self.previewIndex, self.previewCount = 1, 1
end
function Explorer:refreshExplorerPortrait(item)
    if self.previewItemID ~= (item and item.id) then self.previewIndex = 1 end
    self.previewItemID = item and item.id
    local spec, label, count, reason
    if item and self.options.preview then spec, label, count, reason = self.options.preview(item, self.previewIndex) end
    self.previewCount = math.max(1, count or 1)
    self.hasPreview = spec ~= nil
    self.previewLabel = label or item and item.label or ''
    self.previewReason = reason
    if self.preview then
        if spec then
            self.preview:setViewRegion(self.options.viewRegion or 'body')
            self.preview:setTarget(nil, spec, false)
        else self.preview:setVisible(false); self.preview.targetKey = nil end
    end
    if item and self.options.preview and not spec then
        UI.AddKeyValue(self.details, tr('UI_PNC_Authoring_Preview', 'Preview'),
            tr('UI_PNC_Authoring_PreviewUnavailable', 'Preview unavailable'))
    end
end
function Explorer:layoutExplorerPortrait(x, y, side, height, h, gap)
    local visible = side > 0 and self.hasPreview and self.preview ~= nil
    local multiple = visible and self.previewCount > 1
    local portraitHeight = math.max(1, height * .65 - h - gap)
    if self.preview then
        self.preview:setVisible(visible)
        L.SetBounds(self.preview, x, y, side, portraitHeight)
        if visible and self.preview.setPortraitBounds then self.preview:setPortraitBounds(x, y, side, portraitHeight) end
    end
    self.portraitPrevious:setVisible(multiple); self.portraitNext:setVisible(multiple); self.portraitCaption:setVisible(visible)
    local captionY, inset = y + portraitHeight + gap, multiple and 34 or 0
    L.SetBounds(self.portraitPrevious, x, captionY, 28, h)
    L.SetBounds(self.portraitNext, x + math.max(0, side - 28), captionY, 28, h)
    local caption = self.previewLabel .. (multiple and (' (' .. self.previewIndex .. '/' .. self.previewCount .. ')') or '')
    self.portraitCaption:setName(L.Ellipsize(caption, UIFont.Small, math.max(1, side - inset * 2)))
    self.portraitCaption.tooltip = caption
    L.SetBounds(self.portraitCaption, x + inset, captionY, math.max(1, side - inset * 2), h)
    if visible then return captionY + h + gap, math.max(1, height - portraitHeight - h - gap * 2) end
    return y, height
end
return Explorer
