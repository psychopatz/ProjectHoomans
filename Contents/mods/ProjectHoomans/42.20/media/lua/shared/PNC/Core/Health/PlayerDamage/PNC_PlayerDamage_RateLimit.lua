-- Bounded session state for admitted player-hit reports.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}
PNC.PlayerDamage.LastReportAt = PNC.PlayerDamage.LastReportAt or {}

local PlayerDamage = PNC.PlayerDamage
local Internal = PlayerDamage.Internal
local Const = PNC.Const

local REPORT_TRACKING_LIMIT = 2048
local REPORTS_PER_PLAYER_LIMIT = 64
local ROUTINE_PRUNE_BUDGET = 16

local tracker = Internal.ReportTracker or {}
tracker.Slots = type(tracker.Slots) == "table" and tracker.Slots or {}
tracker.ByPlayer = type(tracker.ByPlayer) == "table"
    and tracker.ByPlayer or {}
tracker.Head = tonumber(tracker.Head) or 1
tracker.Count = tonumber(tracker.Count) or 0
if tracker.Head < 1 or tracker.Head > REPORT_TRACKING_LIMIT
    or tracker.Head % 1 ~= 0
then
    tracker.Head = 1
end
if tracker.Count < 0 or tracker.Count > REPORT_TRACKING_LIMIT
    or tracker.Count % 1 ~= 0
then
    tracker.Count = 0
end
Internal.ReportTracker = tracker
Internal.ReportTrackingLimit = REPORT_TRACKING_LIMIT
Internal.ReportsPerPlayerLimit = REPORTS_PER_PLAYER_LIMIT

local function finiteNumber(value)
    local number = tonumber(value)
    if number == nil or number ~= number
        or number == math.huge or number == -math.huge
    then
        return nil
    end
    return number
end

local function reportCooldown()
    return math.max(0,
        tonumber(Const.PLAYER_HIT_REPORT_COOLDOWN_MS) or 80)
end

local function releaseSlot(slot)
    local reportTime = finiteNumber(slot.at)
    local currentTime = finiteNumber(PlayerDamage.LastReportAt[slot.key])
    if reportTime ~= nil and currentTime == reportTime then
        PlayerDamage.LastReportAt[slot.key] = nil
    end
    local count = tonumber(tracker.ByPlayer[slot.playerKey]) or 0
    if count <= 1 then
        tracker.ByPlayer[slot.playerKey] = nil
    else
        tracker.ByPlayer[slot.playerKey] = count - 1
    end
end

local function pruneExpired(now, budget)
    local removed = 0
    local cooldown = reportCooldown()
    while tracker.Count > 0 and removed < budget do
        local slot = tracker.Slots[tracker.Head]
        if type(slot) == "table" then
            local recordedAt = finiteNumber(slot.at)
            if recordedAt ~= nil and now - recordedAt < cooldown then
                break
            end
            releaseSlot(slot)
        end
        tracker.Slots[tracker.Head] = nil
        tracker.Head = tracker.Head % REPORT_TRACKING_LIMIT + 1
        tracker.Count = tracker.Count - 1
        removed = removed + 1
    end
    return removed
end

function Internal.AdmitReportKey(playerKey, key, now)
    local reportTime = finiteNumber(now)
    local lastReportAt
    local playerCount
    local slotIndex
    if type(playerKey) ~= "string" or playerKey == ""
        or #playerKey > 64
        or type(key) ~= "string" or key == "" or #key > 256
        or reportTime == nil
    then
        return false, "invalid_report_key"
    end
    lastReportAt = finiteNumber(PlayerDamage.LastReportAt[key])
    if lastReportAt ~= nil
        and reportTime - lastReportAt < reportCooldown()
    then
        return false, "rate_limited"
    end
    pruneExpired(reportTime, ROUTINE_PRUNE_BUDGET)
    playerCount = tonumber(tracker.ByPlayer[playerKey]) or 0
    if playerCount >= REPORTS_PER_PLAYER_LIMIT
        or tracker.Count >= REPORT_TRACKING_LIMIT
    then
        pruneExpired(reportTime, REPORT_TRACKING_LIMIT)
        playerCount = tonumber(tracker.ByPlayer[playerKey]) or 0
        if playerCount >= REPORTS_PER_PLAYER_LIMIT
            or tracker.Count >= REPORT_TRACKING_LIMIT
        then
            return false, "tracking_capacity"
        end
    end
    slotIndex = (tracker.Head + tracker.Count - 1)
        % REPORT_TRACKING_LIMIT + 1
    tracker.Slots[slotIndex] = {
        key = key,
        playerKey = playerKey,
        at = reportTime,
    }
    tracker.Count = tracker.Count + 1
    tracker.ByPlayer[playerKey] = playerCount + 1
    PlayerDamage.LastReportAt[key] = reportTime
    return true
end
