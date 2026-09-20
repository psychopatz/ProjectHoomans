-- Bounded client-side lifecycle for semantic gift requests.
--
-- This is deliberately transient session state.  It is not ModData and never
-- becomes authoritative inventory state.  The server owns the transfer; this
-- module only prevents duplicate UI work and lets late responses retain the
-- original semantic selection long enough to update dialogue context.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.GiftLifecycle or {}
PNC.Semantics.GiftLifecycle = Lifecycle

Lifecycle.VERSION = 1
Lifecycle.MAX_PENDING = 8
Lifecycle.MAX_EXPIRED = 8
Lifecycle.MAX_HANDLED = 24
Lifecycle.DEFAULT_TIMEOUT = 15000
Lifecycle.MAX_OFFER_CANDIDATES = 8
Lifecycle.DEFAULT_OFFER_CONSENT_TIMEOUT = 45000

local function requestValue(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function nowValue(value)
    if value ~= nil then return tonumber(value) or 0 end
    if getTimeInMillis then return getTimeInMillis() end
    if getTimestampMs then return getTimestampMs() end
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        local ok, result = pcall(core.Now)
        if ok then return tonumber(result) or 0 end
    end
    return 0
end

local function stateFor(session)
    if type(session) ~= "table" then return nil end
    session.semanticGiftRequests = session.semanticGiftRequests or {}
    session.semanticGiftRequestOrder =
        session.semanticGiftRequestOrder or {}
    session.semanticGiftExpired = session.semanticGiftExpired or {}
    session.semanticGiftExpiredOrder =
        session.semanticGiftExpiredOrder or {}
    session.semanticGiftHandled = session.semanticGiftHandled or {}
    session.semanticGiftHandledOrder =
        session.semanticGiftHandledOrder or {}
    return session
end

local function removeValue(list, value)
    local index
    for index = #list, 1, -1 do
        if list[index] == value then table.remove(list, index) end
    end
end

local function trimHandled(session)
    while #session.semanticGiftHandledOrder > Lifecycle.MAX_HANDLED do
        local old = table.remove(session.semanticGiftHandledOrder, 1)
        session.semanticGiftHandled[old] = nil
    end
end

local function trimExpired(session)
    while #session.semanticGiftExpiredOrder > Lifecycle.MAX_EXPIRED do
        local old = table.remove(session.semanticGiftExpiredOrder, 1)
        session.semanticGiftExpired[old] = nil
    end
end

local function normalizedText(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

function Lifecycle.StageOfferConsent(session, offer, candidate, at, timeout)
    session = stateFor(session)
    if not session then return false, "gift_consent_session_missing" end
    offer = type(offer) == "table" and offer or {}
    candidate = type(candidate) == "table" and candidate or {}

    local query = normalizedText(offer.query)
    local recipientID = requestValue(candidate.npcID or candidate.id)
    if query == "" then return false, "gift_consent_item_missing" end
    if not recipientID then return false, "gift_consent_recipient_missing" end

    local groupID = requestValue(offer.groupID)
    local turnID = requestValue(offer.groupTurnID
        or offer.sourceSequence or offer.conversationID)
    local key = table.concat({ groupID or "single", turnID or "turn", query }, ":")
    local current = nowValue(at)
    local maximumAge = tonumber(timeout)
        or Lifecycle.DEFAULT_OFFER_CONSENT_TIMEOUT
    local record = session.semanticGiftConsentOffer
    if type(record) ~= "table"
        or current - (tonumber(record.at) or current) >= maximumAge
        or record.key ~= key
    then
        record = {
            key = key,
            query = query,
            quantity = tonumber(offer.quantity),
            groupID = groupID,
            groupTurnID = turnID,
            conversationID = offer.conversationID,
            at = current,
            overflow = false,
            candidates = {},
        }
        session.semanticGiftConsentOffer = record
    end

    local index
    for index = 1, #record.candidates do
        if tostring(record.candidates[index].npcID or "") == recipientID then
            return true, record
        end
    end
    if #record.candidates >= Lifecycle.MAX_OFFER_CANDIDATES then
        record.overflow = true
        return true, record
    end

    record.candidates[#record.candidates + 1] = {
        npcID = recipientID,
        name = tostring(candidate.name or candidate.npcName or ""),
    }
    return true, record
end

function Lifecycle.PendingOfferConsent(session, at, timeout, groupID)
    if type(session) ~= "table" then return nil end
    local record = session.semanticGiftConsentOffer
    if type(record) ~= "table" then return nil end

    local current = nowValue(at)
    local maximumAge = tonumber(timeout)
        or Lifecycle.DEFAULT_OFFER_CONSENT_TIMEOUT
    if current - (tonumber(record.at) or current) >= maximumAge
        or tostring(record.groupID or "") ~= tostring(groupID or "")
    then
        session.semanticGiftConsentOffer = nil
        return nil
    end

    local output = {
        query = record.query,
        quantity = record.quantity,
        groupID = record.groupID,
        groupTurnID = record.groupTurnID,
        conversationID = record.conversationID,
        at = record.at,
        overflow = record.overflow == true,
        candidates = {},
    }
    local index
    local candidate
    for index = 1, #record.candidates do
        candidate = record.candidates[index]
        output.candidates[index] = {
            npcID = candidate.npcID,
            name = candidate.name,
        }
    end
    return output
end

function Lifecycle.ClearOfferConsent(session)
    if type(session) ~= "table" then return false end
    local existed = type(session.semanticGiftConsentOffer) == "table"
    session.semanticGiftConsentOffer = nil
    return existed
end

function Lifecycle.Expire(session, at, timeout)
    session = stateFor(session)
    if not session then return 0 end
    local current = nowValue(at)
    local maximumAge = tonumber(timeout) or Lifecycle.DEFAULT_TIMEOUT
    local expired = 0
    local index
    local requestID
    local record
    for index = #session.semanticGiftRequestOrder, 1, -1 do
        requestID = session.semanticGiftRequestOrder[index]
        record = session.semanticGiftRequests[requestID]
        if record and current - (tonumber(record.at) or current)
            >= maximumAge
        then
            table.remove(session.semanticGiftRequestOrder, index)
            session.semanticGiftRequests[requestID] = nil
            record.state = "expired"
            record.expiredAt = current
            session.semanticGiftExpired[requestID] = record
            removeValue(session.semanticGiftExpiredOrder, requestID)
            session.semanticGiftExpiredOrder[#session.semanticGiftExpiredOrder + 1] =
                requestID
            expired = expired + 1
        end
    end
    trimExpired(session)
    return expired
end

function Lifecycle.Get(session, requestID)
    session = stateFor(session)
    requestID = requestValue(requestID)
    if not session or not requestID then return nil end
    return session.semanticGiftRequests[requestID]
        or session.semanticGiftExpired[requestID]
end

function Lifecycle.IsHandled(session, requestID)
    session = stateFor(session)
    requestID = requestValue(requestID)
    return session ~= nil and requestID ~= nil
        and session.semanticGiftHandled[requestID] ~= nil
end

function Lifecycle.Active(session, npcID)
    session = stateFor(session)
    if not session then return nil end
    Lifecycle.Expire(session)
    local index
    local requestID
    local record
    for index = 1, #session.semanticGiftRequestOrder do
        requestID = session.semanticGiftRequestOrder[index]
        record = session.semanticGiftRequests[requestID]
        if record and (npcID == nil
            or tostring(record.npcID or "") == tostring(npcID or ""))
        then
            return record
        end
    end
    return nil
end

function Lifecycle.Begin(session, requestID, record, at, timeout)
    session = stateFor(session)
    requestID = requestValue(requestID)
    if not session or not requestID then
        return false, "gift_request_id_missing"
    end
    Lifecycle.Expire(session, at, timeout)
    if session.semanticGiftHandled[requestID] then
        return false, "gift_request_handled"
    end
    if session.semanticGiftRequests[requestID] then
        return false, "gift_request_active",
            session.semanticGiftRequests[requestID]
    end
    if #session.semanticGiftRequestOrder >= Lifecycle.MAX_PENDING then
        return false, "gift_request_capacity"
    end
    session.semanticGiftExpired[requestID] = nil
    removeValue(session.semanticGiftExpiredOrder, requestID)
    record = type(record) == "table" and record or {}
    record.requestID = requestID
    record.state = "pending"
    record.at = nowValue(at)
    session.semanticGiftRequests[requestID] = record
    session.semanticGiftRequestOrder[#session.semanticGiftRequestOrder + 1] =
        requestID
    return true, record
end

function Lifecycle.Clear(session, requestID)
    session = stateFor(session)
    requestID = requestValue(requestID)
    if not session or not requestID then return false end
    local existed = session.semanticGiftRequests[requestID] ~= nil
        or session.semanticGiftExpired[requestID] ~= nil
    session.semanticGiftRequests[requestID] = nil
    session.semanticGiftExpired[requestID] = nil
    removeValue(session.semanticGiftRequestOrder, requestID)
    removeValue(session.semanticGiftExpiredOrder, requestID)
    return existed
end

function Lifecycle.MarkHandled(session, requestID, at)
    session = stateFor(session)
    requestID = requestValue(requestID)
    if not session or not requestID then return false end
    Lifecycle.Clear(session, requestID)
    if session.semanticGiftHandled[requestID] == nil then
        session.semanticGiftHandledOrder[#session.semanticGiftHandledOrder + 1] =
            requestID
    end
    session.semanticGiftHandled[requestID] = nowValue(at)
    trimHandled(session)
    return true
end

Lifecycle.Internal = Lifecycle.Internal or {}
Lifecycle.Internal.Now = nowValue
Lifecycle.Internal.StateFor = stateFor
Lifecycle.Internal.RemoveValue = removeValue

return Lifecycle
