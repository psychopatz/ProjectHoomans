local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.Apple" and "Apple" or nil
end
local itemNameResolver = getItemNameFromFullType

local variants = {}
local commands = {}
local requestedSnapshot
local UI = {
    Layout = {},
    SetButtonVariant = function(button, variant)
        variants[button.internal] = variant
    end,
    CreateButton = function(_, definition)
        local button = {
            internal = definition.id,
            title = definition.title,
            setTitle = function(self, value) self.title = value end,
            setEnable = function(self, value) self.enabled = value end,
            setVisible = function(self, value) self.visible = value end,
        }
        return button
    end,
}

function UI.Layout.Pixels(value) return value end
function UI.Layout.SetBounds() end

PsychopatzCore = { UI = UI }
ISPNCColonyManagementWindow = { onActivitiesControl = function() end }
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
        ExecuteCompanionCommand = function(commandID, npcID)
            commands[#commands + 1] = { commandID = commandID, npcID = npcID }
            return true
        end,
    },
}

local Activities = T["load"](
    "ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_ActivitiesTab.lua"
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
    requestSnapshot = function(_, source) requestedSnapshot = source end,
}

Activities.Create(window)
local rows = Activities.BuildRows({ selectedPerson = person, window = window })
T.equal(rows[1].detail, "Eating - Apple (PLAYING)",
    "activities tab uses canonical activity information and item name")
T.equal(rows[2].detail, "AUTOMATIC",
    "automatic activity state is visible without duplicating execution")

getItemNameFromFullType = nil
person.actionInformation.activityItemFullType = "Base.Bread"
rows = Activities.BuildRows({ selectedPerson = person, window = window })
T.equal(rows[1].detail, "Eating - Bread (PLAYING)",
    "full type still produces a useful item name without a client resolver")
getItemNameFromFullType = itemNameResolver
person.actionInformation.activityItemFullType = "Base.Apple"

T.truthy(Activities.OnControl(window, { internal = "manual_eat" }),
    "activities tab sends the manual command")
T.equal(commands[1].commandID, "manual_eat",
    "activities tab uses the shared companion command id")
T.equal(commands[1].npcID, person.id,
    "activities tab targets the selected colonist")
T.equal(requestedSnapshot, "manual_activity_manual_eat",
    "activities tab refreshes the colony snapshot after dispatch")

person.actionInformation.capability = "sleep"
person.manualActivityDisabled = nil
Activities.OnPersonSelected(window)
T.equal(window.activityControls.manual_sleep.title, "SLEEP: ON",
    "sleep button reflects the canonical active capability")
T.equal(variants.manual_sleep, "selected",
    "active sleep uses the selected button presentation")

local tabsSource = T.read(T.path(
    "ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs.lua"
))
T.truthy(tabsSource:find('id = "activities"', 1, true),
    "activities is a first-class colony management tab")
T.truthy(tabsSource:find("ActivitiesTab.OnControl", 1, true),
    "colony tab delegates command dispatch to its tab module")

T.finish("pnc_colony_management_activities_tab_smoke")
