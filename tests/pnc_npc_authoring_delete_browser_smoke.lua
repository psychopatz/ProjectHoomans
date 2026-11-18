local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
local e = F.Class:new(0, 0, 1060, 700, { mode = 'debug', uiScale = 1 })
e:initialise(); e:instantiate()
local browser, deleted = e.itemExplorer, {}
local records = { { id = 'a', label = 'Alpha', search = 'alpha' }, { id = 'b', label = 'Beta', search = 'beta' } }
browser:Show({ mode = 'preset', items = records, reloadItems = function() return records end,
    onDelete = function(item)
        deleted[#deleted + 1] = item.id
        for index, row in ipairs(records) do if row.id == item.id then table.remove(records, index); break end end
        return true
    end })
T.falsy(browser.deleteButton.enabled, 'Delete requires a selected saved record')
browser.tiles[1].onclick(browser, browser.tiles[1]); browser.deleteButton.onclick(browser)
T.equal(#deleted, 0, 'first click only arms confirmation')
browser.search:setText('beta')
T.equal(browser.deleteArmedID, nil, 'filtering away the record cancels its deletion confirmation')
browser.tiles[1].onclick(browser, browser.tiles[1]); browser.deleteButton.onclick(browser)
T.equal(#deleted, 0, 'new selection needs its own confirmation')
browser.deleteButton.onclick(browser)
T.equal(deleted[1], 'b', 'confirmation deletes only the reviewed record')
T.equal(#browser.visibleRows, 0, 'deleted record disappears immediately from current results')
T.falsy(browser.confirm.enabled, 'deleted stale selection cannot be loaded')
browser:Show({ mode = 'outfit', items = records })
T.falsy(browser.deleteButton.visible, 'outfit catalogs do not expose saved-record deletion')
T.finish('pnc_npc_authoring_delete_browser_smoke')
