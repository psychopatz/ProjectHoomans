-- Builds authored supply and grant items during deterministic templates.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Core = PNC.Core
local Builder = {}

local function createSupplyItems(record, base, supplies, prefix, bagContainerID, archetypeID)
    local counts = {}
    local supply
    local templateKey
    local i
    for i = 1, #(supplies or {}) do
        supply = supplies[i]
        templateKey = Internal.normalizeString(supply.key or supply.templateKey)
        if not templateKey then
            counts[tostring(supply.type)] = (counts[tostring(supply.type)] or 0) + 1
            templateKey = tostring(supply.type) .. ":" .. tostring(counts[tostring(supply.type)])
            if Core.LogWarn then
                Core.LogWarn("PNC spawn supply missing stable key archetype="
                    .. tostring(archetypeID) .. " type=" .. tostring(supply.type))
            end
        end
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
            templateKey = tostring(prefix) .. tostring(templateKey),
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
