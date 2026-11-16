local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[copy(key)] = copy(child) end
    return output
end

PNC = {
    Identity = {
        NormalizeSeed = function(value) return tonumber(value) or 17 end,
        Index = function() return 1 end,
        MixSeed = function() return 17 end,
        GetCharacterAppearance = function()
            return {
                skinTexture = "FemaleBody03",
                skinColor = { r = 0.44, g = 0.31, b = 0.22 },
                hairColor = { r = 0.12, g = 0.07, b = 0.03 },
            }
        end,
        GenerateResolvedIdentity = function(source)
            local authored = source and source.identity or {}
            local survivor = authored.survivor or {}
            local forename = survivor.forename or "Alex"
            local surname = survivor.surname or "Generated"
            return {
                displayName = tostring(forename) .. " " .. tostring(surname),
                nickname = authored.nickname,
                isFemale = source.isFemale == true,
                survivor = copy(survivor),
            }
        end,
    },
    Registry = { MarkDirty = function() end },
    SocialProfiles = {
        GetPlayerProfile = function()
            return { orientation = "gay" }
        end,
    },
    StartingCompanionTraits = {},
}

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_NPCAuthoring.lua")
local Authoring = PNC.NPCAuthoring
local Blueprint = Authoring.Blueprint
local H = PNC.StartingCompanionServiceInternal or {}
PNC.StartingCompanionServiceInternal = H
T.load("ProjectHoomans", "server",
    "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Core.lua")
T.load("ProjectHoomans", "server",
    "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Identity.lua")

local spec = {
    id = "PNC_HasBrother",
    relationshipKind = "brother",
    sex = "male",
    sharesSurname = true,
    sharesAppearance = true,
}
local blueprint = Blueprint.New({
    id = "starter:PNC_HasBrother",
    generationSeed = 17,
})
blueprint = Blueprint.Set(blueprint, "identity.forename", "Riley")
blueprint = Blueprint.Set(blueprint, "identity.surname", "Spoofed")
blueprint = Blueprint.Set(blueprint, "identity.nickname", "Rye")
blueprint = Blueprint.Set(blueprint, "identity.isFemale", true)

local player = {
    isFemale = function() return true end,
    getDescriptor = function()
        return {
            getSurname = function() return "Reyes" end,
            isFemale = function() return true end,
        }
    end,
}
local character = { uuid = "character-authority" }
local definition, plan = H.ResolveAuthoringDefinition(
    player,
    character,
    "starting:authority:brother",
    spec,
    17,
    blueprint
)

T.truthy(definition, "authoritative starter resolution produces a definition")
T.truthy(plan, "authoritative starter resolution retains the shared plan")
T.equal(definition.identity.nickname, "Rye",
    "authoritative resolution preserves canonical nickname")
T.equal(definition.identity.survivor.surname, "Reyes",
    "authoritative relationship binding uses the current player surname")
T.equal(definition.identity.survivor.forename, "Riley",
    "authoritative resolution preserves explicit forename")
T.equal(definition.isFemale, false,
    "authoritative brother policy overrides spoofed sex")
T.equal(definition.identity.survivor.skinTexture, "MaleBody03",
    "authoritative family appearance uses the relationship sex")
T.equal(definition.identity.survivor.skinColor.r, 0.44,
    "authoritative family appearance uses current player color")
T.equal(definition.resolutionTrace.fields["identity.nickname"].source,
    "explicit", "authoritative definition carries the shared trace")
T.equal(definition.resolutionTrace.fields["identity.surname"].source,
    "inherited", "trace identifies authoritative surname inheritance")
T.finish("pnc_starting_companion_authority_smoke")
