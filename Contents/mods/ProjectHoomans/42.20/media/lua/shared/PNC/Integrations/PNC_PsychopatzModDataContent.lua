PNC = PNC or {}
PNC.ModDataProfilerContent = PNC.ModDataProfilerContent or {}

local Content = PNC.ModDataProfilerContent
-- This content is embedded in the profiler's once-per-second JSON snapshot.
-- Keep the live inspector useful without serializing an entire settlement on
-- the game thread. Live records sort first; explicit scans still report the
-- total record count and truncation state.
local MAX_NPCS = 12
local MAX_ROSTER = 100
local MAX_NODES = 120
local MAX_DEPTH = 6
local MAX_STRING = 120

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

local function selectedIDMap(values)
    local selected = {}
    for _, value in ipairs(values or {}) do selected[tostring(value)] = true end
    return selected
end

local function captureRecord(entry)
    local record = entry.record
    local runtimeContent, runtimeStats = capture(record)
    local storageKey = PNC.Registry and PNC.Registry.StorageKeyForID
        and PNC.Registry.StorageKeyForID(entry.id) or nil
    local persisted = storageKey and ModData and ModData.get and ModData.get(storageKey) or nil
    local persistedContent, persistedStats = capture(persisted)
    local inventory = record and record.inventory or nil
    return {
        id = entry.id,
        name = entry.name,
        tacticalClass = tostring(record and record.tacticalClass or "unknown"),
        presence = tostring(record and record.presenceState or "unknown"),
        inventoryItems = countMap(inventory and inventory.items),
        wornItems = countMap(inventory and inventory.worn),
        equippedItems = countMap(inventory and inventory.equipped),
        attachedItems = countMap(inventory and inventory.attached),
        inventoryContainers = countMap(inventory and inventory.containers),
        runtimeEstimatedBytes = runtimeStats.estimatedBytes,
        persistedEstimatedBytes = persistedStats.estimatedBytes,
        runtimeTruncated = runtimeStats.truncated,
        persistedTruncated = persistedStats.truncated,
        runtimeContent = runtimeContent,
        persistedContent = persistedContent,
    }
end

function Content.Scan(options)
    local explicitOptions = options ~= nil
    options = options or {}
    if not explicitOptions then options.scope = "all_bounded" end
    local source = PNC.Registry and PNC.Registry.Data or {}
    local ordered = {}
    for id, record in pairs(source) do
        ordered[#ordered + 1] = {
            id = tostring(id),
            name = recordName(record),
            record = record,
            live = record and record.presenceState == "live",
        }
    end
    table.sort(ordered, function(left, right)
        if left.live ~= right.live then return left.live == true end
        if left.name == right.name then return left.id < right.id end
        return left.name < right.name
    end)
    local output = { totalRecords = #ordered, records = {}, roster = {} }
    local rosterLimit = math.min(#ordered, MAX_ROSTER)
    for index = 1, rosterLimit do
        local entry = ordered[index]
        local record = entry.record
        local inventory = record and record.inventory or nil
        output.roster[#output.roster + 1] = {
            id = entry.id,
            name = entry.name,
            tacticalClass = tostring(record and record.tacticalClass or "unknown"),
            presence = tostring(record and record.presenceState or "unknown"),
            inventoryItems = countMap(inventory and inventory.items),
            wornItems = countMap(inventory and inventory.worn),
            equippedItems = countMap(inventory and inventory.equipped),
            attachedItems = countMap(inventory and inventory.attached),
            inventoryContainers = countMap(inventory and inventory.containers),
        }
    end
    output.rosterTruncated = #ordered > MAX_ROSTER
    local selected = selectedIDMap(options.ids)
    for index = 1, #ordered do
        local entry = ordered[index]
        if options.scope == "all_bounded" or selected[entry.id] then
            output.records[#output.records + 1] = captureRecord(entry)
            if #output.records >= MAX_NPCS then break end
        end
    end
    output.truncated = options.scope == "all_bounded" and #ordered > MAX_NPCS or false
    output.capturedRecords = #output.records
    output.limits = { maxNPCs = MAX_NPCS, maxRoster = MAX_ROSTER, maxNodesPerView = MAX_NODES,
        maxDepth = MAX_DEPTH, maxString = MAX_STRING }
    return output
end

return Content
