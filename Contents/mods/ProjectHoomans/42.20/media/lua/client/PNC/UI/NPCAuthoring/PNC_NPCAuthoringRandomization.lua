require "PNC/Identity/PNC_NPCAuthoringVariation"
local Window = ISPNCNPCAuthoringEditor
local I, UI = Window.Internal, PsychopatzCore.UI
local V, Fields = PNC.NPCAuthoringVariation, PNC.NPCAuthoringFields
local labels = {
    bio = { "UI_PNC_Authoring_DiceBio", "Randomize names and nickname. Gender, archetype and inherited fields stay unchanged." },
    appearance = { "UI_PNC_Authoring_DiceAppearance", "Randomize editable skin, hair and voice. Clothes and inherited values stay unchanged." },
    attributes = { "UI_PNC_Authoring_DiceAttributes", "Randomize skills and compatible traits. Companion-selection traits are excluded." },
    loadout = { "UI_PNC_Authoring_DiceLoadout", "Randomize clothing and gear. Face, voice and identity stay unchanged." },
    relations = { "UI_PNC_Authoring_BackstoryPending", "Backstory generation is planned. The relationship is set by your selected trait." },
}
function Window:buildTabRandomizers()
    self.pageDice = {}
    for scope, page in pairs(self.pages) do
        local button = UI.CreateButton(page, { title = "", target = self,
            onclick = function(target) target:randomizeTab(scope) end, variant = "quiet" })
        button.render = function(control)
            ISButton.render(control)
            local size = math.min(control.width, control.height) * .58
            local x, y = (control.width - size) / 2, (control.height - size) / 2
            local alpha = scope == "relations" and .45 or .95
            control:drawRectBorder(x, y, size, size, alpha, .9, .95, .95)
            local pip = math.max(2, size / 8)
            for _, pos in ipairs({ { .25, .25 }, { .75, .25 }, { .5, .5 }, { .25, .75 }, { .75, .75 } }) do
                control:drawRect(x + size * pos[1] - pip / 2, y + size * pos[2] - pip / 2, pip, pip, alpha, .9, .95, .95)
            end
        end
        self.pageDice[scope] = button
    end
    self:refreshTabRandomizers()
end
function Window:refreshTabRandomizers()
    for scope, button in pairs(self.pageDice or {}) do
        local description = I.tr(labels[scope][1], labels[scope][2])
        if self.presentationAdapter and scope ~= "relations" then
            for _, field in ipairs(I.Presentation.List("companion")) do
                if V.Includes(scope, field.id) then
                    local cap = self:fieldCapability(field.id)
                    if cap.explanation then description = description .. "\n" .. cap.explanation end
                end
            end
        end
        button.tooltip = description
        button:setVisible(not (self.itemExplorer and self.itemExplorer:getIsVisible()))
        Fields.EnableButton(button, self.draft ~= nil and scope ~= "relations")
    end
end
function Window:layoutTabDice(scope, width, rowHeight, gap)
    local button = self.pageDice and self.pageDice[scope]
    if button then UI.Layout.SetBounds(button, math.max(gap, width - rowHeight - gap - 16), gap, rowHeight, rowHeight) end
end
function Window:randomizeTab(scope)
    if scope == "relations" then self:setStatus(I.tr(labels.relations[1], labels.relations[2])); return false end
    if not self.draft then return false end
    if scope ~= "bio" and (self.presentationAdapter or Fields.HasPending(self)) and self:pullForm() == false then return false end
    local ok, reason
    if self.presentationAdapter then
        ok, reason = self.presentationAdapter:RandomizeTab(scope)
        if ok then
            if scope == "bio" then self.textEdits = {} end
            self:refreshFromAdapter(false)
        end
    else
        self.tabVariationCount = (self.tabVariationCount or 0) + 1
        local candidate
        local current = I.Model.BuildBlueprint(self.draft)
        local fingerprint = current and PNC.NPCAuthoring.Blueprint.Fingerprint(current)
        candidate, reason = V.Generate(self.draft, scope, V.Seed(self.draft.previewSeed, scope, self.tabVariationCount, fingerprint))
        if candidate then ok, reason = I.Model.BuildBlueprint(I.Model.BuildPreviewDraft(candidate)) end
        if ok then
            if scope == "bio" then self.textEdits = {} end
            self.draft = candidate
            self:syncControls(); self:refreshPreview(false)
        end
    end
    if not ok then self:setStatus(I.tr("UI_PNC_Authoring_VariationFailed", "Could not generate new values for this tab")) end
    return ok and true or false, reason
end
return Window
