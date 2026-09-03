local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Production/PNC_WorkService.lua")
local prefix = "PNC/Production/WorkService/"
local providers = {
    "PNC_WorkService_WorkLocation",
    "PNC_WorkService_Core",
    "PNC_WorkService_QueueAndClaims",
    "PNC_WorkService_WorkerReconciliation",
    "PNC_WorkService_Targets",
    "PNC_WorkService_Progress",
    "PNC_WorkService_Commands",
    "PNC_WorkService_Queries",
    "PNC_WorkService_Snapshots",
    "PNC_WorkService_Scheduler",
}

local previous = 0
local public = { service = {}, commands = {}, queries = {} }
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
        "function%s+Service%.Commands%.([%w_]+)"
    ) do
        public.commands[name] = true
    end
    for name in providerSource:gmatch(
        "function%s+Service%.Queries%.([%w_]+)"
    ) do
        public.queries[name] = true
    end
    for name in providerSource:gmatch(
        "function%s+Service%.([%w_]+)"
    ) do
        if name ~= "Commands" and name ~= "Queries" then
            public.service[name] = true
        end
    end
end

PNC = {
    WorkRepository = {},
    WorkDefinitions = {
        STATUS = {},
        BALANCE = {},
        CAPABILITY_BY_OPERATION = {},
        JOB_BY_OPERATION = {},
    },
    EventTypes = {},
}
T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkService.lua")

local serviceCount, commandCount, queryCount = 0, 0, 0
for name, _ in pairs(public.service) do
    serviceCount = serviceCount + 1
    T.equal(type(PNC.WorkService[name]), "function",
        "entry point should preserve WorkService." .. name)
end
for name, _ in pairs(public.commands) do
    commandCount = commandCount + 1
    T.equal(type(PNC.WorkService.Commands[name]), "function",
        "entry point should preserve Commands." .. name)
end
for name, _ in pairs(public.queries) do
    queryCount = queryCount + 1
    T.equal(type(PNC.WorkService.Queries[name]), "function",
        "entry point should preserve Queries." .. name)
end
T.equal(serviceCount, 9, "service function declaration count")
T.equal(commandCount, 17, "command function declaration count")
T.equal(queryCount, 6, "query function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_work_service_presence_boundary_smoke")
