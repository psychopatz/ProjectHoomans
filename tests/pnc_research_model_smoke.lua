local T = require "tests/support/test"

local translations = { HQ2 = "Headquarters II", GROUP_HQ = "COLONY UPGRADES",
    GROUP_UTILITIES = "UTILITIES" }
getText = function(key) return translations[key] or key end
PNC = {}

local Model = T.load("ProjectHoomans", "client",
    "PNC/UI/Research/PNC_ResearchModel.lua")

local snapshot = {
    settlement = {
        facilities = {{ definitionId = "research_facility",
            constructionState = "BUILT", components = {
                { role = "work.research" },
            } }},
    },
    research = {
        entries = {
            { id = "hq:2", category = "settlement", labelKey = "HQ2",
                groupId = "colony_upgrades", groupOrder = 10, itemOrder = 20,
                groupTitleKey = "GROUP_HQ", requiredWork = 80 },
            { id = "storage:2", category = "storage", labelKey = "STORAGE2",
                groupId = "utilities", groupOrder = 20, itemOrder = 2,
                groupTitleKey = "GROUP_UTILITIES", requiredWork = 65,
                known = true },
            { id = "hq:3", category = "settlement", labelKey = "HQ3",
                groupId = "colony_upgrades", groupOrder = 10, itemOrder = 30,
                groupTitleKey = "GROUP_HQ", prerequisiteTechnology = "hq:2",
                prerequisiteKnown = false, requiredWork = 140 },
        },
        candidates = {
            { mode = "blueprint", recipeId = 7, displayName = "Spear",
                recordIndex = 3, quantity = 1, known = false },
            { mode = "book", bookFullType = "Base.BookCooking",
                displayName = "Cooking", recordIndex = 4, quantity = 2,
                known = false },
        },
        orders = {{ id = "work:1", operation = "RESEARCH", status = "WORKING",
            progress = 20, requiredWork = 80, workerId = "npc:1",
            payload = { mode = "technology", technologyId = "hq:2" } }},
    },
}

local view = Model.Build(snapshot)
T.equal(#view.groups, 4, "research groups should be hierarchical")
T.equal(view.groups[1].id, "colony_upgrades", "group ordering")
T.equal(view.groups[1].items[1].status, "active", "active status")
T.equal(view.groups[1].items[1].progress, 25, "active progress")
T.equal(view.groups[2].id, "utilities", "utilities grouping")
T.equal(view.groups[2].knownCount, 1, "known count")
T.equal(view.groups[3].id, "blueprints", "blueprint source grouping")
T.equal(view.groups[4].id, "books", "book source grouping")
T.equal(view.activeQueue[1].name, "Headquarters II", "queue target name")
T.equal(view.selectedKey, "technology:hq:2", "active item selection")

local collapsed = Model.Build(snapshot, {
    collapsedGroups = { utilities = true },
    selectedKey = "technology:hq:2",
})
T.truthy(collapsed.groups[2].collapsed, "collapse state")

local filtered = Model.Build(snapshot, { filter = "blueprint" })
T.equal(#filtered.groups, 1, "source filter group count")
T.equal(filtered.groups[1].id, "blueprints", "source filter group")
T.truthy(filtered.groups[1].items[1].researchable,
    "blueprint should be researchable with a research table")

local unavailable = Model.Build({ research = {
    entries = snapshot.research.entries,
    candidates = snapshot.research.candidates,
    orders = {},
} })
T.equal(unavailable.groups[1].items[1].status, "unavailable",
    "missing table status")
T.falsy(unavailable.groups[1].items[1].researchable,
    "missing table should block action")

T.finish("pnc_research_model_smoke")
