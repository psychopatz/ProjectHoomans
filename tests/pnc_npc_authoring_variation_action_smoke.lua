local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Actions.lua')
local e = F.Class:new(0, 0, 1060, 620, { mode = 'companion', uiScale = 1 })
function e:syncControls() end -- Form synchronization is covered separately.
e:initialise(); e:instantiate()
local varied, refreshed = 0, 0
local allowed = true
e.presentationAdapter = { VaryLook = function() varied = varied + 1; return true end }
function e:pullForm() return allowed end
function e:refreshFromAdapter(force) T.truthy(force, 'variation refreshes the resulting visual'); refreshed = refreshed + 1 end
T.falsy(PNC.NPCAuthoringFields.CanRandomize(e), 'random selector policies remain disabled in companion creation')
T.truthy(e.variationButton.visible, 'a distinct quick variation action is visible')
e.variationButton.onclick(e, e.variationButton)
T.equal(varied, 1, 'the real wide button routes to the companion appearance transaction')
T.equal(refreshed, 1, 'successful variation refreshes exactly once')
allowed = false
e.variationButton.onclick(e, e.variationButton)
T.equal(varied, 1, 'invalid pending form cannot mutate appearance')
T.finish('pnc_npc_authoring_variation_action_smoke')
