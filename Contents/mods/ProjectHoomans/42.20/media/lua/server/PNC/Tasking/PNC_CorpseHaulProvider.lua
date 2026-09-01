-- Tasking provider for physical, vanilla-grapple corpse hauling.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = {}
local Service = PNC.CorpseHaulService
local Registry = PNC.Registry

local function recordFor(id)
    return Registry and Registry.Get and Registry.Get(id) or nil
end

local function eligible(record)
    local affiliation = record and record.affiliation or {}
    local role = tostring(affiliation.communityRole or affiliation.role or "")
    return record and record.alive ~= false and role == "worker"
        and (not record.allowedJobs or record.allowedJobs.CorpseHaul ~= false)
        and Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) ~= nil
end

function Provider.GetCandidates(npcId)
    local record = recordFor(npcId)
    local assignment = eligible(record) and Service.FindAssignment(record) or nil
    if not assignment then return {} end
    return {{
        taskId = assignment.taskId, npcId = tostring(npcId),
        kind = "CORPSE_HAUL", sourceDomain = "corpse_haul",
        sourceRef = assignment.haulToken, precedence = "NORMAL_WORK",
        urgency = 0.6, capability = "storage.stockpile",
        interruptPolicy = "NORMAL", revision = 0,
    }}
end

function Provider.Validate(intent)
    local record = recordFor(intent and intent.npcId)
    if not eligible(record) then return false end
    local token = tostring(intent and intent.sourceRef or "")
    return token ~= "" and Service.FindAssignment(record, token) ~= nil
end

function Provider.Assign(intent)
    local record = recordFor(intent and intent.npcId)
    local assignment = record and Service.FindAssignment(record,
        intent.sourceRef) or nil
    if not assignment then return nil, "CORPSE_ASSIGNMENT_UNAVAILABLE" end
    local reserved, reason = Service.Reserve(assignment, record.id)
    if not reserved then return nil, reason end
    assignment.executionMode = "LIVE"
    return assignment
end

function Provider.Start(lease, assignment)
    return Service.Start(lease, assignment)
end

function Provider.RollbackAssignment(intent, assignment)
    local taskId = assignment and assignment.taskId or intent and intent.taskId
    local task = Service.GetTask(taskId)
    if not task then return true end
    Service.Runtime.byTask[taskId] = nil
    Service.Runtime.byToken[task.haulToken] = nil
    Service.Runtime.byDrop[task.dropKey] = nil
    return true
end

function Provider.CanContinue(lease)
    return Service.CanContinue(lease) == true
end

function Provider.Cancel(lease, reason)
    return Service.Cancel(lease, reason)
end

function Provider.Complete()
    -- Service.Finish performs the physical verification and releases its
    -- corpse/drop reservations before the lease is released.
    return true
end

function Provider.Tick(lease)
    return Service.Tick(lease)
end

if PNC.Tasking and PNC.Tasking.Commands then
    PNC.Tasking.Commands.RegisterProvider("corpse_haul", Provider)
end

PNC.CorpseHaulProvider = Provider
return Provider
