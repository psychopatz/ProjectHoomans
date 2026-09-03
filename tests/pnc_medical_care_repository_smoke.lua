local T = require "tests/support/test"

local repositoryPath = T.path(
    "ProjectHoomans",
    "server",
    "PNC/Medical/PNC_MedicalCareRepository.lua"
)
local servicePath = T.path(
    "ProjectHoomans",
    "server",
    "PNC/Medical/PNC_MedicalCareService.lua"
)

local now = 500
local globalData = {}
local eventNPCIDs = {}

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, entry in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(entry, seen)
    end
    return output
end

ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}
PNC = {
    Core = {
        Now = function() return now end,
        DeepCopy = deepCopy,
    },
    Tasking = { Events = {
        Emit = function(_, details)
            eventNPCIDs[#eventNPCIDs + 1] = details and details.npcId
        end,
    } },
    Registry = {
        ForEach = function(callback)
            callback({ id = "doctor-1", alive = true })
        end,
    },
    MedicalCareExecutor = {
        Internal = {
            IsDoctor = function(record)
                return record and record.id == "doctor-1"
            end,
        },
    },
}

local repository = T.load(repositoryPath)
local service = T.load(servicePath)

local first, reason = service.CreateRequest({
    patientKind = "npc",
    patientId = "patient-1",
    factionId = "faction-1",
    communityId = "camp-1",
    woundParts = { "ForeArm_L" },
    incapacitated = true,
})
T.truthy(first, "medical request created")
T.equal(reason, "created", "medical request creation reason")
T.equal(first.operation, "MEDICAL_CARE", "medical operation")
T.equal(first.status, "QUEUED", "medical request starts queued")
T.equal(first.phase, "WAITING_FOR_DOCTOR", "medical request phase")
T.equal(first.priority, 100, "incapacitated request priority")
T.equal(first.woundParts[1], "ForeArm_L", "wound part persisted in request")
local wokeDoctor = false
for _, npcId in ipairs(eventNPCIDs) do
    if npcId == "doctor-1" then wokeDoctor = true end
end
T.truthy(wokeDoctor, "new patient request wakes medical-capable doctors")

now = 550
local coalesced, coalesceReason = service.CreateRequest({
    patientKind = "npc",
    patientId = "patient-1",
    woundParts = { "Hand_L" },
    severity = 80,
})
T.equal(coalesceReason, "coalesced", "duplicate request coalesced")
T.equal(coalesced.id, first.id, "coalescing retained request ID")
T.equal(#coalesced.woundParts, 2,
    "coalescing retained both wounds in one care episode")
T.equal(coalesced.priority, 100, "coalescing retained emergency priority")

local claimed = service.SetPhase(first.id, "CLAIMED", { actorId = "doctor-1" })
T.truthy(claimed, "medical request claimed")
T.equal(service.Get(first.id).actorId, "doctor-1",
    "doctor claim persisted")

T.truthy(repository.Save(), "medical request saved")
repository.Loaded = false
repository.Load(true)
local recovered = service.Get(first.id)
T.equal(recovered.status, "WAITING_FOR_DOCTOR",
    "active medical claim recovered after reload")
T.equal(recovered.actorId, nil,
    "runtime doctor claim was not persisted")
T.equal(recovered.blockedReason, "RECOVERED_AFTER_LOAD",
    "medical reload explains claim recovery")

local cancelled = service.Cancel(first.id, "operator_cancelled")
T.truthy(cancelled, "medical request cancelled")
T.equal(service.Get(first.id).status, "CANCELLED",
    "medical request terminal cancellation")
T.falsy(service.Requeue(first.id),
    "terminal medical request cannot be silently requeued")

T.finish("pnc_medical_care_repository_smoke")
