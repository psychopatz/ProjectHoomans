PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

require "ISUI/ISContextMenu"

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared
local healthTextures = {}

local function currentWorldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and (tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

-- These are the exact suffixes passed to zombie.ui.UI_BodyPart by vanilla's
-- NewHealthPanel. Every damage texture is aligned to the 123x302 base body.
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

local function healthTexture(path)
    if healthTextures[path] == nil then healthTextures[path] = getTexture(path) or false end
    return healthTextures[path] or nil
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

local function drawAlignedTexture(view, texture, x, y, scale, alpha)
    if not texture then return end
    local offsetX = texture.getOffsetX and texture:getOffsetX() or 0
    local offsetY = texture.getOffsetY and texture:getOffsetY() or 0
    local width = textureSize(texture, false)
    local height = textureHeight(texture, false)
    view:drawTextureScaled(texture, x + offsetX * scale, y + offsetY * scale,
        width * scale, height * scale, alpha or 1, 1, 1, 1)
end

local function drawVanillaHealthBody(view, isFemale, x, y, availableWidth, availableHeight, wounds, hpCurrent, hpMax)
    local sex = isFemale and "female" or "male"
    local base = healthTexture("media/ui/BodyDamage/" .. sex .. "_base.png")
    local originalWidth = math.max(1, textureSize(base, true) > 0 and textureSize(base, true) or 123)
    local originalHeight = math.max(1, textureHeight(base, true) > 0 and textureHeight(base, true) or 302)
    local barSpace = 42
    local scale = math.min(availableHeight / originalHeight, availableWidth / (originalWidth + barSpace))
    local bodyWidth = originalWidth * scale
    local bodyHeight = originalHeight * scale
    local drawX = x + math.max(0, (availableWidth - (originalWidth + barSpace) * scale) / 2)
    local partId
    local wound
    local suffix
    local overlay
    local part
    local centerX
    local centerY
    local hitSize = math.max(18, 24 * scale)
    local partOrder = PNC.NPCWounds and PNC.NPCWounds.PartOrder or {}
    local i
    local ratio = Shared.Clamp((tonumber(hpCurrent) or 0) / math.max(1, tonumber(hpMax) or 100), 0, 1)
    local barBack = healthTexture("media/ui/BodyDamage/DamageBar_Vert.png")
    local barFill = healthTexture("media/ui/BodyDamage/DamageBar_Vert_Fill.png")
    local heart = healthTexture("media/ui/Heart_On.png")
    local barX = drawX + bodyWidth + 10 * scale
    local barY = y + scale
    local barWidth = 23 * scale
    local barHeight = 256 * scale

    view.healthHitRegions = {}
    if base then view:drawTextureScaled(base, drawX, y, bodyWidth, bodyHeight, 1, 1, 1, 1) end
    for partId, wound in pairs(wounds or {}) do
        suffix = VANILLA_PART_TEXTURE[partId]
        if suffix then
            -- Vanilla UI_BodyPart renders a clean/dirty bandage first and
            -- skips the wound branch entirely when the part is bandaged.
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
    return { x = drawX, y = y, width = bodyWidth, height = bodyHeight, scale = scale, totalWidth = bodyWidth + barSpace * scale }
end

local function woundLabel(wound)
    local woundType = tostring(wound and wound.type or "wound")
    local keys = {
        scratch = { "IGUI_health_Scratched", "Scratch" },
        laceration = { "IGUI_health_Cut", "Laceration" },
        bite = { "IGUI_health_Bitten", "Bite" },
        bullet = { "IGUI_health_LodgedBullet", "Lodged Bullet" },
        deep_wound = { "IGUI_health_DeepWound", "Deep Wound" },
        fracture = { "IGUI_health_Fracture", "Fracture" },
        burn = { "IGUI_health_Burned", "Burn" },
        glass = { "IGUI_health_LodgedGlassShards", "Lodged Glass Shards" },
    }
    local definition = keys[woundType]
    return definition and Shared.Text(definition[1], definition[2])
        or Shared.Text("UI_PNC_Wound_" .. woundType, woundType)
end

local BODY_PART_TEXT = {
    Hand_L = "IGUI_health_Left_Hand", Hand_R = "IGUI_health_Right_Hand",
    ForeArm_L = "IGUI_health_Left_Forearm", ForeArm_R = "IGUI_health_Right_Forearm",
    UpperArm_L = "IGUI_health_Left_Upper_Arm", UpperArm_R = "IGUI_health_Right_Upper_Arm",
    Torso_Upper = "IGUI_health_Upper_Torso", Torso_Lower = "IGUI_health_Lower_Torso",
    Head = "IGUI_health_Head", Neck = "IGUI_health_Neck", Groin = "IGUI_health_Groin",
    UpperLeg_L = "IGUI_health_Left_Thigh", UpperLeg_R = "IGUI_health_Right_Thigh",
    LowerLeg_L = "IGUI_health_Left_Shin", LowerLeg_R = "IGUI_health_Right_Shin",
    Foot_L = "IGUI_health_Left_Foot", Foot_R = "IGUI_health_Right_Foot",
}

local function overallStatus(current, maximum, incapacitated)
    if incapacitated then return Shared.Text("IGUI_health_Crital_damage", "Critical damage") end
    local ratio = Shared.Clamp((tonumber(current) or 0) / math.max(1, tonumber(maximum) or 100), 0, 1)
    if ratio >= 0.99 then return Shared.Text("IGUI_health_ok", "OK") end
    if ratio >= 0.9 then return Shared.Text("IGUI_health_Very_Minor_damage", "Very Minor damage") end
    if ratio >= 0.8 then return Shared.Text("IGUI_health_Minor_damage", "Minor damage") end
    if ratio >= 0.65 then return Shared.Text("IGUI_health_Moderate_damage", "Moderate damage") end
    if ratio >= 0.45 then return Shared.Text("IGUI_health_Severe_damage", "Severe damage") end
    if ratio >= 0.25 then return Shared.Text("IGUI_health_Very_Severe_damage", "Very Severe damage") end
    return Shared.Text("IGUI_health_Crital_damage", "Critical damage")
end

local function sortedWounds(wounds)
    local rows = {}
    local parts = PNC.NPCWounds and PNC.NPCWounds.Parts or {}
    local order = {}
    local sourceOrder = Shared.BodyParts or {}
    local partId
    local wound
    local i
    for i = 1, #sourceOrder do order[sourceOrder[i].id] = i end
    for partId, wound in pairs(wounds or {}) do
        rows[#rows + 1] = {
            partId = partId,
            label = parts[partId] and parts[partId].label or tostring(partId),
            wound = wound,
        }
    end
    table.sort(rows, function(left, right)
        local leftIndex = order[left.partId] or 999
        local rightIndex = order[right.partId] or 999
        if leftIndex ~= rightIndex then return leftIndex < rightIndex end
        return left.label < right.label
    end)
    return rows
end

function Tabs.RenderHealth(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local payloadHealth = payload and payload.health or {}
    local health = {
        current = resolved.hpCurrent or payloadHealth.current,
        max = resolved.hpMax or payloadHealth.max,
        state = resolved.healthState or payloadHealth.state,
        incapacitatedReason = payloadHealth.incapacitatedReason,
    }
    local body = resolved.bodyHealth or payloadHealth.body or {}
    local wounds = body.wounds or {}
    local rows = sortedWounds(wounds)
    local padding = 12
    local silhouetteWidth = Shared.Clamp(math.floor(view.width * 0.34), 165, 205)
    local silhouetteHeight = math.min(302, math.max(220, view.height - padding * 2 - 24))
    local hpCurrent = tonumber(health.current) or tonumber(body.overallPercent) or 0
    local hpMax = math.max(1, tonumber(health.max) or 100)
    local bodyBounds = drawVanillaHealthBody(
        view, resolved.isFemale == true, padding, padding, silhouetteWidth, silhouetteHeight,
        wounds, hpCurrent, hpMax
    )
    local x = padding + silhouetteWidth + 10
    local width = math.max(150, view.width - x - padding)
    local y = topY
    local state = tostring(health.state or "normal")
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local injuryTint = math.max(0.2, 1 - Shared.Clamp(hpCurrent / hpMax, 0, 1))
    local debugAllowed = PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
    local i

    -- Keep the same hierarchy and color treatment as vanilla ISHealthPanel:
    -- overall body status first, followed by one body-part block per injury.
    view:drawText(Shared.Text("IGUI_health_Overall_Body_Status", "Overall Body Status"), x, y,
        1, 1, 1, 1, UIFont.Small)
    y = y + fontHeight
    view:drawText(overallStatus(hpCurrent, hpMax, state == "incapacitated"), x, y,
        1, 1 - injuryTint, 1 - injuryTint, 1, UIFont.Small)
    y = y + fontHeight
    if debugAllowed then
        local infection = body.infection
        local infected = infection
            and (infection.active == true or infection.fatal == true)
        local infectionText = infected and string.format(
            "DEBUG Knox infection: YES | %s | %.0f%% | %.1f C",
            tostring(infection.stage or "incubating"),
            (tonumber(infection.progress) or 0) * 100,
            tonumber(infection.temperatureC) or 37
        ) or "DEBUG Knox infection: NO"
        view:drawText(infectionText, x, y,
            infected and 1 or 0.45, infected and 0.35 or 0.9, 0.2, 1, UIFont.Small)
        y = y + fontHeight
    end
    y = y + fontHeight

    if #rows > 0 then
        for i = 1, #rows do
            local row = rows[i]
            local wound = row.wound
            local rowTop = y
            local localizedPart = Shared.Text(BODY_PART_TEXT[row.partId], row.label)
            view:drawText(PsychopatzCore.UI.Layout.Ellipsize(localizedPart, UIFont.Small, width),
                x, y, 1, 1, 1, 1, UIFont.Small)
            y = y + fontHeight
            if wound.bandaged == true then
                local bandageLabel = tostring(
                    wound.bandageName or wound.bandageType
                        or Shared.Text("IGUI_health_Bandaged", "Bandaged")
                )
                local prefix = wound.bandageDirty == true
                    and Shared.Text("IGUI_health_DirtyBandage", "Dirty Bandage")
                    or Shared.Text("IGUI_health_Bandaged", "Bandaged")
                view:drawText("- " .. prefix .. " (" .. bandageLabel .. ")", x + 15, y,
                    wound.bandageDirty == true and 0.95 or 0.28,
                    wound.bandageDirty == true and 0.55 or 0.89,
                    0.28, 1, UIFont.Small)
                if debugAllowed then
                    local nowHour = currentWorldHour()
                    local dirtyAt = tonumber(wound.dirtyAtWorldHour) or nowHour
                    local dirtyRemaining = math.max(0, dirtyAt - nowHour)
                    local healed = math.max(0, tonumber(wound.bandageHealedPoints) or 0)
                    local remaining = math.max(
                        0,
                        tonumber(wound.damage) or tonumber(wound.severity) or 0
                    )
                    local initial = math.max(
                        remaining + healed,
                        tonumber(wound.bandageInitialDamage) or 0
                    )
                    local rate = math.max(0, tonumber(wound.healRatePerWorldHour) or 0)
                    y = y + fontHeight
                    view:drawText(
                        wound.bandageDirty == true
                            and "- DEBUG Dirty timer: READY"
                            or string.format(
                                "- DEBUG Dirty in: %.3f world h",
                                dirtyRemaining
                            ),
                        x + 15, y, 0.55, 0.82, 1, 1, UIFont.Small
                    )
                    y = y + fontHeight
                    view:drawText(string.format(
                        "- DEBUG Healed: %.2f / %.2f pts | Remaining: %.2f | Rate: %.2f/h",
                        healed, initial, remaining, rate
                    ), x + 15, y, 0.55, 0.82, 1, 1, UIFont.Small)
                end
            else
                view:drawText("- " .. woundLabel(wound), x + 15, y,
                    0.89, 0.28, 0.28, 1, UIFont.Small)
                y = y + fontHeight
                view:drawText("- " .. Shared.Text("IGUI_health_Bleeding", "Bleeding"), x + 15, y,
                    0.89, 0.28, 0.28, 1, UIFont.Small)
                if body.infection and body.infection.sourcePart == row.partId
                    and (body.infection.active == true or body.infection.fatal == true)
                then
                    y = y + fontHeight
                    view:drawText("- " .. Shared.Text("IGUI_health_Infected", "Infected"), x + 15, y,
                        1, 0.28, 0, 1, UIFont.Small)
                end
            end
            y = y + fontHeight + 5
            view.healthHitRegions[#view.healthHitRegions + 1] = {
                x = x, y = rowTop, width = width, height = y - rowTop,
                partId = row.partId,
            }
        end
    end

    if state == "incapacitated" then
        y = y + 6
        view:drawText("Incapacitated - " .. tostring(health.incapacitatedReason or "critical injury"), x, y, 0.95, 0.36, 0.31, 1, UIFont.Small)
        y = y + fontHeight + 6
        view:drawText("Bandage the wounds; they will stand once sufficiently recovered.",
            x, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 6
    end

    view:drawText(Shared.Text("IGUI_health_RightClickTreatement", "Right click an injury to treat it."),
        padding, padding + bodyBounds.height + 4, 1, 1, 1, 1, UIFont.Small)

    return math.max(y, padding + bodyBounds.height) + 12
end


local function localizedPartName(partId)
    local part = PNC.NPCWounds and PNC.NPCWounds.Parts and PNC.NPCWounds.Parts[partId] or nil
    return Shared.Text(BODY_PART_TEXT[partId], part and part.label or tostring(partId or ""))
end

local function addDebugDamageMenu(context, view, selectedPartId)
    local damageMenu = context:getNew(context)
    local partMenu = context:getNew(context)
    local order = PNC.NPCWounds and PNC.NPCWounds.PartOrder or {}
    local i
    context:addSubMenu(
        context:addOption(Shared.Text("UI_PNC_DebugDamage", "Debug Injury"), nil),
        damageMenu
    )
    damageMenu:addOption(Shared.Text("UI_PNC_DebugDamageRandom", "Random Body Part"), nil, function()
        PNC.Client.SendDebug("damage_part", { id = view.npcId })
    end)
    if selectedPartId and PNC.NPCWounds and PNC.NPCWounds.Parts[selectedPartId] then
        damageMenu:addOption(
            Shared.Text("UI_PNC_DebugDamageSelected", "Injure") .. " " .. localizedPartName(selectedPartId),
            nil,
            function()
                PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = selectedPartId })
            end
        )
    end
    damageMenu:addSubMenu(
        damageMenu:addOption(Shared.Text("UI_PNC_DebugDamageSpecific", "Choose Body Part"), nil),
        partMenu
    )
    for i = 1, #order do
        local damagePartId = order[i]
        partMenu:addOption(localizedPartName(damagePartId), nil, function()
            PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = damagePartId })
        end)
    end
end

local function addDebugInfectionMenu(context, view, selectedPartId, body)
    local infectionMenu = context:getNew(context)
    local infection = body and body.infection or nil
    local infected = infection and (infection.active == true or infection.fatal == true)
    local status = infected and string.format(
        "Status: INFECTED - %s (%.0f%%, %.1f C)",
        tostring(infection.stage or "incubating"),
        (tonumber(infection.progress) or 0) * 100,
        tonumber(infection.temperatureC) or 37
    ) or "Status: NOT INFECTED"
    local statusOption
    context:addSubMenu(
        context:addOption(Shared.Text("UI_PNC_DebugInfection", "Debug Infection"), nil),
        infectionMenu
    )
    statusOption = infectionMenu:addOption(status, nil)
    statusOption.notAvailable = true
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionForce", "Force Infected Bite"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "incubating",
            })
        end
    )
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionFever", "Advance to Fever"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "fever",
            })
        end
    )
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionTerminal", "Advance to Terminal"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "terminal",
            })
        end
    )
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionFatal", "Trigger Infection Death"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "fatal",
            })
        end
    )
    local clearOption = infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionClear", "Clear Knox Infection"),
        nil,
        function()
            PNC.Client.SendDebug("clear_infection", { id = view.npcId })
        end
    )
    clearOption.notAvailable = not infected
end

local function addDebugBandageMenu(context, view, partId, wound)
    local menu
    local statusOption
    local dirtyAt
    local remaining
    if not wound or wound.bandaged ~= true or not partId then return end
    menu = context:getNew(context)
    context:addSubMenu(
        context:addOption(
            Shared.Text("UI_PNC_DebugBandageState", "Debug Bandage State"),
            nil
        ),
        menu
    )
    dirtyAt = tonumber(wound.dirtyAtWorldHour) or currentWorldHour()
    remaining = math.max(0, dirtyAt - currentWorldHour())
    statusOption = menu:addOption(
        wound.bandageDirty == true and "Status: DIRTY"
            or string.format("Status: clean, %.3f world h remaining", remaining),
        nil
    )
    statusOption.notAvailable = true
    local almostDirty = menu:addOption(
        Shared.Text(
            "UI_PNC_DebugBandageAlmostDirty",
            "Make Bandage Almost Dirty"
        ),
        nil,
        function()
            PNC.Client.SendDebug("bandage_almost_dirty", {
                id = view.npcId,
                partId = partId,
            })
        end
    )
    almostDirty.notAvailable = wound.bandageDirty == true
end

local function showHealthMenu(view, partId, x, y)
    local body = Shared.GetSnapshot(view.snapshot, view.payload).bodyHealth
        or view.payload and view.payload.health and view.payload.health.body or {}
    local wound = body and body.wounds and body.wounds[partId] or nil
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local canDebug = PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
    local context
    local bandages
    local option
    local subMenu
    if (not wound
        or (wound.bandaged == true and wound.bandageDirty ~= true)
        or not player) and not canDebug
    then
        return false
    end
    context = ISContextMenu.get(0, x + view:getAbsoluteX(), y + view:getAbsoluteY())
    if wound and (wound.bandaged ~= true or wound.bandageDirty == true) and player then
        bandages = PNC.Treatment and PNC.Treatment.ListBandages and PNC.Treatment.ListBandages(player) or {}
        option = context:addOption(Shared.Text("ContextMenu_Bandage", "Bandage"), nil)
        if #bandages > 0 then
            subMenu = context:getNew(context)
            context:addSubMenu(option, subMenu)
            for _, entry in ipairs(bandages) do
                local bandageType = entry.fullType
                local itemOption = subMenu:addOption(
                    tostring(entry.name) .. " (" .. tostring(entry.count) .. ")",
                    nil,
                    function()
                        PNC.Client.SendBandage(view.npcId, partId, false, bandageType)
                    end
                )
                itemOption.itemForTexture = entry.item
            end
        else
            option.notAvailable = true
        end
        if canDebug then
            context:addOption(Shared.Text("UI_PNC_DebugBandage", "Debug Bandage (No Item)"), nil, function()
                PNC.Client.SendBandage(view.npcId, partId, true)
            end)
        end
    end
    if canDebug then
        addDebugBandageMenu(context, view, partId, wound)
        addDebugDamageMenu(context, view, partId)
        addDebugInfectionMenu(context, view, partId, body)
    end
    return true
end

function Tabs.OnHealthRightMouseUp(view, x, y)
    local regions = view.healthHitRegions or {}
    for i = #regions, 1, -1 do
        local region = regions[i]
        if x >= region.x and x <= region.x + region.width
            and y >= region.y and y <= region.y + region.height
        then
            return showHealthMenu(view, region.partId, x, y)
        end
    end
    return showHealthMenu(view, nil, x, y)
end

return Tabs
