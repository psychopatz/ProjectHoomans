local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local function copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}; for key, item in pairs(value) do out[key] = copy(item) end; return out
end
string.trim = string.trim or function(value) return string.match(value, '^%s*(.-)%s*$') end
PNC.NPCAuthoring = { Registry = { Copy = copy } }
PNC.NPCAuthoringEditorProfile.Label = function(id) return id end
local I = F.Class.Internal
I.appearanceOptions, I.beardOptions = function() return {} end, function() return {} end
F.Model.NameParts = function(draft) return draft.identity.survivor.forename, draft.identity.survivor.surname end
F.Model.BuildBlueprint = function(draft)
    if draft.identity.survivor.forename == 'invalid' then return nil, 'invalid_name' end
    return {}
end
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Actions.lua')
local e = F.Class:new(0, 0, 1000, 620, { mode = 'debug', uiScale = 1 })
function e:syncControls() end -- Populate once, then exercise production sync below.
e:initialise(); e:instantiate()
e.syncControls = nil
function e:refreshConfiguredDetails() end
function e:refreshLoadoutPage() end
function e:requestResponsiveLayout() end
function e:setStatus(reason) self.statusText = reason end
local previews = 0
function e:refreshPreview() previews = previews + 1 end
e.draft.identity.survivor = { forename = 'Robin', surname = 'Tester' }
e.draft.displayName = 'Robin Tester'
e:syncControls()
e.forenameEntry:setText('Riley ')
T.equal(e.draft.identity.survivor.forename, 'Robin', 'typing does not replace accepted draft')
e:syncControls()
T.equal(e.forenameEntry:getText(), 'Riley ', 'production full-form synchronization preserves the pending buffer')
e.forenameEntry:onCommandEntered()
T.equal(e.draft.identity.survivor.forename, 'Riley', 'commit validates and normalizes the field')
T.equal(previews, 1, 'accepted text produces one preview update')
local accepted = e.draft
e.forenameEntry:setText('invalid')
e.forenameEntry:onCommandEntered()
T.equal(e.draft, accepted, 'rejected candidate leaves accepted draft object untouched')
T.equal(e.statusText, 'invalid_name', 'rejection reason is surfaced')
T.equal(e.forenameEntry:getText(), 'invalid', 'rejected text remains editable')
T.equal(previews, 1, 'invalid candidate cannot reach preview update')
e.forenameEntry:setText('Recovered')
e.forenameEntry:onCommandEntered()
T.equal(e.draft.identity.survivor.forename, 'Recovered', 'correcting invalid text recovers normally')
T.equal(previews, 2, 'recovery performs one accepted preview update')
e.presentationMode = 'companion'
e.presentationAdapter = {}
e.commitAdapterDraft = function() return false end
e.draft.identity.survivor.hairModel = nil
e.draft.identity.survivor.beardModel = nil
e.draft.authoringClears = {}
local synced = 0
function e.appearanceTab:refreshGenderOptions() synced = synced + 1 end
e:syncControls()
T.truthy(synced > 0, 'production synchronization also refreshes the visible appearance controls')
e:pullForm()
T.falsy(e.draft.authoringClears['appearance.hairModel'], 'unrelated companion commit cannot clear generated hair')
T.falsy(e.draft.authoringClears['appearance.beardModel'], 'unrelated companion commit cannot clear generated beard')
T.finish('pnc_npc_authoring_form_commit_smoke')
