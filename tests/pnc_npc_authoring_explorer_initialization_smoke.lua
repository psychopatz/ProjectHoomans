local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
local browser = ISPNCNPCAuthoringItemExplorer:new(0, 0, 1, 1)
T.equal(browser.options, nil, 'native explorer starts without a browsing session')
browser:onResize() -- Native callbacks may also arrive before child creation.
browser:initialise(); browser:instantiate()
for _, size in ipairs({ { 1, 1 }, { 96, 128 }, { 1060, 620 } }) do
    browser.width, browser.height = size[1], size[2]
    browser:onResize()
    T.equal(browser.options, nil, 'idle resizing never invents browsing options')
end
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
T.finish('pnc_npc_authoring_explorer_initialization_smoke')
