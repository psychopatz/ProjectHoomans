local F = require('tests/support/pnc_authoring_session')()
local T, StartingTraits, Session, Adapter = F.T, F.StartingTraits, F.Session, F.Adapter
local Authoring, Blueprint, Model, TID, context, copy = F.Authoring, F.Blueprint, F.Model, F.TID, F.context, F.copy
local session = Session.New({ sessionSeed = 123, context = context(
    "Reyes", true, "straight") })
session:Reconcile({ TID.BROTHER }, context("Reyes", true, "straight"))
local adapter = Adapter.New(session, TID.BROTHER)
local initialFingerprint = Blueprint.Fingerprint(session:GetBlueprint(TID.BROTHER))
local draft = adapter:BuildDraft()
T.truthy(draft, "shared adapter builds a resolved authoring draft")
T.equal(draft.appearance.outfit.mode, "random", "new companions inherit a clothed default without authoring an override")
local initialPreviewIdentity = adapter:PreviewIdentity()
local initialGenerationIdentity = adapter:PreviewGenerationIdentity()
T.contains(initialPreviewIdentity, TID.BROTHER,
    "preview identity contains the active companion trait")
T.contains(initialPreviewIdentity, tostring(draft.previewSeed),
    "preview identity contains the generation seed")
T.truthy(string.find(initialPreviewIdentity, "context:", 1, true),
    "preview identity contains a context fingerprint")
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
T.truthy(adapter:FieldCapability("appearance.hairStubble").editable, "companion scalp stubble is editable")
T.truthy(adapter:FieldCapability("appearance.beardStubble").editable, "companion beard stubble is editable")
visualDraft.identity.survivor.hairStubble = true
visualDraft.identity.survivor.beardStubble = true
visualDraft.identity.survivor.chestHair = true
visualDraft.appearanceAuthored.hairStubble = true
visualDraft.appearanceAuthored.beardStubble = true
visualDraft.appearanceAuthored.chestHair = true
T.truthy(adapter:CommitDraft(visualDraft),
    "shared adapter commits a visual field edit")
local visualBlueprint = session:GetBlueprint(TID.BROTHER)
local hairState, hair = Blueprint.Get(
    visualBlueprint, "appearance.hairModel")
local seedState, seedValue = Blueprint.Get(visualBlueprint, "identity.forename")
T.equal(hairState, "value", "hair edit remains canonical")
T.equal(hair, "Long", "hair edit round-trips through the session")
local resolvedStubble = adapter:BuildDraft().identity.survivor
T.equal(resolvedStubble.hairStubble, true, "companion scalp stubble survives session resolution")
T.equal(resolvedStubble.beardStubble, true, "companion beard stubble survives session resolution")
T.equal(resolvedStubble.chestHair, true, "companion chest hair survives session resolution")
T.equal(seedState, "value", "unrelated identity remains authored")
T.equal(seedValue, "Riley", "visual edit does not reroll unrelated values")
T.equal(visualBlueprint.generationSeed, generationSeed,
    "visual edit does not advance the generation seed")
T.equal(adapter:PreviewGenerationIdentity(), initialGenerationIdentity,
    "ordinary visual edit preserves preview generation identity")
T.truthy(adapter:PreviewIdentity() ~= initialPreviewIdentity,
    "ordinary visual edit changes full preview identity")

local randomizedBlueprint = session:RandomizeSlot(TID.BROTHER)
local randomizedSeed = randomizedBlueprint.generationSeed
local randomizedIdentity = adapter:PreviewIdentity()
T.truthy(randomizedSeed ~= generationSeed,
    "explicit randomize changes the canonical generation seed")
T.truthy(randomizedIdentity ~= initialPreviewIdentity,
    "explicit randomize changes the preview identity")
T.equal(adapter.traitID, TID.BROTHER,
    "randomize keeps the adapter bound to the selected companion")

local reboundFingerprint = Blueprint.Fingerprint(
    session:GetBlueprint(TID.BROTHER))
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

local Loadout = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout"
local loadoutDraft = adapter:BuildDraft()
local stableSeed = loadoutDraft.previewSeed
T.truthy(Loadout.SetSlot(loadoutDraft, { kind = "held", id = "primary" },
    { type = "Base.Axe", stack = 1 }), "held item edits canonical startingItems")
T.truthy(adapter:CommitDraft(loadoutDraft), "held item persists through companion adapter")
local _, held = Blueprint.Get(session:GetBlueprint(TID.BROTHER), "startingItems")
T.equal(held[1].type, "Base.Axe", "held type is stored in blueprint")
T.equal(held[1].equipSlot, "primary", "held slot is stored in blueprint")
local roundTrip = adapter:BuildDraft()
T.equal(roundTrip.startingItems[1].type, "Base.Axe", "held item survives resolved refresh")
T.equal(roundTrip.previewSeed, stableSeed, "loadout changes preserve seed")
T.falsy(adapter:CommitDraft(roundTrip), "loadout refresh is not another authored edit")
T.truthy(Loadout.SetSlot(roundTrip, { kind = "carry", id = "new" },
    { type = "Base.WaterBottle", stack = 3, preferredContainer = "bag" }), "carried item authoring")
T.truthy(adapter:CommitDraft(roundTrip), "carried item commits")
local serialized = Blueprint.Serialize(session:GetBlueprint(TID.BROTHER))
local restored = Blueprint.Deserialize(serialized)
local _, inventory = Blueprint.Get(restored, "startingItems")
T.equal(#inventory, 2, "loadout survives serialized preset payload")
T.equal(inventory[2].stack, 3, "quantity survives preset payload")
T.equal(inventory[2].preferredContainer, "bag", "container intent survives preset payload")
local cleared = adapter:BuildDraft()
T.truthy(Loadout.SetSlot(cleared, { kind = "held", id = "primary" }), "held clear is explicit")
T.truthy(adapter:CommitDraft(cleared), "held clear commits")
local afterClear = adapter:BuildDraft()
T.equal(#afterClear.startingItems, 1, "clearing a hand preserves carried items")
T.truthy(Loadout.SetSlot(afterClear, { kind = "item", id = afterClear.startingItems[1].key }), "remove final carried item")
T.truthy(adapter:CommitDraft(afterClear), "empty inventory intent commits")
local emptyState = Blueprint.Get(session:GetBlueprint(TID.BROTHER), "startingItems")
T.equal(emptyState, "clear", "empty loadout cannot resurrect previous authored items")

-- Free-sex companion traits accept both concrete choices; fixed family and
-- orientation policies remain authoritative through preview and serialization.
session:Reconcile({ TID.FRIEND, TID.BROTHER }, context("Reyes", true, "straight"))
local friend = Adapter.New(session, TID.FRIEND)
T.truthy(friend:FieldCapability("identity.isFemale").editable, "Friend gender is editable")
T.truthy(session:SetField(TID.FRIEND, "identity.isFemale", false), "free-sex policy accepts an explicit male default")
for _, female in ipairs({ true, false }) do
    local selected = friend:BuildDraft()
    selected.isFemale = female
    friend:CommitDraft(selected)
    T.equal(session:GetSlot(TID.FRIEND).resolvedDefinition.isFemale, female, "friend gender choice survives resolution")
    local state, value = Blueprint.Get(session:GetBlueprint(TID.FRIEND), "identity.isFemale")
    T.equal(state, "value", "friend gender is authored")
    T.equal(value, female, "false male value is preserved")
    local serialized = Blueprint.Serialize(session:GetBlueprint(TID.FRIEND))
    local decoded = Blueprint.Deserialize(serialized)
    local _, restoredGender = Blueprint.Get(decoded, "identity.isFemale")
    T.equal(restoredGender, female, "friend gender round trips in canonical presets")
end
local freeFingerprint = Blueprint.Fingerprint(session:GetBlueprint(TID.FRIEND))
session:Refresh(context("Changed", false, "gay"))
T.equal(session:GetSlot(TID.FRIEND).resolvedDefinition.isFemale, false, "player sex/orientation cannot override a selected friend gender")
T.equal(Blueprint.Fingerprint(session:GetBlueprint(TID.FRIEND)), freeFingerprint, "context rebinding does not rewrite friend intent")
local trace = Authoring.Resolver.AttachIdentityTrace({}, { isFemale = false, survivor = {} })
T.equal(trace.fields['identity.isFemale'].value, false, "trace preserves male values")

-- Exercise the real policy-aware visual transaction with controlled native
-- materialization at the runtime boundary, never changing nonvisual defaults.
local savedEnsure, savedPortrait = Model.EnsureRuntimeRecord, Model.BuildPortraitSpec
Model.EnsureRuntimeRecord = function() return { inventory = { items = { shirt = { type = "Base.VariationShirt", wornSlot = "Torso", itemState = { visualTextureChoice = 2 } } } } } end
Model.BuildPortraitSpec = function() return { appearance = { hairModel = "Short", beardModel = "", skinTexture = "MaleBody02",
    hairColor = { r = .2, g = .3, b = .4 }, skinColor = { r = .5, g = .5, b = .5 } } } end
local oldSeed = session:GetBlueprint(TID.FRIEND).generationSeed
local beforeName = session:GetSlot(TID.FRIEND).resolvedDefinition.displayName
T.truthy(friend:VaryLook(), "explicit companion variation uses the canonical transaction")
T.equal(session:GetBlueprint(TID.FRIEND).generationSeed, oldSeed, "visual variation preserves the biography generation seed")
T.equal(session:GetSlot(TID.FRIEND).resolvedDefinition.displayName, beforeName, "visual variation preserves name")
T.equal(session:GetSlot(TID.FRIEND).resolvedDefinition.isFemale, false, "visual variation preserves selected gender")
local _, variedHair = Blueprint.Get(session:GetBlueprint(TID.FRIEND), "appearance.hairModel")
T.equal(variedHair, "Short", "concrete generated visual fields are authored")
local _, wardrobe = Blueprint.Get(session:GetBlueprint(TID.FRIEND), "appearance")
T.equal(wardrobe.slots.Torso.type, "Base.VariationShirt", "fallback generated wardrobe is frozen into concrete slots")
T.equal(wardrobe.slots.Torso.itemState.visualTextureChoice, 2, "concrete wardrobe preserves its reviewed native visual state")
local brotherAdapter = Adapter.New(session, TID.BROTHER)
T.falsy(brotherAdapter:FieldCapability("identity.isFemale").editable, "fixed-sex family gender remains locked")
T.truthy(brotherAdapter:VaryLook(), "family look can vary within relationship rules")
T.equal(Blueprint.Get(session:GetBlueprint(TID.BROTHER), "appearance.skinTexture"), "absent", "variation never authors inherited family skin")
T.equal(Blueprint.Get(session:GetBlueprint(TID.BROTHER), "appearance.hairColor"), "absent", "variation never authors inherited family hair color")
local beforeFailure = Blueprint.Fingerprint(session:GetBlueprint(TID.FRIEND))
Model.EnsureRuntimeRecord = function() return nil, "preview_unavailable" end
local failed, why = friend:VaryLook()
T.falsy(failed, "failed native materialization rejects variation")
T.equal(why, "preview_unavailable", "variation explains materialization failure")
T.equal(Blueprint.Fingerprint(session:GetBlueprint(TID.FRIEND)), beforeFailure, "failed variation leaves accepted state unchanged")
Model.EnsureRuntimeRecord, Model.BuildPortraitSpec = savedEnsure, savedPortrait

T.finish("pnc_starting_companion_shared_adapter_smoke")
