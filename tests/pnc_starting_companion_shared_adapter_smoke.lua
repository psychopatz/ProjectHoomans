local T = require "tests/support/test"

T.addPackagePaths()
ZombRand = function(maximum) return math.min(7, (maximum or 7) - 1) end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[copy(key)] = copy(child)
    end
    return output
end

PNC = {
    Core = { DeepCopy = copy },
    Identity = {},
    Inventory = { Queries = {} },
    SkillCatalog = { Find = function() return nil end },
    NPCTraits = {
        NormalizeID = function(id) return tostring(id or "steady") end,
        ResolveSet = function(source) return source, {} end,
    },
    UniqueNPCs = {},
}

PNC.Inventory.Queries.ToDefinitionSpec = function(item, key)
    local output = copy(item)
    output.key = key
    return output
end

package.preload["PNC/Core/Identity/PNC_UniqueNPCs"] =
    function() return PNC.UniqueNPCs end
package.preload["PNC/Core/Inventory/PNC_Inventory"] =
    function() return PNC.Inventory end

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Appearance.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileConstants.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileTypes.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialTraits.lua")

local StartingTraits = require "PNC/Core/Traits/PNC_StartingCompanionTraits"
local Session = require "PNC/CharacterCreation/PNC_StartingCompanionSession"
local Adapter = require
    "PNC/CharacterCreation/PNC_StartingCompanionAuthoringAdapter"
local Authoring = require "PNC/Core/Identity/PNC_NPCAuthoring"
local Blueprint = Authoring.Blueprint
local Model = require "PNC/Identity/PNC_UniqueNPCDraft"
local TID = StartingTraits.IDS

local function context(surname, female, orientation)
    return {
        playerSurname = surname,
        playerFemale = female,
        orientation = orientation,
        playerAppearance = {
            skinTexture = "FemaleBody03",
            skinColor = { r = 0.4, g = 0.3, b = 0.2 },
            hairColor = { r = 0.1, g = 0.1, b = 0.1 },
        },
    }
end

local session = Session.New({ sessionSeed = 123, context = context(
    "Reyes", true, "straight") })
session:Reconcile({ TID.BROTHER }, context("Reyes", true, "straight"))
local adapter = Adapter.New(session, TID.BROTHER)
local initialFingerprint = Blueprint.Fingerprint(session:GetBlueprint(TID.BROTHER))
local draft = adapter:BuildDraft()
T.truthy(draft, "shared adapter builds a resolved authoring draft")
T.falsy(adapter:CommitDraft(draft),
    "opening and closing without edits does not author customization")
T.equal(Blueprint.Fingerprint(session:GetBlueprint(TID.BROTHER)),
    initialFingerprint, "no-op presentation preserves blueprint intent")

draft.identity.survivor.forename = "Riley"
draft.identity.survivor.surname = "Spoofed"
draft.identity.nickname = "Rye"
draft.displayName = "Riley Spoofed"
T.truthy(adapter:CommitDraft(draft),
    "shared adapter commits an edited identity and nickname")
local blueprint = session:GetBlueprint(TID.BROTHER)
local forenameState, forename = Blueprint.Get(blueprint, "identity.forename")
local nicknameState, nickname = Blueprint.Get(blueprint, "identity.nickname")
local surnameState = Blueprint.Get(blueprint, "identity.surname")
T.equal(forenameState, "value", "first name remains canonical")
T.equal(forename, "Riley", "first name edit round-trips")
T.equal(nicknameState, "value", "nickname remains canonical")
T.equal(nickname, "Rye", "nickname edit round-trips")
T.equal(surnameState, "absent",
    "relationship surname cannot become authored through the adapter")

local visualDraft = adapter:BuildDraft()
local generationSeed = visualDraft.previewSeed
visualDraft.identity.survivor.hairModel = "Long"
visualDraft.appearanceAuthored.hairModel = true
T.truthy(adapter:CommitDraft(visualDraft),
    "shared adapter commits a visual field edit")
local visualBlueprint = session:GetBlueprint(TID.BROTHER)
local hairState, hair = Blueprint.Get(
    visualBlueprint, "appearance.hairModel")
local seedState, seedValue = Blueprint.Get(visualBlueprint, "identity.forename")
T.equal(hairState, "value", "hair edit remains canonical")
T.equal(hair, "Long", "hair edit round-trips through the session")
T.equal(seedState, "value", "unrelated identity remains authored")
T.equal(seedValue, "Riley", "visual edit does not reroll unrelated values")
T.equal(visualBlueprint.generationSeed, generationSeed,
    "visual edit does not advance the generation seed")

local reboundFingerprint = Blueprint.Fingerprint(visualBlueprint)
session:Refresh(context("Cruz", false, "straight"))
local rebound = adapter:BuildDraft()
local _, reboundSurname = Model.NameParts(rebound)
T.equal(reboundSurname, "Cruz",
    "player surname rebinding updates the shared preview")
T.equal(rebound.isFemale, false,
    "brother sex remains relationship-derived")
T.equal(rebound.identity.survivor.skinTexture, "MaleBody03",
    "family appearance rebinding updates the shared preview")
T.equal(Blueprint.Fingerprint(session:GetBlueprint(TID.BROTHER)),
    reboundFingerprint, "rebinding does not mutate stored blueprint intent")
T.falsy(adapter:CommitDraft(rebound),
    "rebinding alone does not author generated relationship values")

local second = adapter:BuildDraft()
T.equal(second.previewSeed, rebound.previewSeed,
    "ordinary refresh keeps deterministic generation state")

T.finish("pnc_starting_companion_shared_adapter_smoke")
