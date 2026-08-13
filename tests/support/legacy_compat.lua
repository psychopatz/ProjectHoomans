-- Runner-only bridge for tests not yet migrated to tests/support/test.lua.
-- It rewrites only known mod runtime roots; arbitrary paths are untouched.
local Compat = {}

local repository = os.getenv("PZ_TEST_REPOSITORY") or "."
local config = dofile(repository .. "/tests/test_config.lua")
local hoomansRuntime = os.getenv("PZ_TEST_HOOMANS_RUNTIME")
    or config.projectHoomansRuntime
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME")
    or config.psychopatzCoreRuntime

function Compat.rewrite(path)
    if type(path) ~= "string" then return path end
    path = string.gsub(path,
        "Contents/mods/ProjectHoomans/%d+%.%d+/media/lua/",
        "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/")
    path = string.gsub(path,
        "Contents/mods/PsychopatzCore/%d+%.%d+/media/lua/",
        "Contents/mods/PsychopatzCore/" .. coreRuntime .. "/media/lua/")
    return path
end

local originalDofile = dofile
dofile = function(path) return originalDofile(Compat.rewrite(path)) end

local originalLoadfile = loadfile
loadfile = function(path) return originalLoadfile(Compat.rewrite(path)) end

local originalOpen = io.open
io.open = function(path, mode) return originalOpen(Compat.rewrite(path), mode) end

local originalLines = io.lines
io.lines = function(path)
    if path == nil then return originalLines() end
    return originalLines(Compat.rewrite(path))
end

local originalRequire = require
require = function(name)
    package.path = Compat.rewrite(package.path)
    return originalRequire(name)
end

return Compat
