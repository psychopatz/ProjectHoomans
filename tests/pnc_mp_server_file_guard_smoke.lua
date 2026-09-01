local T = require "tests/support/test"
local ROOT = T.path("ProjectHoomans", "server", "PNC/")

local serverOnlyFiles = {}
local listing = T.truthy(io.popen(
    "find " .. ROOT
        .. " -type f -name '*.lua' ! -name '00_PNC_Server_Init.lua' | sort"
))
for path in listing:lines() do
    serverOnlyFiles[#serverOnlyFiles + 1] = path
end
listing:close()
T.equal(#serverOnlyFiles, 628,
    "server Lua inventory changed without updating the MP loader gate")

isClient = function() return true end
isServer = function() return false end
PNC = {
    Core = {
        IsClientOnly = function() return true end,
    },
}
PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return false end,
    },
}

local originalRequire = require
require = function(name)
    error("pure client required server module: " .. tostring(name))
end
for _, path in ipairs(serverOnlyFiles) do
    T.load(path)
end
require = originalRequire

T.truthy(PNC.ServerCommandRouter == nil
    and PNC.ServerDebugCommandHandler == nil
    and PNC.Supply == nil
    and PNC.ColonyStorageService == nil,
    "pure multiplayer client initialized server-only Project Hoomans state")

isServer = function() return true end
PsychopatzCore.RuntimeRole.AllowsServerCode = function() return true end
local calls = {}
require = function(name)
    calls[#calls + 1] = name
    return true
end
PNC = {
    Core = {
        IsClientOnly = function() return false end,
    },
    SupplyInventory = { Commands = {}, Queries = {} },
    NPCSupplyService = { Process = function() end },
}
local supply = T.load(ROOT .. "Supply/PNC_Supply.lua")
require = originalRequire

T.equal(#calls, 8, "hosted server skipped Supply composition")
T.equal(supply.Process, PNC.NPCSupplyService.Process,
    "hosted server did not bind the Supply process facade")

T.finish("pnc_mp_server_file_guard_smoke")
