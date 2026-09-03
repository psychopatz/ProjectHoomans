local T = require "tests/support/test"

local path = "PNC/Tasking/PNC_Tasking.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Tasking/Tasking/"
local providers = {
    "PNC_Tasking_Core",
    "PNC_Tasking_Evaluation",
    "PNC_Tasking_Lifecycle",
    "PNC_Tasking_Pump",
    "PNC_Tasking_Queries",
}

local previous = 0
local commandFunctions = {}
local queryFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    for name in providerSource:gmatch(
        "function%s+Tasking%.Commands%.([%w_]+)"
    ) do commandFunctions[name] = true end
    for name in providerSource:gmatch(
        "function%s+Tasking%.Queries%.([%w_]+)"
    ) do queryFunctions[name] = true end
end

package.preload["PNC/Tasking/PNC_TaskPriority"] = function()
    PNC.TaskPriority = {}; return PNC.TaskPriority
end
package.preload["PNC/Tasking/PNC_TaskIntent"] = function()
    PNC.TaskIntent = {}; return PNC.TaskIntent
end
package.preload["PNC/Tasking/PNC_TaskLeaseService"] = function()
    PNC.TaskLeaseService = { Active = {} }; return PNC.TaskLeaseService
end
package.preload["PNC/Tasking/PNC_TaskExecutors"] = function() return {} end
package.preload["PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"] =
    function() return {} end
PNC = { Core = {} }
local Tasking = T.load("ProjectHoomans", "server", path)

local commandCount = 0
for name in pairs(commandFunctions) do
    commandCount = commandCount + 1
    T.equal(type(Tasking.Commands[name]), "function",
        "entry point preserves Tasking.Commands." .. name)
end
T.equal(commandCount, 9, "tasking command function count")
local queryCount = 0
for name in pairs(queryFunctions) do
    queryCount = queryCount + 1
    T.equal(type(Tasking.Queries[name]), "function",
        "entry point preserves Tasking.Queries." .. name)
end
T.equal(queryCount, 2, "tasking query function count")

local accepted, reason = Tasking.Commands.RegisterProvider("farming", {
    GetCandidates = function() return {} end,
    Validate = function() return true end,
    Assign = function() return {} end,
})
T.falsy(accepted, "watchdog provider without recovery must be rejected")
T.equal(reason, "TASK_PROVIDER_RECOVERY_UNSUPPORTED",
    "watchdog provider rejection reason")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_tasking_presence_boundary_smoke")
