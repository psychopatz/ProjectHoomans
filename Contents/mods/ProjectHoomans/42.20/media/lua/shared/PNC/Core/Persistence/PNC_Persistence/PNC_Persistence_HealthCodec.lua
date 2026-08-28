PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.compactPartValue(partHealth)
    local maximum = math.max(1, Internal.normalizeNumber(partHealth and partHealth.max, 100))
    local current = Core.Clamp(Internal.normalizeNumber(
        partHealth and partHealth.current,
        maximum
    ), 0, maximum)
    if maximum == 100 then return current end
    return { current = current, max = maximum }
end

function Internal.partSignature(partHealth)
    local maximum = math.max(1, Internal.normalizeNumber(partHealth and partHealth.max, 100))
    local current = Core.Clamp(Internal.normalizeNumber(
        partHealth and partHealth.current,
        maximum
    ), 0, maximum)
    return tostring(current) .. ":" .. tostring(maximum)
end

function Internal.buildCompactHealthBody(rawBody)
    local normalized = Internal.sanitizeHealthBody(rawBody)
    local output = {}
    local counts = {}
    local values = {}
    local bestSignature
    local bestCount = 0
    local signature
    local partId
    local partHealth
    local baseline = { current = 100, max = 100 }
    local wound
    local compactWound
    local infection
    local allStandardParts = true
    local useBaseline = false
    for partId, partHealth in pairs(normalized.parts or {}) do
        signature = Internal.partSignature(partHealth)
        counts[signature] = (tonumber(counts[signature]) or 0) + 1
        values[signature] = partHealth
        if counts[signature] > bestCount then
            bestSignature = signature
            bestCount = counts[signature]
        end
    end
    for i = 1, #Internal.HEALTH_PART_IDS do
        if normalized.parts[Internal.HEALTH_PART_IDS[i]] == nil then
            allStandardParts = false
            break
        end
    end
    if allStandardParts and bestSignature and bestCount >= 2 then
        useBaseline = true
        baseline = values[bestSignature]
        if Internal.partSignature(baseline) ~= "100:100" then
            output.partBase = Internal.compactPartValue(baseline)
        end
    end
    for partId, partHealth in pairs(normalized.parts or {}) do
        if not useBaseline
            or Internal.partSignature(partHealth) ~= Internal.partSignature(baseline)
        then
            output.parts = output.parts or {}
            output.parts[tostring(partId)] = Internal.compactPartValue(partHealth)
        end
    end
    for partId, wound in pairs(normalized.wounds or {}) do
        compactWound = {
            type = wound.type ~= "scratch" and wound.type or nil,
            severity = wound.severity > 0 and wound.severity or nil,
            damage = wound.damage ~= wound.severity and wound.damage or nil,
            bleedingRate = wound.bleedingRate > 0 and wound.bleedingRate or nil,
            bandaged = wound.bandaged == true or nil,
            createdAt = wound.createdAt > 0 and wound.createdAt or nil,
            bandagedAt = wound.bandagedAt > 0 and wound.bandagedAt or nil,
            healAtWorldHour = wound.healAtWorldHour > 0
                and wound.healAtWorldHour or nil,
        }
        output.wounds = output.wounds or {}
        output.wounds[tostring(partId)] = compactWound
    end
    for ailmentID, ailment in pairs(normalized.wholeBodyAilments or {}) do
        local severity = tonumber(ailment and ailment.severity) or 0
        if severity > 0 then
            output.wholeBodyAilments = output.wholeBodyAilments or {}
            output.wholeBodyAilments[tostring(ailmentID)] =
                math.floor(Core.Clamp(severity, 0, 1) * 1000 + 0.5)
        elseif ailment and ailment.active == true
            and ailment.flavorOnly == true
        then
            output.wholeBodyAilments = output.wholeBodyAilments or {}
            output.wholeBodyAilments[tostring(ailmentID)] = {
                active = true,
                flavorOnly = true,
            }
        end
    end
    infection = normalized.infection
    if infection then
        output.infection = {
            active = infection.active == true or nil,
            fatal = infection.fatal == true or nil,
            pendingFatal = infection.pendingFatal == true or nil,
            sourcePart = infection.sourcePart,
            infectedAtWorldHour = infection.infectedAtWorldHour ~= 0
                and infection.infectedAtWorldHour or nil,
            fatalAtWorldHour = infection.fatalAtWorldHour ~= 0
                and infection.fatalAtWorldHour or nil,
            reanimateAtWorldHour = infection.reanimateAtWorldHour ~= 0
                and infection.reanimateAtWorldHour or nil,
            progress = infection.progress ~= 0 and infection.progress or nil,
            stage = infection.stage ~= "incubating" and infection.stage or nil,
            fever = infection.fever ~= 0 and infection.fever or nil,
            temperatureC = infection.temperatureC ~= 37
                and infection.temperatureC or nil,
            lastUpdatedWorldHour = infection.lastUpdatedWorldHour ~= 0
                and infection.lastUpdatedWorldHour or nil,
            lastDamageWorldHour = infection.lastDamageWorldHour ~= 0
                and infection.lastDamageWorldHour or nil,
        }
    end
    if not Internal.hasTableEntries(output) then return nil end
    return output
end

function Internal.sanitizeHealth(rawHealth, fallbackMax)
    local maxValue = math.max(1, Internal.normalizeNumber(rawHealth and rawHealth.max, fallbackMax or Const.DEFAULT_HP_MAX))
    local currentValue = Core.Clamp(Internal.normalizeNumber(rawHealth and rawHealth.current, maxValue), 0, maxValue)
    return {
        current = currentValue,
        max = maxValue,
        state = tostring(rawHealth and rawHealth.state or "normal"),
        lastDamageAt = Internal.normalizeNumber(rawHealth and rawHealth.lastDamageAt, 0),
        downedAt = Internal.normalizeNumber(rawHealth and rawHealth.downedAt, 0),
        recentDamageUntil = Internal.normalizeNumber(rawHealth and rawHealth.recentDamageUntil, 0),
        reviveUntil = Internal.normalizeNumber(rawHealth and rawHealth.reviveUntil, 0),
        reviveProtectionUntil = Internal.normalizeNumber(rawHealth and rawHealth.reviveProtectionUntil, 0),
        incapacitatedReason = Internal.normalizeString(rawHealth and rawHealth.incapacitatedReason),
        body = Internal.sanitizeHealthBody(rawHealth and rawHealth.body),
    }
end

function Internal.serializeHealth(rawHealth, fallbackMax)
    local normalized = Internal.sanitizeHealth(rawHealth, fallbackMax)
    local body = Internal.buildCompactHealthBody(normalized.body)
    local output = {
        current = normalized.current ~= normalized.max
            and normalized.current or nil,
        max = normalized.max ~= Const.DEFAULT_HP_MAX
            and normalized.max or nil,
        state = normalized.state ~= "normal" and normalized.state or nil,
        incapacitatedReason = normalized.state == "incapacitated"
            and normalized.incapacitatedReason or nil,
        body = body,
    }
    return output
end
