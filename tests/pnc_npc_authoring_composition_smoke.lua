local T = require "tests/support/test"
local F = require("tests/support/pnc_authoring_ui")()
local Class = F.Class
for _, mode in ipairs({ "companion", "debug" }) do
    local e = Class:new(0, 0, 1000, 620, { mode = mode, uiScale = 1 })
    e:initialise(); e:instantiate()
    T.equal(#e.tabPanel.viewList, 5, "both hosts use the same five pages")
    T.equal(e.forenameEntry.parent, e.pages.bio, "identity belongs to Bio")
    T.equal(e.skillCombo.parent, e.pages.attributes, "skills belong to Attributes")
    T.equal(e.details.parent, e.pages.relations, "inspector belongs to Details")
    T.equal(e.equipmentModeCombo.parent, e.pages.loadout, "generation policy belongs to Loadout")
    T.falsy(e.appearanceTab.outfitCombo.visible, "outfit combo is not exposed in the shared editor")
    T.equal(e.slotContent.parent, e.pages.loadout, "loadout uses an equipment tile viewport")
    T.equal(e.itemExplorer.parent, e, "both callers share a dedicated item explorer")
    T.truthy(e.equipmentModeCombo.buttons, "equipment policy uses segmented buttons")
    T.truthy(e.genderCombo.buttons, "gender uses icon buttons")
    e:setRoster({ { id = "brother", label = "Phil" }, { id = "sister", label = "Fran" } }, "brother", function(id) e.chosen = id end)
    function e:pullForm() self.flushed = true end
    e.roster.onmousedown(e, e.roster.items[2].item)
    T.truthy(e.flushed, "selection flushes the focused form")
    T.equal(e.chosen, "sister", "roster callback identifies the selected NPC")
    e:onResponsiveLayout()
    T.truthy(e.slotContent.y + e.slotContent.height <= e.pages.loadout.contentHeight, "slots fit in bounded scroll content")
    T.truthy(e.pages.loadout.contentHeight >= e.pages.loadout.height, "long page has a bounded scroll viewport")
end
T.finish("pnc_npc_authoring_composition_smoke")
