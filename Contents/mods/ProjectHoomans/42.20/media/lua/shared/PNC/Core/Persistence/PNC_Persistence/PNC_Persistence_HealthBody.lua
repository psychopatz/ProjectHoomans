PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local Inventory = PNC.Inventory
local RelationshipTypes = PNC.RelationshipTypes
local RelationshipMath = PNC.RelationshipMath
local FactionTypes = PNC.FactionTypes

function Internal.sanitizeHealthBody(rawBody)
    local source = type(rawBody) == "table" and rawBody or {}
    local wounds = {}
    local parts = {}
    local basePart = source.partBase
    local partId
    local wound
    local bleedingRate = 0
    local openWoundCount = 0
    local bandagedWoundCount = 0
    local totalPercent = 0
    local partCount = 0
    for partId, wound in pairs(type(source.wounds) == "table" and source.wounds or {}) do
        if type(wound) == "table" then
            partId = tostring(wound.partId or partId)
            wounds[partId] = {
                partId = partId,
                type = tostring(wound.type or "scratch"),
                severity = math.max(0, Internal.normalizeNumber(wound.severity, 0)),
                damage = math.max(0, Internal.normalizeNumber(wound.damage, wound.severity or 0)),
                bleedingRate = math.max(0, Internal.normalizeNumber(wound.bleedingRate, 0)),
                bandaged = wound.bandaged == true,
                createdAt = Internal.normalizeNumber(wound.createdAt, 0),
                bandagedAt = Internal.normalizeNumber(wound.bandagedAt, 0),
                healAtWorldHour = Internal.normalizeNumber(wound.healAtWorldHour, 0),
            }
            if wounds[partId].bandaged then
                bandagedWoundCount = bandagedWoundCount + 1
            else
                openWoundCount = openWoundCount + 1
                bleedingRate = bleedingRate + wounds[partId].bleedingRate
            end
        end
    end
    local function normalizePart(partHealth)
        local maximum
        if type(partHealth) == "number" then
            maximum = 100
            return {
                current = Core.Clamp(Internal.normalizeNumber(partHealth, maximum), 0, maximum),
                max = maximum,
            }
        end
        if type(partHealth) ~= "table" then return nil end
        maximum = math.max(1, Internal.normalizeNumber(
            partHealth.max or partHealth.m,
            100
        ))
        return {
            current = Core.Clamp(Internal.normalizeNumber(
                partHealth.current or partHealth.c,
                maximum
            ), 0, maximum),
            max = maximum,
        }
    end
    if basePart ~= nil then
        local normalizedBase = normalizePart(basePart)
        if normalizedBase then
            for i = 1, #Internal.HEALTH_PART_IDS do
                parts[Internal.HEALTH_PART_IDS[i]] = {
                    current = normalizedBase.current,
                    max = normalizedBase.max,
                }
            end
        end
    end
    for partId, partHealth in pairs(type(source.parts) == "table"
        and source.parts or {})
    do
        partHealth = normalizePart(partHealth)
        if partHealth then
            parts[tostring(partId)] = partHealth
        end
    end
    for _, partHealth in pairs(parts) do
        totalPercent = totalPercent + (
            (tonumber(partHealth.current) or 0)
            / math.max(1, tonumber(partHealth.max) or 100)
        )
        partCount = partCount + 1
    end
    local infectionSource = type(source.infection) == "table" and source.infection or nil
    local infection = infectionSource and {
        active = infectionSource.active == true,
        fatal = infectionSource.fatal == true,
        pendingFatal = infectionSource.pendingFatal == true,
        sourcePart = Internal.normalizeString(infectionSource.sourcePart),
        infectedAtWorldHour = Internal.normalizeNumber(infectionSource.infectedAtWorldHour, 0),
        fatalAtWorldHour = Internal.normalizeNumber(infectionSource.fatalAtWorldHour, 0),
        reanimateAtWorldHour = Internal.normalizeNumber(infectionSource.reanimateAtWorldHour, 0),
        progress = Core.Clamp(Internal.normalizeNumber(infectionSource.progress, 0), 0, 1),
        stage = tostring(infectionSource.stage or "incubating"),
        fever = Core.Clamp(Internal.normalizeNumber(infectionSource.fever, 0), 0, 100),
        temperatureC = Core.Clamp(Internal.normalizeNumber(infectionSource.temperatureC, 37), 30, 45),
        lastUpdatedWorldHour = Internal.normalizeNumber(infectionSource.lastUpdatedWorldHour, 0),
    } or nil
    return {
        wounds = wounds,
        parts = parts,
        infection = infection,
        totalPartHealth = partCount > 0 and totalPercent * 100
            or math.max(0, Internal.normalizeNumber(source.totalPartHealth, 0)),
        totalPartMax = partCount > 0 and partCount * 100
            or math.max(0, Internal.normalizeNumber(source.totalPartMax, 0)),
        overallPercent = partCount > 0
            and Core.Clamp(totalPercent / partCount * 100, 0, 100)
            or Core.Clamp(Internal.normalizeNumber(source.overallPercent, 100), 0, 100),
        bleedingRate = bleedingRate,
        openWoundCount = openWoundCount,
        bandagedWoundCount = bandagedWoundCount,
        -- Wall-clock values do not survive a process restart. Bleeding resumes
        -- from the next health tick instead of charging an offline time jump.
        lastBleedAt = 0,
    }
end

