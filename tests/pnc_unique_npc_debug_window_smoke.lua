local T = require "tests/support/test"

local WINDOW = T.path("ProjectHoomans", "client", "")
    .. "PNC/UI/UniqueNPC/PNC_UniqueNPCDebugWindow.lua"

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return true end

local colors = {
    text = { r = 1, g = 1, b = 1, a = 1 },
    textMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
    success = { r = 0, g = 1, b = 0, a = 1 },
    danger = { r = 1, g = 0, b = 0, a = 1 },
    warning = { r = 1, g = 1, b = 0, a = 1 },
    textMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
}

local function button(definition)
    local value = {
        internal = definition.id,
        title = definition.title,
        setEnable = function(self, enabled) self.enabled = enabled end,
        setTitle = function(self, title) self.title = title end,
    }
    return value
end

local function list()
    local value = { items = {}, selected = 0 }
    function value:clear() self.items = {} end
    function value:addItem(label, item)
        self.items[#self.items + 1] = {
            label = label, item = item, index = #self.items + 1,
        }
    end
    function value:getItem() return self.items[self.selected] end
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

local UI = {
    Theme = { colors = colors },
    Layout = {
        Pixels = function(value) return value end,
        Flow = function(controls, rect)
            return { bottom = rect.y + 30, height = 30 }
        end,
        SetBounds = function() end,
    },
    CreateButton = function(_, definition) return button(definition) end,
    CreateList = function() return list() end,
    CreateKeyValueList = function() return details() end,
    SetButtonVariant = function(buttonValue, variant)
        buttonValue.variant = variant
    end,
    DrawListSelection = function() end,
    DrawBadge = function() end,
    DrawSectionTitle = function() end,
}

PsychopatzCore = { UI = UI }
UIFont = { Small = 1 }
PNC = {
    Core = { Now = function() return 100 end },
    Network = {
        ClientState = {
            lastUniqueNPCDebugReceiveAt = 1,
            uniqueNPCDebug = {
                counts = { total = 1, alive = 1, dead = 0, problems = 0 },
                entries = {
                    {
                        definitionId = "gorgon_ramsee",
                        displayName = "Gorgon Ramsee",
                        registered = true,
                        status = "alive",
                        spawned = true,
                        runtime = {
                            runtimeNpcId = "npcGorgonRamsee_ABC",
                            name = "Gorgon Ramsee",
                            x = 10, y = 20, z = 0,
                        },
                    },
                },
            },
        },
    },
    Client = {
        CanUseDebug = function() return true end,
        RequestUniqueNPCDebug = function() return true end,
        SendDebug = function(action, args)
            PNC.testSpawnAction = action
            PNC.testSpawnDefinitionID = args.definitionId
            return true
        end,
    },
    NPCMonitor = {
        trackedId = nil,
        TrackTarget = function(item) PNC.NPCMonitor.trackedId = item.id end,
        ClearTrack = function() PNC.NPCMonitor.trackedId = nil end,
    },
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
function BaseWindow:prerender() end
function BaseWindow:render() end
function BaseWindow:new()
    return setmetatable({
        uiScale = 1,
        requestResponsiveLayout = function() end,
        getContentRect = function()
            return { x = 0, y = 0, width = 900, height = 600 }
        end,
        setVisible = function() end,
        removeFromUIManager = function() end,
        addToUIManager = function() end,
        bringToTop = function() end,
    }, self)
end
PsychopatzWindow = BaseWindow

T.load(WINDOW)

local window = ISPNCUniqueNPCDebugWindow:new(0, 0, 900, 600, {})
window:createChildren()
T.equal(#window.list.items, 1, "unique debug window list")
T.equal(window.list.items[1].item.label, "Gorgon Ramsee",
    "unique debug window row")
T.truthy(window.locateButton.enabled, "locate enabled for alive unique")
T.truthy(window.spawnTestButton.enabled, "test spawn enabled for registered unique")
window:onAction(window.spawnTestButton)
T.equal(PNC.testSpawnAction, "spawn_unique_test",
    "test spawn uses the debug command path")
T.equal(PNC.testSpawnDefinitionID, "gorgon_ramsee",
    "test spawn targets the selected definition")
window:onAction(window.locateButton)
T.equal(PNC.NPCMonitor.trackedId, "npcGorgonRamsee_ABC",
    "locate delegates to NPC monitor tracking")
window:onAction(window.locateButton)
T.equal(PNC.NPCMonitor.trackedId, nil, "locate toggles off")
T.finish("pnc_unique_npc_debug_window_smoke")
