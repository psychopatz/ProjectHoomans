local T = require "tests/support/test"

T.addPackagePaths()

local Presentation = T.load("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistActivityPresentation.lua")

local work = Presentation.Current({
    name = "Worker", activity = "working",
    actionInformation = {
        kind = "work_order", operation = "CORPSE_HAUL",
        phase = "TRAVEL_TO_STATION",
    },
})
local idle = Presentation.Current({
    name = "Idle", activity = "working",
    actionInformation = {
        kind = "activity", activityId = "job:GuardAnchor",
        fallback = "Guard Anchor",
    },
})
local treatment = Presentation.Current({
    name = "Doctor", activity = "working",
    actionInformation = { kind = "treatment", phase = "bandaging" },
})

T.contains(work, "CORPSE HAUL",
    "roster exposes the actual work operation")
T.contains(work, "TRAVEL_TO_STATION",
    "roster exposes the actual work phase")
T.contains(idle, "Idle (Guard Anchor)",
    "roster does not call a generic guard job working")
T.contains(treatment, "MEDICAL CARE (bandaging)",
    "roster does not expose canonical treatment activity")

T.finish("pnc_colonist_selector_activity_smoke")
