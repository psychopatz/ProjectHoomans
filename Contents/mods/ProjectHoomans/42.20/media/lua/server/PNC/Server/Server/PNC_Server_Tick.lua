if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Server = PNC.Server
local H = Server.Internal
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics
local StutterTrace = PNC.StutterTrace

function Server.OnTick()
    local clockOK, now = H.SafePhase("server_tick.clock", Core.Now)
    if not clockOK then return end

    local stutterActive = StutterTrace and StutterTrace.Enabled == true
    if stutterActive then StutterTrace.BeginTick(now) end

    local timerName
    local timerStart
    if Diagnostics then
        timerName, timerStart = Diagnostics.BeginTiming("Server.Update", now)
    end

    H.InTick = true
    local prepareOK, due = H.SafePhase("server_tick.prepare", H.PrepareTick,
        nil, now)
    if not prepareOK or type(due) ~= "table" then due = {} end
    local i
    local budgetMs = tonumber(PNC.Const and PNC.Const.SERVER_TICK_RECORD_BUDGET_MS) or 10
    local budgetStartMs = Core.Now and Core.Now() or now
    local scheduler = PNC.Scheduler
    local slotMs = scheduler and tonumber(scheduler.SLOT_MS) or 50
    for i = 1, #due do
        local record = due[i]
        H.SafePhase("server_tick.process_record", H.ProcessRecord, {
            npcId = record and record.id or "unknown",
        }, record, now)
        if i < #due and budgetMs > 0 and Core.Now then
            local elapsed = (tonumber(Core.Now()) or budgetStartMs) - budgetStartMs
            if elapsed >= budgetMs then
                if scheduler and type(scheduler.Schedule) == "function" then
                    local j
                    for j = i + 1, #due do
                        local deferred = due[j]
                        if deferred then
                            scheduler.Schedule(deferred, now + slotMs, true)
                        end
                    end
                end
                if Diagnostics and Diagnostics.Increment then
                    Diagnostics.Increment("Scheduler.BudgetDeferred")
                end
                break
            end
        end
    end
    H.SafePhase("server_tick.finish", H.FinishTick, nil, now)
    H.InTick = false
    if PNC.StartingCompanionCustomizationService
        and PNC.StartingCompanionCustomizationService.Pump
    then
        H.SafePhase(
            "server_tick.starting_companion_customization",
            PNC.StartingCompanionCustomizationService.Pump,
            nil,
            now
        )
    end
    if timerName then Diagnostics.EndTiming(timerName, timerStart) end
    if stutterActive then StutterTrace.EndTick(now) end
    if Diagnostics then Diagnostics.LogRuntimeSummary(now) end
end
