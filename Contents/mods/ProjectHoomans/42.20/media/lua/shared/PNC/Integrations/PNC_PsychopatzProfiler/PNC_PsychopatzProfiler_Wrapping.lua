local Integration = PNC.ProfilerIntegration
local Internal = Integration.Internal

function Internal.Wrap(owner, key, metricName)
    if not owner or type(owner[key]) ~= "function" then return false end
    Integration.originals = Integration.originals or {}
    if Integration.originals[metricName] then return false end
    Integration.originals[metricName] = {
        owner = owner,
        key = key,
        callback = owner[key],
    }
    owner[key] = Internal.Profiler.Wrap(metricName, owner[key], {
        protectErrors = true,
    })
    return true
end

function Internal.CountMap(values)
    local count = 0
    for _, _ in pairs(values or {}) do count = count + 1 end
    return count
end

function Internal.InstallScheduledJobPerformance()
    local scheduler = PNC.Scheduler
    local metricPrefix =
        "ProjectHoomans.Server.Update.Director.ScheduledJobs."
    local function wrapJob(name, job)
        if not job or type(job.callback) ~= "function" then return false end
        return Internal.Wrap(
            job,
            "callback",
            metricPrefix .. tostring(name or "Unknown")
        )
    end
    if not scheduler or type(scheduler.RegisterJob) ~= "function" then
        return false
    end
    for name, job in pairs(scheduler.Jobs or {}) do wrapJob(name, job) end
    Integration.originals = Integration.originals or {}
    local hookMetric = metricPrefix .. "RegisterHook"
    if Integration.originals[hookMetric] then return true end
    local original = scheduler.RegisterJob
    Integration.originals[hookMetric] = {
        owner = scheduler,
        key = "RegisterJob",
        callback = original,
    }
    scheduler.RegisterJob = function(name, interval, callback, options)
        local registered
        local job
        registered, job = original(name, interval, callback, options)
        if registered then wrapJob(name, job) end
        return registered, job
    end
    return true
end

function Integration.Restore()
    for _, entry in pairs(Integration.originals or {}) do
        if entry.owner and entry.owner[entry.key] then
            entry.owner[entry.key] = entry.callback
        end
    end
    Integration.originals = nil
    Integration.serverInstalled = false
end

return Integration
