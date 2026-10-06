local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local scanCalls = 0
local stockpileCalls = 0
PNC = {
    Core = {
        GenerateID = function() return "corpse:test" end,
    },
    CorpseHaulService = {
        Runtime = {},
        Internal = {
            configurationFor = function() return nil end,
            scanBaseCorpses = function()
                scanCalls = scanCalls + 1
                return {}
            end,
            stockpileFacilities = function()
                stockpileCalls = stockpileCalls + 1
                return {}
            end,
        },
    },
}

T.load("ProjectHoomans", "server",
    "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_World_Corpses.lua")
local Service = T.load("ProjectHoomans", "server",
    "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Dispatch_Assignment.lua")

local corpseGetItemCalls = 0
local humanCorpse = {
    getItem = function()
        corpseGetItemCalls = corpseGetItemCalls + 1
        error("corpse inventory must not be materialized during eligibility")
    end,
    isAnimal = function() return false end,
}
T.truthy(Service.IsEligibleCorpse(humanCorpse),
    "human corpse remains eligible without reading its inventory")
T.equal(corpseGetItemCalls, 0,
    "corpse eligibility does not call the unsafe getItem API")

local animalCorpse = {
    getItem = humanCorpse.getItem,
    isAnimal = function() return true end,
}
T.falsy(Service.IsEligibleCorpse(animalCorpse),
    "animal corpse remains excluded without reading its inventory")
T.equal(corpseGetItemCalls, 0,
    "animal filtering does not call the unsafe getItem API")

local assignment, reason = Service.Internal.findBaseAssignment({ id = "base:test" })
T.falsy(assignment, "unconfigured bases do not create corpse assignments")
T.equal(reason, "CORPSE_HAUL_NOT_CONFIGURED",
    "unconfigured bases return the stable configuration reason")
T.equal(scanCalls, 0,
    "unconfigured bases do not scan their entire base zone")
T.equal(stockpileCalls, 0,
    "unconfigured bases do not enumerate stockpile facilities")

T.finish("pnc_corpse_haul_scan_guard_smoke")
