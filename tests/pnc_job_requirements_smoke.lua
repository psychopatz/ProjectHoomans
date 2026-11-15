local T = require "tests/support/test"

local Registry = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/WorkItems/PNC_JobRequirements.lua")

T.truthy(Registry.All, "job requirement registry has no ordered listing")
T.equal(Registry.All()[1], "LUMBER",
    "job requirement listing does not preserve registration order")
T.equal(Registry.All()[2], "FISHING",
    "job requirement listing omits fishing")
T.equal(Registry.All()[3], "FARMING",
    "job requirement listing omits farming")

local farmingDefinition = Registry.Get("farming")
T.truthy(farmingDefinition, "farming requirement definition registered")
T.equal(#farmingDefinition.requirements, 1,
    "farming exposes one primary digging tool requirement")
local farmingReq = farmingDefinition.requirements[1]
T.equal(farmingReq.role, "primary_tool", "farming requirement role")
T.equal(farmingReq.equipSlot, "primary", "farming equips digging tool")
T.truthy(farmingReq.durable, "farming digging tool is durable")
T.equal(farmingReq.validator, "farming_tool", "farming tool validator id")
T.equal(farmingReq.candidates[1], "Base.HandFork",
    "farming includes hand fork candidate")
T.equal(farmingReq.candidates[2], "Base.Trowel",
    "farming includes trowel candidate")
T.equal(farmingReq.candidates[7], "Base.GardenHoe",
    "farming includes garden hoe candidate")

local definition = Registry.Get("lumber")
T.truthy(definition, "lumber requirement definition registered")
T.equal(#definition.requirements, 1,
    "lumber exposes one primary requirement")
local requirement = definition.requirements[1]
T.equal(requirement.role, "primary_tool", "lumber requirement role")
T.equal(requirement.equipSlot, "primary", "lumber equips the tool")
T.truthy(requirement.durable, "lumber tool is durable")
T.equal(requirement.candidates[1], "Base.Axe",
    "lumber prefers the canonical axe item")

local described = Registry.Describe("LUMBER")
T.equal(described.requirements[1].candidates[2], "Base.HandAxe",
    "requirement descriptions are serializable copies")
described.requirements[1].candidates[1] = "Changed"
T.equal(Registry.Get("LUMBER").requirements[1].candidates[1], "Base.Axe",
    "requirement descriptions do not mutate the registry")

T.finish("pnc_job_requirements_smoke")
