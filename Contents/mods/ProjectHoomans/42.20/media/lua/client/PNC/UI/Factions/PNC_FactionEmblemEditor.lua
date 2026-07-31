-- Reusable player-facing layered faction-emblem editor.

require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"

PNC = PNC or {}
PNC.FactionEmblemEditor = PNC.FactionEmblemEditor or {}

local Editor = PNC.FactionEmblemEditor
local UI = PsychopatzCore.UI
local Emblems = PNC.FactionEmblems
local Renderer = PNC.FactionEmblemRenderer

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
        combo:addOptionWithData("(none)", false)
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
        title = "Randomize",
        target = self,
        onclick = ISPNCFactionEmblemEditor.onButton,
        variant = "quiet",
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save",
        title = "Save Emblem",
        target = self,
        onclick = ISPNCFactionEmblemEditor.onButton,
        variant = "success",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel",
        title = "Cancel",
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
    local left = rect.x + 10
    local top = rect.y + 18
    local rowHeight = 42
    self.backgroundCombo:setX(left + 105)
    self.backgroundCombo:setY(top)
    self.backgroundCombo:setWidth(150)
    local index
    for index = 1, Emblems.MAX_LAYERS do
        local row = self.layerControls[index]
        local y = top + 48 + (index - 1) * rowHeight
        row.symbol:setX(left + 72)
        row.symbol:setY(y)
        row.symbol:setWidth(145)
        row.color:setX(left + 225)
        row.color:setY(y)
        row.color:setWidth(105)
        row.scale:setX(left + 338)
        row.scale:setY(y)
        row.scale:setWidth(105)
    end
    local buttonY = rect.y + rect.height - 34
    self.randomButton:setX(left)
    self.randomButton:setY(buttonY)
    self.randomButton:setWidth(105)
    self.cancelButton:setX(rect.x + rect.width - 100)
    self.cancelButton:setY(buttonY)
    self.cancelButton:setWidth(90)
    self.saveButton:setX(rect.x + rect.width - 215)
    self.saveButton:setY(buttonY)
    self.saveButton:setWidth(107)
end

function ISPNCFactionEmblemEditor:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local left = rect.x + 10
    local top = rect.y + 18
    self:drawText(
        "Background",
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
            "Layer " .. tostring(index),
            left,
            top + 53 + (index - 1) * 42,
            0.72,
            0.72,
            0.72,
            1,
            UIFont.Small
        )
    end
    self:drawTextCentre(
        "Layered vanilla map symbols",
        rect.x + rect.width - 100,
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
        rect.x + rect.width - 150,
        top + 28,
        100
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
        title = "Faction Emblem Creator",
        resizable = false,
        responsiveSpec = {
            width = 650,
            height = 300,
            minWidth = 650,
            minHeight = 300,
            maxWidth = 650,
            maxHeight = 300,
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
