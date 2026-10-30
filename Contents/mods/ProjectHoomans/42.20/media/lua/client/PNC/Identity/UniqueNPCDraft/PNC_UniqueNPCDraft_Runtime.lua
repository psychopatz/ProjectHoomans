-- Preview runtime synchronization for the Unique NPC editor model.

PNC = PNC or {}
PNC.UniqueNPCEditorModel = PNC.UniqueNPCEditorModel or {}

local Model = PNC.UniqueNPCEditorModel
local Internal = Model.Internal or {}
local Unique = PNC.UniqueNPCs
local Identity = PNC.Identity
local Appearance = Identity and Identity.Appearance
local Inventory = PNC.Inventory
local copy = Internal.copy
local exportItems = Internal.exportItems

local function applyExplicitIdentity(record, def, draft)
    local survivor = record.identity and record.identity.survivor or {}
    local explicit = def.identity and def.identity.survivor or {}
    local cleared = {}
    record.identity = record.identity or {}
    record.identity.survivor = survivor
    for _, key in ipairs({ "forename", "surname", "hairModel", "beardModel",
        "skinTexture", "hairColor", "skinColor", "voice", "voicePrefix",
        "voiceType", "voicePitch" }) do
        if explicit[key] ~= nil then
            survivor[key] = copy(explicit[key])
        elseif draft.appearanceAuthored
            and (draft.appearanceAuthored[key] == true
                or key == "voice"
                and draft.appearanceAuthored.voice == true)
        then
            -- An explicit Random/None selection must remove the prior
            -- preview override instead of leaving the old custom value on
            -- the retained runtime identity.
            survivor[key] = nil
            cleared[key] = true
        elseif (key == "forename" or key == "surname")
            and draft.identity and draft.identity.survivor
            and draft.identity.survivor[key] ~= nil
        then
            survivor[key] = copy(draft.identity.survivor[key])
        end
    end
    record.identity.displayName = def.displayName
    record.identity.name = def.displayName
    return cleared
end

local function applyPreviewAppearance(record, cleared)
    local survivor = record.identity and record.identity.survivor or {}
    local appearance = record.runtime and record.runtime.appearanceCache or nil
    local generated = record.runtime and record.runtime.generatedAppearance or {}
    if not appearance then return end
    -- Keep the generated outfitItems untouched.  Authored appearance fields
    -- are patched into the existing cache so a hair/faction/name edit cannot
    -- roll clothing or any other fallback value.
    if survivor.skinTexture ~= nil then
        appearance.skinTexture = survivor.skinTexture
    end
    if survivor.hairModel ~= nil then
        appearance.hairModel = survivor.hairModel
    end
    if survivor.beardModel ~= nil then
        appearance.beardModel = record.isFemale and nil or survivor.beardModel
    end
    if survivor.hairColor ~= nil then appearance.hairColor = copy(survivor.hairColor) end
    if survivor.skinColor ~= nil then appearance.skinColor = copy(survivor.skinColor) end
    if cleared then
        for _, key in ipairs({ "skinTexture", "hairModel", "beardModel",
            "hairColor", "skinColor" }) do
            if cleared[key] and survivor[key] == nil
                and generated[key] ~= nil
            then
                appearance[key] = copy(generated[key])
            end
        end
        if (cleared.voice or cleared.voicePrefix or cleared.voiceType
            or cleared.voicePitch) and survivor.voicePrefix == nil
        then
            appearance.voice = generated.voice
            appearance.voicePrefix = generated.voicePrefix
                or generated.voice
            appearance.voiceType = generated.voiceType
            appearance.voicePitch = generated.voicePitch
        end
    end
    if survivor.voicePrefix ~= nil or survivor.voiceType ~= nil
        or survivor.voicePitch ~= nil or survivor.voice ~= nil
    then
        appearance.voice = {
            mode = "item",
            prefix = survivor.voicePrefix or survivor.voice,
            type = survivor.voiceType,
            pitch = survivor.voicePitch,
        }
    end
end

local function createdNativeItem(fullType)
    local equipment = PNC.Equipment
    local created
    if not equipment or not equipment.CreateItem or not fullType then
        return nil
    end
    created = equipment.CreateItem(fullType)
    if type(created) == "table" and created[1] and not created.getVisual then
        return created[1]
    end
    return created
end

-- Archetype clothing starts as a compact item type.  Capture its native
-- visual choice once for the editor preview so recreating the descriptor does
-- not ask the engine to randomize the shirt/pants/decal again.
local function capturePreviewEquipmentVisuals(record)
    local inventory = record and record.inventory or nil
    local equipment = PNC.Equipment
    local item
    local visual
    local native
    if not inventory or not equipment
        or not equipment.VisualStateFromItemState
        or not equipment.CaptureItemVisualState
        or not equipment.StoreVisualStateInItemState
    then
        return false
    end
    for _, candidate in pairs(inventory.items or {}) do
        if candidate and (candidate.wornSlot or candidate.equipSlot) then
            visual = equipment.VisualStateFromItemState(
                candidate.itemState, candidate.type)
            if not visual then
                native = createdNativeItem(candidate.type)
                if native then
                    visual = equipment.CaptureItemVisualState(
                        native, candidate.type)
                    if visual then
                        equipment.StoreVisualStateInItemState(
                            candidate, visual)
                    end
                end
            end
        end
    end
    if Inventory and Inventory.SyncEquipmentFromInventory then
        Inventory.SyncEquipmentFromInventory(record)
    end
    return true
end

local function refreshPreviewVisualSnapshot(record)
    local runtime
    local summary
    if not record then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    summary = Identity and Identity.BuildPortraitSummary
        and Identity.BuildPortraitSummary(record) or nil
    runtime.previewVisualSnapshot = {
        appearance = copy(runtime.appearanceCache or {}),
        equipment = copy(record.equipment or {}),
    }
    runtime.previewVisualRevision = summary and summary.revision
        or (tonumber(runtime.previewVisualRevision) or 0) + 1
    return runtime.previewVisualSnapshot
end

function Model.ApplyDraftToRuntime(draft)
    local record = draft and draft.runtimeRecord
    local def
    local inventory
    local identitySeed
    local authoredFields
    local previousAppearanceSignature
    local nextAppearanceSignature
    local appearanceChanged
    if not record then return nil, "preview_missing" end
    def = Model.BuildDefinition(draft)
    inventory = record.inventory
    identitySeed = record.identitySeed
    previousAppearanceSignature = Appearance and Appearance.Signature
        and Appearance.Signature(record.appearance) or ""
    nextAppearanceSignature = Appearance and Appearance.Signature
        and Appearance.Signature(def.appearance) or ""
    appearanceChanged = previousAppearanceSignature ~= nextAppearanceSignature
    authoredFields = draft.authoredFields or {}
    for _, key in ipairs({
        "displayName", "name", "isFemale", "archetypeID", "archetypeLabel",
        "tacticalClass", "visualProfile", "weaponMode", "attackType",
        "equipmentSpawnMode", "equipmentPoolID", "chanceWeight", "spawnChance",
        "skillLevels", "vanillaTraits", "dynamicTraits", "npcTraits",
        "factionID", "membershipStatus", "factionRole", "factionRank",
        "ownerUsername", "forceLive", "debug", "persist", "recruited",
        "social", "hostility", "equipment", "combatProfile", "orderSpec",
        "patrolPoints", "allowedJobs", "jobPriorities", "mapPresentation",
        "recipeKnowledge", "inventoryTemplateRef", "ownerOnlineID",
        "factionJoinedAt", "appearance",
    }) do
        if key ~= "skillLevels" and key ~= "vanillaTraits"
            and key ~= "dynamicTraits" and key ~= "npcTraits"
        then
            record[key] = copy(def[key])
        elseif def[key] ~= nil or authoredFields[key] then
            -- Unique.Resolve may have generated fallback traits.  Keep those
            -- stable through ordinary edits unless the author has explicitly
            -- touched/reset that collection.
            record[key] = copy(def[key])
        end
    end
    record.id = nil
    record.uniqueDefinitionId = def.id
    record._editorDraft = true
    record.identitySeed = identitySeed
    record.startingItems = copy(def.startingItems or {})
    local clearedAppearance = applyExplicitIdentity(record, def, draft)
    applyPreviewAppearance(record, clearedAppearance)
    if appearanceChanged and Inventory and Inventory.CreateFromTemplate then
        record.runtime = record.runtime or {}
        record.runtime.appearanceCache = nil
        record.runtime.appearanceCacheKey = nil
        Inventory.CreateFromTemplate(record)
    else
        if inventory then record.inventory = inventory end
        if Inventory and Inventory.SyncEquipmentFromInventory then
            Inventory.SyncEquipmentFromInventory(record)
        end
    end
    capturePreviewEquipmentVisuals(record)
    refreshPreviewVisualSnapshot(record)
    draft.id = def.id
    draft._dirty = false
    return record
end

function Model.EnsureRuntimeRecord(draft, force)
    if draft.runtimeRecord and not force then
        return Model.ApplyDraftToRuntime(draft)
    end
    local def = Model.BuildDefinition(draft)
    local record
    local reason
    record, reason = Unique.Resolve(def, {
        -- This is deliberately a preview-only hint.  Unique.Resolve still
        -- creates the real world identity seed at runtime when the definition
        -- is registered/spawned.
        identitySeed = tonumber(draft.previewSeed) or nil,
    })
    if not record then return nil, reason end
    -- Keep the draft outside the authoritative registry. Inventory mutations
    -- see a nil runtime id, so Registry.MarkDirty is intentionally a no-op.
    record.id = nil
    record._editorDraft = true
    record.equipmentSpawnMode = draft.equipmentSpawnMode or "none"
    record.startingItems = copy(def.startingItems or {})
    if Identity and Identity.RollAppearance then Identity.RollAppearance(record) end
    if Inventory and Inventory.EnsureRecordInventory then
        Inventory.EnsureRecordInventory(record, { reconcileWaterContainer = false })
    end
    capturePreviewEquipmentVisuals(record)
    if Inventory and Inventory.SyncEquipmentFromInventory then
        Inventory.SyncEquipmentFromInventory(record)
    end
    refreshPreviewVisualSnapshot(record)
    draft.runtimeRecord = record
    draft.id = def.id
    draft._dirty = false
    return record
end

function Model.SyncFromRuntime(draft)
    local record = draft and draft.runtimeRecord
    if not record then return false end
    if Inventory and Inventory.SyncEquipmentFromInventory then
        Inventory.SyncEquipmentFromInventory(record)
    end
    capturePreviewEquipmentVisuals(record)
    refreshPreviewVisualSnapshot(record)
    draft.startingItems = exportItems(draft)
    draft._dirty = true
    return true
end

return Model
