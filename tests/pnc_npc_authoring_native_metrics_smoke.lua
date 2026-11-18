local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
-- Native ISComboBox stores constructor height in baseHeight; its renderer uses
-- that value for the arrow even when the panel height changes afterward.
local original = ISComboBox
ISComboBox = { new = function(_, x, y, w, h)
    local combo = original:new(x, y, w, h)
    combo.baseHeight = h
    return combo
end }
local parent = F.Base:new(0, 0, 1, 1)
local combo = F.Class.Internal.newCombo(parent)
T.truthy(combo.baseHeight >= 24, 'shared combo starts with a native usable base height')
for _, height in ipairs({ 28, 37, 48 }) do
    F.UI.Layout.SetBounds(combo, 20, 30, 230, height)
    PNC.NPCAuthoringFields.NativeMetrics(parent)
    T.equal(combo.baseHeight, height, 'native arrow follows the resized input height')
    T.equal((combo.baseHeight - 8) / 2, (combo.height - 8) / 2, 'arrow is centered in current control bounds')
end
local label = F.Base:new(0, 0, 1, 1)
label.originalX = 0
function label:setName(name) self.name = name; self.x = self.originalX end
parent:addChild(label)
F.UI.Layout.SetBounds(label, 240, 12, 200, 28)
PNC.NPCAuthoringFields.NativeMetrics(parent)
label:setName('Updated caption')
T.equal(label.x, 240, 'native setName cannot restore a stale original label position')
local stepper = PNC.NPCAuthoringFields.Level(parent)
for n = 0, 10 do stepper:addOptionWithData(tostring(n), n) end
stepper:selectData(10)
stepper.buttons[2].onclick(stepper)
T.equal(stepper.options[stepper.selected].data, 10, 'skill level cannot exceed 10')
stepper:selectData(0)
stepper.buttons[1].onclick(stepper)
T.equal(stepper.options[stepper.selected].data, 0, 'skill level cannot go below 0')
T.finish('pnc_npc_authoring_native_metrics_smoke')
