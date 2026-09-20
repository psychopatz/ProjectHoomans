local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local FACTION_DOGTAG_TYPE = "Base.Necklace_DogTag"
local FACTION_DOGTAG_TEMPLATE_KEY = "tmpl:faction_dogtag:0"
local FACTION_DOGTAG_VERSION = 1

local function buildItem(record, spec, fullType, profile)
    return {
        id = Internal.normalizeString(spec.id)
            or Internal.nextItemID(record),
        type = fullType,
        stack = math.max(
            1,
            math.floor(tonumber(spec.stack) or 1)
        ),
        uses = tonumber(spec.uses),
        cond = tonumber(spec.cond),
        ammoCount = spec.ammoCount ~= nil
            and math.max(0, math.floor(tonumber(spec.ammoCount) or 0))
            or nil,
        fav = spec.fav == true,
        interactionLocked = spec.interactionLocked == true,
        interactionLockReason = Internal.normalizeString(
            spec.interactionLockReason
        ),
        container = Internal.normalizeString(spec.container) or "root",
        bagContainer = Internal.normalizeString(spec.bagContainer),
        maxWeight = tonumber(spec.maxWeight)
            or (profile.capacity > 0 and profile.capacity or nil),
        weightReduction = spec.weightReduction ~= nil
            and Internal.normalizeItemWeightReduction(spec.weightReduction)
            or profile.weightReduction,
        wearableSlot = Internal.normalizeString(spec.wearableSlot)
            or profile.wearableSlot,
        templateKey = Internal.normalizeString(spec.templateKey),
        legacyTemplateKey = Internal.normalizeString(spec.legacyTemplateKey),
        preferredContainer = Internal.normalizeString(spec.preferredContainer),
        wornSlot = Internal.normalizeString(spec.wornSlot),
        attachedSlot = Internal.normalizeString(spec.attachedSlot),
        equipSlot = Internal.normalizeString(spec.equipSlot),
        customName = Internal.normalizeString(spec.customName),
        identityNPCId = Internal.normalizeString(spec.identityNPCId),
        identityNPCName = Internal.normalizeString(spec.identityNPCName),
        itemState = Internal.sanitizeItemState(spec.itemState),
    }
end

local function attachItem(inv, item)
    inv.items[item.id] = item
    Internal.addItemToContainer(inv, item.id, item.container)
    if item.maxWeight and item.maxWeight > 0 then
        Internal.ensureContainer(
            inv,
            "bag_" .. tostring(item.id),
            item.maxWeight
        )
        item.bagContainer = "bag_" .. tostring(item.id)
    elseif item.bagContainer then
        Internal.ensureContainer(inv, item.bagContainer, 0)
    end
    if item.wornSlot then inv.worn[item.wornSlot] = item.id end
    if item.attachedSlot then inv.attached[item.attachedSlot] = item.id end
    if item.equipSlot == "primary" then
        inv.equipped.primary = item.id
    elseif item.equipSlot == "secondary" then
        inv.equipped.secondary = item.id
    elseif item.equipSlot == "bag" then
        inv.equipped.bag = item.id
    elseif item.equipSlot == "waterContainer" then
        inv.equipped.waterContainer = item.id
    end
end

function Internal.createItem(record, inv, spec)
    spec = type(spec) == "table" and spec or {}
    local fullType = Internal.normalizeItemType(spec.type)
    local item
    local profile
    local state
    local now
    if not fullType then return nil end
    item = buildItem(
        record,
        spec,
        fullType,
        Internal.getContainerProfile(fullType)
    )
    profile = Inventory.GetFoodProfile(fullType)
    state = item.itemState or {}
    if profile and profile.food == true
        and spec.origin ~= "world"
        and spec.templateKey == nil
        and state.foodLastAgedHours == nil
        and state.foodCreatedAtHours == nil
    then
        now = Portable.GetWorldAgeHours()
        if now ~= nil then state.foodCreatedAtHours = now end
    end
    item.itemState = Internal.sanitizeItemState(state)
    if Inventory.NormalizeItemState then
        Inventory.NormalizeItemState(item)
    end
    attachItem(inv, item)
    return item
end

function Internal.normalizeLegacyBagSlot(inv)
    local itemID = inv and inv.equipped and inv.equipped.bag or nil
    local item = itemID and inv.items and inv.items[itemID] or nil
    local slot
    if not item then
        if inv and inv.equipped then inv.equipped.bag = nil end
        return false
    end
    slot = Internal.normalizeString(item.wearableSlot)
        or Internal.getContainerProfile(item.type).wearableSlot
    item.equipSlot = nil
    inv.equipped.bag = nil
    if slot and (not inv.worn[slot] or inv.worn[slot] == item.id) then
        item.wearableSlot = slot
        item.wornSlot = slot
        inv.worn[slot] = item.id
        return true
    end
    return false
end

function Internal.ensureIdentityCard(record, inv)
    local item
    local displayName
    local identityNPCID
    local changed = false
    if not record or not inv or type(inv.items) ~= "table" then
        return nil
    end
    item = Internal.findItemByTemplateKey(inv, "tmpl:identity_card:0")
    displayName = tostring(
        record.name or record.displayName or "Unknown NPC"
    )
    identityNPCID = tostring(record.id or "")
    if not item then
        item = Internal.createItem(record, inv, {
            type = "Base.IDcard",
            container = "root",
            templateKey = "tmpl:identity_card:0",
        })
        changed = item ~= nil
    end
    if item then
        -- Repair generator revision 3's incorrectly-cased script item ID.
        changed = changed
            or item.type ~= "Base.IDcard"
            or item.customName ~= "ID Card: " .. displayName
            or item.identityNPCId ~= identityNPCID
            or item.identityNPCName ~= displayName
            or item.interactionLocked ~= true
            or item.interactionLockReason ~= "identity_card"
        item.type = "Base.IDcard"
        item.customName = "ID Card: " .. displayName
        item.identityNPCId = identityNPCID
        item.identityNPCName = displayName
        item.interactionLocked = true
        item.interactionLockReason = "identity_card"
    end
    return item, changed
end

local function factionForRecord(record, faction)
    local factionID
    local factions
    if type(faction) == "table" then return faction end
    factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    factions = PNC.Factions
    if factionID and factions and type(factions.Get) == "function" then
        return factions.Get(factionID)
    end
    return nil
end

local function factionDogtagMetadata(record, faction)
    local factionID = faction and tostring(faction.id or "") or ""
    local factionName = faction and tostring(faction.name or "") or ""
    local npcID = record and tostring(record.id or "") or ""
    if factionID == "" or factionName == "" or npcID == "" then
        return nil
    end
    return {
        PNC_FactionDogTag = true,
        PNC_FactionDogTagVersion = FACTION_DOGTAG_VERSION,
        PNC_FactionDogTagNPCId = npcID,
        PNC_FactionDogTagFactionId = factionID,
        PNC_FactionDogTagFactionName = factionName,
    }
end

local function findFactionDogtag(inv, npcID)
    local candidate
    local metadata
    if not inv or type(inv.items) ~= "table" then return nil end
    for _, candidate in pairs(inv.items) do
        if candidate and candidate.templateKey == FACTION_DOGTAG_TEMPLATE_KEY then
            metadata = candidate.itemState
                and candidate.itemState.modData or nil
            if not metadata or metadata.PNC_FactionDogTag ~= true
                or tostring(metadata.PNC_FactionDogTagNPCId or "")
                    == tostring(npcID or "")
            then
                return candidate
            end
        end
    end
    for _, candidate in pairs(inv.items) do
        if candidate and candidate.type == FACTION_DOGTAG_TYPE then
            metadata = candidate.itemState
                and candidate.itemState.modData or nil
            if metadata and metadata.PNC_FactionDogTag == true
                and tostring(metadata.PNC_FactionDogTagNPCId or "")
                    == tostring(npcID or "")
            then
                return candidate
            end
        end
    end
    for _, candidate in pairs(inv.items) do
        if candidate and candidate.type == FACTION_DOGTAG_TYPE then
            metadata = candidate.itemState
                and candidate.itemState.modData or nil
            if not metadata or metadata.PNC_FactionDogTag ~= true then
                return candidate
            end
        end
    end
    return nil
end

local function copyFactionDogtagItem(item, metadata, factionName)
    local spec = {}
    local key
    local value
    local state
    local sanitizedState
    local modData
    if type(item) == "table" then
        for key, value in pairs(item) do spec[key] = value end
    end
    sanitizedState = Internal.sanitizeItemState(spec.itemState or {})
    state = {}
    modData = {}
    if type(sanitizedState) == "table" then
        for key, value in pairs(sanitizedState) do
            if key == "modData" and type(value) == "table" then
                for key, value in pairs(value) do
                    modData[key] = value
                end
            else
                state[key] = value
            end
        end
    end
    for key, value in pairs(metadata) do modData[key] = value end
    state.modData = modData
    spec.type = FACTION_DOGTAG_TYPE
    spec.stack = 1
    spec.container = Internal.normalizeString(spec.container) or "root"
    spec.templateKey = FACTION_DOGTAG_TEMPLATE_KEY
    spec.customName = "Dog Tags: " .. factionName
    spec.interactionLocked = true
    spec.interactionLockReason = "faction_dogtag"
    spec.itemState = Internal.sanitizeItemState(state)
    return spec
end

local function factionDogtagIsCurrent(item, metadata)
    local oldData = item and item.itemState
        and item.itemState.modData or nil
    local factionName = tostring(
        metadata and metadata.PNC_FactionDogTagFactionName or ""
    )
    return item ~= nil
        and item.type == FACTION_DOGTAG_TYPE
        and item.customName == "Dog Tags: " .. factionName
        and item.templateKey == FACTION_DOGTAG_TEMPLATE_KEY
        and item.interactionLocked == true
        and item.interactionLockReason == "faction_dogtag"
        and oldData ~= nil
        and oldData.PNC_FactionDogTag == true
        and tonumber(oldData.PNC_FactionDogTagVersion)
            == FACTION_DOGTAG_VERSION
        and tostring(oldData.PNC_FactionDogTagNPCId or "")
            == tostring(metadata.PNC_FactionDogTagNPCId or "")
        and tostring(oldData.PNC_FactionDogTagFactionId or "")
            == tostring(metadata.PNC_FactionDogTagFactionId or "")
        and tostring(oldData.PNC_FactionDogTagFactionName or "")
            == tostring(metadata.PNC_FactionDogTagFactionName or "")
end

function Internal.ensureFactionDogTag(record, inv, faction)
    local resolvedFaction = factionForRecord(record, faction)
    local metadata = factionDogtagMetadata(record, resolvedFaction)
    local item = findFactionDogtag(inv, record and record.id)
    local spec
    local changed
    if not metadata or not inv or type(inv.items) ~= "table" then
        -- Keep a previously issued tag as a record of the faction at the
        -- time the NPC joined or died, even after later affiliation cleanup.
        return item, false
    end
    spec = copyFactionDogtagItem(item, metadata,
        metadata.PNC_FactionDogTagFactionName)
    changed = not factionDogtagIsCurrent(item, metadata)
    if not changed then return item, false end
    if item then
        for key, value in pairs(spec) do item[key] = value end
    else
        item = Internal.createItem(record, inv, spec)
    end
    return item, item ~= nil
end

function Inventory.RefreshFactionDogTag(record, faction)
    local inv
    local item
    local metadata
    local existingItem
    local wasCurrent
    local spec
    local ops
    local applied
    if not record then return nil, false, "record_required" end
    local resolvedFaction = factionForRecord(record, faction)
    metadata = factionDogtagMetadata(record, resolvedFaction)
    existingItem = findFactionDogtag(record.inventory, record.id)
    if not metadata then
        return existingItem, false, "faction_unavailable"
    end
    wasCurrent = factionDogtagIsCurrent(existingItem, metadata)
    if wasCurrent then
        return existingItem, false, "unchanged"
    end
    if type(Inventory.EnsureRecordInventory) == "function" then
        inv = Inventory.EnsureRecordInventory(record, {
            reconcileWaterContainer = false,
        })
    else
        inv = record.inventory
    end
    if not inv then return nil, false, "inventory_unavailable" end
    item = findFactionDogtag(inv, record.id)
    if factionDogtagIsCurrent(item, metadata) then
        return item, true, "updated"
    end
    spec = copyFactionDogtagItem(item, metadata,
        metadata.PNC_FactionDogTagFactionName)
    if type(Inventory.ApplyDelta) ~= "function" then
        return nil, false, "inventory_mutation_unavailable"
    end
    ops = {}
    if item then
        if not item.id then return nil, false, "dogtag_id_unavailable" end
        ops[#ops + 1] = { op = "remove", itemID = item.id }
        spec.id = item.id
    end
    ops[#ops + 1] = { op = "add", item = spec }
    applied = Inventory.ApplyDelta(
        record,
        ops,
        "faction_dogtag_refresh"
    )
    if not applied then return nil, false, "inventory_update_failed" end
    item = findFactionDogtag(record.inventory, record.id)
    if not factionDogtagIsCurrent(item, metadata) then
        return item, false, "inventory_update_incomplete"
    end
    return item, true, "updated"
end
