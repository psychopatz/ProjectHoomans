local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
PNC = {}

local Targets = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_InteractionTargetResolver.lua")

local component = {
    id = "research:table",
    kind = "anchor",
    role = "work.research",
    targetResolver = "workstationEdge",
    revision = 1,
    x = 10, y = 10, z = 0,
    occupiedRegion = { levels = {
        [0] = { rows = { [10] = { 10, 11 } } },
    } },
}
local targets = Targets.Resolve(component, { abstract = true })
T.truthy(#targets > 0, "workstation edge resolver creates approach targets")
for _, target in ipairs(targets) do
    T.truthy(target.interactionTarget,
        "workstation edge target identifies the physical interaction tile")
    T.truthy(target.approachKey,
        "workstation edge target has a stable collision key")
    T.falsy(math.floor(target.x) == 10 and math.floor(target.y) == 10,
        "workstation edge targets stay outside the occupied table tiles")
end
T.truthy(targets[1].interactionX == 10.5
    or targets[1].interactionX == 11.5,
    "workstation edge target retains the table tile it borders")

local exact = Targets.Resolve({
    id = "legacy:anchor", kind = "anchor", x = 20, y = 20, z = 0,
    revision = 1,
}, { abstract = true })
T.equal(exact[1].x, 20,
    "workstation approach remains opt-in for other workstations")
T.equal(exact[1].y, 20,
    "non-opted-in workstations retain the legacy exact target")

T.finish("pnc_workstation_approach_smoke")
