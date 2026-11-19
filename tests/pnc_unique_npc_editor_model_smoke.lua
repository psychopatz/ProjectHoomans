local T = require "tests/support/test"

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[deepCopy(key)] = deepCopy(child) end
    return output
end

PNC = {
    Core = { DeepCopy = deepCopy },
    Identity = {},
    Inventory = { Queries = {} },
    SkillCatalog = {
        Find = function(id)
            return tostring(id) == "Cooking" and { id = "Cooking" } or nil
        end,
    },
    NPCTraits = {
        NormalizeID = function(id)
            id = tostring(id or "")
            return (id == "steady" or id == "reckless") and id or nil
        end,
        ResolveSet = function(source)
            local conflicts = {}
            if source.steady and source.reckless then
                conflicts[1] = { preferred = "steady", discarded = "reckless" }
            end
            return source, conflicts
        end,
    },
    UniqueNPCs = {},
}

PNC.Inventory.Queries.ToDefinitionSpec = function(item, key, preferred)
    local output = deepCopy(item)
    output.id = nil
    output.container = nil
    output.bagContainer = nil
    output.templateKey = nil
    output.key = key
    output.preferredContainer = preferred
    return output
end

PNC.UniqueNPCs.NormalizeDefinition = function(definition)
    if not definition.id or not definition.displayName
        or type(definition.isFemale) ~= "boolean"
    then
        return nil, "invalid_definition"
    end
    return deepCopy(definition)
end
PNC.UniqueNPCs.Resolve = function(definition)
    return {
        id = nil,
        uniqueDefinitionId = definition.id,
        displayName = definition.displayName,
        name = definition.displayName,
        isFemale = definition.isFemale,
        identitySeed = definition.identitySeed or 42,
        identity = { survivor = {} },
        dynamicTraits = { generated = true },
        archetypeID = definition.archetypeID,
        equipmentSpawnMode = definition.equipmentSpawnMode,
    }
end
PNC.Inventory.EnsureRecordInventory = function(record)
    record.inventory = record.inventory or {
        revision = 0, items = {}, containers = { root = { items = {} } },
    }
    return record.inventory
end
PNC.Inventory.SyncEquipmentFromInventory = function() return {} end

package.preload["PNC/Core/Identity/PNC_UniqueNPCs"] = function()
    return PNC.UniqueNPCs
end
package.preload["PNC/Core/Inventory/PNC_Inventory"] = function()
    return PNC.Inventory
end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Appearance.lua")
T.load("ProjectHoomans", "client", "PNC/Identity/PNC_UniqueNPCDraft.lua")
T.equal(require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel",
    PNC.UniqueNPCEditorModel, "stable editor entry must return canonical model")
T.falsy(PNC.UniqueNPCEditorWindow, "authoring model loaded a window")

local draft = PNC.UniqueNPCEditorModel.New()
T.equal(draft.appearance.outfit.mode, "random",
    "new drafts default to a stable clothed look")
local randomizedDraft = PNC.UniqueNPCEditorModel.New()
PNC.UniqueNPCEditorModel.Randomize(randomizedDraft)
T.equal(randomizedDraft.appearance.outfit.mode, "random",
    "randomize explicitly enables inherited clothing")
local preview = PNC.UniqueNPCEditorModel.BuildPreviewDraft(draft)
T.equal(preview.displayName, "Preview Survivor",
    "blank drafts receive a temporary preview name")
T.equal(draft.displayName, "", "preview fallback does not mutate the draft")
draft.displayName = "Gorgon Ramsee"
draft.isFemale = true
draft.archetypeID = "Chef"
draft.factionID = "faction:editor"
draft.skillLevels = { Cooking = 10 }
draft.identity.survivor.forename = "Gorgon"
draft.identity.survivor.surname = "Ramsee"
draft.identity.survivor.hairModel = "Long"
draft.runtimeRecord = {
    inventory = {
        items = {
            generated = { id = "generated", type = "Base.Shirt", templateKey = "tmpl:look:shirt" },
            money = { id = "money", type = "Base.Money", stack = 1000,
                templateKey = "editor:editor-draft:1", itemState = {
                    visualTextureChoice = 2,
                    visualColorR = 0.25,
                    modData = { picture = "custom-picture", variant = 3 },
                } },
        },
        containers = { root = { items = { "generated", "money" } } },
    },
}

local definition = PNC.UniqueNPCEditorModel.BuildDefinition(draft)
T.equal(definition.id, "unique:gorgonramsee", "name-derived definition id")
local first, last = PNC.UniqueNPCEditorModel.NameParts(draft)
T.equal(first, "Gorgon", "first name remains a separate identity field")
T.equal(last, "Ramsee", "surname remains a separate identity field")
local valid = PNC.UniqueNPCEditorModel.Validate(draft)
T.equal(valid, true, "separate first and surname fields validate")
T.equal(definition.skillLevels.Cooking, 10, "authored skill preserved")
T.equal(definition.identity.survivor.hairModel, "Long", "authored appearance preserved")
T.equal(definition.factionID, "faction:editor",
    "registry keeps the existing Unique faction authoring field")
T.equal(#definition.startingItems, 1, "generated inventory omitted")
T.equal(definition.startingItems[1].stack, 1000, "custom money preserved")
T.equal(definition.startingItems[1].itemState.visualTextureChoice, 2,
    "item visual metadata preserved")
T.equal(definition.startingItems[1].itemState.modData.picture,
    "custom-picture", "item modData preserved")
T.equal(definition.startingItems[1].key, "editor:unique:gorgonramsee:1",
    "editor item receives stable export key")
T.equal(definition.identitySeed, nil, "runtime identity seed is not authored")
T.equal(definition.hpMax, nil, "health is not editor-authored")
T.equal(definition.outfit, nil, "outfit is not editor-authored")

draft.appearance = {
    outfit = { mode = "item", id = "CostumeFrogman" },
    slots = {
        Torso = {
            mode = "item",
            type = "Base.Shirt",
            wornSlot = "Torso",
        },
    },
}
draft.runtimeRecord.inventory.items.generated.wornSlot = "Torso"
draft.runtimeRecord.inventory.items.generated.itemState = {
    visualTextureChoice = 6,
    visualColorR = 0.1,
    visualColorG = 0.2,
    visualColorB = 0.3,
}
local exactDefinition = PNC.UniqueNPCEditorModel.BuildDefinition(draft)
T.equal(exactDefinition.appearance.slots.Torso.type, "Base.Shirt",
    "worn preview clothing is exported as an appearance slot")
T.equal(exactDefinition.appearance.slots.Torso.itemState.visualTextureChoice, 6,
    "worn clothing visual metadata is exported")
T.equal(#exactDefinition.startingItems, 1,
    "presentation clothing is not duplicated into starting inventory")
local addedSkill, duplicateSkill = PNC.UniqueNPCEditorModel.TryAddSkill(
    draft, "Cooking", 9)
T.equal(addedSkill, false, "duplicate skills are rejected")
T.equal(duplicateSkill, "skill_duplicate", "duplicate skill reason")
local addedTrait = PNC.UniqueNPCEditorModel.TryAddTrait(
    draft, "npc", "steady")
T.equal(addedTrait, true, "first NPC trait is accepted")
local conflictTrait, conflictReason = PNC.UniqueNPCEditorModel.TryAddTrait(
    draft, "npc", "reckless")
T.equal(conflictTrait, false, "conflicting NPC traits are rejected")
T.equal(conflictReason, "trait_conflict", "trait conflict reason")
T.equal(PNC.UniqueNPCEditorModel.FileName(draft), "GorgonRamsee.txt",
    "human-readable produced filename")
local previewDraft = PNC.UniqueNPCEditorModel.BuildPreviewDraft(draft)
local previewRecord = PNC.UniqueNPCEditorModel.EnsureRuntimeRecord(
    previewDraft, true)
local updatedPreview = PNC.UniqueNPCEditorModel.UpdatePreviewDraft(
    previewDraft, draft)
T.equal(PNC.UniqueNPCEditorModel.EnsureRuntimeRecord(updatedPreview, false),
    previewRecord, "name edits retain the cached preview record")
T.equal(previewRecord.dynamicTraits.generated, true,
    "generated fallback traits survive ordinary edits")

PNC.Identity.BuildPortraitSummary = function(record)
    local appearance = record.runtime and record.runtime.appearanceCache or {}
    local equipment = record.equipment or {}
    local visuals = equipment.wornVisuals and equipment.wornVisuals.Shirt or {}
    return {
        revision = tostring(appearance.hairModel or "")
            .. ":" .. tostring(visuals.textureChoice or ""),
    }
end
previewRecord.runtime = {
    appearanceCache = {
        hairModel = "Long",
        beardModel = "Chin",
        hairColor = { r = 0.3, g = 0.2, b = 0.1 },
        skinColor = { r = 0.8, g = 0.6, b = 0.5 },
        outfitItems = { "Base.Shirt", "Base.Trousers" },
    },
}
previewRecord.equipment = {
    worn = { Shirt = "Base.Shirt" },
    wornVisuals = { Shirt = { textureChoice = 3, modelIndex = 1 } },
}
draft.equipment = deepCopy(previewRecord.equipment)
local firstPreviewSpec = PNC.UniqueNPCEditorModel.BuildPortraitSpec(
    updatedPreview)
draft.identity.survivor.hairModel = "Short"
draft.appearanceAuthored.hairModel = true
draft.identity.survivor.hairStubble = true
draft.appearanceAuthored.hairStubble = true
updatedPreview = PNC.UniqueNPCEditorModel.UpdatePreviewDraft(
    updatedPreview, draft)
local secondPreviewSpec = PNC.UniqueNPCEditorModel.BuildPortraitSpec(
    updatedPreview)
T.equal(secondPreviewSpec.appearance.hairModel, "Short",
    "preview applies the newly selected hair")
T.equal(secondPreviewSpec.appearance.hairColor.r, 0.3,
    "hair edit preserves generated hair color")
T.equal(secondPreviewSpec.appearance.outfitItems[1], "Base.Shirt",
    "hair edit preserves generated outfit")
T.equal(secondPreviewSpec.equipment.wornVisuals.Shirt.textureChoice, 3,
    "hair edit preserves clothing visual metadata")
T.falsy(firstPreviewSpec.key == secondPreviewSpec.key,
    "visual edit advances the portrait revision")

T.equal(secondPreviewSpec.appearance.hairStubble, true, "retained preview receives the stubble edit")
draft.identity.survivor.hairStubble = false
updatedPreview = PNC.UniqueNPCEditorModel.UpdatePreviewDraft(updatedPreview, draft)
local shavedPreview = PNC.UniqueNPCEditorModel.BuildPortraitSpec(updatedPreview)
T.equal(shavedPreview.appearance.hairStubble, false, "retained preview clears the stubble edit")
T.falsy(secondPreviewSpec.key == shavedPreview.key, "turning off stubble refreshes the portrait descriptor")

local loaded = PNC.UniqueNPCEditorModel.FromDefinition({
    id = "unique:loaded",
    displayName = "Loaded Person",
    isFemale = false,
    identity = { nickname = "Loady" },
    startingItems = { { type = "Base.Money", stack = 1000 } },
})
local loadedDefinition = PNC.UniqueNPCEditorModel.BuildDefinition(loaded)
T.equal(loadedDefinition.startingItems[1].stack, 1000,
    "loaded authored inventory survives before preview")
T.equal(loadedDefinition.identity.nickname, "Loady",
    "draft definition keeps canonical nickname")
-- Definition persistence uses the same authoring API without a window.
local files, entries = {}, {}
local Database = { ROOT = "Hoomans", INDEX_PATH = "Hoomans/UniqueNPCIndex.txt" }
function Database.GetDirectory() return "Hoomans/NPC Definitions" end
function Database.SafeFileName(name)
    return type(name) == "string" and name:match("^[%w%._%-]+%.txt$") or nil
end
function Database.WriteFile(kind, name, content)
    T.equal(kind, "npc")
    files[name] = content
    return true
end
function Database.Upsert(kind, name, entry)
    T.equal(kind, "npc")
    entries[name] = entry
    return true
end
function Database.List()
    local result = {}
    for _, entry in pairs(entries) do result[#result + 1] = entry end
    return result
end
function Database.ReadFile(_, name) return files[name], "file_missing" end
PNC.DefinitionDatabase = Database
package.loaded["PNC/Core/Definitions/PNC_DefinitionDatabase"] = Database
local Storage = require "PNC/Identity/PNC_UniqueNPCDefinitionStore"
local ok, fileName, stored = Storage.Save(loaded, true)
T.truthy(ok, fileName)
T.equal(fileName, "LoadedPerson.txt")
T.equal(stored.id, "unique:loaded")
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
local payload = Json.Decode(files[fileName])
T.equal(payload.schemaVersion, 2)
T.equal(payload.kind, "ProjectHoomans.UniqueNPC")
T.truthy(payload.produced)
T.falsy(payload.definition.identitySeed, "preview seed leaked into definition")
T.equal(payload.definition.fields["identity.nickname"], "Loady",
    "storage uses canonical nickname field")
local loadedAgain = Storage.LoadFile(fileName)
T.equal(loadedAgain.id, stored.id)
T.equal(loadedAgain.identity.nickname, "Loady",
    "canonical nickname survives save and load")
T.equal(#Storage.List(), 1)
local rejected, reason = Storage.LoadFile("../bad.txt")
T.falsy(rejected)
T.equal(reason, "invalid_file_name")
T.falsy(PNC.UniqueNPCEditorWindow)
local Model = PNC.UniqueNPCEditorModel
local slotDraft = Model.New()
slotDraft.displayName = "Robin Tester"
slotDraft.identity.survivor = { forename = "Robin", surname = "Tester" }
slotDraft.startingItems = { { key = "authoring:held:primary", type = "Base.Axe", equipSlot = "primary" } }
slotDraft.authoredFields.startingItems = true
local retained = { identitySeed = 999, identity = { survivor = {} },
    startingItems = { { key = "old", type = "Base.Money" } }, equipmentSpawnMode = "none",
    runtime = { appearanceCache = { hairModel = "Stable" } },
    inventory = { items = { old = { type = "Base.Money", templateKey = "editor:old" } } } }
local slotPreview = Model.UpdatePreviewDraft({ runtimeRecord = retained }, slotDraft)
local previewDefinition = Model.BuildDefinition(slotPreview)
T.equal(previewDefinition.startingItems[1].type, "Base.Axe", "old retained inventory cannot overwrite the slot edit")
local rebuilds = 0
PNC.Inventory.CreateFromTemplate = function(record)
    rebuilds = rebuilds + 1
    record.inventory = { items = { edited = deepCopy(record.startingItems[1]) } }
end
Model.EnsureRuntimeRecord(slotPreview, false)
T.equal(rebuilds, 1, "changed startingItems rebuild the retained preview inventory")
T.equal(slotPreview.runtimeRecord.inventory.items.edited.type, "Base.Axe", "preview materializes the new held item")
T.equal(slotPreview.runtimeRecord.identitySeed, 999, "inventory edit preserves runtime identity seed")
Model.EnsureRuntimeRecord(slotPreview, false)
T.equal(rebuilds, 1, "unchanged preview does not rebuild inventory again")
T.truthy(Model.SyncFromRuntime(slotPreview), "legacy inventory changes can still synchronize back")
slotDraft.startingItems = {
    { key = "water", type = "Base.WaterBottle", preferredContainer = "bag" },
    { key = "pack", type = "Base.Bag", maxWeight = 20, wornSlot = "Back" },
}
local colorDraft = Model.New()
colorDraft.displayName = "Jamie Tester"
local oldShirt = { mode = "item", type = "Base.Shirt", wornSlot = "Torso",
    itemState = { visualTintR = .2, visualTintG = .3, visualTintB = .4 } }
local oldLook = { outfit = { mode = "none" }, slots = { Torso = oldShirt } }
local oldColorPreview = { runtimeRecord = {
    identitySeed = 999, appearance = oldLook, equipmentSpawnMode = "none",
    inventory = { items = { shirt = deepCopy(oldShirt) } },
} }
colorDraft.appearance = deepCopy(oldLook)
colorDraft.appearance.slots.Torso.itemState.visualTintR = .8
local colorPreview = Model.UpdatePreviewDraft(oldColorPreview, colorDraft)
T.equal(Model.BuildDefinition(colorPreview).appearance.slots.Torso.itemState.visualTintR,
    .8, "saved definition uses the authored tint over the retained shirt")
PNC.Inventory.CreateFromTemplate = function(record)
    record.inventory = { items = { shirt = deepCopy(record.appearance.slots.Torso) } }
end
local appliedColor = Model.EnsureRuntimeRecord(colorPreview, false)
T.equal(appliedColor.inventory.items.shirt.itemState.visualTintR, .8,
    "changing the same shirt's tint rebuilds the retained preview with the authored color")
T.equal(appliedColor.identitySeed, 999, "variant edit keeps the identity seed")

local packed = Model.BuildDefinition(slotDraft)
T.equal(packed.startingItems[1].type, "Base.Bag", "bags materialize before their contents even when authored last")
T.equal(packed.startingItems[2].preferredContainer, "bag", "bag destination remains canonical")

local voiceDraft = Model.New()
voiceDraft.displayName = "Voice Tester"
voiceDraft.identity.survivor = { forename = "Voice", surname = "Tester", voicePrefix = "VoiceMale", voiceType = 0, voicePitch = 100 }
voiceDraft.appearance.voice = { mode = "item", prefix = "VoiceMale", type = 0, pitch = 100 }
T.truthy(Model.BuildDefinition(voiceDraft), "native positive pitch endpoint is valid")
voiceDraft.identity.survivor.voicePitch = -100
voiceDraft.appearance.voice.pitch = -100
T.truthy(Model.BuildDefinition(voiceDraft), "native negative pitch endpoint is valid")
voiceDraft.runtimeRecord = { startingItems = {}, equipmentSpawnMode = "none", identitySeed = 7,
    identity = { survivor = {} }, inventory = { items = {} }, runtime = { appearanceCache = { token = "stable" } },
    appearance = PNC.Identity.Appearance.Normalize(voiceDraft.appearance) }
voiceDraft.identity.survivor.voicePitch = 101
voiceDraft.appearance.voice.pitch = 101
local retainedInventory = voiceDraft.runtimeRecord.inventory
local invalidRecord, invalidReason = Model.EnsureRuntimeRecord(voiceDraft, false)
T.falsy(invalidRecord, "invalid edit returns a validation result")
T.equal(invalidReason, "number_above_max", "validation reason propagates")
T.equal(voiceDraft.runtimeRecord.inventory, retainedInventory, "invalid edit leaves valid inventory untouched")
voiceDraft.identity.survivor.voicePitch = 12
voiceDraft.appearance.voice.pitch = 12
local audioRebuilds = 0
PNC.Inventory.CreateFromTemplate = function() audioRebuilds = audioRebuilds + 1 end
local recovered = Model.EnsureRuntimeRecord(voiceDraft, false)
T.truthy(recovered, "valid edit recovers after rejection")
T.equal(audioRebuilds, 0, "voice-only edit never rebuilds inventory")
T.equal(recovered.runtime.appearanceCache.token, "stable", "voice edit retains exact cached visual state")

local beforeAudioSpec = Model.BuildPortraitSpec(voiceDraft)
voiceDraft.identity.survivor.voicePitch = 45
voiceDraft.appearance.voice.pitch = 45
local afterAudioSpec = Model.BuildPortraitSpec(voiceDraft)
T.equal(afterAudioSpec.key, beforeAudioSpec.key, "audio-only edit does not recreate the native portrait descriptor")
T.falsy(afterAudioSpec.appearance.voicePitch, "render projection does not carry voice-only fields")
local capture = require "PNC/Identity/PNC_UniqueNPCOutfitCapture"
local captures = 0
capture.Capture = function()
    captures = captures + 1
    return { Shirt = { mode = "item", type = "Base.Shirt", itemState = { visualTextureChoice = 6 } } }
end
local oldPreset = Model.New()
oldPreset.displayName = "Old Preset"
oldPreset.identity.survivor = { forename = "Old", surname = "Preset" }
oldPreset.appearance = { outfit = { mode = "item", id = "Police" }, slots = {} }
local namedPreview = Model.BuildPreviewDraft(oldPreset)
oldPreset.identity.survivor.voicePitch = 50
local updatedNamed = Model.UpdatePreviewDraft(namedPreview, oldPreset)
T.equal(captures, 1, "older named outfit is materialized once for preview")
T.equal(updatedNamed.appearance.slots.Shirt.itemState.visualTextureChoice, 6, "ordinary edit reuses named outfit visual choices")
T.falsy(oldPreset.appearance.slots.Shirt, "preview materialization does not modify authored preset intent")
local namedDefinition = Model.BuildDefinition(oldPreset)
T.falsy(namedDefinition.appearance.slots.Shirt, "saving an unchanged old preset does not author generated clothing")
-- A deliberate debug reroll replaces explicit visual choices instead of only
-- changing a seed behind a fixed outfit/hair policy.
local look = PNC.UniqueNPCEditorModel.New({ previewSeed = 12 })
look.displayName = "Audit Example"
look.identity.survivor = { forename = "Audit", surname = "Example", hairModel = "Long", skinTexture = "MaleBody05" }
look.skillLevels = { Cooking = 8 }
look.npcTraits = { steady = true }
look.startingItems = { { type = "Base.Axe", equipSlot = "primary", key = "held" },
    { type = "Base.Money", stack = 2, key = "carried" }, { type = "Base.OldShirt", wornSlot = "Torso", key = "old" } }
look.authoredFields.startingItems = true
look.appearance = { outfit = { mode = "item", id = "Old" }, slots = { Torso = { mode = "item", type = "Base.OldShirt" } } }
PNC.Identity.RollSeed = function() return 66 end
getAllOutfits = function() return { size = function() return 2 end, get = function(_, n) return n == 0 and "LookA" or "LookB" end } end
local captures = 0
PNC.UniqueNPCOutfitCapture.Capture = function(id)
    captures = captures + 1
    return { Torso = { mode = "item", type = "Base.Shirt" .. id, wornSlot = "Torso", itemState = { visualTextureChoice = captures } } }
end
PNC.UniqueNPCEditorModel.Randomize(look)
T.equal(look.previewSeed, 66, "debug look transaction advances the controlled generation")
T.falsy(look.identity.survivor.hairModel, "debug reroll releases explicit hair")
T.falsy(look.identity.survivor.skinTexture, "debug reroll releases explicit skin")
T.equal(look.identity.survivor.forename, "Audit", "look reroll preserves biography")
T.equal(look.skillLevels.Cooking, 8, "look reroll preserves attributes")
T.equal(#look.startingItems, 2, "look reroll removes old clothing and preserves held/carried inventory")
local rerolled = PNC.UniqueNPCEditorModel.BuildDefinition(look)
T.equal(rerolled.appearance.slots.Torso.type, "Base.ShirtLookA", "new controlled clothing reaches canonical output")
T.equal(rerolled.appearance.slots.Torso.itemState.visualTextureChoice, 1, "rerolled clothing carries exact native visual state")
T.falsy(rerolled.identity.survivor.hairModel, "the saved result cannot recapture the old explicit hair")
PNC.UniqueNPCEditorModel.Randomize(look)
T.equal(look.previewSeed, 67, "repeated seed source cannot leave an explicit debug action stale")
T.equal(look.appearance.slots.Torso.type, "Base.ShirtLookB", "the second controlled result replaces clothing")

local genderPreview = PNC.UniqueNPCEditorModel.BuildPreviewDraft(look)
genderPreview.isFemale = false
local previousBody = PNC.UniqueNPCEditorModel.EnsureRuntimeRecord(genderPreview, true)
genderPreview.isFemale = true
local nextBody = PNC.UniqueNPCEditorModel.EnsureRuntimeRecord(genderPreview, false)
T.truthy(previousBody ~= nextBody, "gender change creates a new body-specific runtime preview")
T.equal(nextBody.isFemale, true, "new body uses selected gender")

local skinDraft = Model.New()
skinDraft.displayName = 'Skin Tester'; skinDraft.isFemale = false
skinDraft.identity.survivor = { forename = 'Skin', surname = 'Tester', skinTexture = 'MaleBody05' }
skinDraft.appearanceAuthored.skinTexture = true
-- A real adapter rebind has no RGB authoring flag after clearing the field.
skinDraft.appearanceAuthored.skinColor = nil
skinDraft.runtimeRecord = { isFemale = false, identitySeed = 7, equipmentSpawnMode = 'none', startingItems = {},
    identity = { survivor = { skinTexture = 'MaleBody01', skinColor = { r = .1, g = .1, b = .1 } } },
    inventory = { items = {} }, appearance = PNC.Identity.Appearance.Normalize(skinDraft.appearance),
    runtime = { appearanceCache = { skinTexture = 'MaleBody01', skinColor = { r = .1, g = .1, b = .1 }, outfitItems = { 'Base.Shirt' } } } }
local skinSpec = Model.BuildPortraitSpec(skinDraft)
T.equal(skinSpec.appearance.skinTexture, 'MaleBody05', 'selected native skin tone reaches the portrait projection')
T.falsy(skinSpec.appearance.skinColor, 'native tone selection clears stale custom RGB from the preview cache')
T.equal(skinSpec.appearance.outfitItems[1], 'Base.Shirt', 'skin tone edits leave wardrobe state stable')
T.finish("pnc_unique_npc_editor_model_smoke")
