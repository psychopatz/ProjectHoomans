-- Client-side storage boundary. Storage windows consume this projection instead
-- of reaching into Network.ClientState directly.

PNC = PNC or {}
PNC.ColonyStorageClient = PNC.ColonyStorageClient or {}

local Client = PNC.ColonyStorageClient

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function readState()
    return PNC.Network and PNC.Network.ClientState or {}
end

function Client.ReadSnapshot()
    local management = PNC.ColonyManagementClient
    if management and type(management.ReadSnapshot) == "function" then
        local update = management.ReadSnapshot()
        if type(update) == "table" then
            local snapshot = update.snapshot or {}
            return {
                snapshot = snapshot,
                storage = snapshot.storage,
                revision = tonumber(update.revision) or 0,
                receivedAt = update.receivedAt,
            }
        end
    end

    local state = readState()
    local snapshot = state.colonyManagement or {}
    return {
        snapshot = snapshot,
        storage = snapshot.storage,
        revision = tonumber(state.colonyManagementRevision) or 0,
        receivedAt = state.lastColonyManagementReceiveAt,
    }
end

function Client.HasUpdate(lastRevision, lastReceiveAt)
    local update = Client.ReadSnapshot()
    return update.revision > (tonumber(lastRevision) or 0)
        or (tonumber(update.receivedAt) or 0)
            > (tonumber(lastReceiveAt) or 0),
        update
end

function Client.RequestSnapshot()
    local management = PNC.ColonyManagementClient
    if management and type(management.RequestSnapshot) == "function" then
        local ok, reason = management.RequestSnapshot()
        return ok, reason, now()
    end
    if PNC.Client and PNC.Client.RequestColonyManagement then
        local ok, reason = PNC.Client.RequestColonyManagement()
        return ok, reason, now()
    end
    return false, "client_unavailable", now()
end

function Client.GetStorage(snapshot)
    local value = snapshot
    if type(value) ~= "table" then
        value = Client.ReadSnapshot().snapshot
    elseif type(value.snapshot) == "table" then
        value = value.snapshot
    end
    return value and value.storage or nil
end

function Client.HasAccess(snapshot)
    local allowed = Client.GetAccessStatus(snapshot)
    return allowed == true
end

function Client.GetAccessStatus(snapshot)
    local value = snapshot
    local status
    local storage = Client.GetStorage(snapshot)
    local access = storage and storage.access or nil
    if type(value) ~= "table" then value = Client.ReadSnapshot().snapshot end
    if type(value) == "table" and type(value.snapshot) == "table" then
        value = value.snapshot
    end
    status = value and value.storageStatus or nil
    if not storage then
        return false, status and status.reason or "storage_unavailable", status
    end
    if not access then
        return false, "storage_access_unavailable", status
    end
    if access.hasStockpile ~= true then
        return false, access.reason or "stockpile_required", access
    end
    return true, access.insideBase == true and "writable" or "outside_base",
        access
end

return Client
