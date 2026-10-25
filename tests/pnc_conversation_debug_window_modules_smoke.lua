local T = require "tests/support/test"

local WINDOW = T.path("ProjectHoomans", "client", "")
    .. "PNC/Conversation/Debug/PNC_ConversationDebugWindow.lua"

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationText"] =
    function() return true end
package.preload["PNC/Conversation/Blocks/PNC_ConversationTextLoader"] =
    function() return true end

local function button(definition)
    return {
        internal = definition.id,
        title = definition.title,
        setTitle = function(self, title) self.title = title end,
    }
end

local function list()
    local value = { items = {}, selected = 0, itemheight = 44 }
    function value:clear() self.items = {} end
    function value:addItem(label, item)
        self.items[#self.items + 1] = {
            label = label, item = item, index = #self.items + 1,
        }
    end
    function value:getItem() return self.items[self.selected] end
    function value:getWidth() return 500 end
    function value:drawText() end
    return value
end

local function details()
    local value = { items = {} }
    function value:clear() self.items = {} end
    function value:addItem(key, item)
        self.items[#self.items + 1] = { key = key, item = item }
    end
    return value
end

local colors = {
    text = { r = 1, g = 1, b = 1, a = 1 },
    textMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
    danger = { r = 1, g = 0, b = 0, a = 1 },
}
local UI = {
    Theme = { colors = colors },
    Layout = {
        Ellipsize = function(value) return value end,
        Flow = function(_, rect) return { bottom = rect.y + 30 } end,
        SetBounds = function() end,
    },
    CreateButton = function(_, definition) return button(definition) end,
    CreateSearchEntry = function()
        return { getText = function() return "" end }
    end,
    CreateList = function() return list() end,
    CreateKeyValueList = function() return details() end,
    AddKeyValue = function(target, key, value)
        target:addItem(key, value)
    end,
    DrawListSelection = function() end,
}

local item = {
    id = "debug:block",
    valid = true,
    block = {
        ownerModID = "ProjectHoomans",
        category = "greeting",
        textSource = { pathPattern = "debugger.json" },
        audiences = { "neutral" },
        nodes = {},
    },
    translationValid = true,
    translationFallback = false,
    eligible = true,
    errors = {},
    translationErrors = {},
}
local model = {
    DefaultContext = function()
        return {
            audiences = { neutral = true, member = false,
                special = false, hostile = false },
            relationship = { approval = 0, respect = 0, familiarity = 0 },
            relationshipState = "Acquaintance",
            playerSkills = { Aiming = 1 }, npcSkills = { Aiming = 1 },
            playerPersonality = { bravery = 0 }, npcPersonality = { bravery = 0 },
            hour = 12, worldAgeHours = 12,
        }
    end,
    NormalizeContext = function(context) return context end,
    List = function() return { item } end,
    Inspect = function() return { eligible = true, nodes = {} } end,
    OpenSandbox = function() return { outcomeID = "debug:outcome" } end,
}
package.preload["PNC/Conversation/Debug/PNC_ConversationDebugModel"] =
    function()
        PNC.ConversationDebugModel = model
        return model
    end

PsychopatzCore = {
    UI = UI,
    Conversation = {
        Text = { Resolve = function(spec) return spec.key end },
    },
}
UIFont = { Small = 1 }
PNC = {
    Conversation = {
        TextLoader = { EnsureSource = function() end },
    },
    Client = { CanUseDebug = function() return true end },
}

local BaseWindow = {}
BaseWindow.__index = BaseWindow
function BaseWindow:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function BaseWindow:initialise() end
function BaseWindow:createChildren() end
function BaseWindow:instantiate() self:createChildren() end
function BaseWindow:prerender() end
function BaseWindow:new()
    return setmetatable({
        uiScale = 1,
        requestResponsiveLayout = function() end,
        getContentRect = function()
            return { x = 0, y = 0, width = 900, height = 600 }
        end,
        setVisible = function(self, visible) self.visible = visible end,
        getIsVisible = function(self) return self.visible == true end,
        removeFromUIManager = function() end,
        addToUIManager = function() end,
        bringToTop = function() end,
    }, self)
end
PsychopatzWindow = BaseWindow

T.load(WINDOW)

T.equal(PNC.ConversationDebugUI.Internal.Model, model,
    "debug window retained model ownership")
T.truthy(type(PNC.ConversationDebugUI.Open) == "function",
    "debug window Open API was not preserved")
T.truthy(type(PNC.ConversationDebugUI.Toggle) == "function",
    "debug window Toggle API was not preserved")
for _, method in ipairs({
    "initialise", "createChildren", "onResponsiveLayout", "refreshBlocks",
    "refreshDetails", "adjustGateValue", "onAction", "prerender", "close",
}) do
    T.truthy(type(ISPNCConversationDebugWindow[method]) == "function",
        "debug window method was not installed: " .. method)
end

local window = ISPNCConversationDebugWindow:new(0, 0, 900, 600, {})
window:createChildren()
T.equal(#window.controls, 13, "debug window controls changed during split")
T.equal(#window.blocks.items, 1, "debug window block projection changed")
T.equal(window.blocks.items[1].item.id, "debug:block",
    "debug window selected item changed")

T.finish("pnc_conversation_debug_window_modules_smoke")
