-- Builds authored supply and grant items during deterministic templates.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Core = PNC.Core
local Builder = {}

local function resolveTemplateKey(source, prefix, fallbackKey, counts, archetypeID)
    source = type(source) == "table" and source or {}
    local explicitKey = Internal.normalizeString(
        source.key or source.templateKey
    )
    local repaired = false
    local sourceType
    local baseKey
    local fullKey

    if explicitKey then
        baseKey = explicitKey
    else
        repaired = true
        if fallbackKey ~= nil then
            baseKey = tostring(fallbackKey)
        else
            sourceType = Internal.normalizeString(
                source.type or source.fullType
            ) or "unknown"
            counts = counts or {}
            counts[sourceType] = (counts[sourceType] or 0) + 1
            baseKey = sourceType .. ":" .. tostring(counts[sourceType])
        end
    end

    fullKey = tostring(prefix or "") .. tostring(baseKey)
    if repaired and Core and Core.LogDebug then
        Core.LogDebug("PNC template supply stable key repaired archetype="
            .. tostring(archetypeID) .. " source=" .. tostring(prefix)
            .. " type=" .. tostring(source.type or source.fullType)
            .. " key=" .. fullKey)
    end
    return fullKey
end

-- One template-key contract is shared by archetype supplies and canonical
-- starting items. Runtime/world items may remain keyless; only deterministic
-- template construction comes through this resolver.
function Builder.ResolveTemplateKey(source, prefix, fallbackKey, counts, archetypeID)
    return resolveTemplateKey(source, prefix, fallbackKey, counts, archetypeID)
end

local function createSupplyItems(record, base, supplies, prefix, bagContainerID, archetypeID)
    local counts = {}
    local supply
    local templateKey
    local i
    for i = 1, #(supplies or {}) do
        supply = type(supplies[i]) == "table" and supplies[i] or {}
        templateKey = Builder.ResolveTemplateKey(
            supply, prefix, nil, counts, archetypeID
        )
        local created = Internal.createItem(record, base, {
            type = supply.type,
            stack = supply.stack,
            uses = supply.uses,
            cond = supply.cond,
            ammoCount = supply.ammoCount,
            fav = supply.fav,
            customName = supply.customName,
            itemState = supply.itemState,
            maxWeight = supply.maxWeight,
            weightReduction = supply.weightReduction,
            wearableSlot = supply.wearableSlot,
            wornSlot = supply.wornSlot,
            attachedSlot = supply.attachedSlot,
            equipSlot = supply.equipSlot,
            container = (supply.preferredContainer == "bag" and bagContainerID)
                and bagContainerID
                or "root",
            preferredContainer = supply.preferredContainer,
            templateKey = templateKey,
            legacyTemplateKey = prefix == "tmpl:supply:"
                and "tmpl:supply:" .. tostring(i)
                or nil,
        })
        -- A custom editor bag is part of the same authored item list. Make it
        -- the active destination for following `preferredContainer = "bag"`
        -- entries, like the archetype bag above.
        if created and created.bagContainer then
            bagContainerID = created.bagContainer
        end
    end
end

function Builder.Add(record, base, template, bagContainerID)
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
        template.uniqueItems,
        "tmpl:unique:",
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
end

return Builder
