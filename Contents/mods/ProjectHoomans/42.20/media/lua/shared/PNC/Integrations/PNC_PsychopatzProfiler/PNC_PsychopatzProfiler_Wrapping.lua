local Integration = PNC and PNC.ProfilerIntegration or nil
if not Integration or Integration._loadingProviders ~= true then
    return Integration
end

local Internal = Integration.Internal
if type(Internal) ~= "table" then return Integration end

function Internal.Wrap(owner, key, metricName, depth)
    if not owner or type(owner[key]) ~= "function" then return false end
    Integration.originals = Integration.originals or {}
    if Integration.originals[metricName] then return false end
    local resolvedDepth = depth == "coarse" and "coarse" or "deep"
    Integration.originals[metricName] = {
        owner = owner,
        key = key,
        callback = owner[key],
        depth = resolvedDepth,
    }
    owner[key] = Internal.Profiler.Wrap(metricName, owner[key], {
        protectErrors = true,
        depth = resolvedDepth,
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
            metricPrefix .. tostring(name or "Unknown"),
            "deep"
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
        depth = "deep",
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

function Integration.RestoreServerTick()
    local tickHook = Integration._serverTickHook
    if not tickHook then return false end
    Integration._serverTickHook = nil
    if Events and Events.OnTick and Events.OnTick.Remove then
        Events.OnTick.Remove(tickHook.wrapped)
        if Events.OnTick.Add then
            Events.OnTick.Add(tickHook.original)
        end
    end
    if PNC.Server and PNC.Server.OnTick == tickHook.wrapped then
        PNC.Server.OnTick = tickHook.original
    end
    return true
end

function Integration.RestoreDeep()
    local originals = Integration.originals
    if originals then
        for metricName, entry in pairs(originals) do
            if entry.depth ~= "coarse" then
                if entry.owner and entry.owner[entry.key] then
                    entry.owner[entry.key] = entry.callback
                end
                originals[metricName] = nil
            end
        end
    end
    Integration.deepInstalled = false
    Integration.sharedDeepInstalled = false
    Integration.serverDeepInstalled = false
    return true
end

function Integration.Restore()
    for _, entry in pairs(Integration.originals or {}) do
        if entry.owner and entry.owner[entry.key] then
            entry.owner[entry.key] = entry.callback
        end
    end
    Integration.originals = nil
    Integration.coarseInstalled = false
    Integration.deepInstalled = false
    Integration.sharedDeepInstalled = false
    Integration.serverInstalled = false
    Integration.serverCoarseInstalled = false
    Integration.serverDeepInstalled = false
    Integration.RestoreServerTick()
    return true
end

function Integration.GetInstalledWrapperCounts()
    local total, coarse, deep = 0, 0, 0
    for _, entry in pairs(Integration.originals or {}) do
        total = total + 1
        if entry.depth == "coarse" then
            coarse = coarse + 1
        else
            deep = deep + 1
        end
    end
    if Integration._serverTickHook then
        total = total + 1
        coarse = coarse + 1
    end
    return {
        total = total,
        coarse = coarse,
        deep = deep,
    }
end

return Integration
