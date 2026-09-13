local T = require "tests/support/test"
T.addPackagePaths()

local function copyColor(color)
    return {
        r = color.r, g = color.g, b = color.b, a = color.a,
    }
end

local function sameColor(left, right)
    return left and right
        and left.r == right.r
        and left.g == right.g
        and left.b == right.b
        and left.a == right.a
end

local colors = {
    surface = { r = 0.065, g = 0.078, b = 0.092, a = 0.98 },
    surfaceRaised = { r = 0.09, g = 0.108, b = 0.125, a = 0.98 },
    surfaceHover = { r = 0.12, g = 0.145, b = 0.17, a = 1 },
    border = { r = 0.23, g = 0.28, b = 0.32, a = 0.9 },
    accent = { r = 0.2, g = 0.72, b = 0.82, a = 1 },
    accentDark = { r = 0.08, g = 0.31, b = 0.38, a = 1 },
    text = { r = 0.91, g = 0.94, b = 0.96, a = 1 },
    textMuted = { r = 0.58, g = 0.65, b = 0.7, a = 1 },
}
local themeRevision = 1

local UI = {
    Theme = {
        colors = colors,
        Color = function(name, alpha)
            local color = colors[name] or colors.text
            local result = copyColor(color)
            if alpha ~= nil then result.a = alpha end
            return result
        end,
        GetRevision = function() return themeRevision end,
    },
    ImageResolver = {
        Resolve = function(path) return path end,
    },
    Layout = {
        Pixels = function(value) return value end,
    },
}

PsychopatzCore = {
    UI = UI,
    Conversation = {
        Text = {
            Resolve = function(value, fallback)
                return type(value) == "table"
                    and (value.fallback or fallback)
                    or tostring(value or fallback or "")
            end,
        },
    },
}

-- This is the relevant Build 42 ISButton contract from the installed game's
-- ISUI/ISButton.lua. In particular, setEnable() snapshots the first enabled
-- colors and restores that cache on every later enable call.
ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    local button = {
        x = x,
        y = y,
        width = width,
        height = height,
        title = title,
        target = target,
        onclick = onclick,
        enable = true,
        backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
        backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        borderColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        textureColor = { r = 1, g = 1, b = 1, a = 1 },
    }
    setmetatable(button, { __index = self })
    return button
end
function ISButton:initialise() end
function ISButton:instantiate() end
function ISButton:setX(value) self.x = value end
function ISButton:setY(value) self.y = value end
function ISButton:setWidth(value) self.width = value end
function ISButton:setHeight(value) self.height = value end
function ISButton:getX() return self.x end
function ISButton:getY() return self.y end
function ISButton:getWidth() return self.width end
function ISButton:getHeight() return self.height end
function ISButton:setTitle(value) self.title = value end
function ISButton:setImage(value) self.image = value end
function ISButton:setFont(value) self.font = value end
function ISButton:setTextureRGBA(r, g, b, a)
    self.textureColor = { r = r, g = g, b = b, a = a }
end
function ISButton:setBorderRGBA(r, g, b, a)
    self.borderColor = { r = r, g = g, b = b, a = a }
end
function ISButton:setBackgroundRGBA(r, g, b, a)
    self.backgroundColor = { r = r, g = g, b = b, a = a }
end
function ISButton:setEnable(value)
    self.enable = value
    if not self.borderColorEnabled then
        self.borderColorEnabled = copyColor(self.borderColor)
        self.backgroundColorEnabled = copyColor(self.backgroundColor)
    end
    if value then
        self:setTextureRGBA(1, 1, 1, 1)
        self:setBorderRGBA(
            self.borderColorEnabled.r,
            self.borderColorEnabled.g,
            self.borderColorEnabled.b,
            self.borderColorEnabled.a
        )
        self:setBackgroundRGBA(
            self.backgroundColorEnabled.r,
            self.backgroundColorEnabled.g,
            self.backgroundColorEnabled.b,
            self.backgroundColorEnabled.a
        )
    else
        self:setTextureRGBA(0.3, 0.3, 0.3, 1)
        self:setBorderRGBA(0.7, 0.1, 0.1, 0.7)
        self:setBackgroundRGBA(0, 0, 0, 1)
    end
end

ISPanel = {}
ISScrollingListBox = {}
package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISScrollingListBox"] = function() return true end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] = function()
    return UI.Layout
end
package.preload["PsychopatzCore/UI/Components/PsychopatzVirtualizedList"] =
    function() return {} end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return UI
end

local Part = {}
Part.__index = Part
function Part:derive()
    local child = {}
    child.__index = child
    setmetatable(child, { __index = self })
    return child
end
function Part:new(x, y, width, height, options)
    local object = {
        x = x,
        y = y,
        width = width,
        height = height,
        owner = options and options.owner,
        minimumHeight = options and options.minimumHeight,
        minimumWidth = options and options.minimumWidth,
        children = {},
    }
    setmetatable(object, self)
    return object
end
function Part:addChild(child) self.children[#self.children + 1] = child end
function Part:setHeight(value) self.height = value end
function Part:setVisible(value) self.visible = value end

package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"] =
    function()
        PsychopatzConversationPart = Part
        return Part
    end

UI.CreateButton = function(parent, definition)
    local button = ISButton:new(
        0, 0, 1, 1,
        tostring(definition.title or ""),
        definition.target or parent,
        definition.onclick
    )
    button.internal = definition.id
    button:initialise()
    button:instantiate()
    if definition.image then button:setImage(definition.image) end
    UI.StyleButton(button, definition.variant)
    if parent then parent:addChild(button) end
    return button
end

UI.CreateTextEntry = function(parent)
    local entry = {
        width = 1,
        height = 1,
        text = "",
    }
    function entry:setX(value) self.x = value end
    function entry:setY(value) self.y = value end
    function entry:setWidth(value) self.width = value end
    function entry:setHeight(value) self.height = value end
    function entry:getWidth() return self.width end
    function entry:getText() return self.text end
    function entry:setText(value) self.text = value or "" end
    function entry:setEditable(value) self.editable = value end
    function entry:setMultipleLine(value) self.multipleLine = value end
    function entry:setMaxLines(value) self.maxLines = value end
    if parent then parent:addChild(entry) end
    return entry
end

T.load(
    "PsychopatzCore",
    "client",
    "PsychopatzCore/UI/Components/PsychopatzUIControls.lua"
)
T.load(
    "PsychopatzCore",
    "common_client",
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua"
)

local input = PsychopatzConversationLLMInput:new(0, 0, 320, 108, {
    modeButtons = {
        {
            id = "nearest",
            mode = "nearest",
            title = "SINGLE NPC",
            image = "single.png",
        },
        {
            id = "nearby",
            mode = "nearby",
            title = "NEARBY NPCS",
            image = "group.png",
        },
    },
    getState = function()
        return { visible = true, enabled = true }
    end,
})
input:createChildren()
input:refreshControls()

local function assertVariant(definition, expectedVariant)
    local button = definition.button
    local expectedBackground = colors[
        expectedVariant == "selected" and "accentDark" or "surface"
    ]
    local expectedBorder = colors[
        expectedVariant == "selected" and "accent" or "border"
    ]
    T.equal(button.psychopatzVariant, expectedVariant,
        definition.mode .. " variant marker")
    T.truthy(sameColor(button.backgroundColor, expectedBackground),
        definition.mode .. " live background")
    T.truthy(sameColor(button.backgroundColorEnabled, expectedBackground),
        definition.mode .. " native enabled background cache")
    T.truthy(sameColor(button.borderColor, expectedBorder),
        definition.mode .. " live border")
    T.truthy(sameColor(button.borderColorEnabled, expectedBorder),
        definition.mode .. " native enabled border cache")
    T.equal(button.enable, true, definition.mode .. " is enabled")
end

T.equal(#input.modeButtons, 2, "compact input owns one mode-button pair")
T.equal(#input.children, 4, "compact input has one pair plus entry and send controls")
T.equal(input.modeButtons[1].button.title, "", "single mode stays icon-only")
T.equal(input.modeButtons[2].button.title, "", "nearby mode stays icon-only")
T.equal(input.modeButtons[1].button.image, "single.png", "single icon is preserved")
T.equal(input.modeButtons[2].button.image, "group.png", "nearby icon is preserved")
T.equal(input.modeButtons[1].button.tooltip, "SINGLE NPC",
    "single icon has an unambiguous hover name")
T.equal(input.modeButtons[2].button.tooltip, "NEARBY NPCS",
    "nearby icon has an unambiguous hover name")
T.equal(input.modeButtons[1].button.x, 10, "single button x bound")
T.equal(input.modeButtons[1].button.y, 29, "single button y bound")
T.equal(input.modeButtons[2].button.x, 162, "nearby button x bound")
T.equal(input.modeButtons[2].button.y, 29, "nearby button y bound")
assertVariant(input.modeButtons[1], "selected")
assertVariant(input.modeButtons[2], "quiet")

-- Exercise the live click -> commit -> native refresh -> theme refresh path
-- repeatedly. This catches the old bug where the marker changed but the
-- native setEnable() cache restored the first variant on the next refresh.
for iteration = 1, 24 do
    local requested = iteration % 2 == 1 and "nearby" or "nearest"
    T.truthy(input:onModePressed(requested),
        "mode click accepted without rebuilding the input panel")
    T.equal(input.inputMode, requested, "committed mode after click")
    input:refreshControls()
    UI.RefreshTheme(input)
    input:refreshControls()
    local selected = requested == "nearest" and 1 or 2
    local quiet = requested == "nearest" and 2 or 1
    assertVariant(input.modeButtons[selected], "selected")
    assertVariant(input.modeButtons[quiet], "quiet")
end

colors.accentDark = { r = 0.28, g = 0.12, b = 0.42, a = 1 }
colors.accent = { r = 0.68, g = 0.48, b = 0.95, a = 1 }
themeRevision = themeRevision + 1
input:refreshControls()
assertVariant(input.modeButtons[1], "selected")
assertVariant(input.modeButtons[2], "quiet")

T.finish("pnc_hoomans_llm_native_button_smoke")
