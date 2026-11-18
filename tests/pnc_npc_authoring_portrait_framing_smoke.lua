local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local function copy(v) if type(v) ~= 'table' then return v end; local out = {}; for k, child in pairs(v) do out[k] = copy(child) end; return out end
PNC.NPCAuthoring = { Registry = { Copy = copy } }
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringPortraitView.lua')
local e = F.Class:new(0, 0, 1060, 700, { mode = 'debug', uiScale = 1 })
e:initialise(); e:instantiate()
local targets = {}
function e.portraitPanel:setTarget(_, spec) targets[#targets + 1] = spec; return true end
e.portraitSourceSpec = { key = 'stable-look', appearance = { hairModel = 'Long', outfitItems = { 'Base.Hat' } }, equipment = { primaryFullType = 'Base.Axe' } }
e:syncPageVisibility()
T.equal(e.portraitMode, 'body', 'Bio starts with full body framing')
T.equal(e.portraitPanel.zoom, -3)
e.portraitPanel.zoom = 1
e.tabPanel:activateView(e.appearanceTabName); e:syncPageVisibility()
T.equal(e.portraitMode, 'face', 'Appearance activates face framing')
T.equal(e.portraitPanel.zoom, 14)
T.equal(e.portraitPanel.yOffset, -.85)
T.truthy(targets[#targets].faceOnly, 'descriptor projection is face-specific')
T.equal(#targets[#targets].appearance.outfitItems, 0, 'headgear does not obscure hair editing')
T.equal(e.portraitSourceSpec.appearance.outfitItems[1], 'Base.Hat', 'framing does not mutate NPC clothing')
e.tabPanel:activateView(e.generalTabName); e:syncPageVisibility()
T.equal(e.portraitMode, 'body', 'leaving Appearance restores full body')
T.equal(e.portraitPanel.zoom, 1, 'body zoom preference survives the face view')
T.equal(targets[#targets].equipment.primaryFullType, 'Base.Axe', 'body equipment reappears')
local updated = 0
e.appearanceTab.voicePreview = { Update = function() updated = updated + 1 end }
e:update(); T.equal(updated, 1, 'editor update releases completed menu audio')
T.finish('pnc_npc_authoring_portrait_framing_smoke')
