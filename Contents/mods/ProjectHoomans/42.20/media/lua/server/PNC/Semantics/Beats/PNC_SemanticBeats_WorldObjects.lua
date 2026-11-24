-- Extensible registry for world-object vicinity and OnDeviceText semantic beats.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local OBJECT_SCAN_INTERVAL_MS = 15000
local GLOBAL_OBJECT_BEAT_COOLDOWN_MS = 45000
local OBJECT_SCAN_RADIUS = 3
local DEVICE_TEXT_DEBOUNCE_MS = 8000
local DEVICE_TEXT_RADIUS = 12
local MAX_DEVICE_BUCKETS = 32

local objectHooksById = {}
local objectHookList = {}
local objectHookCooldowns = {}

local deviceHooksById = {}
local deviceHookList = {}
local deviceHookCooldowns = {}
local deviceTextBuckets = {}
local deviceTextBucketCount = 0

local nextObjectScanAt = 0
local globalObjectBeatCooldownUntil = 0

local function rebuildSorted(byId)
    local list = {}
    for _, hook in pairs(byId) do
        list[#list + 1] = hook
    end
    table.sort(list, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        return a.id < b.id
    end)
    return list
end

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj, ...)
    if ok then return val end
    return nil
end

function Beats.RegisterObjectBeatHook(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table"
        or type(spec.matches) ~= "function"
        or type(spec.evaluate) ~= "function"
    then
        return false
    end
    objectHooksById[id] = {
        id = id,
        priority = tonumber(spec.priority) or 25,
        cooldownMs = math.max(0, tonumber(spec.cooldownMs) or 60000),
        maxDistance = math.min(OBJECT_SCAN_RADIUS, math.max(1, tonumber(spec.maxDistance) or OBJECT_SCAN_RADIUS)),
        matches = spec.matches,
        evaluate = spec.evaluate,
    }
    objectHookList = rebuildSorted(objectHooksById)
    return true
end

function Beats.UnregisterObjectBeatHook(id)
    id = tostring(id or "")
    if not objectHooksById[id] then return false end
    objectHooksById[id] = nil
    objectHookCooldowns[id] = nil
    objectHookList = rebuildSorted(objectHooksById)
    return true
end

function Beats.ListObjectBeatHooks()
    local out = {}
    for i = 1, #objectHookList do
        out[i] = objectHookList[i].id
    end
    return out
end

function Beats.RegisterDeviceTextHook(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table"
        or type(spec.matches) ~= "function"
        or type(spec.evaluate) ~= "function"
    then
        return false
    end
    deviceHooksById[id] = {
        id = id,
        priority = tonumber(spec.priority) or 35,
        cooldownMs = math.max(0, tonumber(spec.cooldownMs) or 35000),
        maxDistance = math.max(1, tonumber(spec.maxDistance) or DEVICE_TEXT_RADIUS),
        matches = spec.matches,
        evaluate = spec.evaluate,
    }
    deviceHookList = rebuildSorted(deviceHooksById)
    return true
end

function Beats.UnregisterDeviceTextHook(id)
    id = tostring(id or "")
    if not deviceHooksById[id] then return false end
    deviceHooksById[id] = nil
    deviceHookCooldowns[id] = nil
    deviceHookList = rebuildSorted(deviceHooksById)
    return true
end

function Beats.ListDeviceTextHooks()
    local out = {}
    for i = 1, #deviceHookList do
        out[i] = deviceHookList[i].id
    end
    return out
end

local function buildContext(anchor, partner, now)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if BC and type(BC.Build) == "function" then
        return BC.Build(anchor, partner, { now = now, inCombat = false })
    end
    return { now = now, actor = {}, env = {}, tokens = {} }
end

local function getCellSafe()
    if type(getCell) == "function" then
        local c = getCell()
        if c then return c end
    end
    if type(getWorld) == "function" then
        local w = getWorld()
        if w and type(w.getCell) == "function" then
            return safeCall(w, "getCell")
        end
    end
    return nil
end

local function countAndGetObjects(sq)
    local objs = safeCall(sq, "getObjects")
    if not objs then return nil, 0 end
    if type(objs.size) == "function" and type(objs.get) == "function" then
        return objs, tonumber(safeCall(objs, "size")) or 0
    end
    if type(objs) == "table" then
        return objs, #objs
    end
    return nil, 0
end

local function objectAt(objs, idx)
    if type(objs.get) == "function" then
        return safeCall(objs, "get", idx - 1)
    end
    return objs[idx]
end

function Beats.CheckNearbyWorldObjects(now)
    now = nowMs(now)
    if now < nextObjectScanAt or now < globalObjectBeatCooldownUntil then
        return false
    end
    nextObjectScanAt = now + OBJECT_SCAN_INTERVAL_MS
    if #objectHookList == 0 then
        return false
    end
    local anchor, partner = nil, nil
    if type(Beats.FindCalmSpeakerNearPlayer) == "function" then
        anchor, partner = Beats.FindCalmSpeakerNearPlayer(now)
    end
    if not anchor then
        return false
    end
    local cell = getCellSafe()
    if not cell or type(cell.getGridSquare) ~= "function" then
        return false
    end

    local activeHooks = {}
    for i = 1, #objectHookList do
        local h = objectHookList[i]
        if now >= (tonumber(objectHookCooldowns[h.id]) or 0) then
            activeHooks[#activeHooks + 1] = h
        end
    end
    if #activeHooks == 0 then
        return false
    end

    local ax = math.floor(tonumber(anchor.x) or 0)
    local ay = math.floor(tonumber(anchor.y) or 0)
    local az = math.floor(tonumber(anchor.z) or 0)
    local ctx = buildContext(anchor, partner, now)
    local worldCtx = PNC and PNC.WorldItemContext

    local function checkObject(obj, sq, distSq)
        if not obj then return nil end
        for hi = 1, #activeHooks do
            local h = activeHooks[hi]
            if distSq <= (h.maxDistance * h.maxDistance) then
                local okM, matched = pcall(h.matches, obj, sq, anchor, ctx)
                if okM and matched == true then
                    local okE, plan = pcall(h.evaluate, obj, sq, anchor, partner, ctx)
                    if okE and type(plan) == "table" and (plan.opening or plan.replies) then
                        objectHookCooldowns[h.id] = now + h.cooldownMs
                        globalObjectBeatCooldownUntil = now + GLOBAL_OBJECT_BEAT_COOLDOWN_MS
                        Beats.StartThread(plan, now, ctx)
                        return h.id
                    end
                end
            end
        end
        return nil
    end

    for dx = -OBJECT_SCAN_RADIUS, OBJECT_SCAN_RADIUS do
        for dy = -OBJECT_SCAN_RADIUS, OBJECT_SCAN_RADIUS do
            local distSq = dx * dx + dy * dy
            if worldCtx and worldCtx.GetSquareSnapshot then
                local snap = worldCtx.GetSquareSnapshot(cell, ax + dx, ay + dy, az, now)
                if snap and snap.square then
                    local objs = snap.objects or {}
                    for oi = 1, #objs do
                        local hitId = checkObject(objs[oi], snap.square, distSq)
                        if hitId then return true, hitId end
                    end
                end
            else
                local sq = safeCall(cell, "getGridSquare", ax + dx, ay + dy, az)
                if sq then
                    local objs, n = countAndGetObjects(sq)
                    for oi = 1, n do
                        local hitId = checkObject(objectAt(objs, oi), sq, distSq)
                        if hitId then return true, hitId end
                    end
                end
            end
        end
    end
    return false
end

local function markDeviceBucket(x, y, now)
    local key = tostring(math.floor(x / 6)) .. ":" .. tostring(math.floor(y / 6))
    local last = deviceTextBuckets[key]
    if last ~= nil and now >= last and (now - last) < DEVICE_TEXT_DEBOUNCE_MS then
        return false
    end
    if last == nil then
        deviceTextBucketCount = deviceTextBucketCount + 1
        if deviceTextBucketCount > MAX_DEVICE_BUCKETS then
            deviceTextBuckets = {}
            deviceTextBucketCount = 1
        end
    end
    deviceTextBuckets[key] = now
    return true
end

function Beats.OnDeviceTextEvent(guid, codes, x, y, z, line, device, now)
    if #deviceHookList == 0 or device == nil then
        return false, "device_text_unhandled"
    end
    local text = tostring(line or "")
    if text == "" then
        return false, "device_text_empty"
    end
    local nx = tonumber(x) or tonumber(safeCall(device, "getX"))
    local ny = tonumber(y) or tonumber(safeCall(device, "getY"))
    if not nx or not ny then
        return false, "device_text_position_missing"
    end
    local nz = tonumber(z) or tonumber(safeCall(device, "getZ")) or 0
    now = nowMs(now)
    if not markDeviceBucket(nx, ny, now) then
        return false, "device_text_debounced"
    end

    local anchor, partner = nil, nil
    if type(Beats.FindCalmSpeakerNearPoint) == "function" then
        anchor, partner = Beats.FindCalmSpeakerNearPoint(nx, ny, DEVICE_TEXT_RADIUS, now)
    end
    if not anchor then
        return false, "no_calm_speaker"
    end

    local ctx = buildContext(anchor, partner, now)
    for i = 1, #deviceHookList do
        local h = deviceHookList[i]
        if now >= (tonumber(deviceHookCooldowns[h.id]) or 0) then
            local okM, matched = pcall(h.matches, device, text, nx, ny, nz, anchor, ctx, codes, guid)
            if okM and matched == true then
                local okE, plan = pcall(h.evaluate, device, text, nx, ny, nz, anchor, partner, ctx, codes, guid)
                if okE and type(plan) == "table" and (plan.opening or plan.replies) then
                    deviceHookCooldowns[h.id] = now + h.cooldownMs
                    Beats.StartThread(plan, now, ctx)
                    return true, h.id
                end
            end
        end
    end
    return false, "no_matching_device_hook"
end

function Beats.ResetWorldObjectRuntime()
    nextObjectScanAt = 0
    globalObjectBeatCooldownUntil = 0
    objectHookCooldowns = {}
    deviceHookCooldowns = {}
    deviceTextBuckets = {}
    deviceTextBucketCount = 0
end

local function onDeviceText(guid, codes, x, y, z, line, device)
    Beats.OnDeviceTextEvent(guid, codes, x, y, z, line, device, nil)
end

if Events and Events.OnDeviceText and not Beats._WorldObjectDeviceTextHooked then
    Events.OnDeviceText.Add(onDeviceText)
    Beats._WorldObjectDeviceTextHooked = true
end

return Beats
