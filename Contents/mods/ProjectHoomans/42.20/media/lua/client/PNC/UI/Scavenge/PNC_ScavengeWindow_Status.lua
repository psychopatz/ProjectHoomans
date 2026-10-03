local Window = ISPNCScavengeWindow
if not Window then return end

local Internal = Window.Internal or {}
local UI = Internal.UI
local Layout = Internal.Layout
local Theme = Internal.Theme
local tr = Internal.tr
local readable = Internal.readable

local function drawStatusRow(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local width = list:getWidth()
    local statusColor = row.status == "COLLECTED" and Theme.colors.success
        or row.status == "UNAVAILABLE" and Theme.colors.danger
        or row.status == "PAUSED_CAPACITY" and Theme.colors.warning
        or Theme.colors.text
    list:drawText(readable(row.status):upper(), 8, y + 5,
        statusColor.r, statusColor.g, statusColor.b, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.item or row.message or "",
        UIFont.Small, math.floor(width * 0.46)), math.floor(width * 0.25),
        y + 5, Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.detail or "", UIFont.Small,
        math.floor(width * 0.25)), math.floor(width * 0.73), y + 5,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, 1, UIFont.Small)
    return y + list.itemheight
end


Internal.drawStatusRow = drawStatusRow

local function appendActivityRows(window, rows)
    for index = #rows, 1, -1 do
        local entry = rows[index]
        local actor = tostring(entry.npcName or entry.npcId
            or tr("UI_PNC_Scavenge_Team", "Team"))
        local source = tostring(entry.sourceLabel
            or readable(entry.sourceType) or "")
        local item = tostring(entry.displayName or entry.fullType
            or tr("UI_PNC_Scavenge_Item", "item"))
        local message = item
        local detail = entry.reason or source
        if entry.status == "SOURCE_SEARCHED" then
            message = tr("UI_PNC_Scavenge_LogSearched",
                "%s searched %s", actor, source)
            detail = tr("UI_PNC_Scavenge_LogFound",
                "%s items found", tonumber(entry.itemCount) or 0)
        elseif entry.status == "COLLECTED" then
            message = tr("UI_PNC_Scavenge_LogCollected",
                "%s collected %s x%s", actor, item,
                tonumber(entry.quantity) or 1)
            detail = source ~= "" and tr("UI_PNC_Scavenge_LogFrom",
                "from %s", source) or ""
        elseif entry.status == "SEARCHING" then
            message = tr("UI_PNC_Scavenge_LogSearching",
                "%s is searching %s", actor, source)
            detail = ""
        elseif entry.status == "TAKING" then
            message = tr("UI_PNC_Scavenge_LogTaking",
                "%s is taking %s", actor, item)
            detail = source
        elseif entry.status == "SOURCE_SKIPPED"
            or entry.status == "SOURCE_INVALID"
        then
            message = tr("UI_PNC_Scavenge_LogSkipped",
                "%s could not search %s", actor, source)
        elseif entry.status == "QUEUED" then
            message = tr("UI_PNC_Scavenge_LogQueued",
                "Queued %s", item)
        elseif entry.status == "SEARCH_COMPLETE" then
            message = tr("UI_PNC_Scavenge_LogComplete",
                "Search complete")
        end
        window.statusList:addItem(tostring(index), {
            status = entry.status,
            item = message,
            detail = detail,
        })
    end
    if #rows == 0 and not window.debugEnabled then
        window.statusList:addItem("empty", { status = "WAITING",
            message = "No scavenging activity yet", detail = "" })
    end
end

local function appendLiveDebugRows(window)
    local live = window.snapshot and window.snapshot.scavengeDebug
    if window.debugEnabled and live then
        window.statusList:addItem("debug-session", { status = "SESSION",
            item = tostring(live.state or "none") .. " / "
                .. tostring(live.phase or "none"),
            detail = string.format("sources %d/%d  next %d",
                tonumber(live.processedCount) or 0,
                tonumber(live.candidateCount) or 0,
                tonumber(live.nextCandidateIndex) or 0) })
        for _, worker in ipairs(live.workers or {}) do
            window.statusList:addItem("worker:" .. tostring(worker.npcId), {
                status = "WORKER", item = tostring(worker.npcName)
                    .. " — " .. readable(worker.workerPhase),
                detail = tostring(worker.waitReason or worker.leasePhase or "active") })
            local source = worker.currentSource
            if source then
                window.statusList:addItem("source:" .. tostring(worker.npcId), {
                    status = "SOURCE", item = tostring(source.sourceLabel
                        or readable(source.sourceType) or source.sourceToken),
                    detail = string.format("%s  %.1f,%.1f,%d  d2=%s  %s",
                        tostring(source.sourceType or "source"),
                        tonumber(source.x) or 0, tonumber(source.y) or 0,
                        tonumber(source.z) or 0,
                        tostring(source.workerDistanceSq or "?"),
                        source.valid and "valid" or "INVALID") })
            end
            local path = worker.path or {}
            local intent = worker.moveIntent or {}
            window.statusList:addItem("move:" .. tostring(worker.npcId), {
                status = "MOVE", item = tostring(worker.lastMovement
                    or intent.kind or "none"),
                detail = tostring(path.phase or "no lane") .. " / "
                    .. tostring(path.reason or path.intentReason
                        or intent.reason or worker.lastFailure or "ready") })
        end
        for _, source in ipairs(live.pendingSources or {}) do
            window.statusList:addItem("pending:" .. tostring(source.index), {
                status = source.status or "PENDING",
                item = string.format("#%d %s", tonumber(source.index) or 0,
                    tostring(source.sourceLabel or readable(source.sourceType))),
                detail = string.format("%s  %.1f,%.1f,%d  %s",
                    tostring(source.sourceType or "source"),
                    tonumber(source.x) or 0, tonumber(source.y) or 0,
                    tonumber(source.z) or 0,
                    source.valid and "valid" or "INVALID") })
        end
    end
end

local function appendSnapshotDiagnostics(window, diagnostics)
    if window.debugEnabled and diagnostics then
        local snapshot = window.snapshot
        local debugRows = {
            { "DEBUG", "Session", tostring(snapshot.sessionId or "none") },
            { "DEBUG", "State / task", tostring(snapshot.state or "none")
                .. " / " .. tostring(snapshot.taskPhase or "none") },
            { "DEBUG", "Current source",
                tostring(snapshot.currentSourceToken or "none") },
            { "DEBUG", "Queue", string.format("%d / %d",
                tonumber(snapshot.queueIndex) or 0, #(snapshot.queue or {})) },
            { "DEBUG", "Last failure",
                tostring(snapshot.lastFailure or diagnostics.lastFailure or "none") },
        }
        for _, row in ipairs(debugRows) do
            window.statusList:addItem(row[2], { status = row[1],
                item = row[2], detail = row[3] })
        end
        local names = {}
        for name, _ in pairs(diagnostics.counters or {}) do
            names[#names + 1] = name
        end
        table.sort(names)
        for _, name in ipairs(names) do
            window.statusList:addItem(name, { status = "METRIC",
                item = name, detail = tostring(diagnostics.counters[name]) })
        end
    end
end

function Window:rebuildStatus()
    self.statusList:clear()
    local rows = not self.debugEnabled and self.snapshot
        and self.snapshot.activity or {}
    appendActivityRows(self, rows)
    appendLiveDebugRows(self)
    appendSnapshotDiagnostics(
        self, self.snapshot and self.snapshot.debugDiagnostics
    )
end
