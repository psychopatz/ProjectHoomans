local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

local shown
PsychopatzCore = { Notifications = {
    Show = function(definition)
        shown = definition
        return true
    end,
} }
package.preload["PsychopatzCore/UI/PsychopatzNotificationWindow"] =
    function() return PsychopatzCore.Notifications end
PNC = {}

local Presentation = T.load("ProjectHoomans", "client",
    "PNC/UI/Scavenge/PNC_ScavengeNotifications.lua")
local snapshot = {
    sessionId = "run:1", revision = 9,
    state = "WAITING_FOR_SELECTION", processedCount = 2,
    scavengers = {
        { npcId = "bob", npcName = "Bob" },
        { npcId = "sue", npcName = "Sue" },
    },
    manifest = {
        { fullType = "Base.Beans", displayName = "Beans", quantity = 2,
            sourceToken = "fridge:1", sourceLabel = "Fridge",
            discoveredByNpcId = "bob" },
        { fullType = "Base.WaterBottle", displayName = "Water Bottle",
            quantity = 1, sourceToken = "floor:1", sourceLabel = "Floor",
            discoveredByNpcId = "sue" },
    },
}
T.truthy(Presentation.Receive(nil, snapshot),
    "completed search opens notification")
T.contains(shown.message, "2 scavengers", "team count summary")
T.contains(shown.message, "3 items", "item count summary")
T.contains(shown.details[1], "Bob", "finder name shown")
T.contains(shown.details[1], "Fridge", "source name shown")
T.contains(shown.details[2], "Sue", "second finder shown")
T.falsy(Presentation.Receive(snapshot, snapshot),
    "same completion revision not shown twice")

T.finish("pnc_scavenge_notifications_smoke")
