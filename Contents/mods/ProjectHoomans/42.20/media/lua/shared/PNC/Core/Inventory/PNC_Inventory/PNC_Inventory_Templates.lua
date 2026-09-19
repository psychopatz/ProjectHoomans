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
local Unique = PNC.UniqueNPCs
local SupplyBuilder = require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_TemplateSupplies"

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
    local uniqueItems = record and record.startingItems or nil
    local uniqueTemplate = record and record.inventoryTemplateRef
        and Unique and Unique.GetInventoryTemplate
        and Unique.GetInventoryTemplate(record.inventoryTemplateRef) or nil
    if uniqueTemplate then uniqueItems = uniqueTemplate.items end
    local startingEquipment = Inventory.ResolveStartingEquipment
        and Inventory.ResolveStartingEquipment(record)
        or {}
    return {
        archetypeID = archetype.id,
        appearance = appearance,
        bagType = choose(loadout.bagChoices, seed, "inv:bag:" .. tostring(archetype.id)),
        startingEquipment = startingEquipment,
        attached = Core.DeepCopy(loadout.attached or {}),
        supplies = Internal.shallowArrayCopy(loadout.supplies),
        uniqueItems = Internal.shallowArrayCopy(uniqueItems),
        templateRef = record and record.inventoryTemplateRef or nil,
    }
end

local function addAppearanceItems(record, base, template)
    local appearanceItems = template.appearance and template.appearance.outfitItems or {}
    local appearanceSpecs = template.appearance
        and template.appearance.outfitItemSpecs or nil
    local lookCounts = {}
    local templateKey
    local i
    local item

    for i = 1, math.max(#appearanceItems, #(appearanceSpecs or {})) do
        local appearanceSpec = appearanceSpecs and appearanceSpecs[i] or nil
        local appearanceType = type(appearanceSpec) == "table"
            and appearanceSpec.type or appearanceItems[i]
        if not appearanceType then
            break
        end
        lookCounts[tostring(appearanceType)] = (lookCounts[tostring(appearanceType)] or 0) + 1
        templateKey = "tmpl:look:" .. tostring(appearanceType) .. ":"
            .. tostring(lookCounts[tostring(appearanceType)])
        item = Internal.createItem(record, base, {
            type = appearanceType,
            container = "root",
            templateKey = templateKey,
            legacyTemplateKey = "tmpl:look:" .. tostring(i),
            itemState = type(appearanceSpec) == "table"
                and appearanceSpec.itemState or nil,
            wornSlot = type(appearanceSpec) == "table"
                and appearanceSpec.wornSlot or nil,
        })
        if item and PNC.Equipment and PNC.Equipment.CreateItem then
            local created = PNC.Equipment.CreateItem(appearanceType)
            created = type(created) == "table" and created[1] or created
            if created and created.getBodyLocation then
                item.wornSlot = Internal.normalizeString(created:getBodyLocation())
                if item.wornSlot then
                    base.worn[item.wornSlot] = item.id
                end
            end
        end
    end
end

local function addTemplateBag(record, base, template)
    local bagContainerID
    local bagItem
    if template.bagType then
        local bagProfile = Internal.getContainerProfile(template.bagType)
        bagItem = Internal.createItem(record, base, {
            type = template.bagType,
            container = "root",
            wornSlot = bagProfile.wearableSlot,
            wearableSlot = bagProfile.wearableSlot,
            weightReduction = bagProfile.weightReduction,
            templateKey = "tmpl:bag:0",
            maxWeight = bagProfile.capacity,
        })
        if bagItem then
            bagContainerID = bagItem.bagContainer
        end
    end
    return bagContainerID
end

local function addStartingWeapons(record, base, template)
    if template.startingEquipment.primaryWeapon
        and template.startingEquipment.primaryWeapon.type
    then
        Internal.createItem(record, base, {
            type = template.startingEquipment.primaryWeapon.type,
            cond = template.startingEquipment.primaryWeapon.cond,
            container = "root",
            equipSlot = "primary",
            templateKey = "tmpl:weapon:0",
        })
    end

    if template.startingEquipment.reserveWeapon
        and template.startingEquipment.reserveWeapon.type
    then
        Internal.createItem(record, base, {
            type = template.startingEquipment.reserveWeapon.type,
            cond = template.startingEquipment.reserveWeapon.cond,
            container = "root",
            templateKey = "tmpl:weapon:reserve",
        })
    end
end

function Internal.buildTemplateSnapshot(record, options)
    local base = Internal.createBaseInventory(record, options)
    local template = buildIdentityTemplate(record)
    local bagContainerID

    Internal.ensureIdentityCard(record, base)
    addAppearanceItems(record, base, template)
    bagContainerID = addTemplateBag(record, base, template)
    addStartingWeapons(record, base, template)
    SupplyBuilder.Add(record, base, template, bagContainerID)

    base.template.equipmentPoolID = template.startingEquipment.poolID
    base.template.weaponMode = template.startingEquipment.weaponMode
    base.template.templateRef = template.templateRef
    Internal.calculateWeights(base)
    return base
end

function Inventory.CreateFromTemplate(record, options)
    local inv
    local runtime
    local generatedTemplate
    if not record then
        return nil
    end
    inv = Internal.buildTemplateSnapshot(record, options)
    generatedTemplate = inv.template or {}
    inv.template = {
        archetypeID = record.archetypeID,
        seed = record.identitySeed,
        generatorVersion = PNC.Const and PNC.Const.GENERATOR_VERSION or 1,
        createdAtHours = generatedTemplate.createdAtHours,
        equipmentPoolID = generatedTemplate.equipmentPoolID,
        weaponMode = generatedTemplate.weaponMode,
        templateRef = generatedTemplate.templateRef,
    }
    record.inventory = inv
    runtime = Internal.getRuntimeState(record)
    record.weaponMode = inv.template.weaponMode or record.weaponMode or "melee"
    record.runtime.spawnEquipmentPool = inv.template.equipmentPoolID
    record.runtime.spawnWeaponMode = inv.template.weaponMode
    if options and options.keepRevision then
        inv.revision = tonumber(options.keepRevision) or inv.revision
    else
        inv.revision = 0
    end
    runtime.opLog = {}
    inv.persistenceMode = "SEED_ONLY"
    Internal.refreshNextItemSerial(record, inv)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if (not options or options.reconcileWaterContainer ~= false)
        and Inventory.ReconcileWaterContainer
    then
        Inventory.ReconcileWaterContainer(record)
    end
    return record.inventory
end
