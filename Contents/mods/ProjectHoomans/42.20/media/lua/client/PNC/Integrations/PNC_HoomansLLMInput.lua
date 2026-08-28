-- In-game response-channel text entry for the HoomansLLM bridge integration.
require "ISUI/ISButton"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Conversation = PNC.Conversation
local Text = PsychopatzCore.Conversation.Text
local UI = PsychopatzCore.UI

local MAX_INPUT_LENGTH = 4000

local function label(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

ISPNCHoomansLLMInput = PsychopatzConversationPart:derive(
    "ISPNCHoomansLLMInput"
)

function ISPNCHoomansLLMInput:createChildren()
    self.entry = UI.CreateTextEntry(self, {
        x = 10,
        y = 30,
        width = math.max(80, self.width - 104),
        height = 26,
        maxTextLength = MAX_INPUT_LENGTH,
        tooltip = label("llm.input_tooltip", "Type a message for this NPC."),
    })
    self.entry.onCommandEntered = function()
        self:onSubmit()
    end
    self.sendButton = UI.CreateButton(self, {
        id = "send",
        title = label("llm.send", "SEND"),
        target = self,
        onclick = ISPNCHoomansLLMInput.onSubmit,
        variant = "primary",
        width = 76,
    })
    self:onPartResize()
end

function ISPNCHoomansLLMInput:onPartResize()
    if not self.entry or not self.sendButton then return end
    local width = math.max(80, self.width - 104)
    self.entry:setX(10)
    self.entry:setY(30)
    self.entry:setWidth(width)
    self.entry:setHeight(26)
    self.sendButton:setX(math.max(10, self.width - 86))
    self.sendButton:setY(30)
    self.sendButton:setWidth(76)
    self.sendButton:setHeight(26)
end

function ISPNCHoomansLLMInput:onSubmit()
    local value = self.entry and self.entry:getText() or ""
    local accepted = Integration.Submit(self.owner, value)
    if accepted and self.entry then self.entry:setText("") end
    self:refreshControls()
end

function ISPNCHoomansLLMInput:refreshControls()
    local enabled = false
    local status = label("llm.status.off", "LLM BRIDGE OFF")
    local view = self.owner
    if Integration.IsBridgeEnabled and Integration.IsBridgeEnabled() then
        self:setVisible(true)
        if not view or not view.session then
            status = label("llm.status.open", "OPEN A CONVERSATION")
        elseif view.session.llmPending then
            status = label("llm.status.waiting", "WAITING FOR NPC RESPONSE...")
        elseif not view:isConversationInteractive() then
            status = label("llm.status.speaking", "NPC IS SPEAKING...")
        else
            enabled = true
            status = label("llm.status.ready", "LLM CHAT READY")
        end
    else
        self:setVisible(false)
    end
    if self.entry and self.entry.setEditable then
        self.entry:setEditable(enabled)
    end
    if self.sendButton then
        self.sendButton:setTitle(label("llm.send", "SEND"))
        self.sendButton:setEnable(enabled)
    end
    self.statusText = status
end

function ISPNCHoomansLLMInput:render()
    ISPanel.render(self)
    local accent = self:getAccentColor()
    self:drawText(
        tostring(self.statusText or ""),
        11,
        math.max(57, self.height - 20),
        accent.r,
        accent.g,
        accent.b,
        self:getContentOpacity() * 0.9,
        UIFont.Small
    )
end

function ISPNCHoomansLLMInput:new(x, y, width, height, options)
    options = options or {}
    options.partID = "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "panel.llm_input",
        domain = "pnc.system.shared.categories",
        fallback = "TYPE TO TALK",
    }
    local object = PsychopatzConversationPart.new(
        self, x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    object.statusText = label("llm.status.off", "LLM BRIDGE OFF")
    return object
end

function Integration.CreateInputPart(bounds, options)
    options = options or {}
    return ISPNCHoomansLLMInput:new(
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height,
        options
    )
end

Conversation.CreateHoomansLLMInput = Integration.CreateInputPart

return ISPNCHoomansLLMInput
