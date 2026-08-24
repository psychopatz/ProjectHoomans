local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Player/PNC_PlayerCharacterService.lua")
local prefix = "PNC/Player/PlayerCharacterService/"
local providers = {
    "PNC_PlayerCharacterService_Core",
    "PNC_PlayerCharacterService_MirrorsAndIndexes",
    "PNC_PlayerCharacterService_RecoveryBindings",
    "PNC_PlayerCharacterService_Persistence",
    "PNC_PlayerCharacterService_SocialProfiles",
    "PNC_PlayerCharacterService_StatusValidation",
    "PNC_PlayerCharacterService_IdentityCreation",
    "PNC_PlayerCharacterService_EnsureIdentity",
    "PNC_PlayerCharacterService_Resolution",
    "PNC_PlayerCharacterService_Lifecycle",
    "PNC_PlayerCharacterService_PlayerContext",
}

local previous = 0
local publicFunctions = {}
local contextFunctions = {}
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
        "function%s+PlayerCharacters%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
    for name in providerSource:gmatch(
        "function%s+PNC%.PlayerContext%.([%w_]+)"
    ) do
        contextFunctions[name] = true
    end
end

PNC = {
    PlayerCharacterConstants = { UUID_PREFIX = "character" },
    PlayerCharacterTypes = {
        NewRegistry = function()
            return {
                byUUID = {}, byAccount = {}, byAccountKey = {},
                revision = 0,
            }
        end,
    },
    Core = { GenerateID = function() return "character:1" end },
}
T.load("ProjectHoomans", "server", "PNC/Player/PNC_PlayerCharacterService.lua")

local publicCount, contextCount = 0, 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.PlayerCharacters[name]), "function",
        "entry point should preserve PlayerCharacters." .. name)
end
for name, _ in pairs(contextFunctions) do
    contextCount = contextCount + 1
    T.equal(type(PNC.PlayerContext[name]), "function",
        "entry point should preserve PlayerContext." .. name)
end
T.equal(publicCount, 22, "player-character function declaration count")
T.equal(contextCount, 2, "player-context function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_player_character_service_presence_boundary_smoke")
