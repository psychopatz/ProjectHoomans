local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Communities/PNC_CommunityService.lua")
local prefix = "PNC/Communities/CommunityService/"
local providers = {
    "PNC_CommunityService_Core",
    "PNC_CommunityService_Indexes",
    "PNC_CommunityService_Persistence",
    "PNC_CommunityService_Queries",
    "PNC_CommunityService_Sites",
    "PNC_CommunityService_Affiliations",
    "PNC_CommunityService_Membership",
    "PNC_CommunityService_Leadership",
    "PNC_CommunityService_Attributes",
    "PNC_CommunityService_Supplies",
    "PNC_CommunityService_Lifecycle",
    "PNC_CommunityService_Validation",
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
        "function%s+Communities%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {
    Core = { GenerateID = function() return "community:1" end },
    CommunityConstants = {},
    CommunityTypes = {
        NewRegistry = function()
            return { byID = {}, byFaction = {}, sitesByID = {}, revision = 0 }
        end,
        NormalizeRegistry = function(value) return value end,
        NormalizeCommunity = function(value) return value end,
    },
    CommunityMath = {
        IsInsideHomeArea = function() return false end,
        GetDistanceFromHome = function() return 0 end,
    },
    FactionTypes = {},
}
T.load("ProjectHoomans", "server", "PNC/Communities/PNC_CommunityService.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.Communities[name]), "function",
        "entry point should preserve Communities." .. name)
end
T.equal(publicCount, 40, "public function declaration count")
T.equal(type(PNC.Communities.IsInsideHomeArea), "function",
    "inside-home alias")
T.equal(type(PNC.Communities.GetDistanceFromHome), "function",
    "home-distance alias")
T.equal(type(PNC.Communities.NormalizeRegistry), "function",
    "registry normalization alias")
T.equal(type(PNC.Communities.NormalizeCommunity), "function",
    "community normalization alias")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_community_service_presence_boundary_smoke")
