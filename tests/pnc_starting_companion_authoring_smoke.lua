local T = require "tests/support/test"

T.addPackagePaths()
PNC = { Identity = {} }
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileConstants.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileTypes.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialTraits.lua"))

local StartingTraits = require "PNC/Core/Traits/PNC_StartingCompanionTraits"
local Session = require "PNC/CharacterCreation/PNC_StartingCompanionSession"
local Presets = require "PNC/CharacterCreation/PNC_StartingCompanionPresets"
local Sanitizer = require "PNC/Core/Identity/PNC_StartingCompanionSanitizer"
local Composer = require "PNC/CharacterCreation/PNC_StartingCompanionComposer"
local Authoring = require "PNC/Core/Identity/PNC_NPCAuthoring"
local Blueprint = Authoring.Blueprint

local TID = StartingTraits.IDS
local appearance = {
    skinTexture = "FemaleBody03",
    skinColor = { r = 0.44, g = 0.31, b = 0.22 },
    hairColor = { r = 0.12, g = 0.07, b = 0.03 },
}
local function context(surname, female, orientation)
    return {
        playerSurname = surname,
        playerFemale = female,
        orientation = orientation,
        playerAppearance = appearance,
    }
end

local session = Session.New({
    sessionSeed = 41,
    context = context("Reyes", true, "straight"),
})
local first = session:Reconcile({ TID.BROTHER, TID.IS_MARRIED },
    context("Reyes", true, "straight"))
T.equal(first.added[1], TID.BROTHER, "first reconcile adds brother")
T.equal(first.added[2], TID.IS_MARRIED, "first reconcile adds lover")
T.equal(#first.removed, 0, "first reconcile removes nothing")

local custom = session:SetField(TID.BROTHER, "identity.forename", "Riley")
T.truthy(custom, "forename is editable through the shared composer")
local nickname = session:SetField(TID.BROTHER, "identity.nickname", "Rye")
T.truthy(nickname, "canonical nickname is editable")
local beforeRemove = Blueprint.Fingerprint(session:GetBlueprint(TID.BROTHER))
local removed = session:Reconcile({ TID.IS_MARRIED },
    context("Reyes", true, "straight"))
T.equal(removed.removed[1], TID.BROTHER,
    "removed trait is deactivated")
T.equal(#session:GetActiveSlots(), 1, "removed slot is absent from active set")
local restored = session:Reconcile({ TID.BROTHER, TID.IS_MARRIED },
    context("Reyes", true, "straight"))
T.equal(restored.added[1], TID.BROTHER, "re-added trait is restored")
T.equal(Blueprint.Fingerprint(session:GetBlueprint(TID.BROTHER)), beforeRemove,
    "re-added trait restores the cached blueprint")
T.equal(session:FinalSummary()[1].displayName,
    session:GetSlot(TID.BROTHER).resolvedDefinition.displayName,
    "final summary uses the resolved preview")

local locked, lockedReason = session:SetField(
    TID.BROTHER, "identity.surname", "Spoofed")
T.falsy(locked, "mandatory relationship field is not editable")
T.equal(lockedReason, "field_locked:identity.surname",
    "composer reports the mandatory binding lock")

local brotherRows = Composer.New({ session = session, traitID = TID.BROTHER })
local rows = brotherRows:FieldRows()
local sawInherited = false
for _, row in ipairs(rows) do
    if row.fieldID == "identity.surname" then
        sawInherited = row.sourceLabel == "Inherited from Player"
            and row.editable == false
    end
end
T.truthy(sawInherited, "composer consumes the shared inherited trace")

local deterministicA = Session.New({
    sessionSeed = 77,
    context = context("North", false, "straight"),
})
local deterministicB = Session.New({
    sessionSeed = 77,
    context = context("North", false, "straight"),
})
deterministicA:Reconcile({ TID.FRIEND }, context("North", false, "straight"))
deterministicB:Reconcile({ TID.FRIEND }, context("North", false, "straight"))
T.equal(
    deterministicA:GetSlot(TID.FRIEND).resolvedDefinition.identity.displayName,
    deterministicB:GetSlot(TID.FRIEND).resolvedDefinition.identity.displayName,
    "same session seed and context resolve the same friend preview"
)
local friendBefore = Blueprint.Fingerprint(deterministicA:GetBlueprint(TID.FRIEND))
deterministicA:RandomizeSlot(TID.FRIEND, 78)
T.falsy(Blueprint.Fingerprint(deterministicA:GetBlueprint(TID.FRIEND)) == friendBefore,
    "explicit randomize changes only the generation state")
deterministicA:ResetSlot(TID.FRIEND)
T.equal(Blueprint.Get(deterministicA:GetBlueprint(TID.FRIEND), "identity.forename"),
    "absent", "reset clears authored fields")

local preset = Presets.FromSession(session, "Family setup")
T.truthy(preset, "whole setup preset serializes")
local presetLoaded = Presets.Deserialize(preset)
T.truthy(presetLoaded, "whole setup preset round-trips")
local encodedPreset = Presets.Encode(preset)
local decodedPreset = Presets.Decode(encodedPreset)
T.truthy(decodedPreset, "whole setup preset JSON round-trips")
T.falsy(decodedPreset.slots[TID.BROTHER].fields["identity.surname"],
    "preset omits resolved inherited surname")
T.falsy(decodedPreset.slots[TID.IS_MARRIED].fields["identity.isFemale"],
    "preset omits relationship-derived sex")
local template = Presets.TemplateFromSession(session, TID.BROTHER, "Brother")
T.truthy(template, "individual companion template serializes")

local other = Session.New({
    sessionSeed = 41,
    context = context("Cruz", false, "straight"),
})
local applied = Presets.ApplyToSession(other, presetLoaded)
T.truthy(applied, "whole setup applies to a session")
T.equal(applied.addedTraits, false, "preset does not add paid traits")
other:Reconcile({ TID.BROTHER }, context("Cruz", false, "straight"))
T.equal(other:GetSlot(TID.BROTHER).resolvedDefinition.identity.survivor.surname,
    "Cruz", "preset resolves against the current player")
local direct = Session.New({ sessionSeed = 94, context = context("Cruz", false, "straight") })
direct:Reconcile({ TID.BROTHER }, context("Cruz", false, "straight"))
T.truthy(direct:SetField(TID.BROTHER, "identity.nickname", "Keep me"))
local foreign = Blueprint.New({ id = "saved-sister", generationSeed = 411 })
foreign = assert(Blueprint.Set(foreign, "identity.forename", "Jamie"))
foreign = assert(Blueprint.Set(foreign, "identity.surname", "Old family"))
foreign = assert(Blueprint.Set(foreign, "identity.isFemale", true))
foreign = assert(Blueprint.Set(foreign, "identity.displayName", "Jamie Old family"))
foreign = assert(Blueprint.Set(foreign, "appearance.skinTexture", "FemaleBody05"))
foreign = assert(Blueprint.Set(foreign, "appearance.hairColor", { r = 1, g = 0, b = 0 }))
foreign = assert(Blueprint.Set(foreign, "factionID", "preset-faction"))
foreign = assert(Blueprint.Set(foreign, "attackType", "preset-only-attack"))
local foreignTemplate = assert(Presets.Serialize({
    schemaId = Presets.SCHEMA_ID, schemaVersion = Presets.SCHEMA_VERSION,
    kind = "template", companionTraitID = TID.SISTER,
    slots = { [TID.SISTER] = Blueprint.Serialize(foreign) },
}))
local result = assert(Presets.ApplyToSession(direct, foreignTemplate, {
    targetTraitID = TID.BROTHER, activeOnly = true,
}))
T.equal(result.applied[1], TID.BROTHER, "template applies to the currently selected companion")
T.equal(#result.pending, 0, "loading a template does not queue a different relationship")
local resolved = direct:GetSlot(TID.BROTHER).resolvedDefinition
T.equal(resolved.identity.survivor.forename, "Jamie", "editable preset fields apply")
T.equal(resolved.identity.survivor.surname, "Cruz", "loaded family surname comes from the current player")
T.equal(resolved.identity.survivor.skinTexture, "MaleBody03", "skin is inherited and adapted to the target")
T.equal(resolved.identity.survivor.hairColor.r, appearance.hairColor.r, "family hair color is inherited")
T.equal(resolved.isFemale, false, "target relationship controls sex")
T.equal(resolved.displayName, "Jamie Cruz", "the current family name is used in the preview")
T.equal(resolved.identity.nickname, "Keep me", "an unspecified field retains the existing edit")
T.equal(direct:GetBlueprint(TID.BROTHER).fields["identity.surname"], nil, "preset does not store spoofed inheritance")
T.equal(direct:GetBlueprint(TID.BROTHER).fields.factionID, nil, "preset cannot assign server-owned faction")
T.equal(direct:GetBlueprint(TID.BROTHER).fields.attackType, nil, "preset cannot apply a debug-only field")
local missing, missingReason = Presets.ApplyToSession(direct, {
    schemaId = Presets.SCHEMA_ID, schemaVersion = Presets.SCHEMA_VERSION,
    kind = "whole", slots = { [TID.SISTER] = Blueprint.Serialize(foreign) },
}, { activeOnly = true })
T.falsy(missing, "unmatched roster cannot silently succeed")
T.equal(missingReason, "preset_no_matching_companions")
T.equal(next(direct.pendingBlueprints), nil, "unmatched UI load does not change pending slots")

local loadedForename = other:GetSlot(TID.BROTHER).blueprint.fields["identity.forename"]
other:SetField(TID.BROTHER, "identity.forename", "Changed")
other:RevertToPreset(TID.BROTHER)
T.equal(other:GetSlot(TID.BROTHER).blueprint.fields["identity.forename"],
    loadedForename, "revert to preset restores its baseline")

local lover = Session.New({ sessionSeed = 90 })
lover:Reconcile({ TID.IS_MARRIED }, context("North", false, "straight"))
T.equal(lover:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale, true,
    "straight lover uses the opposite sex")
lover:Refresh(context("North", false, "gay"))
T.equal(lover:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale, false,
    "gay lover uses the player's sex")
lover:Refresh(context("North", false, "bisexual"))
local bisexualSex = lover:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale
lover:Refresh(context("North", false, "bisexual"))
T.equal(lover:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale, bisexualSex,
    "bisexual lover resolution remains deterministic")

local imported, report = Sanitizer.SanitizeDefinition({
    id = "npc:source",
    uniqueDefinitionId = "npc:source",
    generationSeed = 101,
    displayName = "Riley Reyes",
    factionID = "spoofed_faction",
    ownerUsername = "spoofed_owner",
    debug = true,
    identity = {
        nickname = "Rye",
        isFemale = true,
        displayName = "Riley Reyes",
        survivor = {
            forename = "Riley",
            surname = "Reyes",
            skinTexture = "FemaleBody03",
            skinColor = appearance.skinColor,
            hairColor = appearance.hairColor,
            hairModel = "Long",
        },
    },
}, TID.BROTHER)
T.truthy(imported, "canonical Unique NPC import sanitizes")
T.equal(Blueprint.Get(imported, "identity.nickname"), "value",
    "sanitizer preserves canonical nickname")
T.equal(Blueprint.Get(imported, "identity.surname"), "absent",
    "sanitizer removes inherited surname")
T.equal(Blueprint.Get(imported, "identity.isFemale"), "absent",
    "sanitizer removes relationship-derived sex")
T.equal(Blueprint.Get(imported, "appearance.skinTexture"), "absent",
    "sanitizer removes family texture binding")
T.equal(Blueprint.Get(imported, "factionID"), "absent",
    "sanitizer removes faction authority")
local function contains(values, target)
    for _, value in ipairs(values or {}) do
        if value == target then return true end
    end
    return false
end
T.truthy(contains(report.rebound, "identity.surname"),
    "sanitizer reports surname rebinding")
T.truthy(contains(report.removed, "factionID"),
    "sanitizer reports removed faction authority")
T.truthy(contains(report.regenerated, "identity.displayName"),
    "sanitizer reports regenerated display projection")
T.truthy(contains(report.preserved, "identity.nickname"),
    "sanitizer reports preserved nickname")

local _, legacyReason = Sanitizer.SanitizeDefinition({
    identity = { survivor = { firstName = "Legacy" } },
}, TID.FRIEND)
T.equal(legacyReason, "unsupported_source_schema",
    "superseded source aliases are rejected")

T.finish("pnc_starting_companion_authoring_smoke")
