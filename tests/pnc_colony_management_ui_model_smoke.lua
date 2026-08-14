local LUA_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
package.path = LUA_ROOT .. "client/?.lua;" .. package.path
package.path = LUA_ROOT .. "shared/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

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
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
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
equal(#roster, 1, "roster row count")
equal(roster[1].id, "npc_1", "roster preserves selection identity")
equal(roster[1].worstLevel, "CRITICAL", "worst need badge")

local overview = Presentation.BuildOverview(snapshot)
equal(#overview, 4, "overview always produces visible rows")
equal(overview[1].label, "STATUS", "overview status row")

local people = Presentation.BuildPeople(roster[1])
equal(#people, 12, "people tab includes nutrition and journal rows")
equal(people[1].label, "Morgan", "selected person details")
equal(people[5].meter, true, "people needs use meters")
equal(people[10].label, "COLONIST JOURNAL", "journal section is visible")
equal(people[11].label, "Reached Axe level 3", "newest journal entry first")
equal(people[12].label, "Ate Apple (+20% hunger)",
    "journal resolves item names on the client")
local emptyJournal = Presentation.BuildPeople({
    value = {
        id = "npc_2", name = "Taylor", needs = {}, journal = {},
    },
})
equal(emptyJournal[10].detail, "0 entries", "empty journal count")
equal(emptyJournal[11].label, "No recorded history yet",
    "empty journal remains visible")

local needs = Presentation.BuildNeeds(roster[1])
equal(#needs, 10, "needs, nutrition, and condition meter rows")
equal(needs[2].needType, "hunger", "hunger meter binding")
equal(needs[10].key, "morale", "morale meter binding")

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
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ProvisionDiagnosticsModal"
] = function()
    return { Open = function() end }
end

local Components = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
)
local DebugTab = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_DebugTab"
)
local debugPerson = snapshot.people[1]
debugPerson.provision = { evaluations = {
    food = { onHand = 0.2, target = 0.8, refilling = true },
    hydration = { onHand = 0.7, target = 0.7, refilling = false },
} }
local debugRows = DebugTab.BuildRows(debugPerson, {})
equal(#debugRows, 8, "debug tab need, storage, and provision rows")
equal(debugRows[1].meter, true, "debug tab reuses need meters")
equal(debugRows[7].key, "debug_provision_food",
    "debug tab exposes food provision state")
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
equal(#bound.items, 4, "detail rows are bound to the list")
equal(bound.yScroll, 0, "stale detail scroll is reset")
equal(bound.smoothScrollTargetY, nil, "stale smooth scroll is reset")
equal(bound.items[1].item.label, "STATUS", "bound row remains visible")

local scrollbar = { x = -13, y = 0, width = 13, height = 1 }
function scrollbar:getWidth() return self.width end
function scrollbar:setX(value) self.x = value end
function scrollbar:setY(value) self.y = value end
function scrollbar:setHeight(value) self.height = value end
local resizedList = { width = 420, height = 600, vscroll = scrollbar }
function resizedList:getWidth() return self.width end
function resizedList:getHeight() return self.height end
Components.LayoutScrollbar(resizedList)
equal(scrollbar.x, 407, "scrollbar follows resized container edge")
equal(scrollbar.height, 600, "scrollbar follows resized container height")

print("pnc_colony_management_ui_model_smoke: ok")
