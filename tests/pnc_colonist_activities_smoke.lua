local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.Apple" and "Apple" or nil
end

local variants = {}
local commands = {}
local requestedSnapshot
local gridCalls = 0
local UI = {
    Layout = {},
    SetButtonVariant = function(button, variant)
        variants[button.internal] = variant
    end,
    ButtonCallback = function(callback) return callback end,
    DrawSectionTitle = function() end,
    CreatePanel = function()
        local panel = { visible = true, width = 640, children = {} }
        function panel:setVisible(value) self.visible = value end
        function panel:getWidth() return self.width end
        function panel:addChild(child) self.children[#self.children + 1] = child end
        return panel
    end,
    CreateButton = function(_, definition)
        local button = {
            internal = definition.id,
            title = definition.title,
            visible = true,
            enabled = true,
            setTitle = function(self, value) self.title = value end,
            setEnable = function(self, value) self.enabled = value end,
            setVisible = function(self, value) self.visible = value end,
            getTitle = function(self) return self.title end,
        }
        return button
    end,
}

function UI.Layout.Scale() return 1 end
function UI.Layout.Pixels(value) return value end
function UI.Layout.Grid() gridCalls = gridCalls + 1 return { height = 34 } end
function UI.Layout.SetBounds(control, x, y, width, height)
    control.x, control.y, control.width, control.height = x, y, width, height
end

PsychopatzCore = { UI = UI }
ISPanel = {
    render = function() end,
    derive = function(self)
        local child = {}
        child.__index = child
        return setmetatable(child, { __index = self })
    end,
}
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return UI
end
package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISComboBox"] = function()
    ISComboBox = ISComboBox or {}
    ISComboBox.new = function(_, x, y, width, height, target, onChange)
        local combo = {
            x = x, y = y, width = width, height = height,
            target = target, onChange = onChange, selected = 1,
        }
        function combo:initialise() end
        function combo:instantiate() end
        function combo:setVisible(value) self.visible = value end
        function combo:addOptionWithData() end
        function combo:clear() end
        function combo:getOptionData() return nil end
        return combo
    end
    return ISComboBox
end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ProvisionDiagnosticsModal"
] = function()
    return { Open = function() end }
end

PNC = {
    Client = {
        ExecuteCompanionCommand = function(commandID, npcID, _, context)
            commands[#commands + 1] = {
                commandID = commandID, npcID = npcID, context = context,
            }
            return true
        end,
    },
}

local Activities = T.load(
    "ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistActivities.lua"
)

local person = {
    id = "npc_alex", name = "Alex", alive = true, activity = "Eating",
    journal = {
        { "projecthoomans.npc.skill.levelUp", 150, "Axe", 3 },
        { "projecthoomans.npc.needs.foodConsumed", 120,
            "Base.Apple", 0.2 },
    },
    actionInformation = {
        kind = "activity", fallback = "Eating",
        labelKey = "UI_PNC_Task_Eat",
        capability = "survival.eat.inventory", phase = "PLAYING",
        activityItemFullType = "Base.Apple",
    },
}
local window = {
    people = { getItem = function()
        return { item = { value = person } }
    end },
    onColonistControl = function() end,
    requestSnapshot = function(_, source) requestedSnapshot = source end,
}

local activities = Activities.Create(window, UI)
Activities.Apply(window, true, UI.Layout, activities)
T.equal(gridCalls, 1, "activities did not use the responsive command grid")
T.truthy(activities.pane,
    "activities tab does not own its command pane")

local rows = Activities.BuildRows({ selectedPerson = person, window = window })
T.equal(rows[1].detail, "Eating - Apple (PLAYING)",
    "activities tab does not use canonical activity data")
T.equal(rows[2].detail, "AUTOMATIC",
    "activities tab does not show the activity mode")
T.equal(rows[4].label, "COLONIST JOURNAL",
    "activities tab does not include the colonist journal section")
T.equal(rows[4].detail, "2 entries",
    "activities tab does not summarize journal history")
T.equal(rows[5].label, "Reached Axe level 3",
    "activities tab does not render journal history")
T.equal(rows[6].label, "Ate Apple (+20% hunger)",
    "activities tab does not preserve canonical journal formatting")

T.truthy(Activities.OnControl(window, {
    internal = "manual_eat",
    activityCommandID = "manual_eat",
}), "activities tab did not dispatch the selected activity")
T.equal(commands[1].commandID, "manual_eat",
    "activities tab dispatched the wrong command")
T.equal(commands[1].npcID, person.id,
    "activities tab dispatched to the wrong colonist")
T.equal(commands[1].context.source, "colonist_activities",
    "activities tab omitted its command source")
T.equal(requestedSnapshot, "colonist_activity_manual_eat",
    "activities tab did not request a post-action snapshot")

local Registry = T.load(
    "ProjectHoomans", "client", "PNC/UI/Colonist/PNC_ColonistRegistry.lua")
T.load("ProjectHoomans", "client", "PNC/UI/Colonist/PNC_ColonistTabs.lua")
T.truthy(Registry.Get("activities"),
    "activities is not a first-class reusable colonist tab")
T.truthy(Registry.Get("activities").create,
    "activities tab does not expose the tab component lifecycle")
T.truthy(Registry.Get("activities").onControl,
    "activities tab does not expose control dispatch")
local debugTab = Registry.Get("debug")
T.truthy(debugTab, "debug is not a first-class reusable colonist tab")
T.truthy(debugTab.available, "debug tab does not expose its availability gate")
PNC.Client.CanUseDebug = function() return false end
T.falsy(debugTab.available(), "debug tab is visible without authorization")
PNC.Client.CanUseDebug = function() return true end
T.truthy(debugTab.available(), "debug tab is hidden for an authorized user")

local Debug = T.load(
    "ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistDebug.lua"
)
local debug = Debug.Create(window, UI)
T.truthy(debug.pane, "debug tab does not own its command pane")
T.falsy(debug.pane == activities.pane,
    "colonist tabs still share a controls pane")
Debug.Apply(window, false, UI.Layout, debug)
T.equal(activities.pane.visible, true,
    "inactive debug tab hides the Activities controls pane")

T.finish("pnc_colonist_activities_smoke")
