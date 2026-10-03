PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}
PNC.CharacterWindowHealth = PNC.CharacterWindowHealth or {}

local Health = PNC.CharacterWindowHealth
local Shared = PNC.CharacterWindowShared
local Debug = require "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health_Debug"
local healthTextures = {}

local VANILLA_PART_TEXTURE = {
    Hand_L = "hand_left.png", Hand_R = "hand_right.png",
    ForeArm_L = "lowerarm_left.png", ForeArm_R = "lowerarm_right.png",
    UpperArm_L = "upperarm_left.png", UpperArm_R = "upperarm_right.png",
    Torso_Upper = "chest.png", Torso_Lower = "abdomen.png",
    Head = "head.png", Neck = "neck.png", Groin = "groin.png",
    UpperLeg_L = "upperleg_left.png", UpperLeg_R = "upperleg_right.png",
    LowerLeg_L = "lowerleg_left.png", LowerLeg_R = "lowerleg_right.png",
    Foot_L = "foot_left.png", Foot_R = "foot_right.png",
}

local BODY_PART_TEXT = {
    Hand_L = "UI_PNC_Character_BodyPart_LeftHand", Hand_R = "UI_PNC_Character_BodyPart_RightHand",
    ForeArm_L = "UI_PNC_Character_BodyPart_LeftForearm", ForeArm_R = "UI_PNC_Character_BodyPart_RightForearm",
    UpperArm_L = "UI_PNC_Character_BodyPart_LeftUpperArm", UpperArm_R = "UI_PNC_Character_BodyPart_RightUpperArm",
    Torso_Upper = "UI_PNC_Character_BodyPart_UpperTorso", Torso_Lower = "UI_PNC_Character_BodyPart_LowerTorso",
    Head = "UI_PNC_Character_BodyPart_Head", Neck = "UI_PNC_Character_BodyPart_Neck", Groin = "UI_PNC_Character_BodyPart_Groin",
    UpperLeg_L = "UI_PNC_Character_BodyPart_LeftThigh", UpperLeg_R = "UI_PNC_Character_BodyPart_RightThigh",
    LowerLeg_L = "UI_PNC_Character_BodyPart_LeftShin", LowerLeg_R = "UI_PNC_Character_BodyPart_RightShin",
    Foot_L = "UI_PNC_Character_BodyPart_LeftFoot", Foot_R = "UI_PNC_Character_BodyPart_RightFoot",
}

local function currentWorldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and (tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

local function textureSize(texture, original)
    if not texture then return 0 end
    if original and texture.getWidthOrig then return texture:getWidthOrig() end
    return texture.getWidth and texture:getWidth() or 0
end

local function textureHeight(texture, original)
    if not texture then return 0 end
    if original and texture.getHeightOrig then return texture:getHeightOrig() end
    return texture.getHeight and texture:getHeight() or 0
end

local function healthTexture(path)
    if healthTextures[path] == nil then healthTextures[path] = getTexture(path) or false end
    return healthTextures[path] or nil
end

local function drawAlignedTexture(view, texture, x, y, scale, alpha)
    if not texture then return end
    local offsetX = texture.getOffsetX and texture:getOffsetX() or 0
    local offsetY = texture.getOffsetY and texture:getOffsetY() or 0
    local width = textureSize(texture, false)
    local height = textureHeight(texture, false)
    view:drawTextureScaled(texture, x + offsetX * scale, y + offsetY * scale,
        width * scale, height * scale, alpha or 1, 1, 1, 1)
end

local function drawVanillaHealthBody(view, isFemale, x, y, availableWidth,
    availableHeight, wounds, hpCurrent, hpMax)
    local sex = isFemale and "female" or "male"
    local base = healthTexture("media/ui/BodyDamage/" .. sex .. "_base.png")
    local originalWidth = math.max(1, textureSize(base, true) > 0 and textureSize(base, true) or 123)
    local originalHeight = math.max(1, textureHeight(base, true) > 0 and textureHeight(base, true) or 302)
    local barSpace = 42
    local scale = math.min(availableHeight / originalHeight, availableWidth / (originalWidth + barSpace))
    local bodyWidth = originalWidth * scale
    local bodyHeight = originalHeight * scale
    local drawX = x + math.max(0, (availableWidth - (originalWidth + barSpace) * scale) / 2)
    local hitSize = math.max(18, 24 * scale)
    local partOrder = PNC.NPCWounds and PNC.NPCWounds.PartOrder or {}
    local ratio = Shared.Clamp((tonumber(hpCurrent) or 0) / math.max(1, tonumber(hpMax) or 100), 0, 1)
    local barBack = healthTexture("media/ui/BodyDamage/DamageBar_Vert.png")
    local barFill = healthTexture("media/ui/BodyDamage/DamageBar_Vert_Fill.png")
    local heart = healthTexture("media/ui/Heart_On.png")
    local barX = drawX + bodyWidth + 10 * scale
    local barY = y + scale
    local barWidth = 23 * scale
    local barHeight = 256 * scale
    local i
    local partId
    local suffix
    local wound
    local overlay
    local part
    local centerX
    local centerY

    view.healthHitRegions = {}
    if base then view:drawTextureScaled(base, drawX, y, bodyWidth, bodyHeight, 1, 1, 1, 1) end
    for partId, wound in pairs(wounds or {}) do
        suffix = VANILLA_PART_TEXTURE[partId]
        if suffix then
            if wound.bandaged == true then
                overlay = healthTexture("media/ui/BodyDamage/" .. sex .. "_bandage_" .. suffix)
            elseif wound.type == "bite" then
                overlay = healthTexture("media/ui/BodyDamage/" .. sex .. "_bite_" .. suffix)
            else
                overlay = healthTexture("media/ui/BodyDamage/" .. sex .. "_scratch_" .. suffix)
            end
            drawAlignedTexture(view, overlay, drawX, y, scale, 1)
        end
    end
    for i = 1, #partOrder do
        partId = partOrder[i]
        part = PNC.NPCWounds.Parts[partId]
        if part then
            centerX = drawX + bodyWidth * part.x
            centerY = y + bodyHeight * part.y
            view.healthHitRegions[#view.healthHitRegions + 1] = {
                x = centerX - hitSize / 2, y = centerY - hitSize / 2,
                width = hitSize, height = hitSize, partId = tostring(partId),
            }
        end
    end
    if barBack then view:drawTextureScaled(barBack, barX, barY, barWidth, barHeight, 1, 1, 1, 1) end
    if barFill and ratio > 0 then
        view:drawTextureScaled(barFill, barX, barY + barHeight * (1 - ratio),
            barWidth, barHeight * ratio, 1, 1, 1, 1)
    end
    if heart then
        local heartWidth = textureSize(heart, true) * scale
        local heartHeight = textureHeight(heart, true) * scale
        view:drawTextureScaled(heart, barX - math.max(0, (heartWidth - barWidth) / 2),
            y + bodyHeight - heartHeight, heartWidth, heartHeight, 1, 1, 1, 1)
    end
    return { x = drawX, y = y, width = bodyWidth, height = bodyHeight,
        scale = scale, totalWidth = bodyWidth + barSpace * scale }
end

Health.BodyPartText = BODY_PART_TEXT
Health.CurrentWorldHour = currentWorldHour
Health.DrawBody = drawVanillaHealthBody
Debug.SetBodyPartText(BODY_PART_TEXT)

return Health
