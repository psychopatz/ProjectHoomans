PNC = PNC or {}
PNC.ModDataProfiler = PNC.ModDataProfiler or {}

local Analyzer = PNC.ModDataProfiler
local Profiler = PsychopatzCore and PsychopatzCore.Profiler

if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning() then
    return Analyzer
end

local MAX_NODES = 25000
local MAX_DEPTH = 12
local MAX_TOP_PATHS = 30
local SCAN_INTERVAL_MS = 10000

local function countMap(values)
    local count = 0
    for _, _ in pairs(values or {}) do count = count + 1 end
    return count
end

local function pathSegment(key)
    if type(key) == "number" then return "[]" end
    local value = tostring(key or "")
    local lower = string.lower(value)
    if string.match(lower, "^item_%d+$")
        or string.match(lower, "^pnc_[%w_]+_%d+_")
        or #value > 32
    then
        return "[id]"
    end
    value = string.gsub(value, "[^%w_%-]", "_")
    if #value > 40 then value = string.sub(value, 1, 40) .. "~" end
    return value
end

local function rootName(name)
    name = tostring(name or "")
    if string.sub(name, 1, 8) == "PNC_NPC_" then return "PNC_NPC_*" end
    return pathSegment(name)
end

local function childSegment(path, key)
    if path == "Registry_Data" or string.match(path, "%.records$") then return "[record]" end
    if string.match(path, "%.items$") and type(key) ~= "number" then return "[item]" end
    return pathSegment(key)
end

local function newStats()
    return {
        estimatedBytes = 0, nodes = 0, tables = 0, entries = 0,
        strings = 0, stringBytes = 0, numbers = 0, booleans = 0,
        otherValues = 0, cycles = 0, maxDepth = 0, truncated = false,
        pathBytes = {}, roots = {}, visited = {},
    }
end

local function scalarBytes(value)
    local kind = type(value)
    if kind == "string" then return #value + 2 end
    if kind == "number" then return 8 end
    if kind == "boolean" then return 1 end
    if kind == "nil" then return 0 end
    return #tostring(value) + 2
end

local function walk(stats, value, path, depth)
    if stats.nodes >= MAX_NODES then
        stats.truncated = true
        return 0
    end
    stats.nodes = stats.nodes + 1
    if depth > stats.maxDepth then stats.maxDepth = depth end
    local kind = type(value)
    if kind == "string" then
        stats.strings = stats.strings + 1
        stats.stringBytes = stats.stringBytes + #value
        return scalarBytes(value)
    end
    if kind == "number" then stats.numbers = stats.numbers + 1 return 8 end
    if kind == "boolean" then stats.booleans = stats.booleans + 1 return 1 end
    if kind ~= "table" then stats.otherValues = stats.otherValues + 1 return scalarBytes(value) end
    if stats.visited[value] then stats.cycles = stats.cycles + 1 return 0 end
    if depth >= MAX_DEPTH then stats.truncated = true return 0 end
    stats.visited[value] = true
    stats.tables = stats.tables + 1
    local bytes = 2
    for key, child in pairs(value) do
        if stats.nodes >= MAX_NODES then stats.truncated = true break end
        stats.entries = stats.entries + 1
        local childPath = path .. "." .. childSegment(path, key)
        local childBytes = walk(stats, child, childPath, depth + 1)
        bytes = bytes + scalarBytes(key) + childBytes + 2
        stats.pathBytes[childPath] = (stats.pathBytes[childPath] or 0) + childBytes
    end
    return bytes
end

local function addRoot(stats, name, value)
    local normalized = rootName(name)
    local bytes = walk(stats, value, normalized, 0)
    stats.estimatedBytes = stats.estimatedBytes + bytes
    local root = stats.roots[normalized] or { name = normalized, estimatedBytes = 0, instances = 0 }
    root.estimatedBytes = root.estimatedBytes + bytes
    root.instances = root.instances + 1
    stats.roots[normalized] = root
end

local function compactStats(stats)
    local paths = {}
    local roots = {}
    for path, bytes in pairs(stats.pathBytes) do
        paths[#paths + 1] = { path = path, estimatedBytes = bytes }
    end
    table.sort(paths, function(left, right)
        if left.estimatedBytes == right.estimatedBytes then return left.path < right.path end
        return left.estimatedBytes > right.estimatedBytes
    end)
    while #paths > MAX_TOP_PATHS do table.remove(paths) end
    for _, root in pairs(stats.roots) do roots[#roots + 1] = root end
    table.sort(roots, function(left, right)
        if left.estimatedBytes == right.estimatedBytes then return left.name < right.name end
        return left.estimatedBytes > right.estimatedBytes
    end)
    return {
        estimatedBytes = stats.estimatedBytes, nodes = stats.nodes,
        tables = stats.tables, entries = stats.entries, strings = stats.strings,
        stringBytes = stats.stringBytes, numbers = stats.numbers,
        booleans = stats.booleans, otherValues = stats.otherValues,
        cycles = stats.cycles, maxDepth = stats.maxDepth,
        truncated = stats.truncated, roots = roots, topPaths = paths,
    }
end

local function eachModDataName(callback)
    local names = ModData and ModData.getTableNames and ModData.getTableNames() or nil
    if not names then return end
    if names.size and names.get then
        for index = 0, names:size() - 1 do callback(tostring(names:get(index))) end
        return
    end
    for _, name in pairs(names) do callback(tostring(name)) end
end

local function scanPersisted()
    local stats = newStats()
    local count = 0
    eachModDataName(function(name)
        if string.sub(name, 1, 4) == "PNC_" then
            count = count + 1
            addRoot(stats, name, ModData.get(name))
        end
    end)
    local result = compactStats(stats)
    result.modDataTables = count
    return result
end

local function scanRuntimeRecords()
    local stats = newStats()
    addRoot(stats, "Registry.Data", PNC.Registry and PNC.Registry.Data or {})
    local result = compactStats(stats)
    result.recordCount = countMap(PNC.Registry and PNC.Registry.Data)
    return result
end

local function scanInventories()
    local stats = newStats()
    local records, items, containers, operationLogEntries = 0, 0, 0, 0
    for _, record in pairs(PNC.Registry and PNC.Registry.Data or {}) do
        local inventory = record and record.inventory or nil
        if type(inventory) == "table" then
            records = records + 1
            items = items + countMap(inventory.items)
            containers = containers + countMap(inventory.containers)
            addRoot(stats, "Inventory", inventory)
        end
        local runtime = record and record.runtime and record.runtime.inventory or nil
        if type(runtime) == "table" then
            operationLogEntries = operationLogEntries + #(runtime.opLog or {})
            addRoot(stats, "InventoryRuntime", runtime)
        end
    end
    local result = compactStats(stats)
    result.recordCount = records
    result.itemCount = items
    result.containerCount = containers
    result.operationLogEntries = operationLogEntries
    return result
end

local function nowMs()
    return getTimeInMillis and getTimeInMillis() or 0
end

function Analyzer.Scan(force)
    local now = nowMs()
    if not force and Analyzer.lastReport
        and now - (Analyzer.lastScanAt or 0) < SCAN_INTERVAL_MS
    then
        return Analyzer.lastReport
    end
    local started = now
    local report = {
        reportVersion = 1,
        capturedAtMs = now,
        estimateMethod = "bounded_lua_shape_v1",
        valuesRedacted = true,
        limits = { maxNodesPerSection = MAX_NODES, maxDepth = MAX_DEPTH, topPaths = MAX_TOP_PATHS },
        persisted = scanPersisted(),
        runtimeRecords = scanRuntimeRecords(),
        inventories = scanInventories(),
    }
    report.scanMs = math.max(0, nowMs() - started)
    Analyzer.lastReport = report
    Analyzer.lastScanAt = now
    return report
end

Profiler.RegisterSnapshotProvider("ProjectHoomans.modData", function()
    return Analyzer.Scan(false)
end)

return Analyzer
