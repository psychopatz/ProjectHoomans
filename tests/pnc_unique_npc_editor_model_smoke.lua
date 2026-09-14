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
    Inventory = { Internal = {} },
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

PNC.Inventory.Internal.itemToDefinitionSpec = function(item, key, preferred)
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
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel.lua")

local draft = PNC.UniqueNPCEditorModel.New()
T.equal(draft.appearance.outfit.mode, "none",
    "new drafts default to no inherited clothing")
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

local loaded = PNC.UniqueNPCEditorModel.FromDefinition({
    id = "unique:loaded",
    displayName = "Loaded Person",
    isFemale = false,
    startingItems = { { type = "Base.Money", stack = 1000 } },
})
local loadedDefinition = PNC.UniqueNPCEditorModel.BuildDefinition(loaded)
T.equal(loadedDefinition.startingItems[1].stack, 1000,
    "loaded authored inventory survives before preview")
T.finish("pnc_unique_npc_editor_model_smoke")
