local T = require "tests/support/test"
T.addPackagePaths()

local function derive(base)
    local child = {}
    child.__index = child
    setmetatable(child, { __index = base })
    return child
end

local Part = {
    derive = function(self)
        return derive(self)
    end,
}
Part.__index = Part

function Part:new(x, y, width, height, options)
    local object = {
        x = x,
        y = y,
        width = width,
        height = height,
        minimumHeight = options.minimumHeight,
        owner = options.owner,
        partID = options.partID,
    }
    setmetatable(object, self)
    return object
end

function Part:setHeight(value)
    self.height = value
end

function Part:setVisible(value)
    self.visible = value
end

local function makeEntry()
    local entry = {
        text = "",
        cursorPos = 0,
        width = 1,
        height = 1,
    }

    function entry:setMultipleLine(value)
        self.multipleLine = value
    end

    function entry:setMaxLines(value)
        self.maxLines = value
    end

    function entry:getText()
        return self.text
    end

    function entry:getInternalText()
        return self.text
    end

    function entry:setText(value)
        self.text = value or ""
    end

    function entry:getCursorPos()
        return self.cursorPos
    end

    function entry:setCursorPos(value)
        self.cursorPos = value
    end

    function entry:getWidth()
        return self.width
    end

    function entry:setX(value) self.x = value end
    function entry:setY(value) self.y = value end
    function entry:setWidth(value) self.width = value end
    function entry:setHeight(value) self.height = value end
    function entry:setEditable(value) self.editable = value end
    function entry:focus() self.focused = true end
    function entry:unfocus() self.unfocused = true end

    return entry
end

local function makeButton()
    local button = {}
    function button:setX(value) self.x = value end
    function button:setY(value) self.y = value end
    function button:setWidth(value) self.width = value end
    function button:setHeight(value) self.height = value end
    function button:setEnable(value)
        -- Mirrors the relevant ISButton behavior: the native control keeps
        -- the first enabled colors and restores them on later setEnable(true)
        -- calls.  The style marker is intentionally not restored; this is
        -- the stale-rendering case the production refresh must repair.
        if self.enabledVariant == nil then self.enabledVariant = self.variant end
        self.enabled = value
        if value and self.enabledVariant ~= nil then
            self.variant = self.enabledVariant
        end
    end
    function button:setTitle(value) self.title = value end
    function button:setImage(value) self.image = value end
    return button
end

local entry
local variantCalls = 0
local UI = {
    CreateTextEntry = function()
        entry = makeEntry()
        return entry
    end,
    CreateButton = function(_, options)
        local button = makeButton()
        if options then
            button:setTitle(options.title)
            if options.image then button:setImage(options.image) end
        end
        return button
    end,
    SetButtonVariant = function(button, variant)
        variantCalls = variantCalls + 1
        button.variant = variant
        button.psychopatzVariant = variant
    end,
}

PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(value, fallback)
                return type(value) == "table" and (value.fallback or fallback)
                    or tostring(value or fallback or "")
            end,
        },
    },
    UI = UI,
}
Keyboard = {
    KEY_LSHIFT = 42,
    KEY_RSHIFT = 54,
    down = {},
}
function Keyboard.isKeyDown(key)
    return Keyboard.down[key] == true
end

package.preload["ISUI/ISButton"] = function() return true end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return UI end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"] =
    function()
        PsychopatzConversationPart = Part
        return Part
    end

T.load(
    "PsychopatzCore",
    "common_client",
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua"
)

local submitted = {}
local input = PsychopatzConversationLLMInput:new(0, 0, 280, 82, {
    submit = function(_, value)
        submitted[#submitted + 1] = value
        return true
    end,
})
input:createChildren()

T.falsy(entry.multipleLine, "submit-on-enter input remains in command mode")

entry:setText("hello")
entry:setCursorPos(5)
entry.onCommandEntered()
T.equal(submitted[1], "hello", "plain Enter submits the input")
T.equal(entry:getText(), "", "accepted submission clears the input")

entry:setText("hello world")
entry:setCursorPos(5)
Keyboard.down[Keyboard.KEY_LSHIFT] = true
entry.onCommandEntered()
Keyboard.down[Keyboard.KEY_LSHIFT] = false
T.equal(#submitted, 1, "Shift+Enter does not submit")
T.equal(entry:getText(), "hello\n world", "Shift+Enter inserts a newline at the caret")
T.equal(entry:getCursorPos(), 6, "newline leaves the caret after the inserted line break")
T.truthy(input.inputHeight > 26, "newline expands the input height")

input:focusInput()
T.truthy(input:blurInput(), "input exposes a reusable blur operation")
T.truthy(entry.unfocused, "blur operation releases the native text entry")

local modeInput = PsychopatzConversationLLMInput:new(0, 0, 320, 108, {
    modeButtons = {
        { id = "nearest", mode = "nearest", title = "SINGLE NPC", image = "single.png" },
        { id = "nearby", mode = "nearby", title = "NEARBY NPCS", image = "group.png" },
    },
})
modeInput:createChildren()
local initialVariantCalls = variantCalls
T.equal(modeInput.modeButtons[1].button.image, "single.png",
    "single-target mode keeps its icon")
T.equal(modeInput.modeButtons[2].button.image, "group.png",
    "multiple-target mode keeps its icon")
T.equal(modeInput.modeButtons[1].button.title, "",
    "single-target mode uses its hover name instead of a visible label")
T.equal(modeInput.modeButtons[1].button.tooltip, "SINGLE NPC",
    "single-target mode exposes its distinct hover name")
T.equal(modeInput.modeButtons[2].button.tooltip, "NEARBY NPCS",
    "multiple-target mode exposes its distinct hover name")
T.equal(modeInput.modeButtons[1].button.variant, "selected",
    "nearest mode starts selected")
T.equal(modeInput.modeButtons[2].button.variant, "quiet",
    "nearby mode starts unselected")
modeInput:updateModeButtonStyles()
T.equal(variantCalls, initialVariantCalls,
    "stable mode refresh does not repaint the mode buttons")
T.equal(modeInput.modeButtons[1].button.variant, "selected",
    "stable mode refresh does not change the selected state")
local repairVariantCalls = variantCalls
modeInput.modeButtons[2].button.variant = "selected"
modeInput.modeButtons[2].button.psychopatzVariant = "selected"
modeInput:updateModeButtonStyles()
T.equal(variantCalls, repairVariantCalls + 1,
    "mode refresh repairs a stale native button variant")
T.equal(modeInput.modeButtons[2].button.variant, "quiet",
    "mode refresh restores the unselected button variant")

local refreshInput = PsychopatzConversationLLMInput:new(0, 0, 320, 108, {
    modeButtons = {
        { id = "nearest", mode = "nearest", title = "SINGLE NPC" },
        { id = "nearby", mode = "nearby", title = "NEARBY NPCS" },
    },
    getState = function()
        return { visible = true, enabled = true }
    end,
})
refreshInput:createChildren()
refreshInput:refreshControls()
refreshInput.inputMode = "nearby"
refreshInput:refreshControls()
T.equal(refreshInput.modeButtons[1].button.variant, "quiet",
    "control refresh clears the old single-target selected style")
T.equal(refreshInput.modeButtons[2].button.variant, "selected",
    "control refresh paints the nearby-target selected style last")

local modeChanges = {}
local selectableInput = PsychopatzConversationLLMInput:new(0, 0, 320, 108, {
    modeButtons = {
        { id = "nearest", mode = "nearest", title = "NEAREST NPC" },
        { id = "nearby", mode = "nearby", title = "NEARBY NPCS" },
    },
    onModeChanged = function(_, mode)
        modeChanges[#modeChanges + 1] = mode
        return true
    end,
})
selectableInput:createChildren()
selectableInput:onModePressed("nearest")
selectableInput:onModePressed("nearest")
selectableInput:onModePressed("nearby")
T.equal(modeChanges[1], "nearest",
    "nearest mode invokes its integration callback")
T.equal(modeChanges[2], "nearest",
    "repeated nearest clicks invoke the callback for cycling")
T.equal(modeChanges[3], "nearby",
    "nearby mode invokes its integration callback live")

local callbackMode
local rejectingInput = PsychopatzConversationLLMInput:new(0, 0, 320, 108, {
    modeButtons = {
        { id = "nearest", mode = "nearest", title = "NEAREST NPC" },
        { id = "nearby", mode = "nearby", title = "NEARBY NPCS" },
    },
    onModeChanged = function(_, mode, widget)
        callbackMode = widget.inputMode
        return mode ~= "nearby"
    end,
})
rejectingInput:createChildren()
T.falsy(rejectingInput:onModePressed("nearby"),
    "rejected mode callback does not commit the new mode")
T.equal(callbackMode, "nearest",
    "mode callback observes the previously committed selection")
T.equal(rejectingInput.inputMode, "nearest",
    "rejected mode callback preserves the widget selection")

local toggleChanges = {}
local toggleInput = PsychopatzConversationLLMInput:new(0, 0, 320, 108, {
    submit = function() return true end,
    toggleButton = {
        id = "scope",
        title = "COLONISTS",
        alternateTitle = "OTHER NPCS",
    },
    onToggleChanged = function(_, value)
        toggleChanges[#toggleChanges + 1] = value
        return true
    end,
})
toggleInput:createChildren()
T.equal(toggleInput.inputY, 54,
    "a scope toggle keeps the input below the control row")
T.equal(toggleInput.toggleButton.button.title, "COLONISTS",
    "the scope toggle starts on colonists")
toggleInput:onTogglePressed()
T.equal(toggleInput.toggleValue, true,
    "the scope toggle switches to the alternate scope")
T.equal(toggleInput.toggleButton.button.title, "OTHER NPCS",
    "the scope toggle updates its title")
T.equal(toggleChanges[1], true,
    "the scope toggle notifies its integration callback")

T.finish("pnc_hoomans_llm_input_smoke")
