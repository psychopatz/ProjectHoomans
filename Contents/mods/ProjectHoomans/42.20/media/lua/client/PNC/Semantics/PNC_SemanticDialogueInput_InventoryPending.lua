-- Bounded correlation state shared by semantic inventory request and response.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
Input.Internal = Input.Internal or {}

local Pending = Input.Internal.InventoryPending or {}
Input.Internal.InventoryPending = Pending
Pending.MAX_PENDING = Pending.MAX_PENDING or 16

local function recordsFor(view, create)
    local session = view and view.session
    if type(session) ~= "table" then return nil end
    if type(session.semanticInventoryQueries) ~= "table" then
        if not create then return nil end
        session.semanticInventoryQueries = {}
    end
    return session.semanticInventoryQueries
end

local function requestKey(requestID)
    if requestID == nil then return nil end
    local key = tostring(requestID)
    return key ~= "" and key or nil
end

function Pending.Register(view, requestID, record)
    local key = requestKey(requestID)
    local records
    local count = 0
    if not key then return false, "inventory_query_request_id_missing" end
    records = recordsFor(view, true)
    if not records then return false, "inventory_query_session_unavailable" end
    if records[key] ~= nil then return false, "inventory_query_already_pending" end
    for recordKey, pending in pairs(records) do
        if type(pending) == "table" then
            count = count + 1
            if count >= Pending.MAX_PENDING then
                return false, "inventory_query_pending_limit"
            end
        else
            records[recordKey] = nil
        end
    end
    records[key] = type(record) == "table" and record or {}
    return true
end

function Pending.Take(view, requestID)
    local key = requestKey(requestID)
    if not key then return nil end
    local records = recordsFor(view, false)
    if not records then return nil end
    local record = records[key]
    records[key] = nil
    return record
end

function Pending.Remove(view, requestID)
    return Pending.Take(view, requestID) ~= nil
end

return Pending
