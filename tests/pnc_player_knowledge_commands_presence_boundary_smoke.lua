local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(SERVER .. "Knowledge/PNC_PlayerKnowledgeCommands.lua")
local root = SERVER .. "Knowledge/PlayerKnowledgeCommands/"
local core = T.read(root .. "PNC_PlayerKnowledgeCommands_Core.lua")
local presentation = T.read(
    root .. "PNC_PlayerKnowledgeCommands_Presentation.lua"
)
local bootstrap = T.read(root .. "PNC_PlayerKnowledgeCommands_Bootstrap.lua")
local disclosure = T.read(
    root .. "PNC_PlayerKnowledgeCommands_Disclosure.lua"
)

T.contains(entry, "PNC.PlayerKnowledgeCommands.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.SanitizeSnapshot",
    "snapshot sanitation stays behind the internal boundary")
T.contains(presentation, "function Commands.HandlePresentation",
    "public presentation command remains available")
T.contains(bootstrap, "function Commands.HandleBootstrap",
    "public bootstrap command remains available")
T.contains(disclosure, "function Commands.HandleDisclosure",
    "public disclosure command remains available")
T.falsy(string.find(entry, "function Commands.HandleDisclosure", 1, true),
    "entry contains wiring rather than implementation")
