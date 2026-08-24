local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(SERVER .. "Social/PNC_ConductService.lua")
local root = SERVER .. "Social/ConductService/"
local core = T.read(root .. "PNC_ConductService_Core.lua")
local internals = T.read(root .. "PNC_ConductService_EvidenceInternals.lua")
local queries = T.read(root .. "PNC_ConductService_Queries.lua")
local social = T.read(root .. "PNC_ConductService_SocialEvents.lua")
local actions = T.read(root .. "PNC_ConductService_EvidenceActions.lua")

T.contains(entry, "PNC.Conduct.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.Resolve",
    "owner resolution stays behind the internal boundary")
T.contains(internals, "function H.PrepareEvidence",
    "evidence preparation stays behind the internal boundary")
T.contains(queries, "function Conduct.GetForEntity",
    "public queries remain available")
T.contains(social, "function Conduct.PrepareSocialEvent",
    "public social-event preparation remains available")
T.contains(actions, "function Conduct.AddEvidence",
    "public evidence actions remain available")
T.falsy(string.find(entry, "function Conduct.AddEvidence", 1, true),
    "entry contains wiring rather than implementation")
