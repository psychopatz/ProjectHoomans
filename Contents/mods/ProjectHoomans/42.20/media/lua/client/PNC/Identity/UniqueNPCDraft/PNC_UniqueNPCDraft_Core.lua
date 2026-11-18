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
local OutfitCapture = require "PNC/Identity/PNC_UniqueNPCOutfitCapture"

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
    local value
    if Identity and Identity.RollSeed then
        value = Identity.RollSeed()
        if tonumber(value) and tonumber(value) > 0 then
            return tonumber(value)
        end
    end
    if type(ZombRand) == "function" then
        value = ZombRand(2147483646)
        if tonumber(value) then return math.max(1, tonumber(value) + 1) end
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

local function exportItems(draft, fromRuntime)
    -- Slot authoring is newer than the retained preview inventory. Do not
    -- serialize that old inventory over a pending canonical loadout edit.
    if not fromRuntime and draft.authoredFields
        and draft.authoredFields.startingItems == true
    then
        local authored = copy(draft.startingItems or {})
        local order = {}
        for index, item in ipairs(authored) do order[item] = index end
        -- Template construction resolves a bag destination as bags appear.
        -- Emit containers before contents even if the author added the bag last.
        table.sort(authored, function(left, right)
            local leftBag = (tonumber(left.maxWeight) or 0) > 0
            local rightBag = (tonumber(right.maxWeight) or 0) > 0
            if leftBag ~= rightBag then return leftBag end
            return order[left] < order[right]
        end)
        return authored
    end
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
            local spec = Inventory.Queries and Inventory.Queries.ToDefinitionSpec
                and Inventory.Queries.ToDefinitionSpec(
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
                -- A retained preview may still contain an older outfit's
                -- generated garment. It cannot replace the pending policy.
                for existingSlot, existing in pairs(appearance.slots) do
                    if existingSlot ~= slot and existing.mode == "item"
                        and Appearance.AreExclusive(spec and spec.wornSlot or slot, existing.wornSlot or existingSlot)
                    then spec = nil; break end
                end
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

function Model.New(options)
    options = type(options) == "table" and options or {}
    return {
        schemaVersion = 2,
        displayName = "",
        isFemale = false,
        -- Stable slot seed.  The concrete runtime definition may omit it, but
        -- the canonical sparse blueprint persists it for deterministic edits.
        previewSeed = tonumber(options.previewSeed) or nextSeed(),
        identity = { nickname = nil, survivor = {} },
        authoringClears = {},
        appearanceAuthored = {},
        -- New drafts inherit a stable clothed archetype look. Explicit None
        -- remains available for intentionally empty outfits.
        appearance = Appearance and Appearance.Normalize
            and Appearance.Normalize({ outfit = { mode = "random" } }) or {
                schemaVersion = 2,
                outfit = { mode = "random" },
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
function Model.BuildPreviewDraft(draft, previous)
    local output = copy(draft or Model.New())
    if not text(output.displayName) then
        output.displayName = "Preview Survivor"
    end
    if output.isFemale ~= true and output.isFemale ~= false then
        output.isFemale = false
    end
    output.archetypeID = text(output.archetypeID) or "General"
    local outfit = output.appearance and output.appearance.outfit
    if Appearance and outfit and outfit.mode == "item" and outfit.id
        and not Appearance.HasExplicitSlots(output.appearance)
    then
        local key = tostring(outfit.id) .. ":" .. tostring(output.isFemale) .. ":" .. tostring(output.previewSeed)
        local slots = previous and previous.previewNamedOutfitKey == key and previous.previewNamedOutfitSlots
        if not slots then slots = OutfitCapture.Capture(outfit.id, output.isFemale) end
        if slots then
            output.previewNamedOutfitKey, output.previewNamedOutfitSlots = key, copy(slots)
            output.appearance = Appearance.Normalize(output.appearance)
            output.appearance.slots = copy(slots)
        end
    end
    return output
end

-- Copy authored controls into the preview without copying the preview's
-- generated result. The runtime record is deliberately retained so typing a
-- name or changing another non-random field cannot call SurvivorFactory again.
function Model.UpdatePreviewDraft(preview, draft)
    local output = Model.BuildPreviewDraft(draft, preview)
    if preview and preview.runtimeRecord then
        output.runtimeRecord = preview.runtimeRecord
        output.id = preview.id
    end
    return output
end

-- Debug-only user action: replace the visual scope, retaining authored bio,
-- attributes, held/carried gear and audio. Never promote the old preview look.
function Model.Randomize(draft, generationSeed)
    if not draft then return false end
    Model.SyncFromRuntime(draft)
    local previousSeed = tonumber(draft.previewSeed) or 1
    draft.previewSeed = tonumber(generationSeed) or nextSeed()
    if draft.previewSeed == previousSeed then draft.previewSeed = previousSeed % 2147483645 + 1 end
    local voice = draft.appearance and copy(draft.appearance.voice)
    local appearance = Appearance.Normalize({ voice = voice })
    local values = getAllOutfits and getAllOutfits(draft.isFemale == true)
    if values and values:size() > 0 then
        local id = tostring(values:get(draft.previewSeed % values:size()))
        local slots = OutfitCapture.Capture(id, draft.isFemale)
        if slots then
            appearance.outfit, appearance.slots = { mode = "item", id = id }, slots
        end
    end
    draft.appearance = appearance
    draft.appearanceAuthored = draft.appearanceAuthored or {}
    draft.appearanceAuthored.appearance = true
    draft.identity = draft.identity or { survivor = {} }
    draft.identity.survivor = draft.identity.survivor or {}
    draft.authoringClears = draft.authoringClears or {}
    for _, field in ipairs({ "hairModel", "beardModel", "skinTexture", "skinColor", "hairColor" }) do
        draft.identity.survivor[field] = nil
        draft.appearanceAuthored[field] = nil
        draft.authoringClears["appearance." .. field] = nil
    end
    local items = {}
    for _, item in ipairs(draft.startingItems or {}) do
        if not presentationClothing(item) then items[#items + 1] = item end
    end
    draft.startingItems = items
    draft.runtimeRecord = nil
    draft._dirty = true
    return true
end

Model.Internal = Model.Internal or {}
Model.Internal.copy = copy
Model.Internal.text = text
Model.Internal.hasEntries = hasEntries
Model.Internal.generatedItem = generatedItem
Model.Internal.nextSeed = nextSeed
Model.Internal.nameParts = nameParts
Model.Internal.exportItems = exportItems
Model.Internal.captureAppearanceItems = captureAppearanceItems


return Model
