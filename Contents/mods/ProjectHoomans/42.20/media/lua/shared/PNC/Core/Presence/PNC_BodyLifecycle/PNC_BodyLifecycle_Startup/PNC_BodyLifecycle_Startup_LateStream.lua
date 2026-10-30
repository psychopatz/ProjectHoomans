-- Dedicated-server late-stream restart reconciliation.
--
-- Dedicated servers finish global startup before player-interest chunks exist.
-- Preserve one per-record restart claim and settle the saved square before a
-- replacement body may materialize.

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

if not Internal.ClassifyLateStreamCandidates then
    require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_LateStream_Candidates"
end

local function runtimeOf(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    return record.runtime
end

local function logInfo(message)
    if Core and Core.LogInfo then Core.LogInfo(message) end
end

function Lifecycle.HasLateStreamRehydrateClaim(record)
    return record
        and record.alive ~= false
        and record.runtime
        and record.runtime.lateStreamRehydrateExpected == true
        and Internal.ValidLateStreamHint(record)
        or false
end

function Lifecycle.ArmLateStreamRehydrate(record, now)
    local runtime
    if not record or record.alive == false
        or not Internal.ValidLateStreamHint(record)
    then
        return false
    end
    runtime = runtimeOf(record)
    runtime.startupRehydrateExpected = nil
    runtime.startupRehydrateMissed = nil
    runtime.lateStreamRehydrateExpected = true
    runtime.lateStreamRehydrateArmedAt =
        tonumber(now) or Core.Now()
    runtime.lateStreamRehydrateLoadedAt = nil
    runtime.lateStreamRehydrateCandidateAt = nil
    return true
end

function Lifecycle.ClearLateStreamRehydrate(record, reason, now)
    local runtime = record and record.runtime or nil
    if not runtime or runtime.lateStreamRehydrateExpected ~= true then
        return false
    end
    runtime.lateStreamRehydrateExpected = nil
    runtime.lateStreamRehydrateLoadedAt = nil
    runtime.lateStreamRehydrateCandidateAt = nil
    runtime.lateStreamRehydrateClearedAt =
        tonumber(now) or Core.Now()
    runtime.lateStreamRehydrateClearReason =
        tostring(reason or "resolved")
    return true
end

local function rebind(record, body, reason, now)
    local presence = PNC.Presence
    if not presence or not presence.RebindRestoredBody then
        return false
    end
    if not presence.RebindRestoredBody(record, body, reason) then
        return false
    end
    Lifecycle.ClearLateStreamRehydrate(record, "rebound", now)
    logInfo(
        "PNC late_stream_rehydrate_rebound npc="
            .. tostring(record.id)
            .. " reason=" .. tostring(reason)
    )
    return true
end

function Lifecycle.InterceptLateStreamRehydrateBody(
    body,
    now,
    source
)
    local nearby
    local matches = {}
    local i
    local record
    local eligible
    local settled
    local runtime

    if not body or not PNC.SpatialIndex
        or not PNC.SpatialIndex.QueryNPCs
        or not body.getX or not body.getY
    then
        return false
    end

    now = tonumber(now) or Core.Now()
    nearby = PNC.SpatialIndex.QueryNPCs(
        body:getX(),
        body:getY(),
        (tonumber(Const.BODY_SHELL_REHYDRATE_ANON_RADIUS) or 1)
            + 1.5
    )
    for i = 1, #nearby do
        record = nearby[i]
        if Lifecycle.HasLateStreamRehydrateClaim(record) then
            runtime = runtimeOf(record)
            if not runtime.lateStreamRehydrateLoadedAt then
                runtime.lateStreamRehydrateLoadedAt = now
            end
            eligible, settled =
                Internal.MatchAnonymousStartupRehydrate(
                    record,
                    body,
                    now
                )
            if eligible then
                matches[#matches + 1] = {
                    record = record,
                    settled = settled == true,
                }
            end
        end
    end

    if #matches ~= 1 then return false end

    record = matches[1].record
    Internal.QuarantineLateStreamCandidate(
        body,
        tostring(source or "late_stream_body")
            .. "_rehydrate_pending"
    )
    if matches[1].settled ~= true then
        return true
    end

    rebind(
        record,
        body,
        "late_stream_population_rebind",
        now
    )
    return true
end

-- Returns:
--   none       no late-stream claim
--   pending    saved square absent or still settling
--   ambiguous  multiple possible restored bodies; fail closed
--   rebound    old restored shell became canonical
--   released   loaded settle elapsed with no old shell
function Lifecycle.ReconcileLateStreamRehydrate(record, now)
    local runtime
    local exact
    local anonymous
    local candidate
    local loadedAt
    local settle
    local i

    now = tonumber(now) or Core.Now()
    if not Lifecycle.HasLateStreamRehydrateClaim(record) then
        return "none", nil
    end
    runtime = runtimeOf(record)

    if record.presenceState == Const.PRESENCE_LIVE then
        Lifecycle.ClearLateStreamRehydrate(
            record,
            "already_live",
            now
        )
        return "released", nil
    end

    if not Internal.LateStreamCenterSquare(record) then
        return "pending", nil
    end

    loadedAt = tonumber(runtime.lateStreamRehydrateLoadedAt)
    if not loadedAt then
        runtime.lateStreamRehydrateLoadedAt = now
        loadedAt = now
        logInfo(
            "PNC late_stream_rehydrate_window npc="
                .. tostring(record.id)
                .. " settleMs="
                .. tostring(
                    tonumber(Const.BODY_SHELL_LATE_STREAM_SETTLE_MS)
                        or 1500
                )
        )
    end

    exact, anonymous =
        Internal.ClassifyLateStreamCandidates(record, now)

    if #exact > 1
        or (#exact > 0 and #anonymous > 0)
        or #anonymous > 1
    then
        for i = 1, #anonymous do
            Internal.QuarantineLateStreamCandidate(
                anonymous[i].body,
                "late_stream_rehydrate_ambiguous"
            )
        end
        return "ambiguous", nil
    end

    if #exact == 1 then
        candidate = exact[1]
        Internal.QuarantineLateStreamCandidate(
            candidate,
            "late_stream_rehydrate_exact"
        )
    elseif #anonymous == 1 then
        candidate = anonymous[1].body
        Internal.QuarantineLateStreamCandidate(
            candidate,
            "late_stream_rehydrate_anonymous"
        )
        if anonymous[1].settled ~= true then
            runtime.lateStreamRehydrateCandidateAt =
                runtime.lateStreamRehydrateCandidateAt or now
            return "pending", nil
        end
    end

    if candidate then
        if rebind(
            record,
            candidate,
            "late_stream_population_rebind",
            now
        ) then
            return "rebound", candidate
        end
        return "pending", nil
    end

    settle = tonumber(Const.BODY_SHELL_LATE_STREAM_SETTLE_MS)
        or tonumber(Const.BODY_SHELL_STARTUP_SETTLE_MS)
        or 1500
    if now - loadedAt < settle then
        return "pending", nil
    end

    Lifecycle.ClearLateStreamRehydrate(
        record,
        "no_shell_after_loaded_settle",
        now
    )
    runtime.startupRehydrateMissed = true
    logInfo(
        "PNC late_stream_rehydrate_released npc="
            .. tostring(record.id)
            .. " reason=no_shell_after_loaded_settle"
    )
    return "released", nil
end

return Lifecycle
