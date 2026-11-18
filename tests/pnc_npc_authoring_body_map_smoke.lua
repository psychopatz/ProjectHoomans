local F = require('tests/support/pnc_authoring_ui')()
local T = require 'tests/support/test'
local textures = {}
getTexture = function(path)
    local shape = { x = 50, y = 50, w = 20, h = 20 }
    if string.find(path, 'head$', 1) then shape = { x = 50, y = 5, w = 22, h = 25 }
    elseif string.find(path, 'neck$', 1) then shape = { x = 54, y = 32, w = 14, h = 12 }
    elseif string.find(path, 'chest$', 1) then shape = { x = 35, y = 40, w = 50, h = 75 }
    elseif string.find(path, 'abdomen$', 1) then shape = { x = 40, y = 95, w = 40, h = 45 }
    elseif string.find(path, 'groin$', 1) then shape = { x = 44, y = 120, w = 30, h = 25 } end
    local t = { path = path, getOffsetX = function() return shape.x end, getOffsetY = function() return shape.y end,
        getWidth = function() return shape.w end, getHeight = function() return shape.h end }
    textures[path] = t
    return t
end
local Map = require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringBodyMap'
local selected
local map = Map:new(0, 0, 246, 604, function(id) selected = id end)
map:initialise(); map:instantiate()
map:SetState(false, { head = { equipped = 0 }, neck = { equipped = 1 }, torso = { equipped = 2 }, waist = { equipped = 1 } }, 'torso')
map:onMouseDown(120, 30)
T.equal(selected, 'head', 'scaled head selection uses native trimmed texture bounds')
map:onMouseDown(120, 70)
T.equal(selected, 'neck', 'neck has its own clickable region')
map:onMouseDown(120, 250)
T.equal(selected, 'waist', 'native groin z-order wins over overlapping abdomen')
T.falsy(map:Hit(-1, -1), 'outside body map never changes a loadout region')
local drawn = {}
function map:drawTextureScaledUniform(texture, _, _, _, alpha, r, g, b) drawn[texture.path] = { alpha, r, g, b } end
map:render()
local green = drawn['media/ui/BodyParts/bps_male_neck']
T.truthy(green[3] > green[2] and green[3] > green[4], 'equipped region is green')
local empty = drawn['media/ui/BodyParts/bps_male_head']
T.truthy(empty[3] < .7, 'empty region does not claim to have equipment')
map:SetState(true, map.counts, 'head')
T.truthy(textures['media/ui/BodyParts/bps_female_head'], 'changing NPC gender rebinds native female silhouette')
map.width, map.height = 80, 400
local x, y, scale = map:Projection()
T.near(scale, 80 / 123, .0001, 'compact width preserves native aspect ratio')
map:onMouseDown(x + 60 * scale, y + 15 * scale)
T.equal(selected, 'head', 'letterboxed/scaled silhouette retains correct hit coordinates')
T.finish('pnc_npc_authoring_body_map_smoke')
