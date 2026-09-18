-- Widget construction and context lifecycle for the Puppet Opera beat tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaBeatsTabInternal
local UI = Internal.UI
local tr = Internal.tr
local drawBeatItem = Internal.drawBeatItem
local Class = ISPNCPuppetOperaBeatsTab

function Class:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function Class:createChildren()
    ISPanel.createChildren(self)
    self.beatList = UI.CreateList(self, {
        itemHeight = 50,
        doDrawItem = drawBeatItem,
    })
    self.beatList.onMouseDown = function(list, x, y)
        return self:onBeatListMouseDown(list, x, y)
    end
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        valueXMax = 112,
        ellipsize = true,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.durationEntry = UI.CreateTextEntry(self, {
        clearButton = false,
        width = 100,
        height = 26,
    })
    self.applyDurationButton = UI.CreateButton(self, {
        id = "apply_duration",
        title = tr("UI_PNC_PuppetOpera_ApplyDuration", "Apply duration"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return self:onAction(button)
        end),
        variant = "selected",
    })
    self.buttons = {}
    for _, definition in ipairs({
        { "add", "ADD BEAT", "selected" },
        { "duplicate", "DUPLICATE", "quiet" },
        { "remove", "REMOVE", "danger" },
        { "up", "MOVE UP", "quiet" },
        { "down", "MOVE DOWN", "quiet" },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onAction(clicked)
            end),
            variant = definition[3],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
end

function Class:setContext(window)
    self.ownerWindow = window
    self.model = window and window.model or nil
    self:refresh()
end

return Class
