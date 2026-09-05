PNC = PNC or {}
PNC.NameplatePresentation = PNC.NameplatePresentation or {}

local Presentation = PNC.NameplatePresentation
local DisplaySettings = PNC.NameplateDisplaySettings

Presentation.Layout = {
    barWidth = 60,
    barHeight = 6,
    barGap = 6,
    padding = 2,
    maxDrawDistance = 22,
    floorTolerance = 1,
    nameYOffset = 152,
    barYOffset = 130,
    debugTextGap = 14,
    nameDebugGap = 16,
    speechMaxCharsPerLine = 42,
    speechGap = 3,
}

Presentation.Fonts = {
    name = UIFont.Small,
    debug = UIFont.Small,
    speech = UIFont.Medium,
}

Presentation.DefaultSpeechColor = {
    r = 0.82,
    g = 0.96,
    b = 0.94,
    a = 1.0,
}

local NAME_COLORS = {
    hostile = { r = 1.0, g = 0.28, b = 0.28, a = 1.0 },
    controlled = { r = 0.3, g = 1.0, b = 0.3, a = 1.0 },
    neutral = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
}

local HEALTH_COLORS = {
    healthy = { r = 0.1, g = 0.75, b = 0.15, a = 1.0 },
    injured = { r = 0.95, g = 0.8, b = 0.1, a = 1.0 },
    critical = { r = 0.8, g = 0.15, b = 0.15, a = 1.0 },
}

local TREATMENT_COLORS = {
    applying = { r = 0.35, g = 0.95, b = 1.0, a = 1.0 },
    retreat = { r = 1.0, g = 0.72, b = 0.15, a = 1.0 },
    dirty = { r = 1.0, g = 0.55, b = 0.12, a = 1.0 },
    clean = { r = 0.35, g = 0.95, b = 0.35, a = 1.0 },
}
local ACTION_COLOR = { r = 0.35, g = 0.88, b = 1.0, a = 1.0 }

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function copySpeechColor(value, fallback)
    if type(value) ~= "table" then
        return {
            r = fallback.r,
            g = fallback.g,
            b = fallback.b,
            a = fallback.a,
        }
    end
    local red = tonumber(value.r) or fallback.r
    local green = tonumber(value.g) or fallback.g
    local blue = tonumber(value.b) or fallback.b
    local alpha = tonumber(value.a) or fallback.a
    local scale = math.max(red, green, blue) > 1 and (1 / 255) or 1
    if alpha > 1 then alpha = alpha / 255 end
    return {
        r = clamp(red * scale, 0, 1),
        g = clamp(green * scale, 0, 1),
        b = clamp(blue * scale, 0, 1),
        a = clamp(alpha, 0, 1),
    }
end

local function ratio(current, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or 1)
    return clamp((tonumber(current) or 0) / safeMax, 0, 1)
end

function Presentation.Distance(a, b)
    if not a or not b then return 9999 end
    local dx = a:getX() - b:getX()
    local dy = a:getY() - b:getY()
    return math.sqrt((dx * dx) + (dy * dy))
end

function Presentation.HealthRatio(snapshot)
    return ratio(snapshot and snapshot.hpCurrent, snapshot and snapshot.hpMax)
end

function Presentation.StaminaRatio(snapshot)
    return ratio(snapshot and snapshot.staminaCurrent, snapshot and snapshot.staminaMax)
end

function Presentation.NameColor(snapshot)
    if snapshot and snapshot.hostility
        and snapshot.hostility.attackPlayers == true
    then
        return NAME_COLORS.hostile
    end
    if snapshot and (snapshot.colonyOwned == true
        or snapshot.recruited == true)
    then
        return NAME_COLORS.controlled
    end
    return NAME_COLORS.neutral
end

function Presentation.HealthColor(healthRatio)
    if healthRatio >= 0.7 then return HEALTH_COLORS.healthy end
    if healthRatio >= 0.35 then return HEALTH_COLORS.injured end
    return HEALTH_COLORS.critical
end

function Presentation.IncapacitatedColor(currentTime)
    local pulse = (math.sin(currentTime / 140) + 1) * 0.5
    return {
        r = 0.35 + (0.2 * pulse),
        g = 0.03 + (0.04 * pulse),
        b = 0.03 + (0.04 * pulse),
        a = 0.8 + (0.2 * pulse),
    }
end

function Presentation.StaminaColor(staminaRatio)
    local value = 0.28 + (0.72 * clamp(tonumber(staminaRatio) or 0, 0, 1))
    return { r = value, g = value, b = value, a = 1.0 }
end

function Presentation.GetSpeechColor(record)
    local message = record and record.message or record
    local state = type(message and message.presentationState) == "table"
        and message.presentationState or nil
    local source = type(message and message.source) == "table"
        and message.source or nil
    local payload = type(message and message.payload) == "table"
        and message.payload or nil
    local style = type(payload and payload.style) == "table"
        and payload.style or nil
    local candidate = (type(record) == "table" and record.speechColor)
        or (state and (state.speechColor or state.nameplateColor or state.color))
        or (source and (source.speechColor or source.nameplateColor or source.color))
        or (style and (style.speechColor or style.nameplateColor or style.color))
    return copySpeechColor(candidate, Presentation.DefaultSpeechColor)
end

local function treatmentPartLabel(partId)
    local part = PNC.NPCWounds and PNC.NPCWounds.Parts
        and PNC.NPCWounds.Parts[partId] or nil
    return tostring(part and part.label or partId or "Wound")
end

function Presentation.TreatmentStatus(snapshot)
    local state = snapshot and snapshot.treatmentState or nil
    local phase = tostring(state and state.phase or "idle")
    local body = snapshot and snapshot.bodyHealth or nil
    local partId
    local wound
    if phase == "bandaging" then
        return "Bandaging " .. treatmentPartLabel(state.partId)
            .. " - " .. tostring(state.bandageName or state.bandageType or "Ripped Sheets"),
            TREATMENT_COLORS.applying,
            true
    end
    if phase == "retreat" then
        return "Seeking safety to bandage", TREATMENT_COLORS.retreat, true
    end
    for candidateId, candidate in pairs(body and body.wounds or {}) do
        if candidate and candidate.bandaged == true and candidate.bandageDirty == true then
            return "Dirty bandage: " .. treatmentPartLabel(candidateId)
                .. " (" .. tostring(candidate.bandageName or candidate.bandageType or "Ripped Sheets") .. ")",
                TREATMENT_COLORS.dirty,
                false
        end
        if not wound and candidate and candidate.bandaged == true then
            partId = candidateId
            wound = candidate
        end
    end
    if wound then
        return "Bandaged: " .. treatmentPartLabel(partId)
            .. " (" .. tostring(wound.bandageName or wound.bandageType or "Ripped Sheets") .. ")",
            TREATMENT_COLORS.clean,
            false
    end
    return "", TREATMENT_COLORS.clean, false
end

local function facilityName(info)
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get(info.facilityDefinitionId) or nil
    return definition and tr(definition.displayNameKey,
        tostring(info.facilityDefinitionId or "Building"))
        or tr("UI_PNC_Action_BuildingTarget", "Building")
end

local function itemName(fullType, fallback)
    if fullType and getItemNameFromFullType then
        local value = getItemNameFromFullType(fullType)
        if value and value ~= "" then return value end
    end
    if fullType and tostring(fullType) ~= "" then
        local shortType = string.match(tostring(fullType), "([^%.]+)$")
            or tostring(fullType)
        return string.gsub(shortType, "_", " ")
    end
    return fallback
end

local function activityItemName(info)
    local fallback = info.activityItemLabelKey
        and tr(info.activityItemLabelKey, "item") or nil
    return itemName(info.activityItemFullType, fallback)
end

local function recipeTarget(info)
    local resolved = info.recipeId and PNC.RecipeKnowledgeRegistry
        and PNC.RecipeKnowledgeRegistry.Queries
        and PNC.RecipeKnowledgeRegistry.Queries.Resolve(info.recipeId) or nil
    local output = resolved and resolved.descriptor
        and resolved.descriptor.outputs and resolved.descriptor.outputs[1] or nil
    local fullType = output and output.itemTypes and output.itemTypes[1] or nil
    return itemName(fullType, tr("UI_PNC_Action_ItemTarget", "item"))
end

function Presentation.WorkActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    if not info then return "", ACTION_COLOR, false end
    if info.kind == "return_home" then
        return tr("UI_PNC_Action_ReturningHome", "Returning Home")
            .. "  " .. tostring(math.max(0,
                math.min(100, math.floor(tonumber(info.percent) or 0))))
            .. "%", ACTION_COLOR, true
    end
    if info.kind == "at_home" then
        return tr("UI_PNC_Action_Idle", "Idle"), ACTION_COLOR, true
    end
    if info.kind ~= "work_order" then return "", ACTION_COLOR, false end
    local operation = tostring(info.operation or "")
    local verb, target
    if operation == "CONSTRUCT" then
        verb, target = tr("UI_PNC_Action_Building", "Building"), facilityName(info)
    elseif operation == "RECONSTRUCT" then
        verb, target = tr("UI_PNC_Action_Reconstructing", "Reconstructing"),
            facilityName(info)
    elseif operation == "DECONSTRUCT" then
        verb, target = tr("UI_PNC_Action_Deconstructing", "Deconstructing"),
            facilityName(info)
    elseif operation == "BUILD_OBJECT" then
        verb = tr("UI_PNC_Action_Building", "Building")
        target = tostring(info.buildDisplayName or info.objectInfoName
            or tr("UI_PNC_Action_BuildObjectTarget", "object"))
    elseif operation == "CRAFT" then
        verb, target = tr("UI_PNC_Action_Crafting", "Crafting"), recipeTarget(info)
    elseif operation == "DISASSEMBLE" then
        verb = tr("UI_PNC_Action_Disassembling", "Disassembling")
        target = itemName(info.specimenFullType,
            tr("UI_PNC_Action_ItemTarget", "item"))
    elseif operation == "RESEARCH" then
        verb = tr("UI_PNC_Action_Researching", "Researching")
        local definition = PNC.ColonyResearchDefinitions
            and PNC.ColonyResearchDefinitions.Get(info.technologyId) or nil
        target = definition and tr(definition.labelKey,
            tostring(info.technologyId or "technology"))
            or tr("UI_PNC_Action_KnowledgeTarget", "knowledge")
    elseif operation == "PROVISION_PICKUP" then
        verb = tr("UI_PNC_Action_Grabbing", "Grabbing")
        target = itemName(info.activityItemFullType,
            tr("UI_PNC_Action_ProvisionTarget", "provision"))
    else
        verb = tr("UI_PNC_Action_Working", "Working")
        target = tostring(operation)
    end
    local text = verb .. " " .. target
    local status = tostring(info.status or "")
    if status == "TRAVEL_TO_STOCKPILE" then
        if operation == "PROVISION_PICKUP" then
            text = text .. " - "
                .. tr("UI_PNC_Action_Traveling", "traveling")
        else
            text = tr("UI_PNC_Action_CollectingMaterials", "Collecting materials for")
                .. " " .. target
        end
    elseif status == "TRAVEL_TO_STATION" then
        text = text .. " - " .. tr("UI_PNC_Action_Traveling", "traveling")
    elseif status == "BLOCKED" then
        text = text .. " - " .. tr("UI_PNC_Action_Blocked", "blocked")
    elseif info.waitingFor then
        local waiting = tostring(info.waitingFor or "")
        local reason = tostring(info.waitingReason or "")
        if reason ~= "" then
            waiting = waiting .. ":" .. reason
        end
        text = text .. " (" .. string.gsub(waiting, "[_:]", " ") .. ")"
    end
    return text .. "  " .. tostring(math.max(0,
        math.min(100, math.floor(tonumber(info.percent) or 0)))) .. "%",
        ACTION_COLOR, true
end

function Presentation.ActivityActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    if not info or info.kind ~= "activity" then
        return "", ACTION_COLOR, false
    end
    local fallback = tostring(info.fallback or info.activityId or "")
    local text = type(info.labelKey) == "string" and info.labelKey ~= ""
        and tr(info.labelKey, fallback) or fallback
    if info.facilityDefinitionId then
        text = text .. " - " .. facilityName(info)
    end
    local activityItem = activityItemName(info)
    if activityItem and activityItem ~= "" then
        text = text .. " - " .. activityItem
    end
    local phase = string.upper(tostring(info.phase or ""))
    if phase == "TRAVELLING" or phase == "TRAVEL" then
        text = text .. " ("
            .. tr("UI_PNC_Action_Traveling", "traveling") .. ")"
    elseif phase == "QUEUED" or phase == "STARTING" then
        text = text .. " ("
            .. tr("UI_PNC_Action_Preparing", "preparing") .. ")"
    elseif phase == "BLOCKED" then
        text = text .. " ("
            .. tr("UI_PNC_Action_Blocked", "blocked") .. ")"
    elseif info.waitingFor then
        local waiting = tostring(info.waitingFor or "")
        local reason = tostring(info.waitingReason or "")
        if reason ~= "" then
            waiting = waiting .. ":" .. reason
        end
        text = text .. " (" .. string.gsub(waiting, "[_:]", " ") .. ")"
    end
    return text, ACTION_COLOR, text ~= ""
end

function Presentation.ActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    if info and info.kind == "treatment" then
        return Presentation.TreatmentStatus(snapshot)
    end
    local text, color, active = Presentation.ActivityActionStatus(snapshot)
    if text ~= "" then return text, color, active end
    text, color, active = Presentation.WorkActionStatus(snapshot)
    if text ~= "" then return text, color, active end
    return Presentation.TreatmentStatus(snapshot)
end

function Presentation.ShouldShowHealth(snapshot, currentTime)
    if not snapshot then return false end
    if tostring(snapshot.healthState or "") == "incapacitated" then return true end
    if snapshot.inCombat == true then return true end
    return (tonumber(snapshot.recentDamageUntil) or 0) > currentTime
end

function Presentation.ShouldShowStamina(snapshot, currentTime)
    if not snapshot then return false end
    if tostring(snapshot.healthState or "") == "incapacitated" then return true end
    if snapshot.inCombat == true then return true end
    if (tonumber(snapshot.staminaVisibleUntil) or 0) > currentTime then return true end
    return Presentation.StaminaRatio(snapshot) < 0.999
end

function Presentation.ScaleFor(playerIndex)
    local zoom = getCore():getZoom(playerIndex)
    if zoom <= 0 then zoom = 1 end
    local divisor = zoom > 1 and (zoom * 1.15) or 1
    local barScale = DisplaySettings
        and DisplaySettings.GetNameplateBarScale
        and DisplaySettings.GetNameplateBarScale() or 1
    return {
        zoom = zoom,
        barWidth = (Presentation.Layout.barWidth * barScale) / divisor,
        barHeight = (Presentation.Layout.barHeight * barScale) / divisor,
        barGap = (Presentation.Layout.barGap * barScale) / zoom,
        nameYOffset = Presentation.Layout.nameYOffset / zoom,
        barYOffset = Presentation.Layout.barYOffset / zoom,
    }
end

function Presentation.CacheTextMetric(entry, key, text, font)
    local widthKey = key .. "Width"
    local fontKey = key .. "Font"
    if entry[key] ~= text or not entry[widthKey]
        or entry[fontKey] ~= font
    then
        entry[key] = text
        entry[fontKey] = font
        entry[widthKey] = getTextManager():MeasureStringX(font, text)
    end
end

function Presentation.DrawOutlinedText(manager, text, x, y, color, alpha, font)
    local textAlpha
    local red
    local green
    local blue
    if not text or text == "" then return end
    textAlpha = alpha or 1
    red = color and tonumber(color.r) or 1
    green = color and tonumber(color.g) or 1
    blue = color and tonumber(color.b) or 1
    local outlineAlpha = math.min(1, textAlpha * 0.95)
    manager:drawText(text, x - 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x + 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y - 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y + 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y, red, green, blue, textAlpha, font)
end

function Presentation.CreateSpeechTextObject(text, color, maxCharsPerLine)
    if not TextDrawObject or not TextDrawObject.new then return nil end
    text = tostring(text or "")
    if text == "" then return nil end
    text = string.gsub(text, "\r\n?", "\n")
    text = string.gsub(text, "\n", "[br/]")
    color = copySpeechColor(color, Presentation.DefaultSpeechColor)
    local object = TextDrawObject.new(
        255, 255, 255,
        true,   -- allow explicit [br/] line breaks
        false,  -- images
        false,  -- chat icons
        false,  -- inline color tags; the message color is authoritative
        false,  -- inline font tags
        true    -- equalize line heights like player chat
    )
    object:setDefaultColors(color.r, color.g, color.b, 1.0)
    object:setOutlineColors(0, 0, 0, 255)
    object:ReadString(
        Presentation.Fonts.speech or Presentation.Fonts.debug,
        text,
        math.max(1, math.floor(tonumber(maxCharsPerLine)
            or Presentation.Layout.speechMaxCharsPerLine))
    )
    return object
end

return Presentation
