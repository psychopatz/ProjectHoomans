local T = require "tests/support/test"

local source = T.read("ProjectHoomans", "server",
    "PNC/Production/PNC_ResearchService.lua")
local prefix = "PNC/Production/ResearchService/"
local providers = {
    "PNC_ResearchService_Context",
    "PNC_ResearchService_Knowledge",
    "PNC_ResearchService_Queueing",
    "PNC_ResearchService_Artifacts",
    "PNC_ResearchService_Lifecycle",
    "PNC_ResearchService_Snapshot",
}

local previous = 0
local publicFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    local scopes = { "Commands", "Queries" }
    local scopeIndex
    for scopeIndex = 1, #scopes do
        local scope = scopes[scopeIndex]
        for name in providerSource:gmatch(
            "function%s+Service%." .. scope .. "%.([%w_]+)"
        ) do
            publicFunctions[scope .. "." .. name] = true
        end
    end
end

PNC = { WorkService = {
    CancellationHandlers = {},
    RegisterPreparation = function() end,
    RegisterCompletion = function() end,
    RegisterTargetProvider = function() end,
    RegisterReconciler = function() end,
} }
package.preload["PNC/Production/PNC_WorkInputService"] = function()
    PNC.WorkInputService = {}
    return PNC.WorkInputService
end
T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_ResearchService.lua")

local publicCount = 0
for qualifiedName in pairs(publicFunctions) do
    publicCount = publicCount + 1
    local scope, name = qualifiedName:match("^([^.]+)%.(.+)$")
    T.equal(type(PNC.ResearchService[scope][name]), "function",
        "entry point preserves ResearchService." .. qualifiedName)
end
T.equal(publicCount, 11, "research-service function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PNC/Production/PNC_WorkInputService"] = nil

T.finish("pnc_research_service_presence_boundary_smoke")
