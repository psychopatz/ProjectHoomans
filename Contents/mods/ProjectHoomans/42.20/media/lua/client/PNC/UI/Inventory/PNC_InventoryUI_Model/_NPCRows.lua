local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local probe = Helpers.probe
local isNPCDepositForbidden = Helpers.isNPCDepositForbidden
local TooltipModel = Helpers.tooltipModel
local TooltipOptions = Helpers.tooltipOptions
local ROOT_INVENTORY_TEXTURE = Helpers.rootInventoryTexture
local Currency = Helpers.currency

local Model = PNC.InventoryUIModel

local function virtualMetadataRow(
    containerID, npcID, id, fullType, name, reason
)
    local metadata = probe(fullType)
    local rowID = "virtual:" .. tostring(id) .. ":" .. tostring(npcID or "")
    return {
        source = "npc",
        id = rowID,
        fullType = fullType,
        name = name,
        category = metadata.category,
        texture = metadata.texture,
        weight = 0,
        unitWeight = 0,
        conditionMax = metadata.conditionMax,
        stateful = false,
        virtual = true,
        interactionLocked = true,
        restricted = true,
        restrictionReason = reason or "identity_metadata",
        container = containerID,
        stack = 1,
        equipped = false,
        favorite = false,
        stateKey = "virtual:" .. rowID .. ":" .. tostring(name or ""),
    }
end

local function appendVirtualIdentityRows(rows, inventory, containerID, snapshot)
    local identity = inventory and inventory.identityMetadata or nil
    local organizationalFaction = snapshot
        and snapshot.organizationalFaction or nil
    local npcID = identity and identity.npcId
        or snapshot and snapshot.id or ""
    local displayName = identity and identity.displayName
        or snapshot and snapshot.displayName or nil
    local factionID = identity and identity.factionID
        or organizationalFaction and organizationalFaction.factionID
    local factionName = identity and identity.factionName
        or organizationalFaction and organizationalFaction.name
    local factionLabel
    if tostring(containerID or "root") ~= "root" then return end
    if displayName and tostring(displayName) ~= "" then
        rows[#rows + 1] = virtualMetadataRow(
            "root",
            npcID,
            "identity-card",
            "Base.IDcard",
            "ID Card: " .. tostring(displayName)
        )
    end
    if factionID and tostring(factionID) ~= ""
        and factionName and tostring(factionName) ~= ""
    then
        factionLabel = "Dog Tags: " .. tostring(factionName)
        rows[#rows + 1] = virtualMetadataRow(
            "root",
            npcID,
            "faction-dogtag:" .. tostring(factionID),
            "Base.Necklace_DogTag",
            factionLabel
        )
    end
end

function Model.BuildNPCContainers(inventory)
    local output = {
        { id = "root", label = "Inventory", texture = ROOT_INVENTORY_TEXTURE },
    }
    for _, item in pairs(inventory and inventory.items or {}) do
        if item.bagContainer and inventory.containers
            and inventory.containers[item.bagContainer]
        then
            local metadata = probe(item.type)
            output[#output + 1] = {
                id = item.bagContainer,
                label = tostring(item.customName or metadata.name),
                texture = metadata.texture,
                itemID = item.id,
            }
        end
    end
    table.sort(output, function(a, b)
        if a.id == "root" then return true end
        if b.id == "root" then return false end
        return string.lower(a.label) < string.lower(b.label)
    end)
    return output
end

function Model.BuildNPCRows(
    inventory, containerID, expandedGroups, characterSnapshot
)
    local rows = {}
    local currencyRow
    local container = inventory and inventory.containers
        and inventory.containers[containerID or "root"]
        or nil
    appendVirtualIdentityRows(
        rows,
        inventory,
        containerID or "root",
        characterSnapshot
    )
    for _, itemID in ipairs(container and container.items or {}) do
        local item = inventory.items and inventory.items[itemID] or nil
        if item then
            if Currency and Currency.IsType(item.type) then
                if not currencyRow then
                    currencyRow = Helpers.newCurrencyRow(
                        containerID or "root", "npc")
                end
                Helpers.addCurrencyValue(
                    currencyRow, item.type,
                    math.max(1, math.floor(tonumber(item.stack) or 1)), 1)
            else
            local metadata = probe(item.type)
            rows[#rows + 1] = {
                source = "npc",
                id = item.id,
                compactItem = item,
                fullType = item.type,
                name = tostring(item.customName or metadata.name),
                category = metadata.category,
                texture = metadata.texture,
                weight = metadata.weight * math.max(1, tonumber(item.stack) or 1),
                unitWeight = metadata.weight,
                conditionMax = metadata.conditionMax,
                stateful = true,
                container = item.container,
                stack = math.max(1, tonumber(item.stack) or 1),
                equipped = item.equipSlot ~= nil
                    or item.wornSlot ~= nil
                    or item.attachedSlot ~= nil,
                favorite = item.fav == true,
                restricted = isNPCDepositForbidden(item),
                restrictionReason = item.interactionLockReason,
            }
            rows[#rows].stateKey = TooltipModel.StateSignature(
                rows[#rows], nil, false, TooltipOptions.modelOptions)
            end
        end
    end
    if currencyRow and currencyRow.currencyUnits > 0 then
        rows[#rows + 1] = currencyRow
    end
    table.sort(rows, function(a, b)
        if a.currency ~= b.currency then return a.currency == true end
        if a.equipped ~= b.equipped then return a.equipped == true end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return Model.GroupRows(rows, expandedGroups)
end

function Model.FindContainer(containers, containerID)
    for _, entry in ipairs(containers or {}) do
        if tostring(entry.id) == tostring(containerID) then return entry end
    end
    return nil
end

return Model
