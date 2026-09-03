-- Selects a stable, valid tile inside a serialized base region.

PNC = PNC or {}
PNC.MapTrackingTarget = PNC.MapTrackingTarget or {}

local Target = PNC.MapTrackingTarget

local function regionTarget(region)
    if type(region) ~= "table" or type(region.levels) ~= "table" then
        return nil
    end

    local count, sumX, sumY, sumZ = 0, 0, 0, 0
    local z, level, rows, y, spans, index
    for z, level in pairs(region.levels) do
        rows = type(level) == "table" and (level.rows or level) or nil
        for y, spans in pairs(rows or {}) do
            local rowY = tonumber(y)
            if rowY and type(spans) == "table" then
                for index = 1, #spans - 1, 2 do
                    local first = tonumber(spans[index])
                    local last = tonumber(spans[index + 1])
                    if first and last and first <= last then
                        local width = last - first + 1
                        count = count + width
                        sumX = sumX + (first + last) * width / 2
                        sumY = sumY + rowY * width
                        sumZ = sumZ + (tonumber(z) or 0) * width
                    end
                end
            end
        end
    end
    if count <= 0 then return nil end

    local centerX = sumX / count + 0.5
    local centerY = sumY / count + 0.5
    local centerZ = sumZ / count
    local best
    local bestDistance

    for z, level in pairs(region.levels) do
        rows = type(level) == "table" and (level.rows or level) or nil
        for y, spans in pairs(rows or {}) do
            local rowY = tonumber(y)
            if rowY and type(spans) == "table" then
                for index = 1, #spans - 1, 2 do
                    local first = tonumber(spans[index])
                    local last = tonumber(spans[index + 1])
                    if first and last and first <= last then
                        local desiredX = math.max(first, math.min(last,
                            centerX - 0.5))
                        local tileX = math.floor(desiredX + 0.5)
                        local pointX, pointY = tileX + 0.5, rowY + 0.5
                        local pointZ = tonumber(z) or 0
                        local dx, dy = pointX - centerX, pointY - centerY
                        local dz = pointZ - centerZ
                        local distance = dx * dx + dy * dy + dz * dz
                        if not bestDistance or distance < bestDistance then
                            bestDistance = distance
                            best = { x = pointX, y = pointY, z = pointZ }
                        end
                    end
                end
            end
        end
    end
    return best
end

local function boundsTarget(bounds)
    if type(bounds) ~= "table" then return nil end
    local minX, maxX = tonumber(bounds.minX), tonumber(bounds.maxX)
    local minY, maxY = tonumber(bounds.minY), tonumber(bounds.maxY)
    if not minX or not maxX or not minY or not maxY then return nil end
    return {
        x = (minX + maxX) / 2 + 0.5,
        y = (minY + maxY) / 2 + 0.5,
        z = tonumber(bounds.minZ or bounds.z) or 0,
    }
end

function Target.FromSettlement(settlement)
    local geometry = settlement and settlement.geometry or nil
    if type(geometry) ~= "table" then return nil end
    return regionTarget(geometry.region) or boundsTarget(geometry.bounds)
end

function Target.FromRegion(region)
    return regionTarget(region)
end

return Target
