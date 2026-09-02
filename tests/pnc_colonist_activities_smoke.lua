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
function UI.Layout.Grid() gridCalls = gridCalls + 1 end

PsychopatzCore = { UI = UI }
ISPanel = {
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
    tabControlsPane = {
        setVisible = function(self, value) self.visible = value end,
        getWidth = function() return 640 end,
    },
    onColonistControl = function() end,
    requestSnapshot = function(_, source) requestedSnapshot = source end,
}

Activities.Create(window, UI, window.tabControlsPane)
Activities.Apply(window, true, UI.Layout)
T.equal(gridCalls, 1, "activities did not use the responsive command grid")

local rows = Activities.BuildRows({ selectedPerson = person, window = window })
T.equal(rows[1].detail, "Eating - Apple (PLAYING)",
    "activities tab does not use canonical activity data")
T.equal(rows[2].detail, "AUTOMATIC",
    "activities tab does not show the activity mode")

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

T.finish("pnc_colonist_activities_smoke")
