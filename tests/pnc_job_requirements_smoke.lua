local T = require "tests/support/test"

local Registry = T.load("ProjectHoomans", "shared",
    "PNC/Core/Jobs/PNC_JobRequirements.lua")

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
