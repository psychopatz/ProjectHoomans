PNC = PNC or {}
PNC.ColonyManagementUI = PNC.ColonyManagementUI or {}
PNC.ColonyManagementClient = PNC.ColonyManagementClient or {}

local Client = PNC.ColonyManagementClient

local function workPolicy()
    return PNC.WorkPolicy
        or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
end

local function workPolicyKey(npcID, job)
    return tostring(npcID or "") .. "|" .. tostring(job or "")
end

function Client.QueueWorkPolicy(npcID, job, priority)
    local policy = workPolicy()
    Client.workPolicyPending = Client.workPolicyPending or {}
    Client.workPolicySerial = (tonumber(Client.workPolicySerial) or 0) + 1
    local requestId = "work-policy:" .. tostring(npcID or "") .. ":"
        .. tostring(job or "") .. ":" .. tostring(Client.workPolicySerial)
    Client.workPolicyPending[workPolicyKey(npcID, job)] = {
        requestId = requestId,
        priority = policy.NormalizePriority(priority),
        sentAt = PNC.Core.Now(),
    }
    return requestId
end

function Client.ClearWorkPolicy(npcID, job)
    if not Client.workPolicyPending then return end
    Client.workPolicyPending[workPolicyKey(npcID, job)] = nil
end

function Client.ReconcileWorkPolicies(snapshot)
    local policy = workPolicy()
    snapshot = type(snapshot) == "table" and snapshot or {}
    Client.workPolicyPending = Client.workPolicyPending or {}
    Client.workPolicyStates = Client.workPolicyStates or {}
    local result = snapshot.actionResult
    local details = result and result.details or nil
    if result and result.action == "job_permission_set" then
        local key = details and workPolicyKey(details.npcID, details.job) or nil
        local pending = key and Client.workPolicyPending[key] or nil
        if not pending and result.requestId then
            for candidateKey, candidate in pairs(Client.workPolicyPending) do
                if tostring(candidate.requestId) == tostring(result.requestId) then
                    key, pending = candidateKey, candidate
                    break
                end
            end
        end
        if pending then
            if result.ok == true and details then
                Client.workPolicyStates[key] = {
                    priority = policy.NormalizePriority(details.priority,
                        details.enabled == true
                            and policy.DEFAULT_PRIORITY or 0),
                    revision = tonumber(details.recordRevision) or 0,
                }
            end
            Client.workPolicyPending[key] = nil
        end
    end
    local now = PNC.Core.Now()
    for key, pending in pairs(Client.workPolicyPending) do
        if now - (tonumber(pending.sentAt) or now) >= 15000 then
            Client.workPolicyPending[key] = nil
        end
    end
    local jobs = PNC.WorkDefinitions and PNC.WorkDefinitions.COLONY_JOBS
        or { "Constructor", "Researcher", "WorkshopWorker", "Farmer",
            "Fishing", "Lumber", "Provisioner", "CorpseHaul",
            "MedicalCare" }
    for _, person in ipairs(snapshot.people or {}) do
        local incomingRevision = tonumber(person.recordRevision) or 0
        for _, job in ipairs(jobs) do
            local key = workPolicyKey(person.id, job)
            local state = Client.workPolicyStates[key]
            if state and incomingRevision < (tonumber(state.revision) or 0) then
                policy.SetPriority(person, job, state.priority)
            else
                Client.workPolicyStates[key] = {
                    priority = policy.GetPriority(person, job),
                    revision = incomingRevision,
                }
            end
            local pending = Client.workPolicyPending[key]
            if pending then
                policy.SetPriority(person, job, pending.priority)
            end
        end
    end
    return snapshot
end

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

function Client.ReadSnapshot()
    local state = clientState()
    return {
        snapshot = state.colonyManagement or {},
        revision = tonumber(state.colonyManagementRevision) or 0,
        receivedAt = state.lastColonyManagementReceiveAt,
    }
end

function Client.HasUpdate(lastRevision, lastReceiveAt)
    local update = Client.ReadSnapshot()
    return update.revision > (tonumber(lastRevision) or 0)
        or (tonumber(update.receivedAt) or 0)
            > (tonumber(lastReceiveAt) or 0),
        update
end

function Client.RequestSnapshot(taskBrainNpcID)
    local ok = false
    local reason = "client_unavailable"
    if PNC.Client and PNC.Client.RequestColonyManagement then
        ok, reason = PNC.Client.RequestColonyManagement(taskBrainNpcID)
    end
    return ok, reason, PNC.Core.Now()
end

require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Layout"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Diagnostics"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Controller"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Window"

return PNC.ColonyManagementUI
