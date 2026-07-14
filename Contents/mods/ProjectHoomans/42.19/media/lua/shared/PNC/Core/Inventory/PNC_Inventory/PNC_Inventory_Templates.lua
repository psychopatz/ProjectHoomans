--[[
    PNC Inventory Templates
    Deterministic archetype/appearance inventory generation.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Core = PNC.Core
local Archetypes = PNC.Archetypes
local Identity = PNC.Identity

local function choose(list, seed, salt)
    if type(list) ~= "table" or #list <= 0 then
        return nil
    end
    return list[Identity.Index(seed, salt, #list)]
end

local function buildIdentityTemplate(record)
    local appearance = Identity and Identity.RollAppearance and Identity.RollAppearance(record) or {}
    local archetype = Archetypes.Get(record and record.archetypeID or nil)
    local loadout = archetype.loadout or {}
    local seed = Identity.NormalizeSeed(record and record.identitySeed or nil, record and record.id or "npc")
    return {
        archetypeID = archetype.id,
        appearance = appearance,
        bagType = choose(loadout.bagChoices, seed, "inv:bag:" .. tostring(archetype.id)),
        primaryType = choose(loadout.primaryChoices, seed, "inv:primary:" .. tostring(archetype.id)),
        attached = Core.DeepCopy(loadout.attached or {}),
        supplies = Internal.shallowArrayCopy(loadout.supplies),
    }
end

function Internal.buildTemplateSnapshot(record)
    local base = Internal.createBaseInventory(record)
    local template = buildIdentityTemplate(record)
    local appearanceItems = template.appearance and template.appearance.outfitItems or {}
    local lookCounts = {}
    local supplyCounts = {}
    local bagContainerID
    local bagItem
    local templateKey
    local supply
    local item
    local i

    for i = 1, #appearanceItems do
        lookCounts[tostring(appearanceItems[i])] = (lookCounts[tostring(appearanceItems[i])] or 0) + 1
        templateKey = "tmpl:look:" .. tostring(appearanceItems[i]) .. ":"
            .. tostring(lookCounts[tostring(appearanceItems[i])])
        item = Internal.createItem(record, base, {
            type = appearanceItems[i],
            container = "root",
            templateKey = templateKey,
            legacyTemplateKey = "tmpl:look:" .. tostring(i),
        })
        if item and PNC.Equipment and PNC.Equipment.CreateItem then
            local created = PNC.Equipment.CreateItem(appearanceItems[i])
            created = type(created) == "table" and created[1] or created
            if created and created.getBodyLocation then
                item.wornSlot = Internal.normalizeString(created:getBodyLocation())
                if item.wornSlot then
                    base.worn[item.wornSlot] = item.id
                end
            end
        end
    end

    if template.bagType then
        bagItem = Internal.createItem(record, base, {
            type = template.bagType,
            container = "root",
            equipSlot = "bag",
            templateKey = "tmpl:bag:0",
            maxWeight = Internal.getItemCapacity(template.bagType),
        })
        if bagItem then
            bagContainerID = bagItem.bagContainer
        end
    end

    if template.primaryType then
        Internal.createItem(record, base, {
            type = template.primaryType,
            container = "root",
            equipSlot = "primary",
            templateKey = "tmpl:weapon:0",
        })
    end

    for i = 1, #(template.supplies or {}) do
        supply = template.supplies[i]
        templateKey = Internal.normalizeString(supply.key)
        if not templateKey then
            supplyCounts[tostring(supply.type)] = (supplyCounts[tostring(supply.type)] or 0) + 1
            templateKey = tostring(supply.type) .. ":" .. tostring(supplyCounts[tostring(supply.type)])
            if Core.LogWarn then
                Core.LogWarn("PNC archetype supply missing stable key archetype=" .. tostring(template.archetypeID)
                    .. " type=" .. tostring(supply.type))
            end
        end
        Internal.createItem(record, base, {
            type = supply.type,
            stack = supply.stack,
            container = (supply.preferredContainer == "bag" and bagContainerID) and bagContainerID or "root",
            preferredContainer = supply.preferredContainer,
            templateKey = "tmpl:supply:" .. tostring(templateKey),
            legacyTemplateKey = "tmpl:supply:" .. tostring(i),
        })
    end

    Internal.calculateWeights(base)
    return base
end

function Inventory.CreateFromTemplate(record, options)
    local inv
    local runtime
    if not record then
        return nil
    end
    inv = Internal.buildTemplateSnapshot(record)
    inv.deltaMode = "template_plus_delta"
    inv.template = {
        archetypeID = record.archetypeID,
        seed = record.identitySeed,
        generatorVersion = PNC.Const and PNC.Const.GENERATOR_VERSION or 1,
    }
    record.inventory = inv
    runtime = Internal.getRuntimeState(record)
    if options and options.keepRevision then
        inv.revision = tonumber(options.keepRevision) or inv.revision
    else
        inv.revision = 0
    end
    runtime.opLog = {}
    Internal.refreshNextItemSerial(record, inv)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    return record.inventory
end
