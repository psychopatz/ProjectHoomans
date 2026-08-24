local T = require "tests/support/test"

local path = "PNC/Production/ConstructionService/" ..
    "PNC_ConstructionService_Lifecycle.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Production/ConstructionService/" ..
    "ConstructionService_Lifecycle/"
local providers = {
    "PNC_ConstructionService_Lifecycle_Targets",
    "PNC_ConstructionService_Lifecycle_Preparation",
    "PNC_ConstructionService_Lifecycle_Requirements",
    "PNC_ConstructionService_Lifecycle_Refunds",
    "PNC_ConstructionService_Lifecycle_Completions",
    "PNC_ConstructionService_Lifecycle_Cancellation",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

local targets = {}
local preparations = {}
local completions = {}
PNC = {
    ConstructionService = { Internal = {} },
    WorkService = {
        CancellationHandlers = {},
        RegisterTargetProvider = function(operation, handler)
            targets[operation] = handler
        end,
        RegisterPreparation = function(operation, handler)
            preparations[operation] = handler
        end,
        RegisterCompletion = function(operation, handler)
            completions[operation] = handler
        end,
    },
}
T.load("ProjectHoomans", "server", path)

local internal = PNC.ConstructionService.Internal
for _, name in ipairs({
    "ResolveTarget",
    "Prepare",
    "ConstructionRequirements",
    "CancellationRefund",
}) do
    T.equal(type(internal[name]), "function",
        "lifecycle preserves internal " .. name)
end
T.equal(type(PNC.ConstructionService.Queries.GetCancellationRefund),
    "function", "cancellation-refund query remains public")
for _, operation in ipairs({
    "CONSTRUCT",
    "RECONSTRUCT",
    "DECONSTRUCT",
}) do
    T.equal(type(targets[operation]), "function",
        operation .. " target provider remains registered")
    T.equal(type(completions[operation]), "function",
        operation .. " completion remains registered")
    T.equal(type(PNC.WorkService.CancellationHandlers[operation]),
        "function", operation .. " cancellation remains registered")
end
T.equal(type(preparations.CONSTRUCT), "function",
    "construct preparation remains registered")
T.equal(type(preparations.RECONSTRUCT), "function",
    "reconstruct preparation remains registered")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_construction_lifecycle_presence_boundary_smoke")
