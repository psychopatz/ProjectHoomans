local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local function copy(v) if type(v) ~= 'table' then return v end; local out = {}; for k, child in pairs(v) do out[k] = copy(child) end; return out end
PNC.NPCAuthoring = { Registry = { Copy = copy } }
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringPortraitView.lua')
local e = F.Class:new(0, 0, 1060, 700, { mode = 'debug', uiScale = 1 })
e:initialise(); e:instantiate()
function e:refreshLoadoutPage() end -- this test isolates framing; slot navigation has its own fixture
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
e.tabPanel:activateView(PNC.Translation.GetKey('UI_PNC_Authoring_Loadout', 'Loadout')); e:syncPageVisibility()
T.equal(e.loadoutPart, nil, 'loadout opens without a selected region')
T.equal(e.portraitPanel:getViewRegion(), 'body', 'loadout opens on the full actor')
e:selectLoadoutPart('head')
T.equal(e.portraitPanel:getViewRegion(), 'head', 'head selection uses the reusable Core camera API')
T.equal(targets[#targets].faceOnly, false, 'loadout head framing keeps the equipped headgear visible')
e:selectLoadoutPart('torso', 'left_arm')
T.equal(e.portraitPanel:getViewRegion(), 'left_arm', 'clicked arm frames the arm while retaining torso slot navigation')
e:selectLoadoutPart('legs')
T.equal(e.portraitPanel:getViewRegion(), 'legs', 'leg selection activates lower-body framing')
e.tabPanel:activateView(e.generalTabName); e:syncPageVisibility()
T.equal(e.portraitPanel:getViewRegion(), 'body', 'leaving loadout restores the default body view')
T.equal(e.portraitPanel.zoom, 1, 'region views preserve the existing body camera preference')
e.tabPanel:activateView(PNC.Translation.GetKey('UI_PNC_Authoring_Loadout', 'Loadout')); e:syncPageVisibility()
e.itemExplorer:setVisible(true)
T.falsy(e.slotContent:onMouseUp(), 'a visible picker retains the current slot focus')
T.equal(e.loadoutPart, 'legs')
e.itemExplorer:setVisible(false)
T.truthy(e.slotContent:onMouseUp(), 'clicking empty grid space clears the selection')
T.equal(e.loadoutPart, nil)
T.equal(e.loadoutViewRegion, nil)
T.equal(e.portraitPanel:getViewRegion(), 'body')
T.equal(e.portraitPanel.zoom, -3, 'deselection restores the default full-body zoom')
e:selectLoadoutPart('torso')
local model = {
    onMouseDown = function(view) view.mouseDown = true; return true end,
    onMouseUp = function(view) view.mouseDown = false; return true end,
}
e.portraitPanel.modelView = model
e:syncPortraitView()
model:onMouseDown(10, 10); model:onMouseUp(60, 10)
T.equal(e.loadoutPart, 'torso', 'dragging to rotate the actor keeps the selected region')
model:onMouseDown(10, 10); model:onMouseUp(10, 10)
T.equal(e.loadoutPart, nil, 'a click on the preview clears the selected region')
local updated = 0
e.appearanceTab.voicePreview = { Update = function() updated = updated + 1 end }
e:update(); T.equal(updated, 1, 'editor update releases completed menu audio')
local now, waves = 1000, 0
getTimeInMillis = function() return now end
ZombRand = function() return 0 end
function e.portraitPanel:playAnimation(id, duration)
    T.equal(id, 'greeting.wavehi')
    T.equal(duration, 2200)
    waves = waves + 1
end
e.tabPanel:activateView(e.appearanceTabName); e:syncPageVisibility()
e.appearanceTab.voicePreview.handle = 1
e:update()
now = 9000
e:update()
T.equal(waves, 0, 'voice playback defers a due wave')
e.appearanceTab.voicePreview.handle = 0
e:update()
T.equal(waves, 1, 'appearance preview waves after the initial idle')
e:update()
T.equal(waves, 1, 'wave cooldown prevents repeated triggers')
e.portraitPanel:setVisible(false)
now = 30000
e:update()
T.equal(waves, 1, 'hidden preview does not wave')
T.equal(e.nextPreviewWaveAt, nil, 'hidden preview drops its pending wave')
local axe = { type = 'Base.Axe' }
instanceof = function(item, class) return item == axe and class == 'HandWeapon' end
WeaponType = { getWeaponType = function() return { getType = function() return '2handed' end } end }
PNC.Equipment = { CreateItem = function() return axe end }
local attacks = {}
function e.portraitPanel:setWeaponPreviewAttacking(value) attacks[#attacks + 1] = value end
e.portraitPanel:setVisible(true)
e.stowedPortraitKey = nil
e.tabPanel:activateView(PNC.Translation.GetKey('UI_PNC_Authoring_Loadout', 'Loadout'))
e:syncPageVisibility()
T.equal(targets[#targets].previewHandItems.primary, axe, 'main Loadout portrait holds its primary weapon')
T.equal(targets[#targets].previewWeaponPose, '2handed', 'primary item determines the native pose')
e:update()
now = now + 700
e:update()
T.equal(attacks[1], true, 'main portrait starts a preview attack')
now = now + 900
e:update()
T.equal(attacks[2], false, 'portrait returns to its weapon-ready pose')
e.width = 1560
e:onResponsiveLayout()
T.truthy(e.portraitPanel.width > 260, 'large editors give the Loadout portrait more width')
T.finish('pnc_npc_authoring_portrait_framing_smoke')
