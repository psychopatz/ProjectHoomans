local Presentation = PNC.NameplatePresentation

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
local RECOVERY_COLOR = { r = 1.0, g = 0.78, b = 0.42, a = 1.0 }

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
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

function Presentation.RecoveryStatus(snapshot)
    local state = snapshot and snapshot.staminaRecovery or nil
    local key
    if not state or state.active ~= true then
        return "", RECOVERY_COLOR, false
    end
    key = state.emoteKey
    if type(key) ~= "string" or key == "" then
        return "", RECOVERY_COLOR, false
    end
    return tr(key, "*Panting*"), RECOVERY_COLOR, true
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
    return "", TREATMENT_COLORS.clean, false
end

