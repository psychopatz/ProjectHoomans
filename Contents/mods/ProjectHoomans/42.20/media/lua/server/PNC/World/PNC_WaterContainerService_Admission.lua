if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.WaterContainerService
if not Service then return end
local Internal = Service.Internal or {}
local Inventory = Internal.Inventory
local SupplyInternal = Internal.SupplyInternal
local EPSILON = Internal.EPSILON
local logRefillAdmission = Internal.logRefillAdmission
local liveBody = Internal.liveBody

function Service.FindContainer(record, itemID)
    local inv = record and Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local item = inv and inv.items and inv.items[tostring(itemID or "")]
    if not item and inv then item = Inventory.GetWaterContainer(record) end
    -- Keep full liquid containers in the transaction path so the caller gets
    -- the precise WATER_CONTAINER_FULL reason instead of the broader
    -- not-refillable result.
    if not item or not Inventory.IsLiquidContainer(item) then
        return nil, "WATER_CONTAINER_NOT_REFILLABLE"
    end
    local description = Inventory.DescribeLiquidContainer(item)
    if not description then
        return nil, "WATER_CONTAINER_NOT_REFILLABLE"
    end
    return item, description
end

-- Read the destination state from the live body before a refill scene is
-- started.  The compact item can lag behind the native projection when a
-- previous refill, inventory packet, or vanilla action changed the bottle.
-- Keeping this check separate from Refill makes scene admission read-only;
-- Refill remains the transaction boundary that commits the mutation.
function Service.CanRefill(record, itemID)
    local item
    local compactDescription
    local body
    local selected
    local native
    local description
    local function result(accepted, reason)
        logRefillAdmission(
            record,
            item,
            itemID,
            compactDescription,
            native,
            description,
            selected and #selected or 0,
            accepted,
            reason
        )
        return accepted, reason
    end
    item, compactDescription = Service.FindContainer(record, itemID)
    if not item then return result(false, compactDescription) end
    body = liveBody(record)
    if not body then return result(false, "NPC_BODY_UNAVAILABLE") end
    selected = SupplyInternal and SupplyInternal.NativeCandidates
        and SupplyInternal.NativeCandidates(body, item) or {}
    native = selected[1] and selected[1].item or nil
    if not native then
        return result(false, "WATER_CONTAINER_PHYSICAL_MISSING")
    end
    description = Inventory.DescribeLiquidContainer(item, native)
    if not description then
        return result(false, "WATER_CONTAINER_NOT_REFILLABLE")
    end
    if (tonumber(description.freeCapacity) or 0) <= EPSILON then
        return result(false, "WATER_CONTAINER_FULL")
    end
    if description.canFill ~= true then
        return result(false, "WATER_CONTAINER_NOT_REFILLABLE")
    end
    return result(true, "WATER_CONTAINER_REFILLABLE")
end


return Service
