local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Social/PNC_SocialEventService.lua")
local prefix = "PNC/Social/SocialEventService/"
local providers = {
    "PNC_SocialEventService_Context",
    "PNC_SocialEventService_Validation",
    "PNC_SocialEventService_Observers",
    "PNC_SocialEventService_Process",
    "PNC_SocialEventService_Emit",
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
    for name in providerSource:gmatch(
        "function%s+SocialEvents%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Social/PNC_SocialEventService.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.SocialEvents[name]), "function",
        "entry point preserves SocialEvents." .. name)
end
T.equal(publicCount, 4, "social-event-service function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_social_event_service_presence_boundary_smoke")
