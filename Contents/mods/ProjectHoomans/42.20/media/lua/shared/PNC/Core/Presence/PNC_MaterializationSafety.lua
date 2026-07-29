--[[
    PNC Materialization Safety
    Keeps abstract NPCs bodyless while their destination chunk is streaming,
    then resolves a conservative world square before Presence creates a body.
]]

PNC = PNC or {}
PNC.MaterializationSafety = PNC.MaterializationSafety or {}

local Safety = PNC.MaterializationSafety
local Const = PNC.Const
local Core = PNC.Core

local function getSquare(cell, x, y, z)
    if not cell or not cell.getGridSquare then
        return nil
    end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

local function getChunk(square)
    if not square or not square.getChunk then
        return nil
    end
    return square:getChunk()
end

local function chunkIsReady(chunk)
    if not chunk then
        return false
    end
    -- IsoChunk.loaded is a public Build 42 field. Treat an unavailable field
    -- as compatible/ready so older point releases still use the settle gate.
    return chunk.loaded ~= false
end

local function neighborhoodIsLoaded(cell, x, y, z)
    local radius = math.max(
        0,
        math.floor(tonumber(Const.MATERIALIZE_NEIGHBOR_RADIUS) or 1)
    )
    local dx
    local dy
    for dx = -radius, radius do
        for dy = -radius, radius do
            if not getSquare(cell, x + dx, y + dy, z) then
                return false
            end
        end
    end
    return true
end

local function stageKey(x, y, z)
    -- Project Zomboid chunks are 10x10 world squares. Key the settle window
    -- by coordinates instead of the Java IsoChunk wrapper: Kahlua may expose
    -- a different userdata wrapper on consecutive calls, and an abstract
    -- traveller may legitimately move between squares while the chunk settles.
    return tostring(math.floor((tonumber(x) or 0) / 10))
        .. ":" .. tostring(math.floor((tonumber(y) or 0) / 10))
        .. ":" .. tostring(math.floor(tonumber(z) or 0))
end

local function markStage(record, key, now)
    local runtime = record.runtime
    local stage = runtime.materializationSafety
    if not stage or stage.key ~= key then
        stage = {
            key = key,
            readySince = now,
        }
        runtime.materializationSafety = stage
    end
    -- Keep the handoff position current without restarting the readiness
    -- timer while abstract travel continues inside this chunk.
    stage.probeX = record.x
    stage.probeY = record.y
    stage.probeZ = record.z
    stage.lastCheckedAt = now
    return stage
end

function Safety.Reset(record)
    if not record or not record.runtime then
        return
    end
    record.runtime.materializationSafety = nil
    record.runtime.materializationDeferredReason = nil
end

function Safety.Defer(record, reason, now)
    local retryMs = math.max(
        50,
        math.floor(tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
    )
    local retryAt
    if not record then
        return
    end
    record.runtime = record.runtime or {}
    record.runtime.materializationDeferredReason = tostring(reason or "chunk_loading")
    retryAt = (tonumber(now) or Core.Now()) + retryMs
    record.runtime.materializeRetryAt = retryAt
    -- A deferred materialization is its own scheduled lifecycle operation.
    -- Do not depend solely on the periodic nearby-NPC scan to rediscover it.
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", retryAt)
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(record, retryAt)
    end
end

function Safety.Resolve(record, now, cell, options)
    local query = PNC.TraversalQuery
    local square
    local chunk
    local key
    local stage
    local settleMs
    local safeX
    local safeY
    local safeZ
    local recoveryReason
    local safeSquare
    local safeChunk

    if not record then
        return nil, nil, nil, nil, "missing_record"
    end
    record.runtime = record.runtime or {}
    now = tonumber(now) or Core.Now()
    cell = cell or (getCell and getCell() or nil)
    if not cell or not query or not query.FindNearestMaterializationSquare then
        return nil, nil, nil, nil, "world_unavailable"
    end

    square = getSquare(cell, record.x, record.y, record.z)
    if not square then
        record.runtime.materializationSafety = nil
        return nil, nil, nil, nil, "target_square_loading"
    end
    chunk = getChunk(square)
    if square.getChunk and not chunk then
        record.runtime.materializationSafety = nil
        return nil, nil, nil, nil, "target_chunk_loading"
    end
    if chunk and not chunkIsReady(chunk) then
        record.runtime.materializationSafety = nil
        return nil, nil, nil, nil, "target_chunk_loading"
    end
    if not neighborhoodIsLoaded(cell, record.x, record.y, record.z) then
        record.runtime.materializationSafety = nil
        return nil, nil, nil, nil, "target_neighborhood_loading"
    end

    key = stageKey(record.x, record.y, record.z)
    stage = markStage(record, key, now)
    settleMs = math.max(
        0,
        math.floor(tonumber(Const.MATERIALIZE_CHUNK_SETTLE_MS) or 1000)
    )
    if (not options or options.requireSettle ~= false)
        and now - (tonumber(stage.readySince) or now) < settleMs
    then
        return nil, nil, nil, nil, "target_chunk_settling"
    end

    safeX, safeY, safeZ, recoveryReason =
        query.FindNearestMaterializationSquare(
            stage.probeX,
            stage.probeY,
            stage.probeZ,
            tonumber(Const.MATERIALIZE_SAFE_RADIUS) or 8,
            cell
        )
    if safeX == nil or safeY == nil or safeZ == nil then
        return nil, nil, nil, recoveryReason, "no_safe_square"
    end

    safeSquare = getSquare(cell, safeX, safeY, safeZ)
    safeChunk = getChunk(safeSquare)
    if not safeSquare
        or (safeSquare.getChunk and not safeChunk)
        or (safeChunk and not chunkIsReady(safeChunk))
        or not neighborhoodIsLoaded(cell, safeX, safeY, safeZ)
    then
        return nil, nil, nil, recoveryReason, "safe_square_loading"
    end

    record.runtime.materializationDeferredReason = nil
    return safeX, safeY, safeZ, recoveryReason, nil
end
