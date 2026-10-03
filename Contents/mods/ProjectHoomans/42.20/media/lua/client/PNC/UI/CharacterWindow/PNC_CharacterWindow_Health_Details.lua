PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}
PNC.CharacterWindowHealth = PNC.CharacterWindowHealth or {}

local Health = PNC.CharacterWindowHealth
local Shared = PNC.CharacterWindowShared
local BODY_PART_TEXT = Health.BodyPartText or {}

local function woundLabel(wound)
    local woundType = tostring(wound and wound.type or "wound")
    local keys = {
        scratch = { "UI_PNC_Wound_scratch", "Scratch" },
        laceration = { "UI_PNC_Wound_laceration", "Laceration" },
        bite = { "UI_PNC_Wound_bite", "Bite" },
        bullet = { "UI_PNC_Wound_bullet", "Lodged Bullet" },
        deep_wound = { "UI_PNC_Wound_deep_wound", "Deep Wound" },
        fracture = { "UI_PNC_Wound_fracture", "Fracture" },
        burn = { "UI_PNC_Wound_burn", "Burn" },
        glass = { "UI_PNC_Wound_glass", "Lodged Glass Shards" },
    }
    local definition = keys[woundType]
    return definition and Shared.Text(definition[1], definition[2])
        or Shared.Text("UI_PNC_Wound_" .. woundType, woundType)
end

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

local function activityPartLabel(partId)
    partId = tostring(partId or "")
    if partId == "" then return nil end
    return Shared.Text(BODY_PART_TEXT[partId], partId)
end

local function renderMedicalActivity(view, x, y, width, fontHeight, snapshot, payload)
    local activity = Shared.GetMedicalActivity and Shared.GetMedicalActivity(snapshot, payload) or nil
    if not activity then return y end
    local detail = activity.label
    local partLabel = activityPartLabel(activity.partId)
    if partLabel then detail = detail .. " | " .. partLabel end
    if activity.source == "medical" and activity.patientId then
        detail = detail .. " | Patient: " .. tostring(activity.patientId)
    elseif activity.bandageName then
        detail = detail .. " | Bandage: " .. tostring(activity.bandageName)
    end
    if activity.progress ~= nil then detail = detail .. string.format(" | Progress: %.0f%%", activity.progress * 100) end
    if activity.blockedReason then
        detail = detail .. " | Blocked: " .. tostring(activity.blockedReason)
    elseif activity.interruptedReason then
        detail = detail .. " | Interrupted: " .. tostring(activity.interruptedReason)
    end
    if view.drawRect then view:drawRect(x, y, width, fontHeight * 2 + 8, 0.78, 0.08, 0.16, 0.20) end
    view:drawText(Shared.Text("UI_PNC_Medical_Activity", "Medical Activity"), x + 6, y + 3, 0.45, 0.85, 1, 1, UIFont.Small)
    view:drawText(detail, x + 6, y + 3 + fontHeight, 1, 1, 1, 1, UIFont.Small)
    return y + fontHeight * 2 + 12
end

local function needLevel(needType, value)
    local definitions = PNC.NeedsDefinitions
    if definitions and definitions.GetLevel then return definitions.GetLevel(needType, value) end
    value = tonumber(value) or 0
    if value >= 0.84 then return "CRITICAL" end
    if value >= 0.70 then return "SEVERE" end
    if value >= 0.45 then return "MODERATE" end
    if value >= 0.25 then return "MINOR" end
    return "NORMAL"
end

local function renderWholeBodyAilmentDetails(view, x, y, width, fontHeight, needs, ailments)
    local rows = {}
    local definitions = PNC.NeedsDefinitions or {}
    local order = definitions.WHOLE_BODY_AILMENT_ORDER or {}
    local byID = definitions.WHOLE_BODY_AILMENTS or {}
    local rendered = {}
    local function addRow(ailmentID, ailment, definition)
        local severity = tonumber(ailment and ailment.severity) or 0
        local flavorOnly = definition and (definition.displayMode == "flavor" or definition.flavorOnly == true)
        local needValue = definition and definition.needType and tonumber(needs and needs[definition.needType]) or nil
        local label = Shared.Text(definition and definition.labelKey or "UI_PNC_Health_Whole_Body_Ailment", definition and (definition.label or definition.id) or ailmentID)
        local cause = definition and definition.cause and Shared.Text(definition.causeKey, definition.cause) or nil
        local status
        local detail
        local color
        if flavorOnly then
            if ailment.active ~= true then return end
            detail = label .. (cause and " - " .. cause or "")
            rows[#rows + 1] = { detail = detail, color = { r = 1, g = 0.68, b = 0.24 } }
            rendered[ailmentID] = true
            return
        end
        if severity <= 0 then return end
        if severity >= 1 then
            status = Shared.Text("UI_PNC_Health_Ailment_Damaging", "DAMAGE ACTIVE")
            color = { r = 1, g = 0.28, b = 0.20 }
        elseif definition and definition.severityProgression == "building" then
            status = Shared.Text("UI_PNC_Health_Ailment_Building", "BUILDING")
            color = { r = 1, g = 0.68, b = 0.24 }
        elseif needValue ~= nil and needValue >= 1 then
            status = Shared.Text("UI_PNC_Health_Ailment_Building", "BUILDING")
            color = { r = 1, g = 0.68, b = 0.24 }
        else
            status = Shared.Text("UI_PNC_Health_Ailment_Recovering", "RECOVERING")
            color = { r = 0.35, g = 0.88, b = 0.45 }
        end
        detail = string.format("%s: %.0f%%", label, severity * 100)
        if cause and needValue ~= nil then detail = detail .. string.format(" | %s: %.0f%% (%s)", cause, needValue * 100, tostring(needLevel(definition.needType, needValue))) end
        rows[#rows + 1] = { detail = detail .. " - " .. status, color = color }
        rendered[ailmentID] = true
    end
    local i
    local ailmentID
    local ailment
    for i = 1, #order do
        ailmentID = order[i]
        ailment = ailments and ailments[ailmentID]
        if ailment then addRow(ailmentID, ailment, byID[ailmentID]) end
    end
    for ailmentID, ailment in pairs(ailments or {}) do
        if not rendered[ailmentID] then addRow(ailmentID, ailment, byID[ailmentID]) end
    end
    if #rows == 0 then return y end
    view:drawText(Shared.Text("UI_PNC_Health_Whole_Body", "Whole Body"), x, y, 1, 1, 1, 1, UIFont.Small)
    y = y + fontHeight
    for i = 1, #rows do
        local row = rows[i]
        view:drawText("- " .. row.detail, x + 15, y, row.color.r, row.color.g, row.color.b, 1, UIFont.Small)
        y = y + fontHeight
    end
    view.healthHitRegions[#view.healthHitRegions + 1] = {
        x = x, y = y - fontHeight * (#rows + 1), width = width,
        height = fontHeight * (#rows + 1), partId = "WholeBody",
    }
    return y
end

local function sortedWounds(wounds)
    local rows = {}
    local parts = PNC.NPCWounds and PNC.NPCWounds.Parts or {}
    local order = {}
    local sourceOrder = Shared.BodyParts or {}
    local i
    for i = 1, #sourceOrder do order[sourceOrder[i].id] = i end
    for partId, wound in pairs(wounds or {}) do
        rows[#rows + 1] = { partId = partId, label = parts[partId] and parts[partId].label or tostring(partId), wound = wound }
    end
    table.sort(rows, function(left, right)
        local leftIndex = order[left.partId] or 999
        local rightIndex = order[right.partId] or 999
        if leftIndex ~= rightIndex then return leftIndex < rightIndex end
        return left.label < right.label
    end)
    return rows
end

local function renderWoundRows(view, x, y, width, fontHeight, rows, body, debugAllowed)
    local i
    for i = 1, #rows do
        local row = rows[i]
        local wound = row.wound
        local rowTop = y
        local localizedPart = Shared.Text(BODY_PART_TEXT[row.partId], row.label)
        view:drawText(PsychopatzCore.UI.Layout.Ellipsize(localizedPart, UIFont.Small, width), x, y, 1, 1, 1, 1, UIFont.Small)
        y = y + fontHeight
        if wound.bandaged == true then
            local bandageLabel = tostring(wound.bandageName or wound.bandageType or Shared.Text("IGUI_health_Bandaged", "Bandaged"))
            local prefix = wound.bandageDirty == true and Shared.Text("IGUI_health_DirtyBandage", "Dirty Bandage") or Shared.Text("IGUI_health_Bandaged", "Bandaged")
            view:drawText("- " .. prefix .. " (" .. bandageLabel .. ")", x + 15, y, wound.bandageDirty == true and 0.95 or 0.28, wound.bandageDirty == true and 0.55 or 0.89, 0.28, 1, UIFont.Small)
            if debugAllowed then
                local nowHour = Health.CurrentWorldHour()
                local dirtyAt = tonumber(wound.dirtyAtWorldHour) or nowHour
                local dirtyRemaining = math.max(0, dirtyAt - nowHour)
                local healed = math.max(0, tonumber(wound.bandageHealedPoints) or 0)
                local remaining = math.max(0, tonumber(wound.damage) or tonumber(wound.severity) or 0)
                local initial = math.max(remaining + healed, tonumber(wound.bandageInitialDamage) or 0)
                local rate = math.max(0, tonumber(wound.healRatePerWorldHour) or 0)
                y = y + fontHeight
                view:drawText(wound.bandageDirty == true and "- DEBUG Dirty timer: READY" or string.format("- DEBUG Dirty in: %.3f world h", dirtyRemaining), x + 15, y, 0.55, 0.82, 1, 1, UIFont.Small)
                y = y + fontHeight
                view:drawText(string.format("- DEBUG Healed: %.2f / %.2f pts | Remaining: %.2f | Rate: %.2f/h", healed, initial, remaining, rate), x + 15, y, 0.55, 0.82, 1, UIFont.Small)
            end
        else
            view:drawText("- " .. woundLabel(wound), x + 15, y, 0.89, 0.28, 0.28, 1, UIFont.Small)
            y = y + fontHeight
            view:drawText("- " .. Shared.Text("IGUI_health_Bleeding", "Bleeding"), x + 15, y, 0.89, 0.28, 0.28, 1, UIFont.Small)
            if body.infection and body.infection.sourcePart == row.partId and (body.infection.active == true or body.infection.fatal == true) then
                y = y + fontHeight
                view:drawText("- " .. Shared.Text("IGUI_health_Infected", "Infected"), x + 15, y, 1, 0.28, 0, 1, UIFont.Small)
            end
        end
        y = y + fontHeight + 5
        view.healthHitRegions[#view.healthHitRegions + 1] = { x = x, y = rowTop, width = width, height = y - rowTop, partId = row.partId }
    end
    return y
end

Health.OverallStatus = overallStatus
Health.RenderMedicalActivity = renderMedicalActivity
Health.RenderAilments = renderWholeBodyAilmentDetails
Health.SortWounds = sortedWounds
Health.RenderWounds = renderWoundRows

return Health
