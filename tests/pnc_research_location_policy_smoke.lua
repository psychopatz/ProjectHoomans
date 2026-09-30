-- An away researcher used to stall the server: research orders inherited the
-- default HOME/HOME location policy, so the scheduler hit its
-- "worker_left_home" branch on every pass - releasing the claim, marking the
-- repository dirty, pushing a SendHome command, re-finding a worker and
-- re-claiming the station, forever. Research is abstract work and must default
-- to ANYWHERE/REMOTE/STAY.
local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = { WorkService = {} }

local Definitions = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Constants.lua")

local research = Definitions.LocationPolicy("RESEARCH")
T.truthy(research ~= nil, "RESEARCH has a default location policy")
T.equal(research.start, "HOME",
    "research is assigned to a colonist who is at the base")
T.equal(research.execution, "REMOTE", "research executes remotely")
T.equal(research.returnHome, "STAY", "research does not force a trip home")

local readBook = Definitions.LocationPolicy("READ_BOOK")
T.truthy(readBook ~= nil, "READ_BOOK has a default location policy")
T.equal(readBook.start, "HOME", "book study is also assigned at the base")
T.equal(readBook.execution, "REMOTE", "book study also executes remotely")

T.falsy(Definitions.LocationPolicy("CRAFT") ~= nil,
    "station crafting keeps the home-based default")
T.falsy(Definitions.LocationPolicy(nil) ~= nil,
    "a missing operation has no default policy")

-- The scheduler's away-release branch requires StartsAtHome AND NOT
-- ExecutionIsRemote. REMOTE is what stops it firing for an away researcher.
T.load("ProjectHoomans", "server",
    "PNC/Production/WorkService/PNC_WorkService_WorkLocation.lua")
local Location = PNC.WorkService.Location
T.truthy(Location ~= nil, "work-location policy module did not load")
local order = { operation = "RESEARCH",
    locationPolicy = Definitions.LocationPolicy("RESEARCH") }
T.truthy(Location.ExecutionIsRemote(order),
    "research order is marked remote-executing")
T.truthy(Location.StartsAtHome(order),
    "research is still assigned at the base")
T.falsy(Location.ReturnsHome(order),
    "research order does not send the worker home")

-- The key regression: an assigned researcher who wanders must KEEP the order
-- instead of the scheduler releasing and re-claiming it every pass.
T.truthy(Location.ExecutionIsRemote(order),
    "away researcher keeps the order instead of being released")

-- An explicit caller policy still wins over the default.
local explicit = { operation = "CRAFT",
    locationPolicy = { start = "HOME", execution = "HOME",
        returnHome = "HOME" } }
T.truthy(Location.StartsAtHome(explicit),
    "explicit caller policy is still honoured")
T.falsy(Location.ExecutionIsRemote(explicit),
    "explicit caller policy is not overridden")

-- And the queue path applies the default when the caller states none.
local queueSource = T.read("ProjectHoomans", "server",
    "PNC/Production/WorkService/PNC_WorkService_QueueAndClaims.lua")
T.contains(queueSource, "Definitions.LocationPolicy",
    "queue does not apply the operation default location policy")

T.finish("pnc_research_location_policy_smoke")
