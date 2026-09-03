PNC = PNC or {}
PNC.WorkPolicy = PNC.WorkPolicy or {}

local Policy = PNC.WorkPolicy

Policy.MIN_PRIORITY = 0
Policy.MAX_PRIORITY = 4
Policy.DEFAULT_PRIORITY = 3

local function clamp(value)
    return math.max(Policy.MIN_PRIORITY,
        math.min(Policy.MAX_PRIORITY, value))
end

function Policy.NormalizePriority(value, fallback)
    fallback = tonumber(fallback)
    if fallback == nil then fallback = Policy.DEFAULT_PRIORITY end
    fallback = clamp(math.floor(fallback))
    if type(value) == "boolean" then
        return value and fallback or Policy.MIN_PRIORITY
    end
    local numeric = tonumber(value)
    if numeric == nil then return fallback end
    return clamp(math.floor(numeric))
end

function Policy.GetPriority(record, job)
    if not record then return Policy.MIN_PRIORITY end
    job = tostring(job or "")
    if job == "" then return Policy.MIN_PRIORITY end
    local priorities = record.jobPriorities
    if type(priorities) == "table" and priorities[job] ~= nil then
        return Policy.NormalizePriority(priorities[job])
    end
    local allowed = record.allowedJobs
    if type(allowed) == "table" and allowed[job] ~= nil then
        return Policy.NormalizePriority(allowed[job])
    end
    -- Missing entries retain the old Hoomans behavior: a colonist is allowed
    -- to perform a job until the player explicitly disables it.
    return Policy.DEFAULT_PRIORITY
end

function Policy.IsEnabled(record, job)
    return Policy.GetPriority(record, job) > Policy.MIN_PRIORITY
end

function Policy.CanAutoClaim(record, job)
    return Policy.IsEnabled(record, job)
end

function Policy.SetPriority(record, job, value)
    if not record then return nil end
    job = tostring(job or "")
    if job == "" then return nil end
    local priority = Policy.NormalizePriority(value)
    record.jobPriorities = record.jobPriorities or {}
    record.jobPriorities[job] = priority
    -- Keep the legacy map synchronized while older consumers and existing
    -- saves are still present. New consumers must use jobPriorities.
    record.allowedJobs = record.allowedJobs or {}
    record.allowedJobs[job] = priority > Policy.MIN_PRIORITY
    return priority
end

function Policy.Snapshot(record, jobs)
    local output = {}
    jobs = jobs or PNC.WorkDefinitions
        and PNC.WorkDefinitions.COLONY_JOBS or {}
    for _, job in ipairs(jobs) do
        output[job] = Policy.GetPriority(record, job)
    end
    return output
end

function Policy.HasAnyEnabled(record, jobs)
    jobs = jobs or PNC.WorkDefinitions
        and PNC.WorkDefinitions.COLONY_JOBS or nil
    if type(jobs) == "table" and #jobs > 0 then
        for _, job in ipairs(jobs) do
            if Policy.IsEnabled(record, job) then return true end
        end
        return false
    end
    for job, value in pairs(record and record.jobPriorities or {}) do
        if tostring(job) ~= "" and Policy.NormalizePriority(value) > 0 then
            return true
        end
    end
    for job, value in pairs(record and record.allowedJobs or {}) do
        if tostring(job) ~= "" and Policy.NormalizePriority(value) > 0 then
            return true
        end
    end
    return true
end

return Policy
