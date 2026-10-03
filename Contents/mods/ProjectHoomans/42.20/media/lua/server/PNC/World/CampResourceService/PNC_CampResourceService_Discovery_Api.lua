if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local number = function(value, fallback)
    return Internal.Number(value, fallback)
end
local requestCapture = Internal.RequestCapture
local pumpCapture = Internal.PumpCapture

function Service.Capture(record, force)
    local order = Internal.CampContext(record)
    local entry
    local state
    local reason
    if not order then return nil, "NOT_CAMPED" end
    state, reason = requestCapture(record, force)
    if state then return state end
    if reason ~= "CAMP_RESOURCE_CAPTURE_PENDING" then
        return nil, reason
    end
    entry = Service.Attach(record, order)
    while entry and entry.capture do
        state = pumpCapture(entry.capture, 1000000)
        if state then return state end
    end
    return entry and entry.state or nil
end

function Service.GetSnapshot(record, force)
    return requestCapture(record, force)
end

function Service.Pump(nowValue)
    local budget = math.max(1, math.floor(number(
        Const.CAMP_RESOURCE_SCAN_SQUARES_PER_TICK, 32)))
    local processed = 0
    local used
    local entry
    for _, candidate in pairs(Service.Runtime.camps) do
        if processed >= budget then break end
        entry = candidate
        if entry and entry.capture then
            _, used = pumpCapture(entry.capture, budget - processed)
            processed = processed + (tonumber(used) or 0)
        end
    end
    Internal.EvictCacheEntries()
    return processed
end

return Service
