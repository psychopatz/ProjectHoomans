local T = require "tests/support/test"
T.addPackagePaths()

local Transfer = T.load("PsychopatzCore", "server",
    "PsychopatzCore/Inventory/PsychopatzItemTransfer.lua")
local equipmentPath = "PNC/Core/Equipment/PNC_Equipment_Slots/"
T.load("ProjectHoomans", "shared", equipmentPath .. "VisualCapture.lua")
T.load("ProjectHoomans", "shared", equipmentPath .. "VisualNormalization.lua")
local Equipment = PNC.Equipment

Color = { new = function(r, g, b) return { r = r, g = g, b = b } end }
ImmutableColor = { new = function(r, g, b)
    return {
        getRedFloat = function() return r end,
        getGreenFloat = function() return g end,
        getBlueFloat = function() return b end,
    }
end }

local shirtType = "Mod.PrintedShirt"
local function item(fullType)
    local visual = { hue = 0.2, textureChoice = -1 }
    function visual:getBaseTexture() return self.baseTexture end
    function visual:setBaseTexture(value) self.baseTexture = value end
    function visual:getTextureChoice() return self.textureChoice end
    function visual:setTextureChoice(value) self.textureChoice = value end
    function visual:getHue() return self.hue end
    function visual:setHue(value) self.hue = value end
    function visual:getDecal() return self.decal end
    function visual:setDecal(value) self.decal = value end
    function visual:setTint(value) self.tint = value end
    local native = { color = Color.new(1, 1, 1), visual = visual, custom = false }
    function native:getFullType() return fullType end
    function native:getClothingItem() return {} end
    function native:getVisual() return visual end
    function native:setColorRed(value) self.colorRed = value end
    function native:getColorRed() return self.colorRed end
    function native:setCustomColor(value) self.custom = value end
    function native:isCustomColor() return self.custom end
    function native:setColor(value) self.color = value end
    function native:getR() return self.color.r end
    function native:getG() return self.color.g end
    function native:getB() return self.color.b end
    function visual:getTint(clothing)
        if clothing and native.custom then
            return ImmutableColor.new(native:getR(), native:getG(), native:getB())
        end
        return self.tint
    end
    return native
end

local authoringItem = { type = shirtType, itemState = { condition = 7 } }
T.truthy(Equipment.StoreVisualStateInItemState(authoringItem, {
    fullType = shirtType, baseTexture = 0, textureChoice = 2,
    hue = -0.4, decal = "ModDecal", customColor = true,
    tint = { r = 0.8, g = 0.7, b = 0.6 }, color = { r = 0.1, g = 0.2, b = 0.3 },
}))
T.equal(authoringItem.itemState.condition, 7, "encoding preserves unrelated item state")
local target = item(shirtType)
Transfer.ApplyState(target, authoringItem.itemState)
T.equal(target.visual.baseTexture, 0, "zero-based asset index is preserved")
T.equal(target.visual.textureChoice, 2)
T.equal(target.visual.hue, -0.4)
T.equal(target.visual.decal, "ModDecal")
T.equal(target.visual.tint:getGreenFloat(), 0.7)
T.equal(target:getG(), 0.2, "engine color matches authoring RGB")
local captured = Transfer.CaptureState(target)
local state = Equipment.VisualStateFromItemState(captured, shirtType)
T.equal(Equipment.Internal.VisualStateSignature(state),
    Equipment.Internal.VisualStateSignature(Equipment.CaptureItemVisualState(target, shirtType)),
    "transfer and authoring capture the same selected variant")
T.equal(state.hue, -0.4, "selected hue survives transfer capture")
T.equal(state.tint.g, 0.7, "transfer preserves tint separately from rendered RGB")

local legacy = item(shirtType)
legacy.custom = true
Transfer.ApplyState(legacy, { visualTextureChoice = "0", visualColorR = 0.4, visualCustomColor = false })
T.equal(legacy.visual.textureChoice, 0, "legacy string index is accepted")
T.equal(legacy.visual.hue, 0.2, "legacy record keeps the native hue")
T.equal(legacy.colorRed, 0.4, "legacy sparse color is applied")
T.falsy(legacy.custom, "an explicit false clears custom color")
T.equal(Transfer.CaptureState(legacy).visualCustomColor, false,
    "portable state preserves an explicit false")
local different = item("Mod.OtherShirt")
Transfer.ApplyState(different, authoringItem.itemState)
T.equal(different.visual.hue, 0.2, "a variant cannot recolor a different full type")
legacy.visual.hue = math.huge
T.equal(Transfer.CaptureState(legacy).visualHue, nil, "uninitialized hue is omitted")
T.finish("pnc_item_visual_roundtrip_smoke")
