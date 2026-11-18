local T = require "tests/support/test"
local F = require("tests/support/pnc_authoring_ui")()
local count = 0
local items = {}
for i = 1, 260 do
    local n = i
    items[i] = { getFullName = function() return 'Base.Item' .. n end,
        getDisplayName = function() return 'Very long modded display name ' .. n end,
        getObsolete = function() return false end, isHidden = function() return false end,
        getDisplayCategory = function() return 'Tools' end, getModuleName = function() return 'Base' end,
        getNormalTexture = function() return nil end }
end
getAllItems = function() return { size = function() return #items end, get = function(_, n) return items[n + 1] end } end
PNC.Equipment = { NormalizeLoadoutSpec = function(value) return value end,
    CreateItem = function() count = count + 1 end }
PNC.UniqueNPCAppearanceUI.Internal.locations = function() return { 'Hat', 'Pants' } end
PNC.UniqueNPCAppearanceUI.Internal.itemOptions = function() return { { id = 'Base.Item1', label = 'Example' } } end
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
local e = F.Class:new(0, 0, 1000, 620, { mode = 'debug', uiScale = 1 })
e:initialise(); e:instantiate(); e:refreshLoadoutPage()
T.truthy(#e.slotTiles > 0, 'supported equipment is shown as tiles')
T.equal(count, 0, 'equipment overview does not instantiate the catalog')
local explorer = e.itemExplorer
local function inside(c, width, height, message)
    if c.visible then T.truthy(c.x >= 0 and c.y >= 0 and c.x + c.width <= width + 1
        and c.y + c.height <= height + 1, message) end
end
for _, scale in ipairs({ 1, 1.25, 1.5 }) do
    getTextManager = function() return { getFontHeight = function() return math.floor(18 * scale) end } end
    for _, size in ipairs({ { 780, 420 }, { 1060, 620 }, { 1540, 900 } }) do
        e.width, e.height, e.uiScale = size[1], size[2], scale
        e:onResponsiveLayout()
        for _, part in ipairs({ 'head', 'legs', 'carry' }) do
            e.loadoutPart = part; e:onResponsiveLayout()
            for _, action in ipairs(e.loadoutParts) do inside(action, e.pages.loadout.width, e.pages.loadout.contentHeight, 'body-part navigation fits scrollable page') end
            if part == 'carry' then
                inside(e.carriedPanel, e.pages.loadout.width, e.pages.loadout.contentHeight, 'inventory view fits scrollable page')
                inside(e.carriedList, e.carriedPanel.width, e.carriedPanel.height, 'inventory list fits its panel at compact/large-font sizes')
                for _, action in ipairs(e.carriedActions) do inside(action, e.carriedPanel.width, e.carriedPanel.height, 'inventory actions fit their panel') end
            end
        end
        for scope, dice in pairs(e.pageDice) do inside(dice, e.pages[scope].width, e.pages[scope].contentHeight or e.pages[scope].height, 'tab dice stays inside its page') end
        for _, tile in ipairs(e.slotTiles) do
            inside(tile, e.slotContent.width, e.slotContent.contentHeight, 'slot tile stays inside its scroll content')
            inside(tile.clear, e.slotContent.width, e.slotContent.contentHeight, 'clear action stays inside slot content')
        end
        explorer:Show({ title = 'Choose item', onChoose = function() return true end })
        T.falsy(explorer.contextActionButton.visible, 'item browsers never inherit preset-saving controls')
        e:onResponsiveLayout()
        T.falsy(e.tabPanel.visible, 'explorer hides underlying page hit targets')
        T.falsy(e.pageDice.bio.visible, 'tab action cannot change the NPC behind a modal')
        T.falsy(e.roster.visible, 'explorer prevents changing the target behind the picker')
        for _, control in ipairs({ explorer.sources, explorer.categories, explorer.search, explorer.grid,
            explorer.details, explorer.quantity, explorer.destination, explorer.confirm, explorer.closeButton,
            explorer.previous, explorer.nextButton, explorer.counter }) do
            inside(control, explorer.width, explorer.height, 'explorer control stays in viewport')
        end
        for _, tile in ipairs(explorer.tiles) do inside(tile, explorer.grid.width, explorer.grid.contentHeight, 'item tile stays in scroll content') end
        T.equal(explorer.total, 260, 'all modded definitions remain browseable')
        explorer.nextButton.onclick(explorer)
        T.equal(explorer.offset, 48, 'Next advances the page')
        explorer:Hide()
        T.truthy(e.tabPanel.visible, 'dismissal restores editor controls')
        for _, mode in ipairs({ 'carry', 'outfit', 'preset' }) do
            local saves = 0
            explorer:Show({ mode = mode, items = mode ~= 'carry' and { { id = 'one', label = 'Long catalog entry', search = 'long catalog entry' } } or nil,
                contextAction = mode == 'preset' and { title = 'Save roster preset...', onClick = function() saves = saves + 1 end } or nil,
                preview = mode == 'preset' and function(_, index) return { key = 'saved-member:' .. index }, 'Member ' .. index, 2 end or nil,
                onChoose = function() return true end })
            if mode == 'preset' then
                explorer.tiles[1].onclick(explorer, explorer.tiles[1])
                T.equal(explorer.preview.spec.key, 'saved-member:1', 'preset selection targets the side portrait')
                explorer.portraitNext.onclick(explorer)
                T.equal(explorer.preview.spec.key, 'saved-member:2', 'roster next control changes the portrait')
                explorer.portraitPrevious.onclick(explorer)
                T.equal(explorer.preview.spec.key, 'saved-member:1', 'roster previous control returns to the first member')
            end
            for _, control in ipairs({ explorer.heading, explorer.hint, explorer.sources, explorer.categories,
                explorer.grid, explorer.details, explorer.quantity, explorer.quantityLabel, explorer.destination,
                explorer.confirm, explorer.previous, explorer.counter, explorer.nextButton, explorer.contextActionButton,
                explorer.preview, explorer.portraitPrevious, explorer.portraitNext, explorer.portraitCaption }) do
                inside(control, explorer.width, explorer.height, 'contextual browser control fits its viewport')
            end
            if mode == 'preset' then
                T.truthy(explorer.search.y >= explorer.contextActionButton.y + explorer.contextActionButton.height,
                    'preset saving reserves its own row above search')
                explorer.contextActionButton.onclick(explorer)
                T.equal(saves, 1, 'preset action routes only to its configured callback')
                explorer:Show({ mode = 'preset', items = {}, contextAction = { title = 'Save roster preset...', onClick = function() saves = saves + 1 end } })
                explorer.contextActionButton.onclick(explorer)
                T.equal(saves, 2, 'the first roster can be saved from an empty preset browser')
                T.falsy(explorer.preview.visible, 'empty/changed selection hides the old NPC portrait')
                T.falsy(explorer.portraitNext.visible, 'empty selection hides roster navigation')
            end
            explorer:Hide()
        end
        for _, group in ipairs(e.attributeGroups) do
            inside(group.browse, e.pages.attributes.width, e.pages.attributes.contentHeight, 'attribute picker fits its content')
            inside(group.configured, e.pages.attributes.width, e.pages.attributes.contentHeight, 'grouped configured values fit content')
        end
    end
end
T.finish('pnc_npc_authoring_explorer_layout_smoke')
