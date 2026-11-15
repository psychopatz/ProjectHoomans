-- WorkZoneService dual-mode worker dispatch (autonomous WorkPolicy vs forced AssignWorker).

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkZoneService = PNC.WorkZoneService or {}
local Service = PNC.WorkZoneService

---Assigns a colonist manually to a work zone for FORCED_ORDER execution.
function Service.AssignWorker(zoneId, npcId)
    local zone = Service.GetZone and Service.GetZone(zoneId) or nil
    npcId = tostring(npcId or "")
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    if npcId == "" then return false, "WORKER_REQUIRED" end
    zone.workers = zone.workers or {}
    zone.workers[npcId] = true
    zone.revision = (tonumber(zone.revision) or 1) + 1
    return true, zone
end

---Removes a manual worker assignment from a work zone and releases their claims.
function Service.UnassignWorker(zoneId, npcId)
    local zone = Service.GetZone and Service.GetZone(zoneId) or nil
    npcId = tostring(npcId or "")
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    if npcId == "" then return false, "WORKER_REQUIRED" end
    zone.workers = zone.workers or {}
    local removed = zone.workers[npcId] == true
    zone.workers[npcId] = nil
    if removed then
        zone.revision = (tonumber(zone.revision) or 1) + 1
    end
    if Service.ReleaseTarget then
        Service.ReleaseTarget(zoneId, nil, npcId)
    end
    return removed, zone
end

---Resolves dispatch mode and WorkService priority for a worker on a zone.
function Service.ResolveDispatchMode(zone, record)
    if not zone or zone.enabled == false then
        return nil, "WORK_ZONE_DISABLED"
    end
    if not record or record.id == nil then
        return nil, "WORKER_REQUIRED"
    end
    local workerId = tostring(record.id)
    local Definitions = PNC.WorkDefinitions
    local Priority = Definitions and Definitions.PRIORITY or {}
    local forcedPriority = tonumber(Priority.FORCED_ORDER) or 90

    if zone.workers and zone.workers[workerId] == true then
        return "FORCED_ORDER", forcedPriority
    end

    local job = Definitions and Definitions.JobForOperation
        and Definitions.JobForOperation(zone.operation) or zone.job
    local Policy = PNC.WorkPolicy
    if job and Policy then
        if type(Policy.IsEnabled) == "function" and not Policy.IsEnabled(record, job) then
            return nil, "JOB_DISABLED"
        end
        if type(Policy.WorkServicePriority) == "function" then
            return "NORMAL_WORK", Policy.WorkServicePriority(record, job)
        end
    end
    return "NORMAL_WORK", tonumber(Priority.NORMAL_WORK) or 40
end

return Service
