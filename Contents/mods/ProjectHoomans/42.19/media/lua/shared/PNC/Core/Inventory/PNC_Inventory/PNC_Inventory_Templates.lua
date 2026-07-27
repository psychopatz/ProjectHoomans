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
    }
end

local function createSupplyItems(record, base, supplies, prefix, bagContainerID, archetypeID)
    local counts = {}
    local supply
    local templateKey
    local i
    for i = 1, #(supplies or {}) do
        supply = supplies[i]
        templateKey = Internal.normalizeString(supply.key)
        if not templateKey then
            counts[tostring(supply.type)] = (counts[tostring(supply.type)] or 0) + 1
            templateKey = tostring(supply.type) .. ":" .. tostring(counts[tostring(supply.type)])
            if Core.LogWarn then
                Core.LogWarn("PNC spawn supply missing stable key archetype="
                    .. tostring(archetypeID) .. " type=" .. tostring(supply.type))
            end
        end
        Internal.createItem(record, base, {
            type = supply.type,
            stack = supply.stack,
            uses = supply.uses,
            cond = supply.cond,
            container = (supply.preferredContainer == "bag" and bagContainerID)
                and bagContainerID
                or "root",
            preferredContainer = supply.preferredContainer,
            templateKey = tostring(prefix) .. tostring(templateKey),
            legacyTemplateKey = prefix == "tmpl:supply:"
                and "tmpl:supply:" .. tostring(i)
                or nil,
        })
    end
end

function Internal.buildTemplateSnapshot(record)
    local base = Internal.createBaseInventory(record)
    local template = buildIdentityTemplate(record)
    local appearanceItems = template.appearance and template.appearance.outfitItems or {}
    local lookCounts = {}
    local bagContainerID
    local bagItem
    local templateKey
    local item
    local i

    Internal.ensureIdentityCard(record, base)

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

    createSupplyItems(
        record,
        base,
        template.startingEquipment.primaryWeapon
            and template.startingEquipment.primaryWeapon.grants
            or {},
        "tmpl:equipment_grant:primary:",
        bagContainerID,
        template.archetypeID
    )
    createSupplyItems(
        record,
        base,
        template.startingEquipment.reserveWeapon
            and template.startingEquipment.reserveWeapon.grants
            or {},
        "tmpl:equipment_grant:reserve:",
        bagContainerID,
        template.archetypeID
    )
    createSupplyItems(
        record,
        base,
        template.supplies,
        "tmpl:supply:",
        bagContainerID,
        template.archetypeID
    )

    base.template.equipmentPoolID = template.startingEquipment.poolID
    base.template.weaponMode = template.startingEquipment.weaponMode
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
    inv = Internal.buildTemplateSnapshot(record)
    inv.deltaMode = "template_plus_delta"
    generatedTemplate = inv.template or {}
    inv.template = {
        archetypeID = record.archetypeID,
        seed = record.identitySeed,
        generatorVersion = PNC.Const and PNC.Const.GENERATOR_VERSION or 1,
        equipmentPoolID = generatedTemplate.equipmentPoolID,
        weaponMode = generatedTemplate.weaponMode,
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
    Internal.refreshNextItemSerial(record, inv)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    return record.inventory
end
