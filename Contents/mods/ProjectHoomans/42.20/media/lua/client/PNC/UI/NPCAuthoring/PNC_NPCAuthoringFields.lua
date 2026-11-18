-- Shared edit/lock presentation. Native text owns its caret while being edited;
-- resolved NPC state is updated only at an explicit commit boundary.
PNC.NPCAuthoringFields = PNC.NPCAuthoringFields or {}
local Fields = PNC.NPCAuthoringFields
local UI = PsychopatzCore.UI
local function tr(key, fallback) return PNC.Translation.GetKey(key, fallback) end

function Fields.HasPending(editor)
    for _ in pairs(editor.textEdits or {}) do return true end
    return false
end

function Fields.BindText(editor, entry, id)
    entry.pncTextField = id
    entry.onTextChange = function()
        if editor.syncing then return end
        if editor:fieldCapability(id).editable == false then return end
        editor.textEdits = editor.textEdits or {}
        editor.textEdits[id] = entry:getText()
    end
    local function commit()
        if not editor.syncing and Fields.HasPending(editor) then
            local ok = editor:pullForm()
            if ok ~= false and not editor.presentationAdapter then editor:refreshPreview(false) end
        end
    end
    entry.onCommandEntered = commit
    entry.onLostFocus = commit
end

function Fields.SyncText(editor, entry, value)
    value = value == nil and "" or tostring(value)
    if editor.textEdits and editor.textEdits[entry.pncTextField] ~= nil then return end
    if entry:getText() ~= value then entry:setText(value) end
end

-- Disabled actions are neutral, not validation errors. Native setEnable uses
-- a red border; restore the shared quiet theme while retaining native gating.
function Fields.EnableButton(button, enabled)
    button.pncEnabledVariant = button.pncEnabledVariant or button.psychopatzVariant or "quiet"
    button:setEnable(enabled == true)
    if UI.StyleButton then UI.StyleButton(button, enabled and button.pncEnabledVariant or "quiet") end
end

function Fields.Lock(editor, control, id, parent)
    local capability = editor:fieldCapability(id)
    local locked = capability.editable == false
    if control.buttons and control.setEnabled then control:setEnabled(not locked)
    elseif control.setEditable then control:setEditable(not locked)
    elseif control.setEnabled then control:setEnabled(not locked)
    elseif control.setEnable then control:setEnable(not locked) end
    if not control.pncLock then
        local lock = UI.CreateButton(parent, { title = "", target = editor,
            onclick = function() end, variant = "quiet" })
        if lock.setImage and getTexture then lock:setImage(getTexture("media/ui/MP/mp_ui_passwordOn.png")) end
        control.pncLock = lock
    end
    local reason = capability.sourceLabel or tr("UI_PNC_Authoring_Locked", "Derived value")
    if capability.rule and string.find(capability.rule, "surname", 1, true) then
        reason = tr("UI_PNC_Authoring_LockSurname", "Matches the player's surname for this family relationship")
    elseif capability.rule and string.find(capability.rule, "appearance", 1, true) then
        reason = tr("UI_PNC_Authoring_LockAppearance", "Inherited from the player's family appearance")
    elseif capability.derived then
        reason = tr("UI_PNC_Authoring_LockRelationship", "Determined by this companion relationship")
    end
    control.pncLock.tooltip = reason
    control.tooltip = locked and control.pncLock.tooltip or nil
    control.pncLocked = locked and capability.visible ~= false
    control.pncLock:setVisible(control.pncLocked)
    return locked
end

function Fields.Bounds(control, x, y, width, height)
    local lock = control.pncLock
    local locked = control.pncLocked == true
    local reserve = locked and height + 4 or 0
    UI.Layout.SetBounds(control, x, y, math.max(1, width - reserve), height)
    if lock then
        UI.Layout.SetBounds(lock, x + width - height, y, height, height)
        if lock.forceImageSize then lock:forceImageSize(height - 8, height - 8) end
        lock:setVisible(locked)
    end
end

function Fields.SelectButton(button, selected, enabled)
    local variant = selected and "selected" or "quiet"
    button.pncEnabledVariant = variant
    button:setEnable(enabled ~= false)
    if UI.StyleButton then UI.StyleButton(button, variant)
    else button.backgroundColor = selected and { r = .11, g = .34, b = .24, a = 1 }
        or { r = .08, g = .10, b = .12, a = 1 } end
end

function Fields.Gender(editor, parent)
    local panel = ISPanel:new(0, 0, 1, 1)
    panel:initialise(); panel:instantiate(); panel:noBackground()
    panel.options = { { data = false }, { data = true } }
    panel.selected = 1
    panel.pncKind = "gender"
    panel.buttons = {}
    function panel:setEnabled(value)
        self.enabled = value
        for index, button in ipairs(self.buttons) do Fields.SelectButton(button, index == self.selected, value) end
    end
    function panel:selectData(value)
        self.selected = value == true and 2 or 1
        for index, button in ipairs(self.buttons) do Fields.SelectButton(button, index == self.selected, self.enabled) end
    end
    function panel:onResize()
        local w = math.max(1, (self.width - 6) / 2)
        for index, button in ipairs(self.buttons) do
            UI.Layout.SetBounds(button, (index - 1) * (w + 6), 0, w, self.height)
            if button.forceImageSize then button:forceImageSize(self.height - 8, self.height - 8) end
        end
    end
    for index, name in ipairs({ "Male", "Female" }) do
        local female = index == 2
        local button = UI.CreateButton(panel, { title = "", target = panel,
            onclick = function(target)
                if target.enabled == false then return end
                target:selectData(female)
                editor:onComboChanged(target)
            end, variant = "quiet" })
        if button.setImage and getTexture then button:setImage(getTexture("media/PNC_Gender" .. name .. ".png")) end
        button.tooltip = tr("UI_PNC_UniqueNPCEditor_" .. name, name)
        panel.buttons[index] = button
    end
    parent:addChild(panel)
    return panel
end

function Fields.Choice(editor, parent, callback)
    local panel = ISPanel:new(0, 0, 1, 1)
    panel:initialise(); panel:instantiate(); panel:noBackground()
    panel.options, panel.buttons, panel.selected = {}, {}, 0
    function panel:clear()
        for _, button in ipairs(self.buttons) do self:removeChild(button) end
        self.buttons, self.options, self.selected = {}, {}, 0
    end
    function panel:selectData(value)
        for index, option in ipairs(self.options) do
            if option.data == value then self.selected = index end
        end
        for index, button in ipairs(self.buttons) do Fields.SelectButton(button, index == self.selected, self.enabled) end
    end
    function panel:addOptionWithData(label, data)
        local index = #self.options + 1
        self.options[index] = { text = label, data = data }
        self.buttons[index] = UI.CreateButton(self, { title = label, target = self,
            onclick = function(target)
                if target.enabled == false then return end
                target:selectData(data)
                if callback then callback(editor, target) end
            end, variant = "quiet" })
    end
    function panel:setEnabled(value)
        self.enabled = value
        for index, button in ipairs(self.buttons) do Fields.SelectButton(button, index == self.selected, value) end
    end
    function panel:onResize()
        local count = math.max(1, #self.buttons)
        local columns = math.min(2, count)
        local rows = math.ceil(count / columns)
        local w, h = math.max(1, (self.width - 4) / columns), math.max(1, (self.height - 4 * (rows - 1)) / rows)
        for index, button in ipairs(self.buttons) do
            UI.Layout.SetBounds(button, ((index - 1) % columns) * (w + 4), math.floor((index - 1) / columns) * (h + 4), w, h)
        end
    end
    parent:addChild(panel)
    return panel
end

-- Presentation capability, shared by hosts, callbacks and option builders.
function Fields.CanRandomize(editor)
    local host = editor and (editor.presentationMode and editor or editor.parentEditor)
    return not host or host.presentationMode ~= "companion"
end

-- A generated value is a display-only current selection, never a way to
-- re-enter Random after choosing a concrete value in companion creation.
function Fields.Options(editor, combo, values, current)
    if not combo then return end
    combo:clear()
    local random = Fields.CanRandomize(editor)
    for _, value in ipairs(values or {}) do
        if random or value.id ~= "random" and value.id ~= "__random" then
            combo:addOptionWithData(value.label, value.id)
        end
    end
    Fields.Select(editor, combo, current)
end

function Fields.Select(editor, combo, value)
    if not combo then return end
    local generated = value == nil or value == "random" or value == "__random"
    if not Fields.CanRandomize(editor) and generated then
        value = "__current"
        local found
        for _, option in ipairs(combo.options or {}) do if option.data == value then found = true end end
        if not found then combo:addOptionWithData(tr("UI_PNC_Authoring_CurrentValue", "Current value"), value) end
    elseif value == nil then
        value = ""
        for _, option in ipairs(combo.options or {}) do if option.data == "__random" then value = "__random" end end
    end
    for index, option in ipairs(combo.options or {}) do
        if option.data == value then combo.selected = index; return end
    end
    -- Preserve missing modded values without silently selecting the first row.
    local label = value == "custom" and tr("UI_PNC_Authoring_CustomColor", "Custom color")
        or value == "legacy" and tr("UI_PNC_UniqueNPCEditor_LegacySkin", "Legacy custom tone (select a native tone to replace)")
        or tr("UI_PNC_UniqueNPCEditor_Unavailable", "Unavailable: ") .. tostring(value)
    combo:addOptionWithData(label, value)
    combo.selected = #combo.options
end

function Fields.NativeMetrics(control)
    if not control then return end
    if control.pncSmallFont and control.setFont then
        control:setFont(UIFont.Small, 6)
        for _, entry in ipairs(control.items or {}) do entry.height = control.itemheight end
    end
    if control.baseHeight ~= nil then control.baseHeight = control.height end
    if control.originalX ~= nil then control.originalX = control.x end
    for _, child in pairs(control.children or {}) do Fields.NativeMetrics(child) end
end

function Fields.Level(parent)
    local panel = ISPanel:new(0, 0, 1, 1)
    panel:initialise(); panel:instantiate(); panel:noBackground()
    panel.options, panel.selected = {}, 1
    function panel:clear() self.options, self.selected = {}, 1 end
    function panel:refreshValue()
        local option = self.options[self.selected]
        self.value:setName(option and tostring(option.data) or "0")
    end
    function panel:addOptionWithData(label, data) self.options[#self.options + 1] = { text = label, data = data }; self:refreshValue() end
    function panel:selectData(data)
        for index, option in ipairs(self.options) do if option.data == data then self.selected = index end end
        self:refreshValue()
    end
    panel.value = ISLabel:new(0, 0, 24, "0", 1, 1, 1, 1, UIFont.Small, true)
    panel.value:initialise(); panel:addChild(panel.value)
    panel.buttons = {}
    for index, title in ipairs({ "-", "+" }) do
        local delta = index == 1 and -1 or 1
        panel.buttons[index] = UI.CreateButton(panel, { title = title, target = panel, onclick = function(target)
            target.selected = math.max(1, math.min(#target.options, target.selected + delta)); target:refreshValue()
        end, variant = "quiet" })
    end
    function panel:setEnabled(value) for _, b in ipairs(self.buttons) do Fields.EnableButton(b, value) end end
    function panel:onResize()
        local size = math.min(self.height, self.width / 3)
        UI.Layout.SetBounds(self.buttons[1], 0, 0, size, self.height)
        UI.Layout.SetBounds(self.buttons[2], self.width - size, 0, size, self.height)
        UI.Layout.SetBounds(self.value, size + 5, 0, math.max(1, self.width - size * 2 - 10), self.height)
        Fields.NativeMetrics(self)
    end
    parent:addChild(panel)
    return panel
end

return Fields
