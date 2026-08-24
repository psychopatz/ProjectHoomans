local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Production/PNC_CraftingService.lua")
local prefix = "PNC/Production/CraftingService/"
local providers = {
    "PNC_CraftingService_Core",
    "PNC_CraftingService_Commands",
    "PNC_CraftingService_Completions",
    "PNC_CraftingService_Lifecycle",
    "PNC_CraftingService_Queries",
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
    for namespace, name in providerSource:gmatch(
        "function%s+Service%.([%w_]+)%.([%w_]+)"
    ) do
        publicFunctions[namespace .. "." .. name] = true
    end
end

package.preload["PNC/Production/PNC_WorkInputService"] =
    function() return {} end
PNC = {
    WorkService = {
        CancellationHandlers = {},
        RegisterPreparation = function() end,
        RegisterCollection = function() end,
        RegisterCompletion = function() end,
    },
}
T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_CraftingService.lua")

local publicCount = 0
for qualifiedName in pairs(publicFunctions) do
    publicCount = publicCount + 1
    local namespace, name = qualifiedName:match("^([^.]+)%.(.+)$")
    T.equal(type(PNC.CraftingService[namespace][name]), "function",
        "entry point preserves CraftingService." .. qualifiedName)
end
T.equal(publicCount, 5, "crafting-service public function count")
T.equal(type(PNC.WorkService.CancellationHandlers.CRAFT), "function",
    "craft cancellation handler remains registered")
T.equal(type(PNC.WorkService.CancellationHandlers.DISASSEMBLE), "function",
    "disassembly cancellation handler remains registered")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PNC/Production/PNC_WorkInputService"] = nil

T.finish("pnc_crafting_service_presence_boundary_smoke")
