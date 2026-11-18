local F = require('tests/support/pnc_authoring_ui')()
local T = require 'tests/support/test'
local D = require 'PNC/Core/Definitions/PNC_DefinitionDatabase'
PNC.LocalNPCCollection = { CanPublish = function() return not isClient or not isClient() end }
package.loaded['PNC/Core/Definitions/PNC_LocalNPCCollection'] = PNC.LocalNPCCollection
local function control(y) return { y = y, setY = function(self, value) self.y = value end } end
ISTextBox = { new = function(_, _, _, width, height, title, name, target, onclick)
    local popup = { width = width, height = height, title = title, target = target, onclick = onclick, yes = control(80), no = control(80) }
    popup.entry = { text = name, getText = function(self) return self.text end, focus = function() end }
    function popup:initialise() end
    function popup:addChild(child) self.child = child end
    function popup:setHeight(value) self.height = value end
    function popup:addToUIManager() end
    function popup:bringToTop() end
    return popup
end }
ISTickBox = { new = function()
    return { initialise = function() end, instantiate = function() end, addOption = function() end,
        setSelected = function(self, _, value) self.selected = value end,
        isSelected = function(self) return self.selected end,
        setEnable = function(self, value) self.enabled = value end }
end }
package.loaded['ISUI/ISTextBox'], package.loaded['ISUI/ISTickBox'] = ISTextBox, ISTickBox
local Dialog = require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringSaveDialog'
local owner = { setStatus = function(self, value) self.status = value end }
local saved = 0
local popup = Dialog.Open(owner, 'Bertram Henry', true, function(label, filename, library)
    saved = saved + 1; T.equal(label, 'My Custom NPC'); T.equal(filename, 'My_Custom_NPC.txt'); T.truthy(library)
end)
T.equal(popup.entry.text, 'Bertram Henry', 'NPC name is the editable default')
T.truthy(popup.library.selected, 'singleplayer encounter export is offered by default')
popup.onclick(owner, { internal = 'CANCEL' })
T.equal(saved, 0, 'Cancel does not save anything')
popup.entry.text = 'My Custom NPC'; popup.onclick(owner, { internal = 'OK' })
T.equal(saved, 1, 'chosen name and encounter scope reach the actual save callback')
isClient = function() return true end
local remote = Dialog.Open(owner, 'Friend', true, function() error('not saving') end)
T.falsy(remote.library.enabled, 'non-admin MP character creation cannot publish encounters')
T.falsy(remote.library.selected, 'MP publication is never silently enabled')
T.finish('pnc_npc_authoring_save_dialog_smoke')
