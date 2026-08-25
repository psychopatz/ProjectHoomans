-- Corpse inventory materialization and worn-item transfer.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local CorpseItems =
    require "PsychopatzCore/Inventory/PsychopatzCorpseItems"

local function identityCardKey(npcId)
    return "ProjectHoomans:identity-card:" .. tostring(npcId or "")
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
            PNC_IDCardNPCId = npcId,
            PNC_IDCardNPCName = npcName,
        },
        match = function(item)
            local modData = item and item.getModData and item:getModData() or nil
            return Internal.itemFullType(item) == "Base.IDcard"
                and modData
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
    if not record or not target then
        return nil, false, "invalid_identity_card_target"
    end
    container = target.getContainer and target:getContainer()
        or target.getInventory and target:getInventory()
        or nil
    item, created, reason = CorpseItems.Inject(
        container,
        identityCardSpec(record)
    )
    return item, created == true, reason
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
        if not candidate or not value then return end
        state = {
            customName = value.customName,
            condition = value.cond,
        }
        if value.identityNPCId then
            state.key = identityCardKey(value.identityNPCId)
            state.modData = {
                PNC_IDCard = true,
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
