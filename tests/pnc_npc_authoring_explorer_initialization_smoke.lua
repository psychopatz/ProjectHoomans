local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local Catalog = T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
local browser = ISPNCNPCAuthoringItemExplorer:new(0, 0, 1, 1)
T.equal(browser.options, nil, 'native explorer starts without a browsing session')
browser:onResize() -- Native callbacks may also arrive before child creation.
browser:initialise(); browser:instantiate()
for _, size in ipairs({ { 1, 1 }, { 96, 128 }, { 1060, 620 } }) do
    browser.width, browser.height = size[1], size[2]
    browser:onResize()
    T.equal(browser.options, nil, 'idle resizing never invents browsing options')
end
T.equal(#browser.tiles, 0, 'opening the host does not allocate a hidden page of item tiles')
local editor = F.Class:new(0, 0, 1060, 700, { mode = 'companion', uiScale = 1 })
editor:initialise(); editor:instantiate(); editor:onResponsiveLayout()
T.equal(editor.itemExplorer.options, nil, 'real host layout safely resizes its idle explorer during startup')
T.falsy(editor.itemExplorer.visible, 'idle explorer remains hidden')
local deleted = 0
browser:Show({ mode = 'preset', items = { { id = 'example', label = 'Example', search = 'example' } },
    onDelete = function() deleted = deleted + 1; return true end, reloadItems = function() return {} end })
T.truthy(browser.visible, 'a later explicit Show still opens normally')
T.truthy(browser.confirm.width > 0, 'configured browsing lays out normal actions')
browser.tiles[1].onclick(browser, browser.tiles[1])
browser.deleteButton.onclick(browser); T.equal(deleted, 0, 'initialization repair retains explicit deletion confirmation')
browser.deleteButton.onclick(browser); T.equal(deleted, 1, 'configured delete action still executes once')
browser:Hide(); browser:onResize()
T.falsy(browser.visible, 'resizing a dismissed session does not reopen it')
local passes, previews, items = 0, 0, {}
for index = 1, 60 do
    local source = index <= 50 and 'Base' or 'Mod'
    items[index] = { id = 'item' .. index, label = 'Item ' .. index,
        source = source, category = source == 'Base' and 'Tools' or 'Clothing',
        search = source:lower() .. ' item' .. index }
end
function Catalog.Items()
    passes = passes + 1
    return items
end
browser:Show({ initialID = 'item55', preview = function()
    previews = previews + 1
    return { key = 'selected' }
end })
T.equal(passes, 1, 'opening with an initial selection scans the catalog once')
T.equal(browser.offset, 48, 'initial selection still locates the correct page')
T.equal(browser:currentSelection().id, 'item55')
T.equal(previews, 1, 'initial selection builds a single portrait')
browser.previous.onclick(browser)
T.equal(passes, 1, 'paging reuses the filtered results')
T.equal(previews, 1, 'paging does not generate portraits for unselected rows')
browser.sources.onmousedown(browser, { value = 'Mod' })
T.equal(browser.total, 10, 'source filtering narrows the page')
T.equal(browser.categories.items[2].item.value, 'Clothing', 'categories follow the active source')
T.equal(passes, 1, 'changing source reuses collected matches')
browser.search:setText('base')
T.equal(passes, 2, 'search edits scan once')
T.equal(browser.source, nil, 'search clears unavailable sources')
T.equal(browser.total, 50, 'results use the fallback source immediately')
T.equal(browser.categories.items[2].item.value, 'Tools', 'fallback source restores matching categories')
T.equal(previews, 1, 'search does not request portraits for unselected rows')
browser.refreshButton.onclick(browser)
T.equal(passes, 3, 'manual refresh invalidates previously collected matches')

T.finish('pnc_npc_authoring_explorer_initialization_smoke')
