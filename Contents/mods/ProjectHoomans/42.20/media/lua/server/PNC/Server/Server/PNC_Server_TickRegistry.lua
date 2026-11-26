-- Ordered, idle-aware pump registry executed inside Server.OnTick.
--
-- Consolidates standalone `Events.OnTick.Add` listeners into deterministic
-- `prepare` / `finish` phases with per-pump interval gating, idle fast-skip,
-- and ScalingDiagnostics profiler visibility.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Server = PNC.Server or {}
PNC.Server.TickRegistry = PNC.Server.TickRegistry or {}

local Registry = PNC.Server.TickRegistry

Registry.VERSION = 1
Registry.Pumps = Registry.Pumps or {}
Registry.Order = Registry.Order or { prepare = {}, finish = {} }
Registry._dirty = Registry._dirty or { prepare = false, finish = false }

local function normalizePhase(phase)
    phase = string.lower(tostring(phase or "finish"))
    if phase == "prepare" then return "prepare" end
    return "finish"
end

local function rebuildOrder(phase)
    local list = {}
    for _, entry in pairs(Registry.Pumps) do
        if entry.phase == phase then
            list[#list + 1] = entry
        end
    end
    table.sort(list, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return left.id < right.id
    end)
    Registry.Order[phase] = list
    Registry._dirty[phase] = false
    return list
end

function Registry.Register(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table" or type(spec.pump) ~= "function" then
        return false, "INVALID_TICK_PUMP"
    end
    local previous = Registry.Pumps[id]
    if previous then
        Registry._dirty[previous.phase] = true
    end
    local phase = normalizePhase(spec.phase)
    local entry = {
        id = id,
        phase = phase,
        priority = tonumber(spec.priority) or 100,
        intervalMs = math.max(0, tonumber(spec.intervalMs) or 0),
        isIdle = type(spec.isIdle) == "function" and spec.isIdle or nil,
        pump = spec.pump,
        lastRunAt = nil,
    }
    Registry.Pumps[id] = entry
    Registry._dirty[phase] = true
    return true, entry
end

function Registry.Unregister(id)
    id = tostring(id or "")
    local existing = Registry.Pumps[id]
    if not existing then return false end
    Registry.Pumps[id] = nil
    Registry._dirty[existing.phase] = true
    return true
end

function Registry.List(phase)
    if phase ~= nil then
        phase = normalizePhase(phase)
        if Registry._dirty[phase] then rebuildOrder(phase) end
        local src = Registry.Order[phase] or {}
        local out = {}
        for i = 1, #src do out[i] = src[i].id end
        return out
    end
    local out = {}
    for id, _ in pairs(Registry.Pumps) do out[#out + 1] = id end
    table.sort(out)
    return out
end

function Registry.PumpPhase(phase, now, runner)
    phase = normalizePhase(phase)
    if Registry._dirty[phase] then rebuildOrder(phase) end
    local list = Registry.Order[phase]
    if not list or #list == 0 then return 0 end
    now = tonumber(now) or 0
    local executed = 0
    for index = 1, #list do
        local entry = list[index]
        local skip = false
        if entry.isIdle then
            local okIdle, idle = pcall(entry.isIdle)
            if okIdle and idle == true then skip = true end
        end
        if not skip and entry.intervalMs > 0 and entry.lastRunAt ~= nil
            and now - entry.lastRunAt < entry.intervalMs
        then
            skip = true
        end
        if not skip then
            entry.lastRunAt = now
            if type(runner) == "function" then
                runner("tick_registry." .. entry.id, entry.pump, now)
            else
                entry.pump(now)
            end
            executed = executed + 1
        end
    end
    return executed
end

return Registry
