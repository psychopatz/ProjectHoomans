local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

for _, moduleName in ipairs({
    "ISUI/ISPanel",
    "ISUI/ISComboBox",
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
    function value:setVisible(visible) self.visible = visible end
    function value:setTitle(title) self.title = title end
    function value:setScrollHeight(height) self.scrollHeight = height end
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

ISComboBox = {
    new = function(_, _, _, _, target)
        local combo = widget()
        combo.target = target
        combo.options = {}
        combo.selected = 1
        function combo:clear() self.options = {} end
        function combo:addOption(option)
            self.options[#self.options + 1] = option
        end
        return combo
    end,
}

local function createTextEntry(parent, options)
    local entry = widget()
    entry.text = ""
    function entry:getText() return self.text end
    function entry:setText(text)
        self.text = tostring(text or "")
        if options.onTextChange then options.onTextChange() end
    end
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
    parent:addChild(button)
    return button
end

PsychopatzCore = {
    UI = {
        Layout = {
            Pixels = function(value) return value end,
            SetBounds = function(widgetValue, x, y, width, height)
                if widgetValue then
                    widgetValue.x = x
                    widgetValue.y = y
                    widgetValue.width = width
                    widgetValue.height = height
                end
            end,
            Ellipsize = function(value) return value end,
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

local entry = {
    node = "wavehi",
    anim = "Bob_WaveHi",
    path = "media/PNC_WaveHi.xml",
    source = "player",
    mode = "action",
    action = "Wave",
    state = "idle",
    playable = true,
    puppetOperaCapability = {
        id = "player.action",
        scenePolicy = "scene_approved",
    },
}
local modelCalls = {}
local model = {
    GetPlayerSource = function() return "player" end,
    SetPlayerSource = function(source)
        modelCalls.playerSource = source
        return true
    end,
    GetNPCStates = function() return { "bumped" } end,
    GetNPCState = function() return nil end,
    SetNPCState = function(state) modelCalls.npcState = state end,
    SetPlayerQuery = function(query) modelCalls.playerQuery = query end,
    SetNPCQuery = function(query) modelCalls.npcQuery = query end,
    GetPlayerCatalogEntries = function() return { entry } end,
    GetNPCCatalogEntries = function() return { entry } end,
    PlayerEntryID = function() return "player.entry.wavehi" end,
    NPCEntryID = function() return "npc.entry.wavehi" end,
    IsPlayerEntryServerApproved = function() return true end,
    IsNPCEntryServerApproved = function() return true end,
    GetActorForCatalog = function() return "actor_1" end,
    GetActorRows = function()
        return {{
            id = "actor_1",
            label = "Actor 1",
            kind = "local_player",
            bindingID = "player",
            liveID = "player",
        }}
    end,
    GetSnapshot = function() return {} end,
    GetSelectionSummary = function() return "Wave / Bob_WaveHi" end,
    EntryBumpType = function() return nil end,
    GetPreviewTarget = function() return { liveID = "player" } end,
    AssignAnimation = function(actorID)
        modelCalls.assignedActorID = actorID
        return true
    end,
}

local previewState = { loop = false }
local clientCalls = {}
PNC = {
    PuppetOpera = {
        Client = {
            GetPreviewLoopEnabled = function() return previewState.loop end,
            SetPreviewLoopEnabled = function(enabled)
                previewState.loop = enabled == true
                clientCalls.loop = previewState.loop
            end,
            PreviewPlayer = function(value)
                clientCalls.previewEntry = value
                return true
            end,
            PreviewNPC = function() return true end,
            StopPreview = function() clientCalls.stopped = true end,
        },
    },
    Translation = {
        GetKey = function(key) return key end,
    },
}

local AnimationTab = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab.lua"
)

T.equal(AnimationTab, ISPNCPuppetOperaAnimationTab,
    "animation tab hub did not preserve its public class identity")
T.truthy(PNC.PuppetOperaAnimationTabInternal,
    "animation tab spokes did not receive a shared private contract table")

for _, method in ipairs({
    "initialise",
    "createChildren",
    "setContext",
    "updateQuery",
    "rebuildFilter",
    "onFilterChanged",
    "refreshTargets",
    "onTargetChanged",
    "getSelectedEntry",
    "refreshCatalog",
    "refreshDetails",
    "onAction",
    "onResponsiveLayout",
}) do
    T.truthy(type(AnimationTab[method]) == "function",
        "animation tab public method was not installed: " .. method)
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
    addChild = function(self, child)
        self.children = self.children or {}
        self.children[#self.children + 1] = child
    end,
}, { __index = AnimationTab })
instance:initialise()
instance:createChildren()
instance:setContext(owner, "player")

T.equal(#instance.list.items, 1,
    "catalog spoke did not project the model entry into the list")
T.equal(instance:getSelectedEntry(), entry,
    "catalog selection did not retain the selected entry")
T.equal(instance.visibleCount, 1,
    "catalog spoke did not publish its bounded visible count")
T.equal(#instance.details.items > 0, true,
    "details spoke did not project selection metadata")

instance.search:setText("wave")
T.equal(modelCalls.playerQuery, "wave",
    "search input did not route through the model query contract")

T.truthy(instance:onAction(instance.loopPreviewButton),
    "loop action did not complete")
T.truthy(previewState.loop, "loop action did not update client preview state")
T.equal(statuses[#statuses].reason, "preview_loop_enabled",
    "loop action lost its status signature")

T.truthy(instance:onAction(instance.previewButton),
    "player preview action did not complete")
T.equal(clientCalls.previewEntry, entry,
    "player preview action did not route the selected entry")
T.equal(statuses[#statuses].reason, "preview_started",
    "player preview action lost its status signature")

T.truthy(instance:onAction(instance.assignButton),
    "assignment action did not complete")
T.equal(modelCalls.assignedActorID, "actor_1",
    "assignment action did not use the selected scene actor")
T.equal(statuses[#statuses].reason, "assigned:actor_1",
    "assignment action lost its status signature")
T.equal(refreshCount, 2,
    "preview and assignment actions did not refresh the parent window")

T.truthy(instance:onAction(instance.stopPreviewButton),
    "stop preview action did not complete")
T.truthy(clientCalls.stopped,
    "stop preview action did not route through the client adapter")

local badEntry = "malformed"
model.GetPlayerCatalogEntries = function() return { badEntry, entry } end
instance:refreshCatalog()
T.equal(#instance.list.items, 1,
    "malformed catalog data was not safely bounded out of the UI list")

return T.finish("pnc_puppet_opera_animation_tab_modules_smoke")
