-- Persistent real-Lua semantic worker for the Python harness.
--
-- This file bootstraps the ordered worker modules and owns the JSON-lines loop.

local repository = arg[1] or os.getenv("PNC_HARNESS_REPOSITORY") or "."
local coreRepository = arg[2]
    or os.getenv("PNC_HARNESS_CORE_REPOSITORY")
    or repository .. "/../psychopatzCore"
local hoomansRuntime = os.getenv("PZ_TEST_HOOMANS_RUNTIME")
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME")
if not hoomansRuntime or not coreRuntime then
    error(
        "semantic worker requires PZ_TEST_HOOMANS_RUNTIME and "
            .. "PZ_TEST_CORE_RUNTIME from the host runtime resolver"
    )
end
local dynamicTradingRepository = os.getenv(
    "PNC_HARNESS_DYNAMIC_TRADING_REPOSITORY"
) or repository .. "/../DynamicTrading"
local dynamicTradingRuntime = os.getenv("PZ_TEST_DYNAMIC_TRADING_RUNTIME")

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
if dynamicTradingRuntime then
    packagePaths[#packagePaths + 1] = path(
        dynamicTradingRepository,
        "Contents/mods/DTCommon/" .. dynamicTradingRuntime
            .. "/media/lua/shared/?.lua"
    )
    packagePaths[#packagePaths + 1] = path(
        dynamicTradingRepository,
        "Contents/mods/DTCommon/common/media/lua/shared/?.lua"
    )
    packagePaths[#packagePaths + 1] = path(
        dynamicTradingRepository,
        "Contents/mods/DTHoomans/" .. dynamicTradingRuntime
            .. "/media/lua/shared/?.lua"
    )
    packagePaths[#packagePaths + 1] = path(
        dynamicTradingRepository,
        "Contents/mods/DTHoomans/common/media/lua/shared/?.lua"
    )
end
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
local FlowEditor = require "worker/FlowEditor"
local InteractionEditor = require "worker/InteractionEditor"
local ScenarioSession = require "worker/ScenarioSession"
local ProductionRehydration = require "worker/ProductionRehydration"
local CommandRouter = require "worker/CommandRouter"
local Commitments = require "worker/Commitments"

local Runtime = RuntimeState.new()
local Context = {
    repository = repository,
    coreRepository = coreRepository,
    dynamicTradingRepository = dynamicTradingRepository,
    dynamicTradingRuntime = dynamicTradingRuntime,
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
    FlowEditor = FlowEditor,
    InteractionEditor = InteractionEditor,
    ScenarioSession = ScenarioSession,
    ProductionRehydration = ProductionRehydration,
    Commitments = Commitments,
    EngineFacts = nil,
    EngineEvents = nil,
}

ScenarioSession.configureRuntime(Context)
ProductionModules.load(Context)
-- After *all* production capability providers are loaded, bring the
-- existing automatic generation registry to its final startup signature.
-- Otherwise the first FLOW_CATALOG request adds pools that the read-only
-- RESPONSE_POOL_LIST request could not see. This changes no gameplay
-- authority, does not select dialogue, and stays in the fixture worker.
local CapabilityCatalog = PNC.Semantics.CapabilityCatalog
if CapabilityCatalog
    and type(CapabilityCatalog.EnsureAutomaticGeneration) == "function"
then
    CapabilityCatalog.EnsureAutomaticGeneration()
end
Context.EngineFacts = PNC.Semantics.EngineFacts
Context.EngineEvents = PNC.Semantics.EngineEvents
Runtime.productionRelationshipService = {}
for _, method in ipairs({
    "Get", "GetOrCreate", "ApplyConversationEffect", "ApplyEventMutation",
    "EvaluateProposal", "Propose", "Preview", "SetInitialBaseline",
    "SetDebugBaseline", "AddMemory", "RemoveMemory", "RecordInteraction",
}) do
    if PNC.Relationships and type(PNC.Relationships[method]) == "function" then
        Runtime.productionRelationshipService[method] = PNC.Relationships[method]
    end
end
Runtime.productionPlayerCharactersService = {
    GetEntityKey = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey,
    GetRegistryRecord = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord,
    ApplyConductRecord = PNC.PlayerCharacters
        and PNC.PlayerCharacters.ApplyConductRecord,
}
ScenarioSession.importSource(
    Context,
    ScenarioSession.initialScenario,
    {
        sourceKind = "FIXTURE",
        sourceID = "fixture:worker-bootstrap",
        mode = "developer_test",
    }
)

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
