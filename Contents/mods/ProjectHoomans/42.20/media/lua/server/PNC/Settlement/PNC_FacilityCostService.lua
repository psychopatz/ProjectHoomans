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

local function playerContainer(player)
    return player and player.getInventory and player:getInventory() or nil
end

local function playerStore(player, sync)
    local container = playerContainer(player)
    if not container then return nil end
    return CoreInventory.wrapPhysicalInventory(container, {
        recursive = true, maxDepth = 8, syncOnMutation = sync == true,
    })
end

local function playerSource(player)
    local container = playerContainer(player)
    local store = container and playerStore(player, false) or nil
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
                    pcall(sendRemoveItemFromContainer, origin, item)
                end
            end
        end
    end
    -- Rollback is rare (a funded build that the queue rejects). Restored items
    -- must be pushed to the owning client or the player keeps seeing the
    -- material as spent until the next full inventory resync.
    function source:onRolledBack(receipts)
        if not (isServer and isServer() and sendAddItemToContainer) then
            return
        end
        for _, receipt in ipairs(receipts or {}) do
            if receipt.source == self then
                local removed = receipt.removed or {}
                for index, item in ipairs(removed.physicalItems or {}) do
                    local origin = removed.physicalContainers
                        and removed.physicalContainers[index] or container
                    pcall(sendAddItemToContainer, origin, item)
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

function Costs.ConsumePlayer(player, definition, options)
    local source = playerSource(player)
    if not source then return false, { affordable = false,
        reason = "PLAYER_INVENTORY_UNAVAILABLE" } end
    local ok, reason, quote = MaterialTransaction.Consume(
        recipeFor(definition), { source }, options)
    quote = quote or { affordable = false }
    quote.reason = reason
    -- Receipts intentionally retain native/virtual objects for rollback and
    -- commit hooks. They must never cross the network or persistence boundary.
    -- Callers that must survive a later failure opt in to keeping them.
    if not (options and options.keepReceipts == true) then
        quote.receipts = nil
    end
    return ok, quote
end

-- Undo a consumption that was already reported as committed. Returns true when
-- nothing was consumed or every receipt was restored.
function Costs.Rollback(quote)
    local receipts = quote and quote.receipts or nil
    if type(receipts) ~= "table" or #receipts == 0 then return true end
    return MaterialTransaction.Rollback(receipts)
end

local function createItemFor(fullType)
    if InventoryItemFactory
        and type(InventoryItemFactory.CreateItem) == "function"
    then
        local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok and item then return item end
    end
    if type(instanceItem) == "function" then
        local ok, item = pcall(instanceItem, fullType)
        if ok and item then return item end
    end
    return nil
end

-- Give products back to a player. Used when a player-funded (bootstrap) build
-- is cancelled or rejected, where there is no stockpile to deposit into.
function Costs.RefundPlayer(player, products)
    local store = playerStore(player, true)
    if not store then return false, "PLAYER_INVENTORY_UNAVAILABLE" end
    for _, product in ipairs(products or {}) do
        local fullType = tostring(product.fullType or "")
        local quantity = math.max(1, math.floor(
            tonumber(product.quantity) or 1))
        if fullType ~= "" then
            local item = createItemFor(fullType)
            if not item then return false, "item_type_unavailable" end
            local record = CoreInventory.encodeItem(item, quantity)
            if not record then return false, "item_encode_failed" end
            local added, addReason = store:add(record)
            if not added then return false, addReason or "player_refund_failed" end
        end
    end
    return true
end

-- Resolve the player a refund belongs to. An explicit reference must resolve;
-- never fall back to player 0 for a named refund or the wrong survivor gets
-- the materials.
function Costs.ResolvePlayer(ref)
    ref = type(ref) == "table" and ref or nil
    local onlineID = ref and tonumber(ref.onlineID) or nil
    if onlineID and type(getPlayerByOnlineID) == "function" then
        local player = getPlayerByOnlineID(onlineID)
        if player then return player end
    end
    local username = ref and tostring(ref.username or "") or ""
    if username ~= "" and type(getPlayerByUsername) == "function" then
        local player = getPlayerByUsername(username)
        if player then return player end
    end
    if ref and (onlineID or username ~= "") then
        -- A named refund must land on that survivor. Only accept the single
        -- connected player (single-player or one-survivor session) so a
        -- multiplayer refund never credits the wrong person.
        if isServer and isServer() and type(getOnlinePlayers) == "function" then
            local players = getOnlinePlayers()
            if players and players:size() == 1 then return players:get(0) end
        elseif type(getSpecificPlayer) == "function" then
            local player = getSpecificPlayer(0)
            if player then return player end
        end
        return nil
    end
    return type(getSpecificPlayer) == "function"
        and getSpecificPlayer(0) or nil
end

return Costs
