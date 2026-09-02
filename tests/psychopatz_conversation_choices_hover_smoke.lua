local T = require "tests/support/test"

T.addPackagePaths()

local Parent = {}
Parent.__index = Parent

function Parent:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end

function Parent:new(x, y, width, height, options)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        options = options or {},
    }, self)
end

function Parent:prerender() end
function Parent:onMouseMove() return false end
function Parent:onMouseMoveOutside() return false end
function Parent:getMouseX() return self.mouseX or 0 end
function Parent:getMouseY() return self.mouseY or 0 end

PsychopatzConversationPart = Parent
PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(value)
                if type(value) == "table" then
                    return value.text or value.fallback or ""
                end
                return value
            end,
        },
    },
}

local originalRequire = require
require = function(name)
    if name == "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart" then
        return Parent
    end
    return originalRequire(name)
end
local Choices = T.load(
    "PsychopatzCore",
    "common_client",
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices.lua"
)
require = originalRequire

local events = {}
local function record(name)
    return function(_, highlighted)
        events[#events + 1] = name .. ":" .. tostring(highlighted)
    end
end

local choices = Choices:new(0, 0, 300, 180, {})
choices:setChoices({
    { id = "recruit", text = "Recruit", onHighlightChanged = record("recruit") },
    { id = "goodbye", text = "Goodbye", onHighlightChanged = record("goodbye") },
})

choices.mouseX = 20
choices.mouseY = 40
T.truthy(choices:onMouseMove(), "hovering a choice is consumed")
T.equal(choices.hoveredChoice, 1, "first choice is highlighted")
T.equal(events[1], "recruit:true", "enter callback fires once")
choices:onMouseMove()
T.equal(#events, 1, "stationary hover does not repeat callback")

choices.mouseY = 90
T.truthy(choices:onMouseMove(), "moving to another choice is consumed")
T.equal(choices.hoveredChoice, 2, "second choice is highlighted")
T.equal(events[2], "recruit:false", "previous choice receives leave callback")
T.equal(events[3], "goodbye:true", "new choice receives enter callback")

choices:onMouseMoveOutside()
T.equal(choices.hoveredChoice, nil, "outside movement clears highlight")
T.equal(events[4], "goodbye:false", "outside movement receives leave callback")

print("psychopatz_conversation_choices_hover_smoke: ok")
