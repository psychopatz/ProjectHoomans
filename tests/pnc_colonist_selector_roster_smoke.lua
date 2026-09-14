local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

PNC = {
    NeedsDefinitions = {
        GetLevel = function(_, value)
            value = tonumber(value) or 0
            if value >= 0.84 then return "CRITICAL" end
            if value >= 0.45 then return "MODERATE" end
            if value >= 0.15 then return "MINOR" end
            return "NORMAL"
        end,
    },
}

package.preload["PNC/UI/Shared/PNC_ColonyUIComponents"] = function()
    return {}
end

local Selector = T.load("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistSelector.lua")

local rows = Selector.BuildRows({ people = {
    {
        id = "healthy", name = "Healthy", role = "resident",
        needs = { hunger = 0, thirst = 0, fatigue = 0 },
        medicalStatus = {
            bleeding = false, openWoundCount = 0, bandagedWoundCount = 0,
        },
        actionInformation = { kind = "at_home" },
    },
    {
        id = "bandaged", name = "Bandaged", role = "resident",
        needs = { hunger = 0.20, thirst = 0.95, fatigue = 0.75 },
        medicalStatus = {
            bleeding = false, openWoundCount = 0, bandagedWoundCount = 1,
        },
        actionInformation = { kind = "activity", activityId = "job:GuardAnchor",
            fallback = "Guard Anchor" },
    },
    {
        id = "bleeding", name = "Bleeding", role = "resident",
        needs = { hunger = 0, thirst = 0, fatigue = 0 },
        medicalStatus = {
            bleeding = true, openWoundCount = 1, bandagedWoundCount = 0,
        },
        activity = "working",
    },
} })

T.equal(#rows, 3, "roster row count")
T.equal(rows[1].detail, "Idle", "healthy row keeps activity only")
T.equal(#rows[1].indicators, 0, "healthy row has no problem icons")
T.falsy(rows[1].detail:find("resident", 1, true),
    "roster does not repeat the role")

T.equal(rows[2].detail, "Idle (Guard Anchor)",
    "roster retains canonical activity text")
T.equal(rows[2].indicators[1].id, "hunger",
    "roster shows hunger icon")
T.equal(rows[2].indicators[2].id, "thirst",
    "roster shows thirst icon")
T.equal(rows[2].indicators[3].id, "fatigue",
    "roster shows exhausted icon")
T.equal(rows[2].indicators[4].id, "pained",
    "bandaged wound uses pained icon")
T.equal(rows[2].indicators[5].id, "critical",
    "critical need uses angry icon")
T.equal(rows[2].indicators[4].texturePath,
    "media/ui/Moodles/32/Mood_Pained.png",
    "bandaged wound uses the vanilla pained texture")
T.equal(rows[2].indicators[4].tooltip,
    "This colonist has a bandaged wound and is still recovering.",
    "bandaged wound exposes an explanatory tooltip")
T.equal(rows[2].indicators[1].tooltip,
    "This colonist is hungry and needs food.",
    "hunger exposes an explanatory tooltip")
T.equal(rows[2].indicators[2].tooltip,
    "This colonist is thirsty and needs water.",
    "thirst exposes an explanatory tooltip")
T.equal(rows[2].indicators[3].tooltip,
    "This colonist is tired and needs rest.",
    "fatigue exposes an explanatory tooltip")
T.equal(rows[2].indicators[5].tooltip,
    "This colonist has a critical need that requires immediate attention.",
    "critical need exposes an explanatory tooltip")

T.equal(#rows[3].indicators, 1,
    "bleeding row has one medical icon when needs are normal")
T.equal(rows[3].indicators[1].id, "bleeding",
    "open wound uses bleeding icon")
T.equal(rows[3].indicators[1].tooltip,
    "This colonist has an untreated wound and is bleeding.",
    "bleeding exposes an explanatory tooltip")

T.finish("pnc_colonist_selector_roster_smoke")
