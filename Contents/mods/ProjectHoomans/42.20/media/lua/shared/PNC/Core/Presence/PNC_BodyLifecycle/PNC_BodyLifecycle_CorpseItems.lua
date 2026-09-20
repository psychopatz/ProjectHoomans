-- Corpse inventory materialization and worn-item transfer.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local CorpseItems =
    require "PsychopatzCore/Inventory/PsychopatzCorpseItems"
local ID_CARD_SCHEMA_VERSION = 1
local FACTION_DOGTAG_SCHEMA_VERSION = 1

local function identityCardKey(npcId)
    return "ProjectHoomans:identity-card:" .. tostring(npcId or "")
end

local function factionDogtagKey(npcId)
    return "ProjectHoomans:faction-dogtag:" .. tostring(npcId or "")
end

local function corpseItemNeedsStateUpdate(item, spec)
    local currentName
    local currentData
    local field
    local value
    if not item then return true end
    if spec.customName ~= nil then
        if not item.getName then return true end
        currentName = item:getName()
        if tostring(currentName or "")
            ~= tostring(spec.customName)
        then
            return true
        end
    end
    if type(spec.modData) == "table" then
        if item.getModData then
            currentData = item:getModData()
        end
        if not currentData then return true end
        for field, value in pairs(spec.modData) do
            if currentData[field] ~= value then return true end
        end
    end
    return false
end

local function identityCardSpec(record)
    local npcId = tostring(record and record.id or "")
    local npcName = tostring(
        record and (record.name or record.displayName) or "Unknown NPC"
    )
    return {
        fullType = "Base.IDcard",
        key = identityCardKey(npcId),
        customName = "ID Card: " .. npcName,
        modData = {
            PNC_IDCard = true,
            PNC_IDCardVersion = ID_CARD_SCHEMA_VERSION,
            PNC_IDCardNPCId = npcId,
            PNC_IDCardNPCName = npcName,
        },
        match = function(item)
            local modData = item and item.getModData and item:getModData() or nil
            return Internal.itemFullType(item) == "Base.IDcard"
                and modData
                and tonumber(modData.PNC_IDCardVersion)
                    == ID_CARD_SCHEMA_VERSION
                and modData.PNC_IDCard == true
                and tostring(modData.PNC_IDCardNPCId or "") == npcId
        end,
        create = function()
            return PNC.Equipment and PNC.Equipment.CreateItem
                and PNC.Equipment.CreateItem("Base.IDcard") or nil
        end,
    }
end

function Internal.ensureCorpseIdentityCard(record, target)
    local container
    local item
    local created
    local reason
    local spec
    local existing
    local changed
    if not record or not target then
        return nil, false, "invalid_identity_card_target"
    end
    container = target.getContainer and target:getContainer()
        or target.getInventory and target:getInventory()
        or nil
    if container and container.getItems and container.Remove then
        local items = container:getItems()
        local stale = {}
        local index
        if items and items.size and items.get then
            for index = 0, items:size() - 1 do
                local candidate = items:get(index)
                local data = candidate and candidate.getModData
                    and candidate:getModData() or nil
                if Internal.itemFullType(candidate) == "Base.IDcard"
                    and data and data.PNC_IDCard == true
                    and tostring(data.PNC_IDCardNPCId or "")
                        == tostring(record.id or "")
                    and tonumber(data.PNC_IDCardVersion)
                        ~= ID_CARD_SCHEMA_VERSION
                then
                    stale[#stale + 1] = candidate
                end
            end
        end
        for index = 1, #stale do
            pcall(container.Remove, container, stale[index])
            if sendRemoveItemFromContainer then
                pcall(sendRemoveItemFromContainer, container, stale[index])
            end
        end
    end
    spec = identityCardSpec(record)
    existing = CorpseItems.Find(container, spec)
    changed = corpseItemNeedsStateUpdate(existing, spec)
    item, created, reason = CorpseItems.Inject(container, spec)
    return item, created == true, reason,
        item ~= nil and (created == true or changed) or false
end

local function factionDogtagMetadata(record)
    local inv = record and record.inventory or nil
    local runtime = record and record.runtime or nil
    local candidate
    local metadata
    local factionID = record and record.affiliation
        and tostring(record.affiliation.factionID or "") or ""
    local faction
    local npcID = tostring(record and record.id or "")
    local inventoryRevision = inv and tonumber(inv.revision) or 0
    local generatorVersion = inv and inv.template
        and tonumber(inv.template.generatorVersion) or 0
    if type(runtime) ~= "table" and record then
        runtime = {}
        record.runtime = runtime
    end
    if runtime
        and runtime.corpseFactionDogTagSourceInventory == inv
        and tonumber(runtime.corpseFactionDogTagSourceRevision)
            == inventoryRevision
        and tonumber(runtime.corpseFactionDogTagGeneratorVersion)
            == generatorVersion
        and tostring(runtime.corpseFactionDogTagSourceFactionID or "")
            == factionID
    then
        return runtime.corpseFactionDogTagSourceMetadata
    end
    for _, candidate in pairs(inv and inv.items or {}) do
        metadata = candidate and candidate.itemState
            and candidate.itemState.modData or nil
        if metadata and metadata.PNC_FactionDogTag == true
            and tostring(metadata.PNC_FactionDogTagNPCId or "") == npcID
            and tostring(metadata.PNC_FactionDogTagFactionId or "") ~= ""
            and tostring(metadata.PNC_FactionDogTagFactionName or "") ~= ""
        then
            metadata = {
                PNC_FactionDogTag = true,
                PNC_FactionDogTagVersion = FACTION_DOGTAG_SCHEMA_VERSION,
                PNC_FactionDogTagNPCId = npcID,
                PNC_FactionDogTagFactionId = tostring(
                    metadata.PNC_FactionDogTagFactionId
                ),
                PNC_FactionDogTagFactionName = tostring(
                    metadata.PNC_FactionDogTagFactionName
                ),
            }
            break
        end
    end
    faction = not metadata and factionID ~= "" and PNC.Factions
        and PNC.Factions.Get and PNC.Factions.Get(factionID) or nil
    if not metadata and faction and tostring(faction.id or "") ~= ""
        and tostring(faction.name or "") ~= "" and npcID ~= ""
    then
        metadata = {
            PNC_FactionDogTag = true,
            PNC_FactionDogTagVersion = FACTION_DOGTAG_SCHEMA_VERSION,
            PNC_FactionDogTagNPCId = npcID,
            PNC_FactionDogTagFactionId = tostring(faction.id),
            PNC_FactionDogTagFactionName = tostring(faction.name),
        }
    end
    if runtime then
        runtime.corpseFactionDogTagSourceInventory = inv
        runtime.corpseFactionDogTagSourceRevision = inventoryRevision
        runtime.corpseFactionDogTagGeneratorVersion = generatorVersion
        runtime.corpseFactionDogTagSourceFactionID = factionID
        runtime.corpseFactionDogTagSourceMetadata = metadata
    end
    return metadata
end

local function factionDogtagSpec(record, metadata)
    local npcID = tostring(record and record.id or "")
    local factionName = tostring(
        metadata.PNC_FactionDogTagFactionName or ""
    )
    return {
        fullType = "Base.Necklace_DogTag",
        key = factionDogtagKey(npcID),
        customName = "Dog Tags: " .. factionName,
        modData = metadata,
        match = function(item)
            local modData = item and item.getModData
                and item:getModData() or nil
            return Internal.itemFullType(item)
                == "Base.Necklace_DogTag"
                and modData and modData.PNC_FactionDogTag == true
                and tonumber(modData.PNC_FactionDogTagVersion)
                    == FACTION_DOGTAG_SCHEMA_VERSION
                and tostring(modData.PNC_FactionDogTagNPCId or "") == npcID
        end,
        create = function()
            return PNC.Equipment and PNC.Equipment.CreateItem
                and PNC.Equipment.CreateItem("Base.Necklace_DogTag") or nil
        end,
    }
end

function Internal.ensureCorpseFactionDogTag(record, target)
    local container
    local metadata
    local existing
    local item
    local created
    local reason
    local spec
    local changed
    if not record or not target then
        return nil, false, "invalid_faction_dogtag_target"
    end
    container = target.getContainer and target:getContainer()
        or target.getInventory and target:getInventory()
        or nil
    existing = CorpseItems.Find(container, {
        fullType = "Base.Necklace_DogTag",
        match = function(candidate)
            local data = candidate and candidate.getModData
                and candidate:getModData() or nil
            return Internal.itemFullType(candidate)
                == "Base.Necklace_DogTag"
                and data and data.PNC_FactionDogTag == true
                and tostring(data.PNC_FactionDogTagNPCId or "")
                    == tostring(record.id or "")
        end,
    })
    if existing then
        local data = existing.getModData
            and existing:getModData() or nil
        if data and tostring(data.PNC_FactionDogTagFactionId or "") ~= ""
            and tostring(data.PNC_FactionDogTagFactionName or "") ~= ""
        then
            metadata = {
                PNC_FactionDogTag = true,
                PNC_FactionDogTagVersion = FACTION_DOGTAG_SCHEMA_VERSION,
                PNC_FactionDogTagNPCId = tostring(record.id),
                PNC_FactionDogTagFactionId = tostring(
                    data.PNC_FactionDogTagFactionId
                ),
                PNC_FactionDogTagFactionName = tostring(
                    data.PNC_FactionDogTagFactionName
                ),
            }
            spec = factionDogtagSpec(record, metadata)
            changed = corpseItemNeedsStateUpdate(existing, spec)
            if changed then CorpseItems.ApplyState(existing, spec) end
            return existing, false, nil, changed
        end
    end
    metadata = factionDogtagMetadata(record)
    if not metadata then return nil, false, "faction_unavailable" end
    spec = factionDogtagSpec(record, metadata)
    existing = CorpseItems.Find(container, spec)
    changed = corpseItemNeedsStateUpdate(existing, spec)
    item, created, reason = CorpseItems.Inject(container, spec)
    return item, created == true, reason,
        item ~= nil and (created == true or changed) or false
end

function Internal.prepareCorpseItems(record, zombie)
    local equipment = PNC.Equipment
    local profiles = PNC.VisualProfiles
    local container = zombie and zombie.getInventory and zombie:getInventory() or nil
    local pool = {}
    local allItems = {}
    local seen = {}
    local claimed = {}
    local appearanceUsed = {}
    local wornItems = zombie and zombie.getWornItems and zombie:getWornItems() or nil
    local itemVisuals = zombie and zombie.getItemVisuals and zombie:getItemVisuals() or nil
    local inventoryItems = container and container.getItems and container:getItems() or nil
    local appearance = profiles and profiles.RollAppearance and profiles.RollAppearance(record) or nil
    local abstractInventory = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or record.inventory
    local i
    local descriptor
    local item
    local fullType
    local visualsByType = {}
    local usedVisuals = {}

    local function applyDescriptorMetadata(candidate, value)
        local state
        local itemState
        if not candidate or not value then return end
        state = {
            customName = value.customName,
            condition = value.cond,
        }
        itemState = value.itemState
        if itemState and type(itemState.modData) == "table" then
            state.modData = itemState.modData
            if itemState.modData.PNC_FactionDogTag == true then
                state.key = factionDogtagKey(
                    itemState.modData.PNC_FactionDogTagNPCId
                )
            end
        end
        if value.identityNPCId then
            state.key = identityCardKey(value.identityNPCId)
            state.modData = {
                PNC_IDCard = true,
                PNC_IDCardVersion = ID_CARD_SCHEMA_VERSION,
                PNC_IDCardNPCId = tostring(value.identityNPCId),
                PNC_IDCardNPCName = tostring(
                    value.identityNPCName or record.name or "Unknown NPC"
                ),
            }
        end
        CorpseItems.ApplyState(candidate, state)
    end

    if not CorpseItems.IsAuthority()
        or not container or not equipment or not equipment.CreateItem
    then
        return false
    end

    if itemVisuals and itemVisuals.size then
        for i = 0, itemVisuals:size() - 1 do
            local visual = itemVisuals:get(i)
            local visualType = visual and visual.getItemType and tostring(visual:getItemType() or "") or ""
            if visualType ~= "" then
                visualsByType[visualType] = visualsByType[visualType] or {}
                visualsByType[visualType][#visualsByType[visualType] + 1] = visual
            end
        end
    end

    local function copyLiveVisual(candidate, kind)
        local candidates = visualsByType[tostring(kind or "")] or {}
        local targetVisual = candidate and candidate.getVisual and candidate:getVisual() or nil
        local index
        if not targetVisual or not targetVisual.copyFrom then
            return false
        end
        for index = 1, #candidates do
            if not usedVisuals[candidates[index]] then
                usedVisuals[candidates[index]] = true
                return pcall(targetVisual.copyFrom, targetVisual, candidates[index])
            end
        end
        return false
    end

    local function remember(candidate)
        local kind
        if not candidate or seen[candidate] then
            return candidate
        end
        seen[candidate] = true
        kind = Internal.itemFullType(candidate)
        if kind ~= "" then
            pool[kind] = pool[kind] or {}
            pool[kind][#pool[kind] + 1] = candidate
            allItems[#allItems + 1] = candidate
            CorpseItems.AddExisting(container, candidate)
        end
        return candidate
    end

    local function create(kind)
        local created = equipment.CreateItem(kind)
        if created then
            remember(created)
        end
        return created
    end

    local function takeForInventory(kind)
        local candidates = pool[kind] or {}
        local index
        for index = 1, #candidates do
            if not claimed[candidates[index]] then
                claimed[candidates[index]] = true
                return candidates[index]
            end
        end
        local created = create(kind)
        if created then
            claimed[created] = true
        end
        return created
    end

    local function takeForAppearance(kind)
        local candidates = pool[kind] or {}
        local index
        for index = 1, #candidates do
            if not appearanceUsed[candidates[index]] then
                appearanceUsed[candidates[index]] = true
                return candidates[index]
            end
        end
        local created = create(kind)
        if created then
            appearanceUsed[created] = true
        end
        return created
    end

    if inventoryItems then
        for i = 0, inventoryItems:size() - 1 do
            remember(inventoryItems:get(i))
        end
    end
    if wornItems then
        for i = 0, wornItems:size() - 1 do
            local entry = wornItems:get(i)
            remember(entry and entry.getItem and entry:getItem() or nil)
        end
    end
    remember(zombie.getPrimaryHandItem and zombie:getPrimaryHandItem() or nil)
    remember(zombie.getSecondaryHandItem and zombie:getSecondaryHandItem() or nil)

    -- Materialize the canonical logical inventory first. Live NPC rendering can
    -- use ItemVisuals, but IsoDeadBody only retains real InventoryItem objects.
    if abstractInventory and type(abstractInventory.items) == "table" then
        for _, descriptorValue in pairs(abstractInventory.items) do
            descriptor = descriptorValue
            fullType = descriptor and descriptor.type and tostring(descriptor.type) or ""
            if fullType ~= "" then
                item = takeForInventory(fullType)
                applyDescriptorMetadata(item, descriptor)
                if item and descriptor.cond ~= nil and item.setCondition then
                    pcall(item.setCondition, item, math.max(0, math.floor(tonumber(descriptor.cond) or 0)))
                end
                if item and descriptor.wornSlot and zombie.setWornItem then
                    copyLiveVisual(item, fullType)
                    if PNC.Core and PNC.Core.ProtectClothingFromFall then
                        PNC.Core.ProtectClothingFromFall(item)
                    end
                    pcall(zombie.setWornItem, zombie, tostring(descriptor.wornSlot), item)
                elseif item and descriptor.equipSlot == "primary" and zombie.setPrimaryHandItem then
                    pcall(zombie.setPrimaryHandItem, zombie, item)
                elseif item and descriptor.equipSlot == "secondary" and zombie.setSecondaryHandItem then
                    pcall(zombie.setSecondaryHandItem, zombie, item)
                end
            end
        end
    end

    -- Named outfits are often visual-only. Add their real clothing counterparts
    -- and wear them so the corpse preserves both appearance and loot.
    if appearance and type(appearance.outfitItems) == "table" then
        for i = 1, #appearance.outfitItems do
            fullType = tostring(appearance.outfitItems[i] or "")
            if fullType ~= "" then
                item = takeForAppearance(fullType)
                if item and item.getBodyLocation and zombie.setWornItem then
                    local bodyLocation = item:getBodyLocation()
                    if bodyLocation and tostring(bodyLocation) ~= "" then
                        copyLiveVisual(item, fullType)
                        if PNC.Core and PNC.Core.ProtectClothingFromFall then
                            PNC.Core.ProtectClothingFromFall(item)
                        end
                        pcall(zombie.setWornItem, zombie, tostring(bodyLocation), item)
                    end
                end
            end
        end
    end

    -- Explicit worn slots take precedence over generated outfit locations.
    if record.equipment and type(record.equipment.worn) == "table" then
        for bodyLocation, kind in pairs(record.equipment.worn) do
            local candidates = pool[tostring(kind)] or {}
            item = candidates[1] or create(tostring(kind))
            if item and zombie.setWornItem then
                copyLiveVisual(item, tostring(kind))
                if PNC.Core and PNC.Core.ProtectClothingFromFall then
                    PNC.Core.ProtectClothingFromFall(item)
                end
                pcall(zombie.setWornItem, zombie, tostring(bodyLocation), item)
            end
        end
    end
    -- Every remembered or created item is already inserted through the shared
    -- corpse-item service. Calling addItemsToItemContainer() again produces
    -- duplicate inventory IDs during IsoDeadBody conversion in multiplayer.
    for i = 1, #allItems do
        CorpseItems.AddExisting(container, allItems[i])
    end
    if PNC.Visuals and PNC.Visuals.RefreshModel then
        PNC.Visuals.RefreshModel(zombie)
    end
    return true
end

Lifecycle.PrepareCorpseItems = Internal.prepareCorpseItems
