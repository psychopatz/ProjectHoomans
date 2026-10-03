-- Command hub client eligibility and material gate policy.
--
-- This provider owns the public Gates contract. Registry category wiring
-- consumes it through the original PNC.CommandHub.Gates table.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.Gates = PNC.CommandHub.Gates or {}

local Gates = PNC.CommandHub.Gates
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

local function hasRadio()
    local journalButton = PNC.ColonyJournalButton
    return journalButton
        and type(journalButton.HasRadio) == "function"
        and journalButton.HasRadio() == true or false
end

local function colonyManagementSnapshot()
    local client = PNC.ColonyManagementClient
    if client and type(client.ReadSnapshot) == "function" then
        local update = client.ReadSnapshot()
        if type(update) == "table" then
            return update.snapshot or {}
        end
    end

    local network = PNC.Network
    local state = network and network.ClientState or nil
    return state and state.colonyManagement or {}
end

local function baseSnapshot()
    local client = PNC.ColonyManagementClient
    if client and type(client.ReadBaseSnapshot) == "function" then
        local update = client.ReadBaseSnapshot()
        if type(update) == "table" then return update.snapshot or {} end
    end
    return colonyManagementSnapshot()
end

function Gates.HasRadio()
    return hasRadio()
end

--[[
    (exists, built, inProgress)

    `built` drives storage/work gating. `inProgress` matters for the bootstrap
    button: hiding "build stockpile" merely because a stockpile *record* exists
    left a planned-but-idle stockpile with no rebuild path anywhere in the UI
    (the FACILITIES tab never lists the stockpile), which is a soft-lock.
]]
local function stockpileStatus(settlement)
    local exists, built, inProgress = false, false, false
    for _, facility in ipairs(settlement.facilities or {}) do
        if tostring(facility.definitionId or "") == "stockpile" then
            exists = true
            built = FacilityState.IsBuilt(facility)
            -- Older stubs and partially loaded contexts may not expose the
            -- shared state helper; never let the gate throw.
            local state = type(FacilityState.ConstructionState) == "function"
                and FacilityState.ConstructionState(facility) or nil
            inProgress = state == "RECONSTRUCTING"
                or state == "UNDER_CONSTRUCTION"
            break
        end
    end
    return exists, built, inProgress
end

local function costTypes(cost)
    local types = cost and (cost.itemTypes or cost.types or cost.items)
    if type(types) == "table" then return types end
    if type(types) == "string" then return { types } end
    if cost and (cost.fullType or cost.itemType or cost.type) then
        return { cost.fullType or cost.itemType or cost.type }
    end
    return {}
end

local function playerItemCount(types)
    local player = type(getSpecificPlayer) == "function"
        and getSpecificPlayer(0) or nil
    local inventory = player and type(player.getInventory) == "function"
        and player:getInventory() or nil
    if not inventory or type(inventory.getItemsFromType) ~= "function" then
        return 0
    end
    local available = 0
    for _, fullType in ipairs(types or {}) do
        local items = inventory:getItemsFromType(fullType, true)
        local count = 0
        if items then
            if type(items.size) == "function" then
                count = items:size()
            elseif type(items.size) == "number" then
                count = items.size
            elseif type(items) == "table" then
                count = #items
            end
        end
        available = math.max(available, math.floor(tonumber(count) or 0))
    end
    return available
end

function Gates.GetStockpileMaterialStatus()
    local definitions = PNC.FacilityDefinitions
    local definition = definitions and type(definitions.Get) == "function"
        and definitions.Get("stockpile") or nil
    local costs = definition and (definition.buildCosts
        or definition.buildCost) or nil
    if type(costs) ~= "table" then
        return { affordable = false, reason = "MATERIAL_DEFINITION_UNAVAILABLE" }
    end
    if costs.fullType or costs.itemType or costs.type then costs = { costs } end
    for _, cost in ipairs(costs) do
        local required = math.max(0, math.floor(tonumber(
            cost.amount or cost.quantity) or 0))
        if required > 0 then
            local types = costTypes(cost)
            local available = playerItemCount(types)
            if available < required then
                return {
                    affordable = false,
                    available = available,
                    required = required,
                    fullType = types[1],
                }
            end
        end
    end
    return { affordable = true }
end

function Gates.GetBaseAndStockpileStatus()
    local snapshot = baseSnapshot()
    local settlement = type(snapshot) == "table" and snapshot.settlement or nil
    local hasBase = type(settlement) == "table"
    local stockpileExists, hasStockpile, stockpileInProgress = false, false, false
    if hasBase then
        stockpileExists, hasStockpile, stockpileInProgress =
            stockpileStatus(settlement)
    end
    return {
        hasBase = hasBase,
        hasStockpile = hasStockpile,
        -- "A stockpile is already handled" - built or actively being worked on.
        -- A planned-and-idle stockpile must not hide its own build button.
        hasStockpileFacility = stockpileExists
            and (hasStockpile or stockpileInProgress),
        stockpileRecordExists = stockpileExists,
        enabled = hasBase and hasStockpile,
    }
end

function Gates.HasBase()
    return Gates.GetBaseAndStockpileStatus().hasBase == true
end

function Gates.BaseZoneDisabledTooltip()
    if Gates.HasBase() then return nil end
    return {
        key = "UI_PNC_CommandHub_Disabled_NoBase",
        fallback = "Requires a colony base.",
    }
end

function Gates.HasBaseAndStockpile()
    return Gates.GetBaseAndStockpileStatus().enabled
end

function Gates.HasColony()
    local state = PNC.Network and PNC.Network.ClientState or nil
    if state and state.colonyManagement == nil and state.colonyBase == nil then
        return false
    end
    local snapshot = baseSnapshot()
    local colony = type(snapshot) == "table" and snapshot.colony or nil
    return type(colony) == "table" and tostring(colony.id or "") ~= ""
end

function Gates.BaseDisabledTooltip()
    if Gates.HasColony() then return nil end
    return {
        key = "UI_PNC_CommandHub_Disabled_NoColony",
        fallback = "Requires colony data before the base can be opened.",
    }
end

function Gates.BaseAndStockpileDisabledTooltip()
    local status = Gates.GetBaseAndStockpileStatus()
    if status.enabled then return nil end
    if not status.hasBase and not status.hasStockpile then
        return {
            key = "UI_PNC_CommandHub_Disabled_NoBaseOrStockpile",
            fallback = "Requires a colony base and a completed stockpile.",
        }
    end
    if not status.hasBase then
        return {
            key = "UI_PNC_CommandHub_Disabled_NoBase",
            fallback = "Requires a colony base.",
        }
    end
    return {
        key = "UI_PNC_CommandHub_Disabled_NoStockpile",
        fallback = "Requires a completed stockpile in your colony base.",
    }
end


return Gates
