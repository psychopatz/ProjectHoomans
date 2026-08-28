PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core

function Wounds.Ensure(record)
    local health = PNC.Health and PNC.Health.Ensure
        and PNC.Health.Ensure(record) or record.health
    local initialRatio = Core.Clamp(
        (tonumber(health.current) or tonumber(health.max) or 100)
            / math.max(1, tonumber(health.max) or 100),
        0,
        1
    )
    health.body = type(health.body) == "table" and health.body or {}
    health.body.wounds = type(health.body.wounds) == "table"
        and health.body.wounds or {}
    health.body.parts = type(health.body.parts) == "table"
        and health.body.parts or {}
    local sourceAilments = type(health.body.wholeBodyAilments) == "table"
        and health.body.wholeBodyAilments or {}
    local normalizedAilments = {}
    local ailmentID
    local ailment
    for sourceID, sourceAilment in pairs(sourceAilments) do
        ailmentID = tostring(sourceID)
        ailment = sourceAilment
        local severity = type(ailment) == "table"
            and tonumber(ailment.severity) or tonumber(ailment)
        if severity and severity > 1 then severity = severity / 1000 end
        if severity and severity > 0 then
            normalizedAilments[ailmentID] = {
                severity = Core.Clamp(severity, 0, 1),
            }
        elseif type(ailment) == "table"
            and ailment.active == true
            and ailment.flavorOnly == true
        then
            normalizedAilments[ailmentID] = {
                active = true,
                flavorOnly = true,
            }
        end
    end
    health.body.wholeBodyAilments = normalizedAilments
    local i
    local partId
    local partHealth
    for i = 1, #Wounds.PartOrder do
        partId = Wounds.PartOrder[i]
        partHealth = health.body.parts[partId]
        if type(partHealth) ~= "table" then
            health.body.parts[partId] = {
                current = initialRatio * 100,
                max = 100,
            }
        else
            partHealth.max = math.max(
                1, tonumber(partHealth.max) or 100
            )
            partHealth.current = Core.Clamp(
                tonumber(partHealth.current) or partHealth.max,
                0,
                partHealth.max
            )
        end
    end
    health.body.bleedingRate =
        tonumber(health.body.bleedingRate) or 0
    health.body.openWoundCount =
        tonumber(health.body.openWoundCount) or 0
    health.body.bandagedWoundCount =
        tonumber(health.body.bandagedWoundCount) or 0
    health.body.lastBleedAt =
        tonumber(health.body.lastBleedAt) or 0
    return health.body
end

function Wounds.SyncOverallHealth(record)
    local health = record and record.health or nil
    local body = health and Wounds.Ensure(record) or nil
    if not body then return nil end
    local totalPartHealth = 0
    local totalPartMax = 0
    local i
    local partHealth
    for i = 1, #Wounds.PartOrder do
        partHealth = body.parts[Wounds.PartOrder[i]]
        totalPartHealth = totalPartHealth + Core.Clamp(
            tonumber(partHealth.current) or 0,
            0,
            math.max(1, tonumber(partHealth.max) or 100)
        )
        totalPartMax = totalPartMax + math.max(
            1, tonumber(partHealth.max) or 100
        )
    end
    body.totalPartHealth = totalPartHealth
    body.totalPartMax = totalPartMax
    body.overallPercent = totalPartMax > 0
        and totalPartHealth / totalPartMax * 100 or 0
    health.current = Core.Clamp(
        (tonumber(health.max) or 100) * body.overallPercent / 100,
        0,
        tonumber(health.max) or 100
    )
    return health.current
end

function Wounds.SetOverallHealth(record, value)
    local health = record and record.health or nil
    local body = health and Wounds.Ensure(record) or nil
    if not body then return nil end
    local ratio = Core.Clamp(
        (tonumber(value) or 0)
            / math.max(1, tonumber(health.max) or 100),
        0,
        1
    )
    local i
    local partHealth
    for i = 1, #Wounds.PartOrder do
        partHealth = body.parts[Wounds.PartOrder[i]]
        partHealth.current = partHealth.max * ratio
    end
    return Wounds.SyncOverallHealth(record)
end

local function changeBodyHealth(record, amount, partId, healing)
    local body = Wounds.Ensure(record)
    local count = #Wounds.PartOrder
    local selectedScale = partId and 2 or 1
    local otherScale = partId
        and ((count - selectedScale) / math.max(1, count - 1))
        or 1
    amount = math.max(0, tonumber(amount) or 0)
    local i
    local id
    local partHealth
    local scale
    for i = 1, count do
        id = Wounds.PartOrder[i]
        partHealth = body.parts[id]
        scale = id == partId and selectedScale or otherScale
        if healing then
            partHealth.current = math.min(
                partHealth.max,
                partHealth.current + amount * scale
            )
        else
            partHealth.current = math.max(
                0,
                partHealth.current - amount * scale
            )
        end
    end
    return Wounds.SyncOverallHealth(record)
end

function Wounds.ApplyBodyDamage(record, amount, partId)
    return changeBodyHealth(
        record, amount, partId and tostring(partId) or nil, false
    )
end

function Wounds.ApplyBodyHealing(record, amount, partId)
    return changeBodyHealth(
        record, amount, partId and tostring(partId) or nil, true
    )
end

function Wounds.Recalculate(record)
    local body = Wounds.Ensure(record)
    local bleedingRate = 0
    local openCount = 0
    local bandagedCount = 0
    local wound
    for _, wound in pairs(body.wounds) do
        if wound.bandaged == true then
            bandagedCount = bandagedCount + 1
        else
            openCount = openCount + 1
            bleedingRate = bleedingRate
                + math.max(0, tonumber(wound.bleedingRate) or 0)
        end
    end
    body.bleedingRate = bleedingRate
    body.openWoundCount = openCount
    body.bandagedWoundCount = bandagedCount
    local wholeBody = Wounds.WholeBody
    if wholeBody and wholeBody.SetFlag then
        wholeBody.SetFlag(record, "blood_loss", bleedingRate > 0)
    elseif bleedingRate > 0 then
        body.wholeBodyAilments.blood_loss = {
            active = true,
            flavorOnly = true,
        }
    elseif bleedingRate <= 0 then
        body.wholeBodyAilments.blood_loss = nil
    end
    Wounds.SyncOverallHealth(record)
    return body
end

function Wounds.Clear(record)
    local body = Wounds.Ensure(record)
    body.wounds = {}
    body.infection = nil
    body.bleedingRate = 0
    body.openWoundCount = 0
    body.bandagedWoundCount = 0
    body.lastBleedAt = 0
    body.wholeBodyAilments = {}
end

return Wounds
