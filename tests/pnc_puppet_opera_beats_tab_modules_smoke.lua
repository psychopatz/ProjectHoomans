local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

for _, moduleName in ipairs({
    "ISUI/ISPanel",
    "PsychopatzCore/UI/PsychopatzUI",
}) do
    package.loaded[moduleName] = true
end

local function widget()
    local value = {
        children = {},
        width = 720,
        height = 480,
    }
    function value:initialise() end
    function value:instantiate() end
    function value:setScrollHeight(height) self.scrollHeight = height end
    function value:setTitle(title) self.title = title end
    function value:getWidth() return self.width end
    function value:getHeight() return self.height end
    function value:addChild(child) self.children[#self.children + 1] = child end
    return value
end

ISPanel = {
    derive = function(base, name)
        local class = { Type = name }
        class.__index = class
        setmetatable(class, { __index = base })
        return class
    end,
    initialise = function() end,
    createChildren = function() end,
    noBackground = function() end,
}

ISScrollingListBox = {
    mouseDownCount = 0,
    onMouseDown = function(list)
        ISScrollingListBox.mouseDownCount = ISScrollingListBox.mouseDownCount + 1
        return list
    end,
}

local function createTextEntry(parent)
    local entry = widget()
    entry.text = ""
    function entry:getText() return self.text end
    function entry:setText(text) self.text = tostring(text or "") end
    parent:addChild(entry)
    return entry
end

local function createList(parent, options)
    local list = widget()
    list.items = {}
    list.selected = 0
    list.itemheight = options.itemHeight
    list.doDrawItem = options.doDrawItem
    function list:clear() self.items = {}; self.selected = 0 end
    function list:addItem(label, item)
        self.items[#self.items + 1] = {
            text = label,
            item = item,
            index = #self.items + 1,
            height = self.itemheight,
        }
    end
    function list:getItem() return self.items[self.selected] end
    function list:drawRect() end
    function list:drawText() end
    function list:drawTextRight() end
    parent:addChild(list)
    return list
end

local function createDetails(parent)
    local details = widget()
    details.items = {}
    function details:clear() self.items = {} end
    parent:addChild(details)
    return details
end

local function createButton(parent, options)
    local button = widget()
    button.internal = options.id
    button.title = options.title
    button.onclick = options.onclick
    parent:addChild(button)
    return button
end

PsychopatzCore = {
    UI = {
        Layout = {
            Pixels = function(value) return value end,
            Ellipsize = function(value) return value end,
            SetBounds = function(widgetValue, x, y, width, height)
                if widgetValue then
                    widgetValue.x = x
                    widgetValue.y = y
                    widgetValue.width = width
                    widgetValue.height = height
                end
            end,
        },
        AddKeyValue = function(list, label, value, warning)
            list.items[#list.items + 1] = {
                label = label,
                value = value,
                warning = warning,
            }
        end,
        ButtonCallback = function(callback) return callback end,
        CreateTextEntry = createTextEntry,
        CreateList = createList,
        CreateKeyValueList = createDetails,
        CreateButton = createButton,
    },
}

UIFont = { Small = "small" }
PNC = {
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}

local selectedIndex = 1
local actionCalls = {}
local model
model = {
    schemaOK = true,
    runtimeReason = nil,
    beats = {
        { id = "opening", durationMs = 1000 },
        { id = "reply", durationMs = 1200 },
    },
    GetSelectedBeatIndex = function() return selectedIndex end,
    GetBeatRows = function()
        return {
            { id = "opening", summary = "Actor 1: arrive", item = model.beats[1] },
            { id = "reply", summary = "Actor 1: reply", item = model.beats[2] },
        }
    end,
    GetSelectedBeat = function() return model.beats[selectedIndex] end,
    SelectBeat = function(index) selectedIndex = index end,
    GetActorRows = function()
        return {{
            id = "actor_1",
            label = "Actor 1",
            liveName = "Alice",
            liveID = "npc-1",
            supported = true,
        }}
    end,
    GetSelectionSummary = function() return "opening / arrive" end,
    GetValidation = function() return model.schemaOK, model.runtimeReason end,
    AddBeat = function()
        actionCalls[#actionCalls + 1] = "AddBeat"
        return true
    end,
    RemoveBeat = function()
        actionCalls[#actionCalls + 1] = "RemoveBeat"
        return false, "at_least_one_beat_required"
    end,
    MoveBeat = function(offset)
        actionCalls[#actionCalls + 1] = "MoveBeat:" .. tostring(offset)
        return true
    end,
    SetBeatDuration = function(value)
        actionCalls[#actionCalls + 1] = "SetBeatDuration:" .. tostring(value)
        if tostring(value) == "99" then
            return false, "duration_must_be_100_to_10000_ms"
        end
        return true
    end,
}

local BeatsTab = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab.lua"
)

T.equal(BeatsTab, ISPNCPuppetOperaBeatsTab,
    "beats tab hub did not preserve its public class identity")
T.truthy(PNC.PuppetOperaBeatsTabInternal,
    "beats tab spokes did not receive a shared private contract table")
for _, method in ipairs({
    "initialise",
    "createChildren",
    "setContext",
    "onBeatListMouseDown",
    "refresh",
    "onAction",
    "onResponsiveLayout",
}) do
    T.truthy(type(BeatsTab[method]) == "function",
        "beats tab public method was not installed: " .. method)
end

local statuses = {}
local refreshCount = 0
local owner = {
    model = model,
    uiScale = 1,
    setEditorStatus = function(_, reason, failed)
        statuses[#statuses + 1] = { reason = reason, failed = failed }
    end,
    refreshViews = function() refreshCount = refreshCount + 1 end,
}

local instance = setmetatable({
    width = 720,
    height = 480,
    getWidth = function(self) return self.width end,
    getHeight = function(self) return self.height end,
    addChild = function(self, child)
        self.children = self.children or {}
        self.children[#self.children + 1] = child
    end,
}, { __index = BeatsTab })
instance:initialise()
instance:createChildren()
instance:setContext(owner)

T.equal(#instance.beatList.items, 2,
    "refresh spoke did not project beat rows")
T.equal(instance.beatList.selected, 1,
    "refresh spoke did not retain the selected beat")
T.equal(instance.durationEntry:getText(), "1000",
    "refresh spoke did not project the selected duration")
T.truthy(#instance.details.items >= 5,
    "refresh spoke did not project beat and actor details")
T.equal(instance.beatList.doDrawItem(instance.beatList, 0,
    instance.beatList.items[1], false), 50,
    "presentation spoke did not render a beat row")

instance.beatList.selected = 2
T.truthy(instance.beatList.onMouseDown(instance.beatList, 0, 0),
    "interaction spoke did not accept a valid selection")
T.equal(selectedIndex, 2, "interaction spoke did not route selection to model")
T.equal(ISScrollingListBox.mouseDownCount, 1,
    "interaction spoke did not preserve list base input handling")
T.truthy(refreshCount > 0,
    "interaction spoke did not refresh the owner window")

selectedIndex = 0
instance:refresh()
T.equal(instance.durationEntry:getText(), "",
    "empty selection did not clear the duration input")
T.equal(instance.details.items[1].label, "Selection",
    "empty selection did not show its safe detail state")

selectedIndex = 1
instance:refresh()
T.truthy(instance:onAction(instance.addButton),
    "add action did not complete")
T.equal(actionCalls[#actionCalls], "AddBeat",
    "add action did not route to the model")
T.truthy(instance:onAction(instance.upButton),
    "move action did not complete")
T.equal(actionCalls[#actionCalls], "MoveBeat:-1",
    "move action did not preserve its direction")
T.falsy(instance:onAction(instance.removeButton),
    "rejected remove action was reported as accepted")
T.equal(statuses[#statuses].reason, "at_least_one_beat_required",
    "rejected model action did not expose its reason")

instance.durationEntry:setText("99")
T.falsy(instance:onAction(instance.applyDurationButton),
    "invalid duration was reported as accepted")
T.equal(statuses[#statuses].reason, "duration_must_be_100_to_10000_ms",
    "invalid duration did not preserve the model reason")
instance.durationEntry:setText("1500")
T.truthy(instance:onAction(instance.applyDurationButton),
    "valid duration was not accepted")
T.equal(statuses[#statuses].reason, "beat_updated",
    "accepted action did not report beat_updated")

model.schemaOK = false
instance:refresh()
T.equal(instance.details.items[#instance.details.items].label, "MP policy",
    "validation projection did not include MP policy")
T.equal(instance.details.items[#instance.details.items].warning, true,
    "invalid model validation was not marked as a warning")

instance.width = 720
instance.height = 480
instance:onResponsiveLayout()
T.truthy(instance.beatList.width > 0 and instance.details.width > 0,
    "responsive spoke did not lay out the primary columns")
T.truthy(instance.addButton.width > 0,
    "responsive spoke did not lay out action buttons")

instance.model = {}
instance:refresh()
T.falsy(instance:onAction(instance.addButton),
    "missing model dependency was reported as accepted")
T.equal(statuses[#statuses].reason, "beat_model_unavailable",
    "missing model dependency did not expose a stable reason")

T.finish("pnc_puppet_opera_beats_tab_modules_smoke")
