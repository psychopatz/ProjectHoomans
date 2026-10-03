-- Shared time, persistence, world lookup, and effect-shape helpers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.WorldEffectService
local Internal = Service.Internal
local Core = Internal.Core or PNC.Core or {}
local Repository = Internal.Repository or PNC.WorkRepository

local function now()
    return Core and type(Core.Now) == "function" and Core.Now() or 0
end

local function copy(value)
    if Core and type(Core.DeepCopy) == "function" then
        return Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function markDirty(provider, owner)
    if provider and type(provider.MarkDirty) == "function" then
        provider.MarkDirty(owner)
        return
    end
    if Repository and type(Repository.MarkDirty) == "function" then
        Repository.MarkDirty()
    end
end

local function pointKey(x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z) or 0
    if not x or not y then return nil end
    return tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))
        .. ":" .. tostring(math.floor(z))
end

local function getCell()
    if type(_G and _G.getCell) == "function" then
        local cell = _G.getCell()
        if cell then return cell end
        return nil, "CELL_LOOKUP_FAILED"
    end
    if IsoWorld and IsoWorld.instance then
        return IsoWorld.instance.currentCell
    end
    return nil, "WORLD_API_UNAVAILABLE"
end

-- Engine lookups remain direct after their API availability checks. Missing
-- world objects are returned to the effect ledger as ordinary failures.
local function squareAt(x, y, z)
    local cell, cellReason = getCell()
    if not cell then return nil, cellReason end
    if type(cell.getGridSquare) ~= "function" then
        return nil, "GRID_LOOKUP_UNAVAILABLE"
    end
    return cell:getGridSquare(x, y, z)
end

local function effectID(providerID, ownerID, effect)
    local id = effect and (effect.id or effect.effectId)
    if id ~= nil and tostring(id) ~= "" then return tostring(id) end
    if Core and type(Core.GenerateID) == "function" then
        return tostring(Core.GenerateID("world_effect"))
    end
    return tostring(providerID) .. ":" .. tostring(ownerID) .. ":"
        .. tostring(effect and effect.kind or "effect")
end

local function effectsFor(provider, owner)
    if provider and type(provider.GetEffects) == "function" then
        local effects = provider.GetEffects(owner)
        if type(effects) == "table" then return effects end
    end
    return {}
end

local function ownerIDFor(providerID, provider, owner)
    if provider and type(provider.GetOwnerID) == "function" then
        return tostring(provider.GetOwnerID(owner) or "")
    end
    return tostring(owner and owner.id or providerID)
end

local function pending(effect, provider, owner)
    if type(effect) ~= "table" then return false end
    if provider and type(provider.IsPending) == "function" then
        return provider.IsPending(owner, effect) == true
    end
    local state = tostring(effect.state or "PENDING")
    return state ~= "APPLIED" and state ~= "CANCELLED"
        and state ~= "CONFLICT" and state ~= "FAILED"
end

local function pointsFor(providerID, provider, owner, effect)
    local points
    local handler = Service.Handlers[tostring(effect and effect.kind or "")]
    if handler and type(handler.GetPoints) == "function" then
        points = handler.GetPoints(owner, effect)
    elseif provider and type(provider.GetPoints) == "function" then
        points = provider.GetPoints(owner, effect)
    elseif type(effect and effect.points) == "table" then
        points = effect.points
    else
        points = {}
        if effect and effect.sourceX ~= nil and effect.sourceY ~= nil then
            points[#points + 1] = {
                role = "source", x = effect.sourceX, y = effect.sourceY,
                z = effect.sourceZ,
            }
        end
        if effect and effect.destinationX ~= nil
            and effect.destinationY ~= nil
        then
            points[#points + 1] = {
                role = "destination", x = effect.destinationX,
                y = effect.destinationY, z = effect.destinationZ,
            }
        end
        if #points == 0 and effect and effect.x ~= nil
            and effect.y ~= nil
        then
            points[1] = {
                role = "target", x = effect.x, y = effect.y, z = effect.z,
            }
        end
    end
    if type(points) ~= "table" then return {} end
    local output = {}
    for index = 1, #points do
        local point = points[index]
        if type(point) == "table" and point.x ~= nil and point.y ~= nil then
            output[#output + 1] = {
                role = point.role or (index == 1 and "source" or "target"),
                x = tonumber(point.x), y = tonumber(point.y),
                z = tonumber(point.z) or 0,
            }
        end
    end
    return output
end

local function entryKey(providerID, ownerID, effect)
    return tostring(providerID) .. ":" .. tostring(ownerID) .. ":"
        .. effectID(providerID, ownerID, effect)
end

Internal.Now = now
Internal.Copy = copy
Internal.MarkDirty = markDirty
Internal.PointKey = pointKey
Internal.SquareAt = squareAt
Internal.EffectID = effectID
Internal.EffectsFor = effectsFor
Internal.OwnerIDFor = ownerIDFor
Internal.Pending = pending
Internal.PointsFor = pointsFor
Internal.EntryKey = entryKey
