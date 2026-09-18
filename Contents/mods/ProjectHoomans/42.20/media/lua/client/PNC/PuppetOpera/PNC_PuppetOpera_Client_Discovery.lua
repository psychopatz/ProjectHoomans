-- Client-side Puppet Opera target discovery.
--
-- This spoke normalizes live registry bodies and client presence snapshots into
-- the stable target rows consumed by the presentation/debug UI. It only
-- discovers targets; callers remain responsible for selecting a target and
-- requesting an authoritative session.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Client = Opera.Client or {}
Opera.Client = Client
local Internal = Client.Internal or {}
Client.Internal = Internal

local localPlayer = Internal.localPlayer

local function nearbyEntry(zombie, record, snapshot, playerBody)
    if not zombie and not snapshot then return nil end
    local x = zombie and zombie.getX and zombie:getX()
        or snapshot and tonumber(snapshot.x)
        or record and tonumber(record.x)
    local y = zombie and zombie.getY and zombie:getY()
        or snapshot and tonumber(snapshot.y)
        or record and tonumber(record.y)
    if not x or not y then return nil end
    local px = playerBody and playerBody.getX and playerBody:getX() or x
    local py = playerBody and playerBody.getY and playerBody:getY() or y
    local id = record and record.id
        or snapshot and snapshot.id
        or zombie and zombie.getModData
            and zombie:getModData().PNC_UUID or nil
    if not id then return nil end
    return {
        id = tostring(id),
        name = record and (record.displayName or record.name)
            or snapshot and (snapshot.displayName or snapshot.name)
            or tostring(id),
        record = record,
        zombie = zombie,
        snapshot = snapshot,
        x = x,
        y = y,
        distSq = (x - px) * (x - px) + (y - py) * (y - py),
    }
end

function Client.GetNearbyNPCs(radius)
    local entries = {}
    local seen = {}
    local playerBody = localPlayer and localPlayer() or nil
    local maxDistance = tonumber(radius) or 8
    local function addEntry(zombie, record, snapshot)
        local entry = nearbyEntry(zombie, record, snapshot, playerBody)
        local id = entry and tostring(entry.id or "") or ""
        if id ~= "" and entry.distSq <= maxDistance * maxDistance
            and not seen[id]
        then
            seen[id] = true
            entries[#entries + 1] = entry
        end
    end
    local registry = PNC.Registry
    if registry and registry.ForEachLive then
        registry.ForEachLive(function(record, body)
            addEntry(body, record, nil)
        end)
    end
    local clientState = PNC.Network and PNC.Network.ClientState
    local sync = PNC.ClientPresenceSync
    for id, snapshot in pairs(clientState and clientState.snapshots or {}) do
        if snapshot
            and snapshot.presenceState == (PNC.Const and PNC.Const.PRESENCE_LIVE)
            and snapshot.alive ~= false
        then
            local body = sync and sync.BodyByID
                and sync.BodyByID[tostring(id)] or nil
            if body == false then body = nil end
            addEntry(body, nil, snapshot)
        end
    end
    table.sort(entries, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        return tostring(left.name) < tostring(right.name)
    end)
    return entries
end

return Client
