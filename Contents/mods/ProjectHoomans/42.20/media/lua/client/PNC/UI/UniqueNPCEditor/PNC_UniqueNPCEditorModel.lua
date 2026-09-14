-- Client-only draft model for the Unique NPC Creator. A draft is never
-- registered with the server registry; Produce only serializes its sparse
-- authored definition.

require "PNC/Core/Identity/PNC_UniqueNPCs"
require "PNC/Core/Inventory/PNC_Inventory"

PNC = PNC or {}
PNC.UniqueNPCEditorModel = PNC.UniqueNPCEditorModel or {}

local Model = PNC.UniqueNPCEditorModel
local Unique = PNC.UniqueNPCs
local Identity = PNC.Identity
local Appearance = Identity and Identity.Appearance
local Inventory = PNC.Inventory

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then return PNC.Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[copy(key)] = copy(child) end
    return output
end

local function text(value)
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end

local function hasEntries(values)
    if type(values) ~= "table" then return false end
    for _, _ in pairs(values) do return true end
    return false
end

local function slug(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", "")
    return value ~= "" and value or "npc"
end

local function filePart(value)
    value = string.gsub(tostring(value or ""), "[^%w]+", "")
    return value ~= "" and value or "NPC"
end

local function nextSeed()
    if Identity and Identity.RollSeed then
        local ok, value = pcall(Identity.RollSeed)
        if ok and tonumber(value) and tonumber(value) > 0 then
            return tonumber(value)
        end
    end
    if type(ZombRand) == "function" then
        local ok, value = pcall(ZombRand, 2147483646)
        if ok and tonumber(value) then return math.max(1, tonumber(value) + 1) end
    end
    if type(getTimestampMs) == "function" then
        return math.max(1, tonumber(getTimestampMs()) or 1)
            % 2147483646
    end
    return 1
end

local function nameParts(name, survivor)
    survivor = type(survivor) == "table" and survivor or {}
    local forename = text(survivor.forename)
    local surname = text(survivor.surname)
    local first
    local last
    if forename and surname then return forename, surname end
    first, last = string.match(tostring(name or ""), "^(%S+)%s+(.+)$")
    return forename or first, surname or last
end

local function buildID(name, survivor, existing)
    if text(existing) then return tostring(existing) end
    local forename, surname = nameParts(name, survivor)
    return "unique:" .. slug(forename) .. slug(surname)
end

local function generatedItem(item)
    local key = tostring(item and item.templateKey or "")
    local generatedPrefixes = {
        "tmpl:look:", "tmpl:bag:", "tmpl:weapon:",
        "tmpl:equipment_grant:", "tmpl:supply:", "tmpl:identity_card:",
    }
    for _, prefix in ipairs(generatedPrefixes) do
        if string.sub(key, 1, #prefix) == prefix then return true end
    end
    return item and item.identityNPCId ~= nil
end

local function generatedLookItem(item)
    local key = tostring(item and item.templateKey or "")
    return string.sub(key, 1, 9) == "tmpl:look:"
end

-- Worn clothing belongs to appearance.slots.  Bags remain regular authored
-- inventory because their worn location also owns a container and capacity.
local function presentationClothing(item)
    return item and item.wornSlot ~= nil
        and item.equipSlot == nil
        and item.maxWeight == nil
        and item.bagContainer == nil
end

local function sortedItemIDs(items)
    local output = {}
    for id, _ in pairs(items or {}) do output[#output + 1] = id end
    table.sort(output, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return output
end

local function exportItems(draft)
    local record = draft.runtimeRecord
    local inv = record and record.inventory or nil
    local output = {}
    local included = {}
    local item
    local ids
    if not inv then return copy(draft.startingItems or {}) end
    ids = sortedItemIDs(inv.items)
    for i = 1, #ids do
        local id = ids[i]
        local value = inv.items[id]
        item = value
        if item and not generatedItem(item)
            and not presentationClothing(item)
        then
            included[id] = true
        end
    end
    local index = 0
    for i = 1, #ids do
        local id = ids[i]
        local value = inv.items[id]
        item = value
        if included[id] then
            index = index + 1
            local preferred = item.container ~= "root" and "bag" or nil
            local key = "editor:" .. tostring(Model.BuildID(draft))
                .. ":" .. tostring(index)
            local spec = Inventory.Internal.itemToDefinitionSpec
                and Inventory.Internal.itemToDefinitionSpec(
                    item, key, preferred)
                or nil
            if spec then output[#output + 1] = spec end
        end
    end
    table.sort(output, function(left, right)
        local leftBag = tonumber(left.maxWeight) and tonumber(left.maxWeight) > 0
        local rightBag = tonumber(right.maxWeight) and tonumber(right.maxWeight) > 0
        if leftBag ~= rightBag then return leftBag end
        return tostring(left.key) < tostring(right.key)
    end)
    return output
end

-- Promote explicit clothing that exists in the preview inventory into the
-- sparse appearance definition.  Generated random look items are only
-- captured when the author already selected that exact slot; otherwise the
-- random policy must remain random and deterministic at runtime.
local function captureAppearanceItems(draft, appearance)
    local inventory = draft and draft.runtimeRecord
        and draft.runtimeRecord.inventory or nil
    local ids
    local captured = {}
    local item
    local slot
    local policy
    local spec
    local previous
    if not inventory or type(inventory.items) ~= "table"
        or not appearance or type(appearance.slots) ~= "table"
    then
        return 0
    end
    ids = sortedItemIDs(inventory.items)
    for i = 1, #ids do
        item = inventory.items[ids[i]]
        if presentationClothing(item) then
            slot = tostring(item.wornSlot)
            policy = appearance.slots[slot]
            if not (policy and policy.mode == "none")
                and (not generatedLookItem(item)
                    or policy and policy.mode == "item"
                    and (not policy.type
                        or tostring(policy.type) == tostring(item.type)))
                and not captured[slot]
            then
                spec = Appearance.CaptureItemSpec(item, slot)
                previous = policy
                if spec then
                    if not spec.itemState and previous
                        and type(previous.itemState) == "table"
                    then
                        spec.itemState = copy(previous.itemState)
                    end
                    appearance.slots[slot] = spec
                    captured[slot] = true
                end
            end
        end
    end
    local count = 0
    for _, _ in pairs(captured) do count = count + 1 end
    return count
end

function Model.NameParts(draft)
    draft = draft or {}
    return nameParts(draft.displayName, draft.identity
        and draft.identity.survivor)
end

function Model.BuildID(draft)
    return buildID(draft and draft.displayName,
        draft and draft.identity and draft.identity.survivor,
        draft and draft.identityIDLocked and draft.id or nil)
end

function Model.FileName(draft)
    local forename, surname = Model.NameParts(draft)
    return filePart(forename) .. filePart(surname) .. ".txt"
end

function Model.New()
    return {
        schemaVersion = 2,
        displayName = "",
        isFemale = false,
        -- Preview-only seed.  The authored definition intentionally does not
        -- contain a seed: runtime identity generation owns it per world save.
        previewSeed = nextSeed(),
        identity = { survivor = {} },
        appearanceAuthored = {},
        -- A new authored NPC starts without inherited factory clothing.
        -- Random remains an explicit choice through the appearance tab or
        -- the Randomize action below.
        appearance = Appearance and Appearance.Normalize
            and Appearance.Normalize({ outfit = { mode = "none" } }) or {
                schemaVersion = 2,
                outfit = { mode = "none" },
                slots = {},
                voice = { mode = "random" },
            },
        authoredFields = {},
        archetypeID = "General",
        equipmentSpawnMode = "none",
        startingItems = {},
        identityIDLocked = false,
        _dirty = true,
    }
end

-- The editor should be able to show the visual result before the author has
-- entered the final name. Keep this temporary fallback isolated from the
-- authored draft so it can never leak into Save/Produce output.
function Model.BuildPreviewDraft(draft)
    local output = copy(draft or Model.New())
    if not text(output.displayName) then
        output.displayName = "Preview Survivor"
    end
    if output.isFemale ~= true and output.isFemale ~= false then
        output.isFemale = false
    end
    output.archetypeID = text(output.archetypeID) or "General"
    return output
end

-- Copy authored controls into the preview without copying the preview's
-- generated result. The runtime record is deliberately retained so typing a
-- name or changing another non-random field cannot call SurvivorFactory again.
function Model.UpdatePreviewDraft(preview, draft)
    local output = Model.BuildPreviewDraft(draft)
    if preview and preview.runtimeRecord then
        output.runtimeRecord = preview.runtimeRecord
        output.id = preview.id
    end
    return output
end

function Model.Randomize(draft)
    if not draft then return false end
    Model.SyncFromRuntime(draft)
    draft.previewSeed = nextSeed()
    -- Randomize is the deliberate escape hatch from the nude-by-default
    -- creator state.  Keep the policy explicit so the preview and produced
    -- definition agree about where the clothing came from.
    if Appearance and Appearance.Normalize then
        draft.appearance = Appearance.Normalize()
        draft.appearanceAuthored = draft.appearanceAuthored or {}
        draft.appearanceAuthored.appearance = true
    end
    draft.runtimeRecord = nil
    draft._dirty = true
    return true
end

function Model.FromDefinition(definition, fileName)
    local output = Model.New()
    for key, value in pairs(copy(definition or {})) do output[key] = value end
    output.displayName = text(output.displayName or output.name) or ""
    output.isFemale = output.isFemale == true
    output.identity = type(output.identity) == "table" and output.identity or { survivor = {} }
    output.identity.survivor = type(output.identity.survivor) == "table"
        and output.identity.survivor or {}
    local first, last = nameParts(output.displayName, output.identity.survivor)
    output.identity.survivor.forename = text(output.identity.survivor.forename) or first
    output.identity.survivor.surname = text(output.identity.survivor.surname) or last
    output.appearanceAuthored = type(output.appearanceAuthored) == "table"
        and output.appearanceAuthored or {}
    if Appearance and Appearance.Normalize then
        output.appearance = Appearance.Normalize(output.appearance,
            output.outfit)
        output.appearanceAuthored.appearance = definition.appearance ~= nil
    end
    output.authoredFields = type(output.authoredFields) == "table"
        and output.authoredFields or {}
    for _, key in ipairs({ "skillLevels", "vanillaTraits", "dynamicTraits",
        "npcTraits" }) do
        if definition[key] ~= nil then output.authoredFields[key] = true end
    end
    for _, key in ipairs({ "hairModel", "beardModel", "skinTexture",
        "hairColor", "skinColor", "voice", "voicePrefix", "voiceType",
        "voicePitch" }) do
        if output.identity.survivor[key] ~= nil then
            output.appearanceAuthored[key] = true
        end
    end
    -- Older files may contain identitySeed.  Use it only to keep the loaded
    -- preview stable during this editing session; never emit it again.
    output.previewSeed = tonumber(output.previewSeed)
        or tonumber(output.identitySeed) or nextSeed()
    output.identitySeed = nil
    output.id = output.id or output.uniqueDefinitionId
    output.identityIDLocked = true
    output.fileName = fileName
    output.originalDisplayName = output.displayName
    output.startingItems = type(output.startingItems) == "table"
        and output.startingItems or {}
    output.equipmentSpawnMode = output.equipmentSpawnMode or "none"
    output._dirty = false
    return output
end

function Model.BuildDefinition(draft)
    local def = {}
    local survivor = draft.identity and draft.identity.survivor or {}
    local appearance
    local voice
    local fields = {
        "archetypeID", "archetypeLabel", "tacticalClass", "visualProfile",
        "weaponMode", "attackType", "equipmentSpawnMode",
        "equipmentPoolID", "chanceWeight", "spawnChance", "skillLevels",
        "vanillaTraits", "dynamicTraits", "npcTraits", "factionID",
        "membershipStatus", "factionRole", "factionRank", "ownerUsername",
        "forceLive", "debug", "persist", "recruited", "social", "hostility",
        "equipment", "combatProfile", "orderSpec", "patrolPoints",
        "allowedJobs", "jobPriorities", "mapPresentation", "recipeKnowledge",
        "inventoryTemplateRef", "ownerOnlineID", "factionJoinedAt",
    }
    def.id = Model.BuildID(draft)
    def.uniqueDefinitionId = def.id
    def.version = 1
    local forename, surname = Model.NameParts(draft)
    local displayName = nil
    if forename and surname then
        displayName = tostring(forename) .. " " .. tostring(surname)
    else
        displayName = text(draft.displayName)
    end
    def.displayName = displayName
    def.name = def.displayName
    def.isFemale = draft.isFemale == true
    for _, key in ipairs(fields) do
        if draft[key] ~= nil and draft[key] ~= "" then def[key] = copy(draft[key]) end
    end
    local explicit = {}
    for _, key in ipairs({ "forename", "surname", "hairModel", "beardModel",
        "skinTexture", "hairColor", "skinColor", "voice", "voicePrefix",
        "voiceType", "voicePitch" }) do
        if survivor[key] ~= nil
            and (survivor[key] ~= ""
                or draft.appearanceAuthored
                and draft.appearanceAuthored[key] == true)
        then
            explicit[key] = copy(survivor[key])
        end
    end
    appearance = Appearance and Appearance.Normalize
        and Appearance.Normalize(draft.appearance, draft.outfit) or nil
    if appearance then captureAppearanceItems(draft, appearance) end
    voice = appearance and appearance.voice or nil
    if voice and voice.mode == "item" then
        if voice.prefix ~= nil then explicit.voice = copy(voice.prefix) end
        if voice.prefix ~= nil then explicit.voicePrefix = copy(voice.prefix) end
        if voice.type ~= nil then explicit.voiceType = copy(voice.type) end
        if voice.pitch ~= nil then explicit.voicePitch = copy(voice.pitch) end
    end
    if hasEntries(explicit) then def.identity = { survivor = explicit } end
    def.startingItems = exportItems(draft)
    if #def.startingItems == 0 then def.startingItems = nil end
    if Appearance and Appearance.Normalize then
        def.appearance = appearance
        if appearance and Appearance.HasExplicitSlots
            and Appearance.HasExplicitSlots(appearance)
        then
            def.appearanceVersion = 2
        end
    end
    return def
end

local function knownSkill(skillID)
    local catalog = PNC.SkillCatalog
    if not catalog or not catalog.Find then return true end
    return catalog.Find(skillID) ~= nil
end

local function validateSkills(draft)
    for skillID, level in pairs(draft.skillLevels or {}) do
        if not knownSkill(skillID) then
            return false, "unknown_skill:" .. tostring(skillID)
        end
        level = tonumber(level)
        if not level or level < 0 or level > 10
            or level ~= math.floor(level)
        then
            return false, "invalid_skill_level:" .. tostring(skillID)
        end
    end
    return true
end

local function npcTraitRegistry()
    return PNC.NPCTraits
end

local function validateNPCTraitSet(source, label)
    local registry = npcTraitRegistry()
    if not registry or not registry.NormalizeID then return true end
    for rawID, selected in pairs(source or {}) do
        if selected then
            local candidate = type(rawID) == "number" and selected or rawID
            if not registry.NormalizeID(candidate) then
                return false, "unknown_" .. label .. ":" .. tostring(candidate)
            end
        end
    end
    if registry.ResolveSet then
        local _, conflicts = registry.ResolveSet(source)
        if conflicts and #conflicts > 0 then
            return false, "conflicting_" .. label
        end
    end
    return true
end

local function findVanillaTrait(id)
    local list
    local ok
    if not CharacterTraitDefinition
        or not CharacterTraitDefinition.getTraits
    then
        return nil
    end
    ok, list = pcall(CharacterTraitDefinition.getTraits)
    if not ok or not list then return nil end
    for index = 0, list:size() - 1 do
        local trait = list:get(index)
        local traitType
        local traitID
        if trait and trait.getType then
            ok, traitType = pcall(trait.getType, trait)
            if ok and traitType and traitType.getName then
                ok, traitID = pcall(traitType.getName, traitType)
                if ok and tostring(traitID) == tostring(id) then
                    return trait
                end
            end
        end
    end
    return nil
end

local function vanillaTraitConflict(left, right)
    local leftDefinition = findVanillaTrait(left)
    local rightDefinition = findVanillaTrait(right)
    local leftType
    local rightType
    local excluded
    if not leftDefinition or not rightDefinition then return false end
    if leftDefinition.getType then
        leftType = leftDefinition:getType()
    end
    if rightDefinition.getType then
        rightType = rightDefinition:getType()
    end
    if leftDefinition.getMutuallyExclusiveTraits and rightType then
        excluded = leftDefinition:getMutuallyExclusiveTraits()
        if excluded and excluded.contains and excluded:contains(rightType) then
            return true
        end
    end
    if rightDefinition.getMutuallyExclusiveTraits and leftType then
        excluded = rightDefinition:getMutuallyExclusiveTraits()
        if excluded and excluded.contains and excluded:contains(leftType) then
            return true
        end
    end
    return false
end

local function validateVanillaTraits(source)
    local selected = {}
    for rawID, enabled in pairs(source or {}) do
        if enabled then
            local candidate = type(rawID) == "number" and enabled or rawID
            if not findVanillaTrait(candidate) then
                -- The base-game catalog is unavailable in headless tests and
                -- older worlds.  In that case retain the authored ID and let
                -- the normal runtime validator decide its compatibility.
                if CharacterTraitDefinition then
                    return false, "unknown_vanilla_trait:" .. tostring(candidate)
                end
            end
            for existing, _ in pairs(selected) do
                if vanillaTraitConflict(existing, candidate) then
                    return false, "conflicting_vanilla_traits"
                end
            end
            selected[tostring(candidate)] = true
        end
    end
    return true
end

local function combinedNPCTraits(draft)
    local output = {}
    for id, selected in pairs(draft.npcTraits or {}) do
        if selected then
            output[type(id) == "number" and selected or id] = true
        end
    end
    for id, selected in pairs(draft.dynamicTraits or {}) do
        if selected then
            output[type(id) == "number" and selected or id] = true
        end
    end
    return output
end

function Model.TryAddSkill(draft, skillID, level)
    local id = text(skillID)
    local numeric = tonumber(level)
    if not id or not knownSkill(id) then return false, "unknown_skill" end
    if not numeric or numeric < 0 or numeric > 10
        or numeric ~= math.floor(numeric)
    then
        return false, "invalid_skill_level"
    end
    draft.skillLevels = type(draft.skillLevels) == "table"
        and draft.skillLevels or {}
    if draft.skillLevels[id] ~= nil then return false, "skill_duplicate" end
    draft.skillLevels[id] = numeric
    draft.authoredFields = draft.authoredFields or {}
    draft.authoredFields.skillLevels = true
    draft._dirty = true
    return true, "skill_added", id
end

function Model.TryAddTrait(draft, kind, traitID)
    local id = text(traitID)
    local field = kind == "vanilla" and "vanillaTraits"
        or kind == "dynamic" and "dynamicTraits" or "npcTraits"
    local traits
    local combined
    local registry
    local _, conflicts
    if not id then return false, "trait_required" end
    registry = npcTraitRegistry()
    if kind ~= "vanilla" and registry and registry.NormalizeID then
        id = registry.NormalizeID(id)
        if not id then return false, "unknown_trait" end
    end
    traits = {}
    for rawID, selected in pairs(draft[field] or {}) do
        if selected then
            local candidate = type(rawID) == "number" and selected or rawID
            if kind ~= "vanilla" and registry and registry.NormalizeID then
                candidate = registry.NormalizeID(candidate) or candidate
            end
            traits[tostring(candidate)] = true
        end
    end
    if traits[id] then return false, "trait_duplicate" end
    if kind == "vanilla" then
        if not validateVanillaTraits({ [id] = true }) then
            return false, "unknown_vanilla_trait"
        end
        for existing, selected in pairs(draft.vanillaTraits or {}) do
            if selected and vanillaTraitConflict(existing, id) then
                return false, "trait_conflict"
            end
        end
    else
        combined = combinedNPCTraits(draft)
        combined[id] = true
        if registry and registry.NormalizeID
            and not registry.NormalizeID(id)
        then
            return false, "unknown_trait"
        end
        if registry and registry.ResolveSet then
            _, conflicts = registry.ResolveSet(combined)
            if conflicts and #conflicts > 0 then
                return false, "trait_conflict"
            end
        end
    end
    traits[id] = true
    draft[field] = traits
    draft.authoredFields = draft.authoredFields or {}
    draft.authoredFields[field] = true
    draft._dirty = true
    return true, "trait_added", id
end

function Model.Validate(draft)
    local forename
    local surname
    if not draft then return false, "name_required" end
    forename, surname = Model.NameParts(draft)
    if not text(forename) or not text(surname) then
        return false, "first_and_surname_required"
    end
    if type(draft.isFemale) ~= "boolean" then return false, "gender_required" end
    local valid, reason = validateSkills(draft)
    if not valid then return false, reason end
    valid, reason = validateNPCTraitSet(combinedNPCTraits(draft), "traits")
    if not valid then return false, reason end
    valid, reason = validateVanillaTraits(draft.vanillaTraits)
    if not valid then return false, reason end
    if Appearance and Appearance.Validate then
        valid, reason = Appearance.Validate(draft.appearance)
        if not valid then return false, reason end
    end
    local normalized, reason = Unique.NormalizeDefinition(Model.BuildDefinition(draft))
    if not normalized then return false, reason end
    return true, normalized
end

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

function Model.BuildPortraitSpec(draft)
    local record = Model.EnsureRuntimeRecord(draft)
    local runtime = record and record.runtime or {}
    local snapshot = runtime.previewVisualSnapshot or {}
    local appearance = snapshot.appearance
        or record and runtime.appearanceCache or {}
    local equipment = snapshot.equipment or record and record.equipment or {}
    local revision = runtime.previewVisualRevision or 0
    return {
        key = tostring(draft.id or Model.BuildID(draft))
            .. ":preview:" .. tostring(revision),
        id = tostring(draft.id or "editor"),
        identitySeed = record and record.identitySeed or draft.previewSeed or 1,
        isFemale = draft.isFemale == true,
        preferDescriptor = true,
        appearance = copy(appearance),
        equipment = copy(equipment),
    }
end

function Model.ExportItems(draft)
    return exportItems(draft)
end

function Model.ListAuthoredItems(draft)
    local output = {}
    local inventory = draft and draft.runtimeRecord
        and draft.runtimeRecord.inventory or nil
    if not inventory then return output end
    for id, item in pairs(inventory.items or {}) do
        if item and not generatedItem(item) then
            output[#output + 1] = {
                runtimeID = id,
                type = item.type,
                stack = item.stack,
                container = item.container,
            }
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.runtimeID) < tostring(right.runtimeID)
    end)
    return output
end

function Model.RemoveInventoryItem(draft, runtimeID)
    local inventory = draft and draft.runtimeRecord
        and draft.runtimeRecord.inventory or nil
    local item
    local index
    if not inventory or runtimeID == nil then return false end
    item = inventory.items and inventory.items[runtimeID]
    if not item then return false end
    inventory.items[runtimeID] = nil
    for _, containerData in pairs(inventory.containers or {}) do
        local itemIDs = containerData and containerData.items or nil
        if type(itemIDs) == "table" then
            for index = #itemIDs, 1, -1 do
                if tostring(itemIDs[index]) == tostring(runtimeID) then
                    table.remove(itemIDs, index)
                end
            end
        end
    end
    inventory.revision = (tonumber(inventory.revision) or 0) + 1
    if Inventory and Inventory.SyncEquipmentFromInventory then
        Inventory.SyncEquipmentFromInventory(draft.runtimeRecord)
    end
    draft._dirty = true
    return true
end

function Model.ParseList(value)
    local output = {}
    for token in string.gmatch(tostring(value or ""), "[^,%s]+") do
        output[#output + 1] = token
    end
    return #output > 0 and output or nil
end

function Model.ParseMap(value)
    local output = {}
    for token in string.gmatch(tostring(value or ""), "[^,]+") do
        local key, number = string.match(token, "^%s*([^=]+)%s*=%s*(%-?[%d%.]+)%s*$")
        if key and number then output[tostring(key)] = tonumber(number) end
    end
    return hasEntries(output) and output or nil
end

return Model
