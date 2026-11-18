local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local nativeCalls = 0
PNC.Equipment = { CreateItem = function() nativeCalls = nativeCalls + 1 end }
local items = {}
for i = 1, 523 do
    local id, label = "Mod" .. (i % 2) .. ".Item" .. i, string.format("Item %04d", i)
    items[i] = { getFullName = function() return id end, getDisplayName = function() return label end,
        getObsolete = function() return i == 1 end, isHidden = function() return i == 2 end,
        getModuleName = function() return "Mod" .. (i % 2) end,
        getDisplayCategory = function() return i % 2 == 0 and "Tools" or "Clothing" end }
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
rows = Catalog.Query({ allowed = { ["Mod1.Item501"] = true }, compatibleOnly = true })
T.equal(#rows, 1, "slot compatibility filters results")
T.equal(nativeCalls, 0, "discovery/paging never creates native items")
items = {}
Catalog.Invalidate()
T.equal(#Catalog.Items(), 0, "explicit invalidation discovers removed scripts")
T.finish("pnc_npc_authoring_catalog_smoke")
