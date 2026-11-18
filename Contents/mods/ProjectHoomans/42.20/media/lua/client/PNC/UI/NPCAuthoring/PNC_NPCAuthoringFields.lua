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

function Fields.Gender(editor, parent)
    local panel = ISPanel:new(0, 0, 1, 1)
    panel:initialise(); panel:instantiate(); panel:noBackground()
    panel.options = { { data = false }, { data = true } }
    panel.selected = 1
    panel.pncKind = "gender"
    panel.buttons = {}
    function panel:setEnabled(value)
        self.enabled = value
        for _, button in ipairs(self.buttons) do button:setEnable(value) end
    end
    function panel:selectData(value)
        self.selected = value == true and 2 or 1
        for index, button in ipairs(self.buttons) do
            button.backgroundColor = index == self.selected
                and { r = 0.11, g = 0.34, b = 0.24, a = 1 }
                or { r = 0.08, g = 0.10, b = 0.12, a = 1 }
        end
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
        for index, button in ipairs(self.buttons) do
            button.backgroundColor = index == self.selected and { r = 0.10, g = 0.32, b = 0.23, a = 1 }
                or { r = 0.07, g = 0.09, b = 0.11, a = 1 }
        end
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
        for _, button in ipairs(self.buttons) do button:setEnable(value) end
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

return Fields
