local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Actions.lua')
local e = F.Class:new(0, 0, 1060, 620, { mode = 'companion', uiScale = 1 })
function e:syncControls() end -- Form synchronization is covered separately.
function e:setStatus(value) self.statusText = value end
e:initialise(); e:instantiate()
local varied, refreshed = 0, 0
local allowed, generationAllowed = true, true
e.presentationAdapter = { RandomizeTab = function(_, scope) e.lastScope = scope; varied = varied + 1; return generationAllowed end }
function e:pullForm() return allowed end
function e:refreshFromAdapter(force) T.equal(force, false, 'scoped variation preserves unaffected preview state'); refreshed = refreshed + 1 end
T.falsy(PNC.NPCAuthoringFields.CanRandomize(e), 'random selector policies remain disabled in companion creation')
for _, scope in ipairs({ 'bio', 'appearance', 'attributes', 'loadout' }) do
    T.truthy(e.pageDice[scope].visible, 'a dice action is visible on each editable tab')
    e.pageDice[scope].onclick(e, e.pageDice[scope])
    T.equal(e.lastScope, scope, 'the real dice callback identifies its tab scope')
end
T.equal(varied, 4, 'all four editable tab actions use the companion transaction')
T.equal(refreshed, 4, 'successful scoped actions refresh exactly once')
T.falsy(e.pageDice.relations.enabled, 'relationship/backstory dice is a visible disabled TODO')
allowed = false
e.pageDice.appearance.onclick(e, e.pageDice.appearance)
T.equal(varied, 4, 'invalid pending form cannot mutate appearance')
e.textEdits = { firstName = 'Uncommitted name' }
generationAllowed = false
T.falsy(e:randomizeTab('bio'), 'rejected name generation reports failure')
T.equal(e.textEdits.firstName, 'Uncommitted name', 'rejected generation preserves the pending name buffer')
generationAllowed = true
T.truthy(e:randomizeTab('bio'), 'successful name generation can replace pending names')
T.equal(e.textEdits.firstName, nil, 'successful name generation releases the replaced buffer')
T.finish('pnc_npc_authoring_variation_action_smoke')
