-- Lightweight, non-modal tactical response strip for active combat prompts.
require "ISUI/ISPanel"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Surface = PNC.Semantics.CombatResponseSurface
    or require "PNC/Semantics/PNC_SemanticCombatResponseSurface"
local Strip = PNC.CombatResponseStrip or {}
PNC.CombatResponseStrip = Strip

ISPNCCombatResponseStrip = ISPanel:derive("ISPNCCombatResponseStrip")

function ISPNCCombatResponseStrip:initialise()
    ISPanel.initialise(self)
end

local function buttonWidth(panel, count)
    count = math.max(1, tonumber(count) or 1)
    local gap = 8
    return math.max(
        130,
        math.floor((panel.width - 24 - gap * (count - 1)) / count)
    ), gap
end

function ISPNCCombatResponseStrip:createChildren()
    ISPanel.createChildren(self)
    self.choiceButtons = {}
    local rows = self.model and self.model.rows or {}
    local width, gap = buttonWidth(self, #rows)
    local total = width * #rows + gap * math.max(0, #rows - 1)
    local x = math.floor((self.width - total) / 2)
    for index, row in ipairs(rows) do
        local button = ISButton:new(
            x + (index - 1) * (width + gap),
            self.height - 36,
            width,
            27,
            tostring(row.label or row.id or ""),
            self,
            ISPNCCombatResponseStrip.onChoice
        )
        button.internal = tostring(row.id or "")
        button:initialise()
        button:instantiate()
        if button.setEnable then
            button:setEnable(row.enabled ~= false)
        end
        self:addChild(button)
        self.choiceButtons[button.internal] = button
    end
end

function ISPNCCombatResponseStrip:onChoice(button)
    local id = button and button.internal or nil
    if not id or id == "" then return false end
    if button.setEnable then button:setEnable(false) end
    local accepted = Surface.Submit(id)
    if accepted ~= true and self.choiceButtons[id]
        and self.choiceButtons[id].setEnable
    then
        self.choiceButtons[id]:setEnable(true)
    end
    return accepted == true
end

function ISPNCCombatResponseStrip:sync(model)
    self.model = model or self.model
    local rows = self.model and self.model.rows or {}
    for _, row in ipairs(rows) do
        local button = self.choiceButtons
            and self.choiceButtons[tostring(row.id or "")] or nil
        if button then
            if button.setTitle then
                button:setTitle(tostring(row.label or row.id or ""))
            else
                button.title = tostring(row.label or row.id or "")
            end
            if button.setEnable then
                button:setEnable(row.enabled ~= false)
            else
                button.enable = row.enabled ~= false
            end
        end
    end
end

function ISPNCCombatResponseStrip:prerender()
    ISPanel.prerender(self)
    self:drawRect(
        0, 0, self.width, self.height,
        0.90, 0.015, 0.015, 0.018
    )
    self:drawRectBorder(
        0, 0, self.width, self.height,
        0.94, 0.72, 0.52, 0.10
    )
    self:drawTextCentre(
        "TACTICAL RESPONSE",
        self.width / 2,
        10,
        0.96, 0.82, 0.48, 1,
        UIFont.Small
    )
end

function ISPNCCombatResponseStrip:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if Strip.instance == self then Strip.instance = nil end
end

function ISPNCCombatResponseStrip:new(x, y, width, height, model)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.model = model
    object.background = false
    object.moveWithMouse = false
    return object
end

function Strip.Show(model)
    model = type(model) == "table" and model or nil
    if not model or type(model.rows) ~= "table" or #model.rows == 0 then
        Strip.Hide("empty")
        return false
    end
    if Strip.instance
        and tostring(Strip.instance.model
            and Strip.instance.model.eventRef or "")
            == tostring(model.eventRef or "")
    then
        Strip.instance:sync(model)
        Strip.instance:setVisible(true)
        Strip.instance:bringToTop()
        return true
    end
    Strip.Hide("replaced")
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local width = math.min(
        math.max(520, (#model.rows * 180) + 32),
        math.max(520, screenWidth - 48)
    )
    local height = 72
    local window = ISPNCCombatResponseStrip:new(
        math.floor((screenWidth - width) / 2),
        math.max(16, screenHeight - 184),
        width,
        height,
        model
    )
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop()
    Strip.instance = window
    return true
end

function Strip.Sync(model)
    if not Strip.instance then return false end
    if tostring(Strip.instance.model
        and Strip.instance.model.eventRef or "")
        ~= tostring(model and model.eventRef or "")
    then
        return Strip.Show(model)
    end
    Strip.instance:sync(model)
    return true
end

function Strip.Hide()
    if Strip.instance then Strip.instance:close() end
    return true
end

Surface.SetUIAdapter(Strip)

return Strip
