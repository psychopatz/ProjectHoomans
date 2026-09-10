local T = require "tests/support/test"

T.addPackagePaths()

local camped = true
local fatigue = 0
local record = { id = "farmer", alive = true, job = "Farmer", fatigue = fatigue,
    runtime = {} }
local facility = { id = "farm:1", revision = 1 }
local provider

PNC = {
    Farming = { FARMER_JOB = "Farming" },
    FarmingService = {
        Internal = {
            BaseFor = function() return { id = "base:1" } end,
        },
        HasConfiguredWork = function() return true end,
    },
    HomeDutyService = {
        IsCamped = function() return camped end,
        GetBase = function() return { id = "base:1" } end,
    },
    Registry = {
        Get = function() return record end,
        GetLiveZombie = function() return nil end,
    },
    SettlementRepository = {
        GetFacility = function() return facility end,
        GetComponent = function() return {} end,
    },
    FacilityService = {
        ListByCapability = function() return { facility } end,
        AcquireActivity = function() return { ok = true, target = true } end,
    },
    FacilityReservations = {
        HasCapacity = function() return true end,
    },
    WorkPolicy = {
        IsEnabled = function() return true end,
        GetPriority = function() return 1 end,
    },
    IndividualNeeds = {
        Get = function(target, needType)
            return needType == "fatigue" and target.fatigue or nil
        end,
    },
    Tasking = {
        Commands = {
            RegisterProvider = function(_, value)
                provider = value
                return true
            end,
        },
    },
}

local loaded = T.load("ProjectHoomans", "server",
    "PNC/Farming/FarmingService/PNC_FarmingService_Provider.lua")
T.equal(provider, PNC.FarmingService.Internal.Provider,
    "farming provider registration")
T.equal(#provider.GetCandidates(record.id), 0,
    "camped NPC has no farming candidate")
T.falsy(provider.Validate({ npcId = record.id, sourceRef = facility.id }),
    "camped farming candidate does not validate")
local _, campReason = provider.Assign({ npcId = record.id,
    sourceRef = facility.id })
T.equal(campReason, "NPC_CAMPED", "camped farming assignment is rejected")
T.falsy(provider.Start({ npcId = record.id }),
    "camped farming task cannot start")
T.falsy(provider.CanContinue({ npcId = record.id, facilityId = facility.id,
    componentId = "component:1", executionMode = "ABSTRACT" }),
    "camped farming lease cannot continue")

camped = false
T.equal(#provider.GetCandidates(record.id), 1,
    "non-camped farmer remains eligible")

record.fatigue = 0.90
T.equal(#provider.GetCandidates(record.id), 0,
    "fatigued farmer has no planting candidate")
T.falsy(provider.Validate({ npcId = record.id, sourceRef = facility.id }),
    "fatigued farming candidate does not validate")
local _, fatigueReason = provider.Assign({ npcId = record.id,
    sourceRef = facility.id })
T.equal(fatigueReason, "WORKER_NEEDS_REST",
    "fatigued farming assignment reports the rest gate")

return T.finish("pnc_farming_provider_smoke")
