local F = require('tests/support/pnc_authoring_ui')()
local T = require 'tests/support/test'
local D = require 'PNC/Core/Definitions/PNC_DefinitionDatabase'
local administrator = false
PNC.LocalNPCCollection = { CanPublish = function() return not isClient or not isClient() or administrator end }
package.loaded['PNC/Core/Definitions/PNC_LocalNPCCollection'] = PNC.LocalNPCCollection
local function control(y)
    return { y = y, width = 60, setY = function(self, value) self.y = value end,
        setX = function(self, value) self.x = value end,
        setWidth = function(self, value) self.width = value end,
        setTitle = function(self, value) self.title = value end }
end
getTextManager = function() return { getFontHeight = function() return 18 end,
    MeasureStringX = function(_, _, text) return #text * 8 end } end
ISTextBox = { new = function(_, _, _, width, height, title, name, target, onclick)
    local popup = { width = width, height = height, title = title, target = target, onclick = onclick, yes = control(80), no = control(80) }
    popup.entry = { text = name, getText = function(self) return self.text end, focus = function() end }
    function popup:initialise() end
    function popup:addChild(child) self.child = child end
    function popup:setHeight(value) self.height = value end
    function popup:addToUIManager() end
    function popup:bringToTop() end
    function popup:setValidateFunction(target, method) self.validateTarget, self.validate = target, method end
    function popup:setValidateTooltipText(text) self.validateTooltip = text end
    function popup:showErrorMessage(value, message) self.showError, self.errorMsg = value, message end
    return popup
end }
ISTickBox = { new = function()
    -- Native ISTickBox has disableOption(name, disabled), not setEnable.
    return { disabledOptions = {}, initialise = function() end, instantiate = function() end,
        addOption = function(self, name) self.option = name end,
        setSelected = function(self, _, value) self.selected = value end,
        isSelected = function(self) return self.selected end,
        disableOption = function(self, name, value) self.disabledOptions[name] = value end }
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
T.falsy(popup.library.disabledOptions[popup.library.option], 'SP encounter checkbox remains usable')
T.equal(popup.yes.title, 'Save preset', 'confirmation states what is being saved')
T.truthy(popup.yes.width >= #popup.yes.title * 8 + 24, 'save label fits its native button')
T.falsy(popup.validate(owner, '!!!'), 'invalid filename cannot enable confirmation')
popup.entry.text = '!!!'; popup.onclick(owner, { internal = 'OK' })
T.truthy(popup.showError, 'invalid name keeps native dialog open for correction')
T.equal(saved, 0, 'invalid filename never writes a preset')
popup.onclick(owner, { internal = 'CANCEL' })
T.equal(saved, 0, 'Cancel does not save anything')
T.falsy(popup.showError, 'Cancel can dismiss even after a validation error')
popup.entry.text = 'My Custom NPC'; popup.onclick(owner, { internal = 'OK' })
T.equal(saved, 1, 'chosen name and encounter scope reach the actual save callback')
T.falsy(popup.showError, 'corrected filename clears the dialog error')
isClient = function() return true end
local remote = Dialog.Open(owner, 'Friend', true, function() error('not saving') end)
T.truthy(remote.library.disabledOptions[remote.library.option], 'native option disabled for non-admin MP')
T.falsy(remote.library.selected, 'MP publication is never silently enabled')
local submitted
local gated = Dialog.Open(owner, 'Friend', true, function(_, _, library) submitted = library end)
gated.library.selected = true; gated.onclick(owner, { internal = 'OK' })
T.equal(submitted, false, 'submission rechecks publication authority even for a stale selection')
administrator = true
local admin = Dialog.Open(owner, 'Friend', true, function(_, _, library) submitted = library end)
T.falsy(admin.library.disabledOptions[admin.library.option], 'MP administrator may choose encounter publication')
admin.onclick(owner, { internal = 'OK' })
T.truthy(submitted, 'MP administrator can submit encounter publication')
administrator = false
admin.onclick(owner, { internal = 'OK' })
T.equal(submitted, false, 'revoked administrator rights cannot submit a stale checked option')
isClient = function() return false end
local roster = Dialog.Open(owner, 'Starting companions', nil, function(_, _, library)
    T.equal(library, false, 'roster save has no encounter-publication scope')
end, { title = 'Save roster preset...', help = 'All companions together' })
T.equal(roster.title, 'Save roster preset...', 'roster dialog names its scope')
T.equal(roster.entry.tooltip, 'All companions together', 'scope explanation reaches the filename field')
T.falsy(roster.library, 'roster does not offer an NPC-only encounter checkbox')
roster.onclick(owner, { internal = 'OK' })
T.finish('pnc_npc_authoring_save_dialog_smoke')
