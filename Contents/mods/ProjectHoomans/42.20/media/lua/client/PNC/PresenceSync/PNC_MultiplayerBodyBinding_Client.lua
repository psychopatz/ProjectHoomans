-- Transient client half of the canonical MP binding seam. No world scans,
-- Registry writes, physical removal, or persistence. Engine observation and
-- accepted server snapshots are the only inputs.
local Binding = require "PNC/Core/Networking/PNC_MultiplayerBodyBinding"

function Binding.NewClient(options)
    options = options or {}
    local client = {}
    local entries, owners, observed, observedUntil
    local count, observedCount, session, retiredRevision
    local limit = options.limit or 512
    local ttl = options.ttl or 10000
    local bodies = setmetatable({}, { __mode = "v" })
    local function reset()
        entries, owners, observedUntil = {}, {}, {}
        observed = setmetatable({}, { __mode = "v" })
        bodies = setmetatable({}, { __mode = "v" })
        count, observedCount, session, retiredRevision = 0, 0, nil, 0
    end
    reset()

    local function release(entry)
        local body = bodies[entry.npcId]
        if body and options.onUnbind then options.onUnbind(body, entry) end
        bodies[entry.npcId] = nil
        if owners[entry.onlineId] == entry.npcId then
            owners[entry.onlineId] = nil
        end
    end
    local function matches(a, b)
        return a.operation == b.operation and a.incarnation == b.incarnation
            and a.onlineId == b.onlineId
    end
    local function reconcile(entry, now)
        if entry.operation ~= "bind" or entry.expires <= now then return nil end
        local body = observed[entry.onlineId]
        if not body or (observedUntil[entry.onlineId] or 0) <= now then return nil end
        if bodies[entry.npcId] == body then return body end
        -- Once used, an old message cannot claim a second local engine object.
        if entry.usedRevision and entry.revision <= entry.usedRevision then return nil end
        if options.canBind and not options.canBind(body, entry) then return nil end
        bodies[entry.npcId] = body
        entry.usedRevision = entry.revision
        if options.onBind then options.onBind(body, entry) end
        return body
    end

    function client.Receive(message, now)
        if type(message) ~= "table" or message.protocol ~= 1
            or type(message.npcId) ~= "string" or #message.npcId == 0 or #message.npcId > 128
            or type(message.session) ~= "string" or #message.session == 0 or #message.session > 256
            or type(message.revision) ~= "number" or message.revision ~= message.revision
            or message.revision < 1 or message.revision > 9007199254740991
            or message.revision ~= math.floor(message.revision)
            or (message.operation ~= "bind" and message.operation ~= "unbind")
        then return false, "invalid" end
        if session and session ~= message.session then return false, "session" end
        if message.operation == "bind" and (
            type(message.incarnation) ~= "string" or #message.incarnation == 0
            or #message.incarnation > 256 or type(message.onlineId) ~= "number"
            or not Binding.ValidOnlineID(message.onlineId)
        ) then return false, "invalid_binding" end
        local current = entries[message.npcId]
        if current and message.revision < current.revision then return false, "stale" end
        if current and message.revision == current.revision then
            return matches(current, message), "duplicate"
        end
        if not current and message.revision <= retiredRevision then return false, "retired" end
        if not current and count >= limit then return false, "capacity" end
        local owner = message.operation == "bind" and owners[message.onlineId] or nil
        if owner and owner ~= message.npcId then return false, "conflict" end
        session = message.session
        local same = current and matches(current, message)
        local usedRevision = same and current.usedRevision or nil
        if current and not same then release(current) end
        local entry = {
            npcId = message.npcId, incarnation = message.incarnation,
            onlineId = message.onlineId, revision = message.revision,
            operation = message.operation, expires = now + ttl,
            usedRevision = usedRevision,
        }
        if not current then count = count + 1 end
        entries[entry.npcId] = entry
        if entry.operation == "bind" then owners[entry.onlineId] = entry.npcId end
        reconcile(entry, now)
        return true
    end

    function client.Observe(body, onlineId, now)
        if not body or not Binding.ValidOnlineID(onlineId) then return false end
        onlineId = tonumber(onlineId)
        local previous = observed[onlineId]
        if previous and previous ~= body then
            local owner = owners[onlineId]
            local entry = owner and entries[owner]
            if entry and bodies[owner] == previous then
                release(entry)
                owners[onlineId] = owner
            end
        end
        if observedUntil[onlineId] == nil then
            if observedCount >= limit then
                -- Reserve capacity for explicitly pending NPCs; do not scan
                -- the engine list or evict another current binding.
                if not owners[onlineId] then return false end
                for id in pairs(observedUntil) do
                    if not owners[id] then
                        observed[id], observedUntil[id] = nil, nil
                        observedCount = observedCount - 1
                        break
                    end
                end
                if observedCount >= limit then return false end
            end
            observedCount = observedCount + 1
        end
        observed[onlineId], observedUntil[onlineId] = body, now + ttl
        local owner = owners[onlineId]
        if owner then reconcile(entries[owner], now) end
        return true
    end

    function client.Resolve(npcId, incarnation, now)
        local entry = entries[tostring(npcId)]
        if not entry or entry.incarnation ~= tostring(incarnation)
            or entry.expires <= now or entry.operation ~= "bind"
        then return nil end
        local body = bodies[entry.npcId]
        if not body or observed[entry.onlineId] ~= body then return nil end
        if options.isValid and not options.isValid(body, entry) then
            release(entry)
            owners[entry.onlineId] = entry.npcId
            return nil
        end
        return body
    end

    function client.Sweep(now)
        for id, entry in pairs(entries) do
            if entry.expires <= now then
                release(entry)
                retiredRevision = math.max(retiredRevision, entry.revision)
                entries[id] = nil
                count = count - 1
            end
        end
        for id, untilAt in pairs(observedUntil) do
            if untilAt <= now or not observed[id] then
                observed[id], observedUntil[id] = nil, nil
                observedCount = observedCount - 1
            end
        end
    end
    function client.Reset()
        for _, entry in pairs(entries) do release(entry) end
        reset()
    end
    function client.Counts() return count, observedCount end
    return client
end
return Binding
