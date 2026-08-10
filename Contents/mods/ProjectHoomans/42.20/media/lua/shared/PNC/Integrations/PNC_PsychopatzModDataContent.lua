PNC = PNC or {}
PNC.ModDataProfilerContent = PNC.ModDataProfilerContent or {}

local Content = PNC.ModDataProfilerContent
local MAX_NPCS = 50
local MAX_NODES = 500
local MAX_DEPTH = 8
local MAX_STRING = 160

local function countMap(values)
    local count = 0
    for _, _ in pairs(values or {}) do count = count + 1 end
    return count
end

local function boundedCopy(value, state, depth)
    if state.nodes >= MAX_NODES then state.truncated = true return "<node-limit>" end
    state.nodes = state.nodes + 1
    local kind = type(value)
    if kind == "string" then
        state.estimatedBytes = state.estimatedBytes + #value + 2
        if #value > MAX_STRING then return string.sub(value, 1, MAX_STRING) .. "..." end
        return value
    end
    if kind == "number" then state.estimatedBytes = state.estimatedBytes + 8 return value end
    if kind == "boolean" then state.estimatedBytes = state.estimatedBytes + 1 return value end
    if kind == "nil" then return nil end
    if kind ~= "table" then
        state.estimatedBytes = state.estimatedBytes + 16
        return "<" .. kind .. ">"
    end
    if state.visited[value] then return "<cycle>" end
    if depth >= MAX_DEPTH then state.truncated = true return "<depth-limit>" end
    state.visited[value] = true
    state.estimatedBytes = state.estimatedBytes + 2
    local output = {}
    for key, child in pairs(value) do
        if state.nodes >= MAX_NODES then state.truncated = true break end
        local safeKey = tostring(key)
        state.estimatedBytes = state.estimatedBytes + #safeKey + 2
        output[safeKey] = boundedCopy(child, state, depth + 1)
    end
    return output
end

local function capture(value)
    local state = { nodes = 0, estimatedBytes = 0, truncated = false, visited = {} }
    local copied = boundedCopy(value, state, 0)
    state.visited = nil
    return copied, state
end

local function recordName(record)
    local identity = record and record.identity or nil
    return tostring(record and (record.name or record.displayName)
        or identity and identity.displayName or "Unknown NPC")
end

function Content.Scan()
    local source = PNC.Registry and PNC.Registry.Data or {}
    local ordered = {}
    for id, record in pairs(source) do
        ordered[#ordered + 1] = { id = tostring(id), name = recordName(record), record = record }
    end
    table.sort(ordered, function(left, right)
        if left.name == right.name then return left.id < right.id end
        return left.name < right.name
    end)
    local output = { totalRecords = #ordered, truncated = #ordered > MAX_NPCS, records = {} }
    local limit = math.min(#ordered, MAX_NPCS)
    for index = 1, limit do
        local entry = ordered[index]
        local record = entry.record
        local runtimeContent, runtimeStats = capture(record)
        local storageKey = PNC.Registry and PNC.Registry.StorageKeyForID
            and PNC.Registry.StorageKeyForID(entry.id) or nil
        local persisted = storageKey and ModData and ModData.get and ModData.get(storageKey) or nil
        local persistedContent, persistedStats = capture(persisted)
        output.records[#output.records + 1] = {
            id = entry.id,
            name = entry.name,
            faction = tostring(record and record.faction or "unknown"),
            presence = tostring(record and record.presenceState or "unknown"),
            inventoryItems = countMap(record and record.inventory and record.inventory.items),
            runtimeEstimatedBytes = runtimeStats.estimatedBytes,
            persistedEstimatedBytes = persistedStats.estimatedBytes,
            runtimeTruncated = runtimeStats.truncated,
            persistedTruncated = persistedStats.truncated,
            runtimeContent = runtimeContent,
            persistedContent = persistedContent,
        }
    end
    output.limits = { maxNPCs = MAX_NPCS, maxNodesPerView = MAX_NODES,
        maxDepth = MAX_DEPTH, maxString = MAX_STRING }
    return output
end

return Content
