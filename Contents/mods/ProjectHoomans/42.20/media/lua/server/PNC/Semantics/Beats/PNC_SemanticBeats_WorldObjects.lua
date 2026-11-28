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

function Beats.GetObjectHookAuditEntries(at)
    local now = nowMs(at)
    local out = {}
    for i = 1, #objectHookList do
        local h = objectHookList[i]
        local untilAt = tonumber(objectHookCooldowns[h.id]) or 0
        out[i] = {
            id = h.id,
            priority = h.priority,
            cooldownMs = h.cooldownMs,
            cooldownRemainingMs = math.max(0, untilAt - now),
        }
    end
    return out
end

function Beats.GetDeviceHookAuditEntries(at)
    local now = nowMs(at)
    local out = {}
    for i = 1, #deviceHookList do
        local h = deviceHookList[i]
        local untilAt = tonumber(deviceHookCooldowns[h.id]) or 0
        out[i] = {
            id = h.id,
            priority = h.priority,
            cooldownMs = h.cooldownMs,
            cooldownRemainingMs = math.max(0, untilAt - now),
        }
    end
    return out
end

function Beats.GetWorldObjectAuditState(at)
    local now = nowMs(at)
    return {
        nextObjectScanRemainingMs = math.max(0, nextObjectScanAt - now),
        globalCooldownRemainingMs = math.max(0, globalObjectBeatCooldownUntil - now),
        deviceTextBucketCount = deviceTextBucketCount,
    }
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
    -- Skip world-object banter scans for off-screen NPCs (> 16 tiles from players).
    local nearestDistSq = anchor.runtime and tonumber(anchor.runtime.nearestPlayerDistSq) or nil
    if nearestDistSq ~= nil and nearestDistSq > (16 * 16) then
        return false
    end
    local ctx = buildContext(anchor, partner, now)
    local worldCtx = PNC and PNC.WorldItemContext
    local inspectedObjects = 0
    local MAX_INSPECTED_OBJECTS = 128

    local function checkObject(obj, sq, distSq)
        if not obj or inspectedObjects >= MAX_INSPECTED_OBJECTS then return nil end
        inspectedObjects = inspectedObjects + 1
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

    local function inspectSquare(dx, dy)
        local distSq = dx * dx + dy * dy
        if worldCtx and worldCtx.GetSquareSnapshot then
            local snap = worldCtx.GetSquareSnapshot(cell, ax + dx, ay + dy, az, now)
            if snap and snap.square then
                local objs = snap.objects or {}
                for oi = 1, #objs do
                    local hitId = checkObject(objs[oi], snap.square, distSq)
                    if hitId then return hitId end
                    if inspectedObjects >= MAX_INSPECTED_OBJECTS then return nil end
                end
            end
        else
            local sq = safeCall(cell, "getGridSquare", ax + dx, ay + dy, az)
            if sq then
                local objs, n = countAndGetObjects(sq)
                for oi = 1, n do
                    local hitId = checkObject(objectAt(objs, oi), sq, distSq)
                    if hitId then return hitId end
                    if inspectedObjects >= MAX_INSPECTED_OBJECTS then return nil end
                end
            end
        end
        return nil
    end

    local hit0 = inspectSquare(0, 0)
    if hit0 then return true, hit0 end
    for ring = 1, OBJECT_SCAN_RADIUS do
        if inspectedObjects >= MAX_INSPECTED_OBJECTS then break end
        for d = -ring, ring do
            local h1 = inspectSquare(d, -ring)
            if h1 then return true, h1 end
            local h2 = inspectSquare(d, ring)
            if h2 then return true, h2 end
            if d > -ring and d < ring then
                local h3 = inspectSquare(-ring, d)
                if h3 then return true, h3 end
                local h4 = inspectSquare(ring, d)
                if h4 then return true, h4 end
            end
            if inspectedObjects >= MAX_INSPECTED_OBJECTS then break end
        end
    end
    return false
end

local function isDeviceBucketDebounced(x, y, now)
    local key = tostring(math.floor(x / 6)) .. ":" .. tostring(math.floor(y / 6))
    local last = deviceTextBuckets[key]
    return last ~= nil and now >= last and (now - last) < DEVICE_TEXT_DEBOUNCE_MS
end

local function markDeviceBucket(x, y, now)
    local key = tostring(math.floor(x / 6)) .. ":" .. tostring(math.floor(y / 6))
    local last = deviceTextBuckets[key]
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

local function resolveDevicePosition(x, y, z, device)
    local nx, ny, nz = tonumber(x), tonumber(y), tonumber(z) or 0
    -- WaveSignalDevice.AddDeviceText passes (-1, -1, -1) for handheld and car radios.
    if (not nx or not ny) or (nx == -1 and ny == -1) then
        local vx, vy, vz = nil, nil, nil
        if device then
            local veh = safeCall(device, "getVehicle")
            if veh then
                vx = tonumber(safeCall(veh, "getX"))
                vy = tonumber(safeCall(veh, "getY"))
                vz = tonumber(safeCall(veh, "getZ")) or 0
            else
                local dx = tonumber(safeCall(device, "getX"))
                local dy = tonumber(safeCall(device, "getY"))
                if dx and dy and not (dx == -1 and dy == -1) then
                    vx, vy, vz = dx, dy, tonumber(safeCall(device, "getZ")) or 0
                end
            end
        end
        if not vx or not vy then
            local core = PNC.Core
            if core and type(core.ForEachPlayer) == "function" then
                core.ForEachPlayer(function(p)
                    if vx or not p then return end
                    local px = p.getX and tonumber(p:getX())
                    local py = p.getY and tonumber(p:getY())
                    if px and py then
                        vx, vy = px, py
                        vz = p.getZ and tonumber(p:getZ()) or 0
                    end
                end)
            end
        end
        nx, ny, nz = vx, vy, vz or 0
    end
    return nx, ny, nz
end

function Beats.OnDeviceTextEvent(guid, codes, x, y, z, line, device, now)
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    if #deviceHookList == 0 or device == nil then
        return false, "device_text_unhandled"
    end
    local text = tostring(line or "")
    if text == "" then
        return false, "device_text_empty"
    end
    local nx, ny, nz = resolveDevicePosition(x, y, z, device)
    if not nx or not ny then
        if audit then
            Beats.AuditLog("device_text", { "ok=false", "reason=device_text_position_missing" })
        end
        return false, "device_text_position_missing"
    end
    now = nowMs(now)
    -- Award player-parity media XP on every unique skill-code line before
    -- dialogue debouncing so companions learn from TV/VHS just like the player.
    if type(codes) == "string" and codes ~= ""
        and type(Beats.AwardNearbyCompanionMediaXP) == "function"
    then
        Beats.AwardNearbyCompanionMediaXP(guid, codes, nx, ny, nz, device, text)
    end
    if isDeviceBucketDebounced(nx, ny, now) then
        return false, "device_text_debounced"
    end

    local anchor, partner, third, fourth, teamKey = nil, nil, nil, nil, nil
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if type(Beats.FindCalmGroupsNearPoint) == "function" then
        local groups = Beats.FindCalmGroupsNearPoint(nx, ny, DEVICE_TEXT_RADIUS, now, 1)
        if type(groups) == "table" and groups[1] and type(groups[1].members) == "table" then
            local m = groups[1].members
            if Dir and type(Dir.ResolveVoiceProfile) == "function" and #m > 1 then
                local sorted = {}
                for mi = 1, #m do sorted[mi] = m[mi] end
                table.sort(sorted, function(m1, m2)
                    local c1 = Dir.ResolveVoiceProfile(m1, now).chattiness or 1.0
                    local c2 = Dir.ResolveVoiceProfile(m2, now).chattiness or 1.0
                    if c1 ~= c2 then return c1 > c2 end
                    return tostring(m1.id or "") < tostring(m2.id or "")
                end)
                m = sorted
            end
            teamKey = groups[1].teamKey
            anchor, partner, third, fourth = m[1], m[2], m[3], m[4]
        end
    end
    if not anchor and type(Beats.FindCalmSpeakerNearPoint) == "function" then
        anchor, partner = Beats.FindCalmSpeakerNearPoint(nx, ny, DEVICE_TEXT_RADIUS, now)
    end
    -- Fallback: if squad has an active skirmish flag from a teammate outside,
    -- still allow a nearby non-fighting NPC standing by the TV/radio to react.
    if not anchor and PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function" then
        local nearList = PNC.SpatialIndex.QueryNPCs(nx, ny, DEVICE_TEXT_RADIUS) or {}
        local idle = {}
        for i = 1, #nearList do
            local r = nearList[i]
            local rt = type(r) == "table" and type(r.runtime) == "table" and r.runtime or nil
            if type(r) == "table" and r.alive ~= false and r.id ~= nil
                and (not rt or (rt.target == nil and rt.attackAction == nil))
            then
                idle[#idle + 1] = r
            end
        end
        if #idle > 0 then
            if Dir and type(Dir.ResolveVoiceProfile) == "function" and #idle > 1 then
                table.sort(idle, function(m1, m2)
                    local c1 = Dir.ResolveVoiceProfile(m1, now).chattiness or 1.0
                    local c2 = Dir.ResolveVoiceProfile(m2, now).chattiness or 1.0
                    if c1 ~= c2 then return c1 > c2 end
                    return tostring(m1.id or "") < tostring(m2.id or "")
                end)
            end
            anchor, partner, third, fourth = idle[1], idle[2], idle[3], idle[4]
            local perc = PNC.Perception
            teamKey = tostring((perc and perc.GetTeamKey and perc.GetTeamKey(anchor)) or anchor.id)
        end
    end
    if not anchor then
        if audit then
            Beats.AuditLog("device_text", {
                "x=" .. tostring(math.floor(nx)),
                "y=" .. tostring(math.floor(ny)),
                "ok=false",
                "reason=no_calm_speaker",
            })
        end
        return false, "no_calm_speaker"
    end

    local ctx = buildContext(anchor, partner, now)
    ctx.third = third
    ctx.fourth = fourth
    ctx.teamKey = teamKey
    for i = 1, #deviceHookList do
        local h = deviceHookList[i]
        if now >= (tonumber(deviceHookCooldowns[h.id]) or 0) then
            local okM, matched = pcall(h.matches, device, text, nx, ny, nz, anchor, ctx, codes, guid)
            if okM and matched == true then
                local okE, plan = pcall(h.evaluate, device, text, nx, ny, nz, anchor, partner, ctx, codes, guid)
                if okE and type(plan) == "table" and (plan.opening or plan.replies) then
                    markDeviceBucket(nx, ny, now)
                    deviceHookCooldowns[h.id] = now + h.cooldownMs
                    local tid, openOk = Beats.StartThread(plan, now, ctx)
                    if audit then
                        Beats.AuditLog("device_text", {
                            "hook=" .. tostring(h.id),
                            "anchor=" .. tostring(anchor.id or ""),
                            "threadID=" .. tostring(tid or "nil"),
                            "openingDelivered=" .. tostring(openOk == true),
                            "ok=true",
                        })
                    end
                    return true, h.id
                end
            end
        end
    end
    if audit then
        Beats.AuditLog("device_text", {
            "x=" .. tostring(math.floor(nx)),
            "y=" .. tostring(math.floor(ny)),
            "anchor=" .. tostring(anchor.id or ""),
            "ok=false",
            "reason=no_matching_device_hook",
        })
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
