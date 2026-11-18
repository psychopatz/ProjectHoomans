local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local nativeCalls = 0
ItemType = { WEAPON = {}, NORMAL = {} }
PNC.Equipment = { CreateItem = function() nativeCalls = nativeCalls + 1 end }
local items = {}
for i = 1, 523 do
    local id, label = "Mod" .. (i % 2) .. ".Item" .. i, string.format("Item %04d", i)
    items[i] = { getFullName = function() return id end, getDisplayName = function() return label end,
        getObsolete = function() return i == 1 end, isHidden = function() return i == 2 end,
        getModuleName = function() return "Mod" .. (i % 2) end,
        getDisplayCategory = function() return i % 2 == 0 and "Tools" or "Clothing" end,
        getItemType = function() return i == 501 and ItemType.WEAPON or ItemType.NORMAL end }
end
getAllItems = function() return { size = function() return #items end, get = function(_, n) return items[n + 1] end } end
local Catalog = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog"
T.equal(#Catalog.Items(), 521, "obsolete/hidden entries are excluded while mod scripts are discovered")
local seen = {}
for offset = 0, 520, 48 do
    local rows, total = Catalog.Query({ offset = offset, limit = 48 })
    T.equal(total, 521, "paging retains total")
    for _, row in ipairs(rows) do T.falsy(seen[row.id], "pages do not duplicate items"); seen[row.id] = true end
end
local count = 0
for _ in pairs(seen) do count = count + 1 end
T.equal(count, 521, "all results beyond 200 remain reachable")
local rows = Catalog.Query({ source = "Mod0", category = "Tools", query = "Item 0500" })
T.equal(#rows, 1, "module/category/search intersect")
T.equal(rows[1].id, "Mod0.Item500", "intersection returns expected mod item")
rows = Catalog.Query({ allowed = { ["Mod1.Item501"] = true } })
T.equal(#rows, 1, "slot compatibility filters results")
T.equal(nativeCalls, 0, "discovery/paging never creates native items")
local weapons = Catalog.Weapons()
T.truthy(weapons['Mod1.Item501'], 'mod weapons are discovered by native script type')
T.falsy(weapons['Mod0.Item500'], 'nonweapon tools are not mislabeled as weapons')
T.equal(nativeCalls, 0, 'weapon discovery never instantiates the item catalog')
local sources, categories = Catalog.Filters({ ["Mod1.Item501"] = true }, "", nil)
T.equal(#sources, 1, "source filters only contain compatible matches")
T.equal(categories[1], "Clothing", "only populated compatible categories appear")
T.equal(#categories, 1, "empty compatible categories are omitted")
local _, searchedCategories = Catalog.Filters(nil, "Item 0500", "Mod0")
T.equal(searchedCategories[1], "Tools", "search and source narrow available categories")

local function hiddenVisual(id, location, category)
    return {
        getFullName = function() return id end,
        getDisplayName = function() return id end,
        getObsolete = function() return false end,
        isHidden = function() return true end,
        getBodyLocation = function() return location end,
        getDisplayCategory = function() return category end,
    }
end
local makeup = hiddenVisual("Base.MakeUp_CamoFullFace1", "base:makeup_fullface", "Appearance")
local injury = hiddenVisual("Base.Wound_Chest_Scratch_Male", "base:wound", "Wound")
local zombieDamage = hiddenVisual("Base.ZedDmg", "base:zeddmg", "Appearance")
items = { makeup, injury, zombieDamage }
PNC.UniqueNPCAppearanceUI = { Internal = { itemOptions = function(location)
    if location == "base:wound" then return { { id = injury:getFullName() } } end
    return { { id = makeup:getFullName() } }
end } }
Catalog.Invalidate()
T.equal(#Catalog.Query(), 0, "hidden overlays stay out of ordinary item browsing")
T.equal(#Catalog.Clothing("base:makeup_fullface"), 1, "makeup is available in its native slot")
T.equal(#Catalog.Clothing("base:wound", false), 1, "male wound overlay is selectable")
T.equal(#Catalog.Clothing("base:wound", true), 0, "male wound overlay is hidden for female bodies")
T.equal(#Catalog.Clothing("base:zeddmg"), 0, "native zombie damage is excluded from the editor")
T.equal(#Catalog.Query({ allowed = { [makeup:getFullName()] = true } }), 1, "slot browser can show hidden makeup")
ScriptManager = { instance = { FindItem = function() return makeup end } }
PNC.Equipment.CreateItem = function(id) nativeCalls = nativeCalls + 1; return { id = id } end
T.falsy(Catalog.Create(makeup:getFullName()), "hidden makeup cannot be added through the carried-item picker")
T.falsy(Catalog.Create(makeup:getFullName(), "base:wound"), "hidden makeup cannot be added to an unrelated slot")
T.truthy(Catalog.Create(makeup:getFullName(), "base:makeup_fullface"), "hidden makeup can be constructed for its native slot")

items = {
    hiddenVisual("Base.YardstickDEBUG", nil, "Hidden"),
    hiddenVisual("Base.FISH_DEV_ITEM", nil, "Fishing"),
    hiddenVisual("Base.BareHands", nil, "Weapon"),
    hiddenVisual("Mod.DebugFallback", nil, "Hidden"),
}
for _, entry in ipairs(items) do entry.isHidden = function() return false end end
Catalog.Invalidate()
T.equal(#Catalog.Query(), 0, "debug items are blocked even when native metadata marks them visible")
items = {}
Catalog.Invalidate()
T.equal(#Catalog.Items(), 0, "explicit invalidation discovers removed scripts")
T.finish("pnc_npc_authoring_catalog_smoke")
