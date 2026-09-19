-- Persistent real-Lua semantic worker for the Python harness.
--
-- This file bootstraps the ordered worker modules and owns the JSON-lines loop.

local repository = arg[1] or os.getenv("PNC_HARNESS_REPOSITORY") or "."
local coreRepository = arg[2]
    or os.getenv("PNC_HARNESS_CORE_REPOSITORY")
    or repository .. "/../psychopatzCore"
local hoomansRuntime = os.getenv("PZ_TEST_HOOMANS_RUNTIME") or "42.20"
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME") or "42.20"

local function path(root, relative)
    return root .. "/" .. relative
end

local packagePaths = {
    path(repository, "tools/semantic_harness/lua/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/shared/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/server/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/client/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/common/media/lua/shared/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/" .. coreRuntime .. "/media/lua/shared/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/common/media/lua/client/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/" .. coreRuntime .. "/media/lua/client/?.lua"),
    package.path,
}
package.path = table.concat(packagePaths, ";")

local Protocol = require "worker/Protocol"
local RuntimeState = require "worker/RuntimeState"
local Values = require "worker/Values"
local Translations = require "worker/Translations"
local RuntimeEnvironment = require "worker/RuntimeEnvironment"
local SemanticAdapters = require "worker/SemanticAdapters"
local InventoryFixtures = require "worker/InventoryFixtures"
local ProductionModules = require "worker/ProductionModules"
local Conversation = require "worker/Conversation"
local OutputProjection = require "worker/OutputProjection"
local ScenarioSession = require "worker/ScenarioSession"
local CommandRouter = require "worker/CommandRouter"

local Runtime = RuntimeState.new()
local Context = {
    repository = repository,
    coreRepository = coreRepository,
    hoomansRuntime = hoomansRuntime,
    coreRuntime = coreRuntime,
    Runtime = Runtime,
    RuntimeState = RuntimeState,
    Protocol = Protocol,
    Values = Values,
    Translations = Translations,
    RuntimeEnvironment = RuntimeEnvironment,
    SemanticAdapters = SemanticAdapters,
    InventoryFixtures = InventoryFixtures,
    ProductionModules = ProductionModules,
    Conversation = Conversation,
    OutputProjection = OutputProjection,
    ScenarioSession = ScenarioSession,
}

ScenarioSession.configureRuntime(Context)
ProductionModules.load(Context)
ScenarioSession.reset(Context, ScenarioSession.initialScenario)

Protocol.emit(CommandRouter.hello(Context), "__hello__")

for line in io.lines() do
    local request, reason = Protocol.readRequest(line)
    if not request then
        io.stderr:write("protocol error: " .. tostring(reason) .. "\n")
        break
    end
    local response, failure, shouldQuit = CommandRouter.dispatch(Context, request)
    if failure then
        Protocol.fail(request.id, failure)
    elseif response then
        Protocol.emit(response, request.id)
    end
    if shouldQuit then break end
end
