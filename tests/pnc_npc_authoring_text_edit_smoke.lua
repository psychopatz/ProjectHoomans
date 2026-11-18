local T = require "tests/support/test"
local F = require("tests/support/pnc_authoring_ui")()
local Fields, commits, previews = PNC.NPCAuthoringFields, 0, 0
local editor = { textEdits = {}, syncing = false }
function editor:fieldCapability() return { editable = true, visible = true } end
function editor:pullForm() commits = commits + 1; self.textEdits = {}; return true end
function editor:refreshPreview() previews = previews + 1 end
local entry = F.Base:new(0, 0, 200, 28)
Fields.BindText(editor, entry, 'identity.forename')
editor.syncing = true
entry:setText('Robin')
editor.syncing = false
entry:focus()
entry.caret = 2
local function insert(text, deleteCount)
    local caret = entry.caret
    entry.text = string.sub(entry.text, 1, caret - (deleteCount or 0)) .. text .. string.sub(entry.text, caret + 1)
    entry.caret = caret - (deleteCount or 0) + #text
    entry:onTextChange()
end
insert(' X')
T.equal(entry:getText(), 'Ro Xbin', 'middle insertion and a space remain in native edit buffer')
local cursor = entry.caret
Fields.SyncText(editor, entry, 'Robin')
T.equal(entry:getText(), 'Ro Xbin', 'resolved state cannot overwrite pending text')
T.equal(entry.caret, cursor, 'caret stays where the user left it')
T.truthy(entry.focused, 'synchronization does not remove focus')
insert('', 1)
insert('Pasted name')
T.equal(commits, 0, 'typing/backspace/paste never runs the full form pipeline')
entry:onCommandEntered()
T.equal(commits, 1, 'Enter commits once')
entry:unfocus()
T.equal(commits, 1, 'focus loss after Enter does not recommit')
entry:focus(); entry.caret = #entry.text; insert(' End')
entry:unfocus()
T.equal(commits, 2, 'focus loss commits a later edit once')
T.equal(previews, 2, 'preview updates at commit boundaries only')
entry:focus(); entry.caret = 0; insert('Start ')
T.equal(commits, 2, 'first-character edits remain buffered')
editor.textEdits = {}
local old = entry.caret
Fields.SyncText(editor, entry, entry:getText())
T.equal(entry.caret, old, 'unchanged synchronization never calls SetText and moves caret')
local parent = F.Base:new(0, 0, 300, 200)
function editor:fieldCapability() return { editable = false, visible = true,
    sourceLabel = 'Inherited from Player', rule = 'relationship.family_appearance' } end
Fields.Lock(editor, entry, 'appearance.skinTexture', parent)
T.falsy(entry.editable, 'derived data stays in a non-editable input')
T.truthy(entry.pncLock.visible, 'derived data exposes a lock')
T.truthy(#entry.pncLock.tooltip > 0, 'disabled control has a separate hover reason')
local gender = Fields.Gender(editor, parent)
Fields.Lock(editor, gender, 'identity.isFemale', parent)
local changed = 0
function editor:onComboChanged() changed = changed + 1 end
gender.buttons[2].onclick(gender)
T.equal(changed, 0, 'locked gender cannot toggle even through the callback boundary')
F.UI.StyleButton = function(button, variant)
    button.psychopatzVariant = variant
    button.backgroundColor = { g = variant == 'selected' and .34 or .10 }
end
gender:setEnabled(true)
gender:selectData(true)
T.equal(gender.buttons[2].psychopatzVariant, 'selected', 'selected gender belongs to theme state')
gender:setEnabled(true)
T.equal(gender.buttons[2].backgroundColor.g, .34, 'enabling cannot erase selected gender color')
for _, b in ipairs(gender.buttons) do F.UI.StyleButton(b, b.psychopatzVariant) end
T.equal(gender.buttons[2].backgroundColor.g, .34, 'theme refresh retains selection')
gender:setEnabled(false)
T.equal(gender.buttons[2].psychopatzVariant, 'selected', 'locked selected value remains identifiable')
gender:setEnabled(true); gender.buttons[1].onclick(gender)
T.equal(gender.selected, 1, 'unlocked friend-style gender toggles to male')
T.equal(gender.buttons[1].psychopatzVariant, 'selected', 'new selection is highlighted')
function editor:fieldCapability() return { editable = false, visible = true, source = 'generated' } end
Fields.Lock(editor, entry, 'appearance.skinTexture', parent)
T.equal(entry.pncLocked, false, 'generic unavailable data has no trait-constraint padlock')
T.falsy(entry.pncLock.visible, 'lock icon is hidden without a real constraint')
function editor:fieldCapability() return { editable = false, visible = true, constraint = true, explanation = 'Father requires a male companion.' } end
Fields.Lock(editor, gender, 'identity.isFemale', parent)
T.equal(gender.pncLock.tooltip, 'Father requires a male companion.', 'constraint tooltip uses the current relationship explanation')
function editor:fieldCapability() return { editable = true, visible = true, constraint = false } end
Fields.Lock(editor, gender, 'identity.isFemale', parent)
T.falsy(gender.pncLock.visible, 'switching to an unconstrained type removes the lock')
T.truthy(gender.enabled, 'the unconstrained control is editable again')
T.finish('pnc_npc_authoring_text_edit_smoke')
