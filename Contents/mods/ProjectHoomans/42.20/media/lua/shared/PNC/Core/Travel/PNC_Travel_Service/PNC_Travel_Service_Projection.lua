local Service = PNC.Travel.Service
local Internal = Service.Internal
local Core = PNC.Core
local Const = PNC.Const
local Model = PNC.Travel.Model
local Projection = PNC.Travel.Projection

function Service.RefreshAbstractPositions(nowMs, force)
    nowMs = tonumber(nowMs) or Core.Now()
    if force ~= true and nowMs - (tonumber(Service.LastPositionRefreshAt) or 0)
        < (tonumber(Const.TRAVEL_POSITION_REFRESH_MS) or 250)
    then
        return 0
    end
    Service.LastPositionRefreshAt = nowMs
    local count = 0
    local hour = Internal.WorldHour()
    if not PNC.Registry or not PNC.Registry.ForEach then return 0 end
    PNC.Registry.ForEach(function(record)
        if record.presenceState == Const.PRESENCE_ABSTRACT
            and Model.IsActive(record.travel)
        then
            Service.Advance(record, hour)
            if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
                PNC.SpatialIndex.UpdateNPC(record)
            end
            count = count + 1
        end
    end)
    return count
end

function Service.GetProgress(recordOrID, atWorldHour)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey then return nil end
    local projected = journey
    if record.presenceState ~= Const.PRESENCE_LIVE then
        projected = Projection.Project(
            journey,
            tonumber(atWorldHour) or Internal.WorldHour()
        ) or journey
    end
    local total = math.max(0, tonumber(projected.distanceTotal) or 0)
    local travelled = math.max(
        0,
        math.min(total, tonumber(projected.distanceTravelled) or 0)
    )
    return {
        journeyId = projected.journeyId,
        npcId = record.id,
        state = projected.state,
        x = projected.x or record.x,
        y = projected.y or record.y,
        z = projected.z or record.z,
        percent = total <= 0 and 1 or travelled / total,
        distanceTotal = total,
        distanceTravelled = travelled,
        distanceRemaining = math.max(0, total - travelled),
        etaWorldHour = projected.etaWorldHour,
        remainingWorldHours = projected.etaWorldHour
            and math.max(
                0,
                projected.etaWorldHour
                    - (tonumber(atWorldHour) or Internal.WorldHour())
            )
            or nil,
        presenceState = record.presenceState,
        controller = projected.controller,
        ownerMod = projected.ownerMod,
        ownerRef = projected.ownerRef,
        metadata = Model.CopyMetadata(projected.metadata),
    }
end

for _, eventName in pairs(Internal.EventNames) do
    if LuaEventManager and LuaEventManager.AddEvent then
        pcall(LuaEventManager.AddEvent, eventName)
    end
end

return Service
