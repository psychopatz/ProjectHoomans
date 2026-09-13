local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

PNC = {
    NeedsDefinitions = {
        GetLevel = function(_, value)
            if value >= 0.84 then return "CRITICAL" end
            if value >= 0.45 then return "MODERATE" end
            return "NORMAL"
        end,
    },
    ConditionStats = {
        TYPES = { "stress", "boredom", "panic" },
        DEFINITIONS = {
            stress = { minimum = 0, maximum = 1, default = 0 },
            boredom = { minimum = 0, maximum = 100, default = 0 },
            panic = { minimum = 0, maximum = 100, default = 0 },
        },
        GetLevel = function() return "STABLE" end,
    },
}
getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    if fullType == "Base.Apple" then return "Apple" end
end

local Presentation = require(
    "PNC/UI/Shared/PNC_ColonyPresentation"
)

local snapshot = {
    colony = { mode = "camp" },
    people = {
        {
            id = "npc_1", name = "Morgan", role = "resident",
            activity = "working",
            needs = { hunger = 0.12, thirst = 0.95, fatigue = 0.30 },
            conditionStats = { stress = 0.4, boredom = 10, panic = 20 },
            morale = 35,
            journal = {
                { "projecthoomans.npc.skill.levelUp", 150, "Axe", 3 },
                { "projecthoomans.npc.needs.foodConsumed", 120,
                    "Base.Apple", 0.2 },
            },
        },
    },
    attention = {
        { name = "Morgan", needType = "thirst", value = 0.95,
            severity = "CRITICAL" },
    },
}

local roster = Presentation.BuildRoster(snapshot)
T.equal(#roster, 1, "roster row count")
T.equal(roster[1].id, "npc_1", "roster preserves selection identity")
T.equal(roster[1].worstLevel, "CRITICAL", "worst need badge")

local selectedRoster = {
    getItem = function() return { item = roster[1] } end,
}
local Shared = require(
    "PNC/UI/Shared/PNC_ColonyUIShared"
)
T.equal(Shared.ListValue(selectedRoster), snapshot.people[1],
    "roster selection unwraps the colonist snapshot")

local overview = Presentation.BuildOverview(snapshot)
T.equal(#overview, 4, "overview always produces visible rows")
T.equal(overview[1].label, "STATUS", "overview status row")

local people = Presentation.BuildPeople(roster[1])
T.equal(#people, 12, "people tab includes nutrition and journal rows")
T.equal(people[1].label, "Morgan", "selected person details")
T.equal(people[5].meter, true, "people needs use meters")
T.equal(people[10].label, "COLONIST JOURNAL", "journal section is visible")
T.equal(people[11].label, "Reached Axe level 3", "newest journal entry first")
T.equal(people[12].label, "Ate Apple (+20% hunger)",
    "journal resolves item names on the client")
local emptyJournal = Presentation.BuildPeople({
    value = {
        id = "npc_2", name = "Taylor", needs = {}, journal = {},
    },
})
T.equal(emptyJournal[10].detail, "0 entries", "empty journal count")
T.equal(emptyJournal[11].label, "No recorded history yet",
    "empty journal remains visible")

local needs = Presentation.BuildNeeds(roster[1])
T.equal(#needs, 10, "needs, nutrition, and condition meter rows")
T.equal(needs[2].needType, "hunger", "hunger meter binding")
T.equal(needs[10].key, "morale", "morale meter binding")

ISPanel = {
    derive = function(self)
        local child = {}
        child.__index = child
        setmetatable(child, { __index = self })
        return child
    end,
}
PsychopatzCore = {
    UI = {
        Theme = { colors = {} },
        Layout = {},
    },
}
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISComboBox"] = function()
    ISComboBox = ISComboBox or {}
    return ISComboBox
end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
local Components = require(
    "PNC/UI/Shared/PNC_ColonyUIComponents"
)
local bound = {
    items = { { stale = true } },
    yScroll = -900,
    scrollHeight = 900,
    smoothScrollTargetY = -900,
    smoothScrollY = -900,
}
function bound:clear() self.items = {} end
function bound:setScrollHeight(value) self.scrollHeight = value end
function bound:setYScroll(value) self.yScroll = value end
function bound:addItem(key, row)
    self.items[#self.items + 1] = { key = key, item = row }
end
Components.SetRows(bound, overview)
T.equal(#bound.items, 4, "detail rows are bound to the list")
T.equal(bound.yScroll, 0, "stale detail scroll is reset")
T.equal(bound.smoothScrollTargetY, nil, "stale smooth scroll is reset")
T.equal(bound.items[1].item.label, "STATUS", "bound row remains visible")

local scrollbar = { x = -13, y = 0, width = 13, height = 1 }
function scrollbar:getWidth() return self.width end
function scrollbar:setX(value) self.x = value end
function scrollbar:setY(value) self.y = value end
function scrollbar:setHeight(value) self.height = value end
local resizedList = { width = 420, height = 600, vscroll = scrollbar }
function resizedList:getWidth() return self.width end
function resizedList:getHeight() return self.height end
Components.LayoutScrollbar(resizedList)
T.equal(scrollbar.x, 407, "scrollbar follows resized container edge")
T.equal(scrollbar.height, 600, "scrollbar follows resized container height")

T.finish("pnc_colony_management_ui_model_smoke")
