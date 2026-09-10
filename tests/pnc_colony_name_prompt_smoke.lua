local T = require "tests/support/test"

local UI = {
    Layout = {
        Pixels = function(value) return value end,
        Flow = function(_, bounds)
            return { bottom = bounds.y + 70 }
        end,
        SetBounds = function() end,
    },
    Theme = {
        colors = {
            text = { r = 1, g = 1, b = 1, a = 1 },
            danger = { r = 1, g = 0, b = 0, a = 1 },
        },
    },
}

local function entry()
    local value = ""
    return {
        getText = function() return value end,
        setText = function(_, nextValue) value = tostring(nextValue or "") end,
        focus = function() end,
    }
end

function UI.CreateTextEntry(parent)
    local control = entry()
    if parent and parent.addChild then parent:addChild(control) end
    return control
end

function UI.CreateButton(parent, options)
    local control = {
        internal = options.id,
        title = options.title,
        onclick = options.onclick,
    }
    function control:setVisible(value) self.visible = value end
    if parent and parent.addChild then parent:addChild(control) end
    return control
end

local Window = {}
function Window:derive(name)
    local class = { Type = name }
    setmetatable(class, { __index = self })
    class.__index = class
    return class
end
function Window:new(x, y, width, height)
    local object = {
        x = x, y = y, width = width, height = height,
        children = {}, visible = false,
    }
    setmetatable(object, self)
    return object
end
function Window:initialise() end
function Window:createChildren() end
function Window:requestResponsiveLayout() end
function Window:getContentRect()
    return { x = 10, y = 30, width = self.width - 20, height = self.height - 42 }
end
function Window:addChild(child) self.children[#self.children + 1] = child end
function Window:drawText() end

PsychopatzWindow = Window
PsychopatzCore = { UI = UI }
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return UI
end
UIFont = { Small = 1 }

function UI.NewWindow(class, options)
    local window = class:new(0, 0, 430, 170, options)
    window.title = options.title
    window.uiScale = 1
    function window:instantiate() self:createChildren() end
    function window:addToUIManager() self.added = true end
    function window:setVisible(value) self.visible = value end
    function window:getIsVisible() return self.visible end
    function window:bringToTop() self.focused = true end
    function window:removeFromUIManager() self.added = false end
    return window
end

local renamed
PNC = {
    Client = {
        RenameFaction = function(name)
            renamed = name
            return true, "renamed"
        end,
    },
}

local Prompt = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/PNC_ColonyNamePrompt.lua")
local snapshot = {
    faction = { id = "faction-player", name = "Morgan Clan", revision = 4 },
}

T.truthy(Prompt.Open({ snapshot = snapshot, mode = "rename" }),
    "manual rename did not open the modal")
T.equal(Prompt.instance.mode, "rename", "manual modal mode changed")
T.equal(Prompt.instance.title, "CHANGE NAME", "manual modal title changed")
T.equal(Prompt.instance.nameEntry:getText(), "Morgan Clan",
    "manual modal did not bind the current faction name")
T.equal(Prompt.instance.saveButton.title, "SAVE",
    "manual modal save action changed")
T.equal(Prompt.instance.cancelButton.title, "CANCEL",
    "manual modal cancel action changed")
Prompt.instance.nameEntry:setText("Morgan Wardens")
Prompt.instance:onSave()
T.equal(renamed, "Morgan Wardens", "manual modal did not submit the new name")
T.falsy(Prompt.instance, "manual modal remained open after a successful rename")

snapshot.faction.renamePending = true
snapshot.people = { { id = "npc-one" } }
T.truthy(Prompt.OpenIfNeeded(snapshot),
    "first-faction prompt did not open through the shared opener")
T.equal(Prompt.instance.mode, "first", "first-faction mode changed")
T.equal(Prompt.instance.title, "NAME YOUR FACTION",
    "first-faction title changed")
T.falsy(Prompt.OpenIfNeeded(snapshot),
    "first-faction prompt ignored its revision de-duplication")
Prompt.Close()

T.finish("pnc_colony_name_prompt_smoke")
