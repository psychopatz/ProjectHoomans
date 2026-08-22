if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityCostService = PNC.FacilityCostService or {}

local Costs = PNC.FacilityCostService
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local MaterialTransaction = CoreInventory.MaterialTransaction

local function recipeFor(definition)
    if not definition then return {} end
    return definition.buildCosts or definition.buildCost or {}
end

local function playerSource(player)
    local container = player and player.getInventory and player:getInventory() or nil
    local store = container and CoreInventory.wrapPhysicalInventory(container, {
        recursive = true, maxDepth = 8,
    }) or nil
    if not store then return nil end
    local source = { id = "player", label = "PLAYER", priority = 1,
        store = store }
    function source:onCommitted(receipts)
        if not (isServer and isServer() and sendRemoveItemFromContainer) then
            return
        end
        for _, receipt in ipairs(receipts or {}) do
            if receipt.source == self then
                local removed = receipt.removed or {}
                for index, item in ipairs(removed.physicalItems or {}) do
                    local origin = removed.physicalContainers
                        and removed.physicalContainers[index] or container
                    sendRemoveItemFromContainer(origin, item)
                end
            end
        end
    end
    return source
end

local function stockpileSource(player)
    local service = PNC.ColonyStorageService
    local storage = service and service.ResolveForPlayer
        and service.ResolveForPlayer(player) or nil
    if not storage or not storage.inventory then return nil end
    local source = { id = "stockpile", label = "BASE STOCKPILE", priority = 2,
        store = storage.inventory, storage = storage }
    function source:onCommitted(receipts)
        local specs = {}
        for _, receipt in ipairs(receipts or {}) do
            if receipt.source == self then
                specs[#specs + 1] = { fullType = receipt.fullType,
                    quantity = receipt.quantity }
            end
        end
        if #specs <= 0 then return end
        if service.Internal and service.Internal.CommitStorage then
            service.Internal.CommitStorage(storage)
        end
        if service.Internal and service.Internal.RecordActivity then
            service.Internal.RecordActivity(storage, "TAKE",
                player and player.getUsername and player:getUsername()
                    or "construction", specs, "facility_construction")
        end
    end
    return source
end

function Costs.ResolveSources(player)
    local output = {}
    local physical = playerSource(player)
    local stockpile = stockpileSource(player)
    if physical then output[#output + 1] = physical end
    if stockpile then output[#output + 1] = stockpile end
    return output
end

function Costs.Measure(player, definition)
    local sources = Costs.ResolveSources(player)
    local quote = MaterialTransaction.Quote(recipeFor(definition), sources)
    for _, source in ipairs(sources) do
        if source.storage then quote.storageId = source.storage.id; break end
    end
    return quote
end

function Costs.CanAfford(player, definition)
    local quote = Costs.Measure(player, definition)
    return quote.affordable == true, quote
end

function Costs.Consume(player, definition)
    local ok, reason, quote = MaterialTransaction.Consume(
        recipeFor(definition), Costs.ResolveSources(player))
    quote = quote or { affordable = false }
    quote.reason = reason
    -- Receipts intentionally retain native/virtual objects for rollback and
    -- commit hooks. They must never cross the network or persistence boundary.
    quote.receipts = nil
    return ok, quote
end

function Costs.ConsumePlayer(player, definition)
    local source = playerSource(player)
    if not source then return false, { affordable = false,
        reason = "PLAYER_INVENTORY_UNAVAILABLE" } end
    local ok, reason, quote = MaterialTransaction.Consume(
        recipeFor(definition), { source })
    quote = quote or { affordable = false }
    quote.reason = reason
    quote.receipts = nil
    return ok, quote
end

return Costs
