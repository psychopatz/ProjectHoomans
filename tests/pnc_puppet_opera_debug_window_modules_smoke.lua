local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

-- Load the window hub against the smallest deterministic engine surface. The
-- individual tabs and model are contract dependencies here; their behavior
-- is covered by their own smoke suites.
for _, moduleName in ipairs({
    "ISUI/ISTabPanel",
    "ISUI/ISComboBox",
    "PsychopatzCore/UI/PsychopatzUI",
    "PNC/PuppetOpera/PNC_PuppetOpera_Client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaTraceTab",
}) do
    package.loaded[moduleName] = true
end

PsychopatzWindow = {
    derive = function(_, name)
        local class = { Type = name }
        class.__index = class
        return class
    end,
    initialise = function() end,
    createChildren = function() end,
    prerender = function() end,
    render = function() end,
}
local function widget()
    return {
        initialise = function() end,
        instantiate = function() end,
        setContext = function() end,
        setVisible = function() end,
        setTitle = function() end,
    }
end

local function tabClass()
    return {
        new = function() return widget() end,
    }
end

ISTabPanel = {
    new = function()
        local panel = widget()
        panel.tabHeight = 0
        panel.views = {}
        panel.addView = function(self, name, view)
            self.views[#self.views + 1] = { name = name, view = view }
        end
        return panel
    end,
}
ISComboBox = {
    new = function() return widget() end,
}
ISPNCPuppetOperaLayoutTab = tabClass()
ISPNCPuppetOperaAnimationTab = tabClass()
ISPNCPuppetOperaBeatsTab = tabClass()
ISPNCPuppetOperaTraceTab = tabClass()

PsychopatzCore = {
    UI = {
        Layout = {
            Pixels = function(value) return value end,
            SetBounds = function() end,
            Ellipsize = function(value) return value end,
        },
        ButtonCallback = function(callback) return callback end,
        CreateButton = function(_, options)
            local button = widget()
            button.internal = options.id
            return button
        end,
        NewWindow = function() return widget() end,
    },
}
PNC = {
    Client = {
        CanUseDebug = function() return false end,
    },
    PuppetOpera = {
        Client = {},
    },
    PuppetOperaDebugModel = {
        State = {},
    },
    Translation = {
        GetKey = function(key) return key end,
    },
}

local WindowAPI = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow.lua"
)
local Class = ISPNCPuppetOperaDebugWindow

T.equal(WindowAPI, PNC.PuppetOperaDebugWindow,
    "debug window hub did not preserve namespace identity")
T.truthy(type(WindowAPI.Open) == "function",
    "debug window public Open API was not preserved")
T.truthy(WindowAPI.Internal and WindowAPI.Internal.createTabs,
    "debug window tab contract was not installed")
T.truthy(type(WindowAPI.Internal.tr) == "function"
    and WindowAPI.Internal.TEXT_TITLE
    and WindowAPI.Internal.TEXT_DESCRIPTION
    and WindowAPI.Internal.TEXT_NO_ACTOR,
    "debug window presentation contracts were not installed")
T.equal(WindowAPI.Internal.Model, PNC.PuppetOperaDebugModel,
    "debug window did not retain model ownership")
T.equal(WindowAPI.Internal.Client, PNC.PuppetOpera.Client,
    "debug window did not retain client adapter ownership")

for _, method in ipairs({
    "initialise",
    "createChildren",
    "onResponsiveLayout",
    "refreshBlueprints",
    "refreshAnimationTabs",
    "refreshActorSlots",
    "refreshViews",
    "setEditorStatus",
    "clearEditorStatus",
    "onBlueprintChanged",
    "onActorChanged",
    "onTopAction",
    "prepareRuntime",
    "requestPlacementPreview",
    "onControl",
    "prerender",
    "render",
    "close",
}) do
    T.truthy(type(Class[method]) == "function",
        "debug window method was not installed: " .. method)
end

local window = setmetatable({
    addChild = function() end,
    requestResponsiveLayout = function() end,
}, { __index = Class })
window:createChildren()
T.equal(#window.topButtons, 4,
    "debug window lifecycle did not create the top action controls")
T.equal(#window.controls, 6,
    "debug window lifecycle did not create the runtime controls")
T.equal(#window.tabPanel.views, 5,
    "debug window tab spoke did not create all tabs")
T.equal(#window.tabDefinitions, 5,
    "debug window tab definitions were not preserved")

local instance = setmetatable({}, { __index = Class })
instance:setEditorStatus("contract_failure", true)
T.equal(instance.editorStatus, "contract_failure",
    "debug window status setter lost its public state")
T.equal(PNC.PuppetOperaDebugModel.State.editorError, "contract_failure",
    "debug window status setter lost model error ownership")
instance:clearEditorStatus()
T.falsy(instance.editorStatus, "debug window status was not cleared")
T.falsy(PNC.PuppetOperaDebugModel.State.editorError,
    "model error state was not cleared")

T.equal(WindowAPI.Open(), nil,
    "debug window opened without the existing debug-authority check")

return T.finish("pnc_puppet_opera_debug_window_modules_smoke")
