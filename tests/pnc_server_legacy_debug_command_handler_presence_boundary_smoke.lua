local T = require "tests/support/test"

local path = "PNC/Networking/Handlers/PNC_ServerLegacyDebugCommandHandler.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/"
local providers = {
    "PNC_ServerLegacyDebugCommandHandler_Core",
    "PNC_ServerLegacyDebugCommandHandler_Relationships",
    "PNC_ServerLegacyDebugCommandHandler_KnowledgeRecruitment",
    "PNC_ServerLegacyDebugCommandHandler_Diagnostics",
    "PNC_ServerLegacyDebugCommandHandler_ApiActions",
    "PNC_ServerLegacyDebugCommandHandler_BodyAudit",
    "PNC_ServerLegacyDebugCommandHandler_Routing",
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
T.finish("pnc_server_legacy_debug_command_handler_presence_boundary_smoke")
