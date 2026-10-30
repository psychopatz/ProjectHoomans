-- Exact online-id recovery for authoritative binds that arrive before the
-- engine replica has been observed by OnZombieUpdate. This is intentionally
-- one-id-at-a-time and cadence-bounded; it is not a recurring population scan.

local Recovery = {}
local pendingLookupAt = {}

function Recovery.Observe(message, at, client, binding)
    local onlineID
    local key
    local interval
    local body
    if type(message) ~= "table"
        or message.operation ~= "bind"
        or not binding.ValidOnlineID(message.onlineId)
        or not PNC.Network
        or type(PNC.Network.FindZombieByOnlineID) ~= "function"
    then
        return nil
    end

    onlineID = tonumber(message.onlineId)
    key = tostring(onlineID)
    interval = tonumber(
        PNC.Const.CLIENT_BODY_SCAN_UNRESOLVED_MS
    ) or 200
    if at < (tonumber(pendingLookupAt[key]) or 0) then
        return nil
    end
    pendingLookupAt[key] = at + interval

    body = PNC.Network.FindZombieByOnlineID(onlineID)
    if body then
        client.Observe(body, onlineID, at)
        pendingLookupAt[key] = nil
    end
    return body
end

function Recovery.Sweep(at)
    for key, nextAt in pairs(pendingLookupAt) do
        if at > (tonumber(nextAt) or 0) + 10000 then
            pendingLookupAt[key] = nil
        end
    end
end

function Recovery.Reset()
    pendingLookupAt = {}
end

return Recovery
