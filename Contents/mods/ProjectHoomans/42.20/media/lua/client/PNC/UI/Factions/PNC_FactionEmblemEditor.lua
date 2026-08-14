-- Reusable player-facing layered faction-emblem editor.

require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"

PNC = PNC or {}
PNC.FactionEmblemEditor = PNC.FactionEmblemEditor or {}

local Editor = PNC.FactionEmblemEditor
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Emblems = PNC.FactionEmblems
local Renderer = PNC.FactionEmblemRenderer

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

ISPNCFactionEmblemEditor =
    PsychopatzWindow:derive("ISPNCFactionEmblemEditor")

local function addCombo(owner, callback)
    local combo = ISComboBox:new(
        0,
        0,
        150,
        26,
        owner,
        callback
    )
    combo:initialise()
    combo:instantiate()
    owner:addChild(combo)
    return combo
end

local function populate(combo, values, includeNone)
    if includeNone then
        combo:addOptionWithData(tr("UI_PNC_Emblem_None", "(none)"), false)
    end
    local index
    for index = 1, #values do
        combo:addOptionWithData(values[index], values[index])
    end
end

local function selectData(combo, data)
    if combo and combo.selectData then combo:selectData(data) end
end

function ISPNCFactionEmblemEditor:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFactionEmblemEditor:createChildren()
    PsychopatzWindow.createChildren(self)
    self.backgroundCombo = addCombo(
        self,
        ISPNCFactionEmblemEditor.onChanged
    )
    populate(
        self.backgroundCombo,
        Emblems.COLOR_IDS,
        false
    )
    self.layerControls = {}
    local index
    for index = 1, Emblems.MAX_LAYERS do
        local row = {
            symbol = addCombo(
                self,
                ISPNCFactionEmblemEditor.onChanged
            ),
            color = addCombo(
                self,
                ISPNCFactionEmblemEditor.onChanged
            ),
            scale = addCombo(
                self,
                ISPNCFactionEmblemEditor.onChanged
            ),
        }
        populate(row.symbol, Emblems.SYMBOL_IDS, true)
        populate(row.color, Emblems.COLOR_IDS, false)
        row.scale:addOptionWithData("small", 0.45)
        row.scale:addOptionWithData("medium", 0.70)
        row.scale:addOptionWithData("large", 0.95)
        self.layerControls[index] = row
    end
    self.randomButton = UI.CreateButton(self, {
        id = "randomize",
        title = tr("UI_PNC_Emblem_Randomize", "Randomize"),
        target = self,
        onclick = ISPNCFactionEmblemEditor.onButton,
        variant = "quiet",
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save",
        title = tr("UI_PNC_Emblem_Save", "Save Emblem"),
        target = self,
        onclick = ISPNCFactionEmblemEditor.onButton,
        variant = "success",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel",
        title = tr("UI_PNC_Cancel", "Cancel"),
        target = self,
        onclick = ISPNCFactionEmblemEditor.onButton,
        variant = "danger",
    })
    self:setEmblem(self.initialEmblem)
    self:requestResponsiveLayout(true)
end

function ISPNCFactionEmblemEditor:setEmblem(value)
    self.emblem = Emblems.Normalize(
        value,
        self.archetypeID,
        self.seed
    )
    selectData(
        self.backgroundCombo,
        self.emblem.backgroundColorID
    )
    local index
    for index = 1, Emblems.MAX_LAYERS do
        local layer = self.emblem.layers[index]
        local row = self.layerControls[index]
        selectData(row.symbol, layer and layer.symbolID or false)
        selectData(row.color, layer and layer.colorID or "white")
        local scale = layer and tonumber(layer.scale) or 0.70
        selectData(
            row.scale,
            scale < 0.58 and 0.45
                or scale > 0.82 and 0.95 or 0.70
        )
    end
end

function ISPNCFactionEmblemEditor:buildEmblem()
    local layers = {}
    local index
    for index = 1, Emblems.MAX_LAYERS do
        local row = self.layerControls[index]
        local symbolID = row.symbol:getSelectedData()
        if symbolID then
            layers[#layers + 1] = {
                symbolID = symbolID,
                colorID = row.color:getSelectedData(),
                scale = row.scale:getSelectedData(),
                offsetX = index == 1 and 0
                    or index == 2 and -0.08 or 0.08,
                offsetY = index == 1 and 0
                    or index == 2 and -0.08 or 0.08,
            }
        end
    end
    return Emblems.Normalize({
        backgroundColorID =
            self.backgroundCombo:getSelectedData(),
        layers = layers,
        revision = self.emblem
            and self.emblem.revision or 0,
    }, self.archetypeID, self.seed)
end

function ISPNCFactionEmblemEditor:onChanged()
    self.emblem = self:buildEmblem()
end

function ISPNCFactionEmblemEditor:onButton(button)
    if button.internal == "randomize" then
        self.seed = tostring(
            getTimestampMs and getTimestampMs()
                or PNC.Core and PNC.Core.Now
                    and PNC.Core.Now() or 0
        ) .. ":" .. tostring(self.randomCount or 0)
        self.randomCount = (self.randomCount or 0) + 1
        self:setEmblem(
            Emblems.Generate(self.archetypeID, self.seed)
        )
        return
    end
    if button.internal == "save" and self.onSave then
        self.onSave(self:buildEmblem(), self.callbackContext)
    end
    self:close()
end

function ISPNCFactionEmblemEditor:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local scale = self.uiScale or 1
    local padding = Layout.Pixels(10, scale)
    local gap = Layout.Pixels(8, scale)
    local comboHeight = Layout.Pixels(28, scale)
    local buttonHeight = Layout.Pixels(30, scale)
    local footerGap = Layout.Pixels(12, scale)
    local left = rect.x + padding
    local top = rect.y + Layout.Pixels(14, scale)
    local labelWidth = Layout.Pixels(82, scale)
    local previewWidth = math.max(Layout.Pixels(118, scale),
        math.floor(rect.width * 0.25))
    local formWidth = math.max(Layout.Pixels(300, scale),
        rect.width - previewWidth - padding * 3)
    local symbolWidth = math.max(Layout.Pixels(112, scale),
        math.floor((formWidth - labelWidth - gap * 2) * 0.43))
    local remaining = formWidth - labelWidth - symbolWidth - gap * 2
    local colorWidth = math.max(Layout.Pixels(78, scale),
        math.floor(remaining * 0.52))
    local sizeWidth = math.max(Layout.Pixels(72, scale),
        remaining - colorWidth)
    local rowHeight = comboHeight + Layout.Pixels(12, scale)
    Layout.SetBounds(self.backgroundCombo, left + labelWidth, top,
        math.min(symbolWidth, formWidth - labelWidth), comboHeight)
    local index
    for index = 1, Emblems.MAX_LAYERS do
        local row = self.layerControls[index]
        local y = top + rowHeight + (index - 1) * rowHeight
        local controlX = left + labelWidth
        Layout.SetBounds(row.symbol, controlX, y,
            symbolWidth, comboHeight)
        Layout.SetBounds(row.color, controlX + symbolWidth + gap, y,
            colorWidth, comboHeight)
        Layout.SetBounds(row.scale,
            controlX + symbolWidth + colorWidth + gap * 2, y,
            sizeWidth, comboHeight)
    end
    local buttonY = rect.y + rect.height - buttonHeight - footerGap
    local randomWidth = Layout.Pixels(112, scale)
    local cancelWidth = Layout.Pixels(94, scale)
    local saveWidth = Layout.Pixels(122, scale)
    Layout.SetBounds(self.randomButton, left, buttonY,
        randomWidth, buttonHeight)
    Layout.SetBounds(self.cancelButton,
        rect.x + rect.width - cancelWidth - padding, buttonY,
        cancelWidth, buttonHeight)
    Layout.SetBounds(self.saveButton,
        rect.x + rect.width - cancelWidth - saveWidth - padding - gap,
        buttonY, saveWidth, buttonHeight)
    self.emblemLayout = {
        left = left, top = top, labelWidth = labelWidth,
        rowHeight = rowHeight,
        previewX = rect.x + rect.width - previewWidth,
        previewWidth = previewWidth,
    }
end

function ISPNCFactionEmblemEditor:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local layout = self.emblemLayout or {}
    local left = layout.left or rect.x + 10
    local top = layout.top or rect.y + 18
    local rowHeight = layout.rowHeight or 42
    self:drawText(
        tr("UI_PNC_Emblem_Background", "Background"),
        left,
        top + 5,
        0.82,
        0.82,
        0.82,
        1,
        UIFont.Small
    )
    local index
    for index = 1, Emblems.MAX_LAYERS do
        self:drawText(
            tr("UI_PNC_Emblem_Layer", "Layer") .. " " .. tostring(index),
            left,
            top + rowHeight + 5 + (index - 1) * rowHeight,
            0.72,
            0.72,
            0.72,
            1,
            UIFont.Small
        )
    end
    self:drawTextCentre(
        tr("UI_PNC_Emblem_Description", "Layered vanilla map symbols"),
        (layout.previewX or rect.x + rect.width - 150)
            + math.floor((layout.previewWidth or 100) / 2),
        top,
        0.72,
        0.72,
        0.72,
        1,
        UIFont.Small
    )
    Renderer.Draw(
        self,
        self:buildEmblem(),
        (layout.previewX or rect.x + rect.width - 150)
            + math.floor(((layout.previewWidth or 100) - 100) / 2),
        top + Layout.Pixels(30, self.uiScale or 1),
        math.min(100, (layout.previewWidth or 100)
            - Layout.Pixels(12, self.uiScale or 1))
    )
end

function ISPNCFactionEmblemEditor:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if Editor.instance == self then Editor.instance = nil end
end

function ISPNCFactionEmblemEditor:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(
        x,
        y,
        width,
        height,
        options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function Editor.Open(options)
    options = type(options) == "table" and options or {}
    if Editor.instance then Editor.instance:close() end
    local window = UI.NewWindow(ISPNCFactionEmblemEditor, {
        title = tr("UI_PNC_Emblem_Title", "Faction Emblem Creator"),
        resizable = true,
        responsiveSpec = {
            width = 720,
            height = 360,
            minWidth = 580,
            minHeight = 330,
            maxWidth = 1050,
            maxHeight = 680,
            anchor = "center",
        },
    })
    window.archetypeID = options.archetypeID or "settler"
    window.seed = options.seed or "player_faction"
    window.initialEmblem = options.emblem
        or Emblems.Generate(window.archetypeID, window.seed)
    window.onSave = options.onSave
    window.callbackContext = options.context
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    Editor.instance = window
    return window
end

return Editor
