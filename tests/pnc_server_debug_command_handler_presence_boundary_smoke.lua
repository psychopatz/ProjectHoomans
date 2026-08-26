local T = require "tests/support/test"

local path = "PNC/Networking/Handlers/PNC_ServerDebugCommandHandler.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Networking/Handlers/ServerDebugCommandHandler/"
local providers = {
    "PNC_ServerDebugCommandHandler_Core",
    "PNC_ServerDebugCommandHandler_Relationships",
    "PNC_ServerDebugCommandHandler_KnowledgeRecruitment",
    "PNC_ServerDebugCommandHandler_Diagnostics",
    "PNC_ServerDebugCommandHandler_ApiActions",
    "PNC_ServerDebugCommandHandler_BodyAudit",
    "PNC_ServerDebugCommandHandler_Routing",
}
local previous = 0
local i
for i = 1, #providers do
    local needle = 'require "' .. prefix .. providers[i] .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, providers[i] .. " load order")
    previous = position
    T.read("ProjectHoomans", "server", prefix .. providers[i] .. ".lua")
end
local registered
PNC = {
    ServerCommandRouter = {
        Register = function(_, callback) registered = callback end,
    },
    Const = { CMD_DEBUG = "DebugCommand" },
}
local Handler = T.load("ProjectHoomans", "server", path)
T.equal(type(Handler.ConfigureTeleport), "function",
    "ConfigureTeleport remains public")
T.equal(type(registered), "function", "debug route remains registered")
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
T.finish("pnc_server_debug_command_handler_presence_boundary_smoke")
