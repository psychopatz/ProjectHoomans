local T = require "tests/support/test"

PNC = { Identity = {} }
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local Authoring = require "PNC/Core/Identity/PNC_NPCAuthoring"
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint
local Resolver = Authoring.Resolver

T.truthy(Registry.Validate(), "canonical field registry validates")
T.truthy(Registry.Get("identity.nickname"), "nickname is registered")
T.falsy(Registry.Get("alias"), "legacy alias is not registered")
T.truthy(Registry.Fingerprint(), "registry fingerprint is available")

local blueprint = Blueprint.New({ id = "unique:authoring", generationSeed = 17 })
blueprint = Blueprint.Set(blueprint, "identity.forename", "Riley")
blueprint = Blueprint.Set(blueprint, "identity.surname", "North")
blueprint = Blueprint.Set(blueprint, "identity.nickname", "Rye")
blueprint = Blueprint.Set(blueprint, "identity.isFemale", true)
blueprint = Blueprint.Set(blueprint, "skills.baseLevels", { Cooking = 7 })
blueprint = Blueprint.Clear(blueprint, "identity.nickname")

local state, value = Blueprint.Get(blueprint, "identity.nickname")
T.equal(state, "clear", "explicit clear is distinct from absent")
T.equal(value, nil, "explicit clear has no value")
T.equal(Blueprint.Get(blueprint, "identity.surname"), "value",
    "explicit value is distinct from clear")
T.equal(Blueprint.Get(blueprint, "appearance.hairModel"), "absent",
    "absent field remains absent")

local serialized = Blueprint.Serialize(blueprint)
local loaded = Blueprint.Deserialize(serialized)
T.truthy(loaded, "canonical sparse blueprint round-trips")
T.equal(Blueprint.Fingerprint(loaded), Blueprint.Fingerprint(blueprint),
    "blueprint fingerprint is stable")
local randomized = Blueprint.Randomize(blueprint, 18)
T.falsy(Blueprint.Fingerprint(randomized) == Blueprint.Fingerprint(blueprint),
    "explicit randomize changes the blueprint fingerprint")

local generated = Blueprint.New({ id = "unique:generated", generationSeed = 31 })
local generatedA = Resolver.ResolvePlan(
    generated, {}, Resolver.Policies.Debug, { id = generated.id })
local generatedB = Resolver.ResolvePlan(
    generated, {}, Resolver.Policies.Debug, { id = generated.id })
T.equal(generatedA.definition.displayName, generatedB.definition.displayName,
    "same seed produces the same generated preview")
T.equal(generatedA.definition.identity.survivor.forename,
    generatedB.definition.identity.survivor.forename,
    "same seed produces the same generated forename")
local generatedRandom = Resolver.ResolvePlan(
    Blueprint.Randomize(generated, 32), {}, Resolver.Policies.Debug,
    { id = generated.id })
T.falsy(generatedRandom.definition.displayName
    == generatedA.definition.displayName,
    "randomize changes the generated preview")

local compact = Registry.EncodeCompact(blueprint)
T.truthy(compact, "compact codec encodes canonical blueprint")
local compactLoaded = Registry.DecodeCompact(compact)
T.equal(Blueprint.Fingerprint(compactLoaded), Blueprint.Fingerprint(blueprint),
    "compact codec preserves sparse intent")
local incompatible = Registry.Copy(compact)
incompatible.registryFingerprint = "registry:incompatible"
local rejected, reason = Registry.DecodeCompact(incompatible)
T.falsy(rejected, "incompatible compact schema is rejected atomically")
T.equal(reason, "registry_fingerprint_mismatch", "incompatibility reason")

local policy = Resolver.PolicyForStartingCompanion({
    id = "PNC_HasBrother",
    relationshipKind = "brother",
    sex = "male",
    sharesSurname = true,
    sharesAppearance = true,
})
local starter = Blueprint.New({ id = "starter:brother", generationSeed = 23 })
starter = Blueprint.Set(starter, "identity.surname", "Authored")
starter = Blueprint.Set(starter, "identity.isFemale", true)
starter = Blueprint.Clear(starter, "identity.nickname")
local rejectedClear, clearReason = Blueprint.Clear(
    starter, "appearance.skinTexture", policy)
T.falsy(rejectedClear, "mandatory relationship field cannot be cleared")
T.equal(clearReason, "mandatory_field_cannot_clear:appearance.skinTexture",
    "mandatory clear rejection is explicit")
local plan = Resolver.ResolvePlan(starter, {
    playerSurname = "Current",
    playerFemale = true,
    playerAppearance = {
        skinTexture = "FemaleBody03",
        skinColor = { r = 0.8, g = 0.7, b = 0.6 },
        hairColor = { r = 0.1, g = 0.2, b = 0.3 },
    },
}, policy, { id = "starter:brother" })
T.truthy(plan, "relationship policy resolves a starter blueprint")
T.equal(plan.definition.identity.survivor.surname, "Current",
    "mandatory surname binding overrides authored value")
T.equal(plan.definition.isFemale, false,
    "mandatory relationship sex binding overrides authored value")
T.equal(plan.trace.fields["identity.surname"].source, "inherited",
    "trace identifies inherited relationship surname")
T.equal(plan.trace.fields["identity.isFemale"].source, "derived",
    "trace identifies derived relationship sex")
T.equal(plan.trace.fields["appearance.skinTexture"].value, "MaleBody03",
    "trace carries bounded inherited appearance value")

local explicitDisplayName = Blueprint.Set(
    Blueprint.New({ id = "starter:display", generationSeed = 23 }),
    "identity.displayName",
    "Riley Authored"
)
local displayPlan = Resolver.ResolvePlan(explicitDisplayName, {
    playerSurname = "Current",
    playerFemale = true,
    playerAppearance = {
        skinTexture = "FemaleBody03",
        skinColor = { r = 0.8, g = 0.7, b = 0.6 },
        hairColor = { r = 0.1, g = 0.2, b = 0.3 },
    },
}, policy, { id = "starter:display" })
T.truthy(displayPlan, "starter name projection resolves")
T.equal(displayPlan.definition.displayName, "Riley Current",
    "inherited surname is reflected in the shared preview name")
T.equal(displayPlan.definition.identity.survivor.forename, "Riley",
    "explicit display name supplies the canonical forename")
T.equal(displayPlan.trace.fields["identity.displayName"].source, "derived",
    "name projection is visible as a derived trace field")
T.equal(displayPlan.trace.fields["identity.displayName"].editable, false,
    "relationship name projection is locked by policy")

local retired = Registry.RetireWireCode(900)
T.truthy(retired, "unused wire code can be retired")
local registered, registerReason = Registry.Register({
    id = "test.retiredWireCode",
    wireCode = 900,
    valueType = "string",
    authorable = true,
    persistable = true,
    networkable = true,
})
T.falsy(registered, "retired wire code cannot be reused")
T.equal(registerReason, "wire_code_retired",
    "wire-code lifecycle is immutable")

local futureRegistered, futureReason = Registry.Register({
    id = "test.futureField",
    wireCode = 901,
    valueType = "string",
    runtimePath = { "futureField" },
    draftPath = { "futureField" },
    authorable = true,
    persistable = true,
    networkable = true,
    bindingAllowed = false,
    clearable = true,
    limits = { maxLength = 32 },
})
T.truthy(futureRegistered, futureReason)
local futureBlueprint = Blueprint.New({ generationSeed = 41 })
futureBlueprint = Blueprint.Set(futureBlueprint, "test.futureField", "kept")
local futureDefinition = Blueprint.ToDefinition(futureBlueprint)
T.equal(futureDefinition.futureField, "kept",
    "one registry registration reaches the concrete serializer")
T.truthy(Registry.Get("test.futureField"),
    "future field is visible through the shared registry")

T.finish("pnc_npc_authoring_schema_smoke")
