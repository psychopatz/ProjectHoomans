if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PsychopatzCore/Economy/PsychopatzCurrencyServer"

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Const = PNC.Const
local Registry = PNC.Registry
local Inventory = PNC.Inventory
local ItemTransfer = Internal.ItemTransfer
local Currency = PsychopatzCore and PsychopatzCore.Currency

local MAX_CURRENCY = tonumber(Const.INVENTORY_CURRENCY_MAX_AMOUNT) or 1000000

local function rollbackProjections(projections)
    for index = #(projections or {}), 1, -1 do
        local undo = projections[index]
        if type(undo) == "function" then pcall(undo) end
    end
end

local function nativeContainerFor(player, containerID)
    local inventory = player and player.getInventory
        and player:getInventory() or nil
    containerID = tostring(containerID or "root")
    if not inventory then return nil, "inventory_unavailable" end
    if containerID == "" or containerID == "root" then return inventory end
    local item = ItemTransfer and ItemTransfer.FindByIDRecursive
        and ItemTransfer.FindByIDRecursive(inventory, containerID) or nil
    if not item then return nil, "source_container_not_found" end
    local container = item.getItemContainer and item:getItemContainer()
        or item.getInventory and item:getInventory() or nil
    if not container then return nil, "source_container_not_found" end
    return container
end

local function currencySpecs(amount)
    if type(Currency.CanonicalSpecs) == "function" then
        return Currency.CanonicalSpecs(amount)
    end
    local bundles, loose = Currency.NormalizeUnits(amount)
    local specs = {}
    if bundles > 0 then
        specs[#specs + 1] = { type = Currency.BUNDLE_TYPE, stack = bundles }
    end
    if loose > 0 then
        specs[#specs + 1] = { type = Currency.MONEY_TYPE, stack = loose }
    end
    return specs, bundles, loose
end

local function projectCurrency(record, compactIDs, projections)
    local body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    if not body then return true end
    if not Inventory.MaterializeItem then
        return false, "live_inventory_projection_unavailable"
    end
    for index = 1, #compactIDs do
        local projected, reason, undo = Inventory.MaterializeItem(
            record, body, compactIDs[index])
        if not projected then return false, reason end
        projections[#projections + 1] = undo
    end
    return true
end

local function validAmount(value)
    local amount = math.floor(tonumber(value) or 0)
    if amount < 1 or amount > MAX_CURRENCY then return nil end
    return amount
end

local function transferPlayerToNPCCurrency(player, record, args, sinceRevision)
    local amount = validAmount(args.currencyAmount)
    if not amount then return false, "invalid_currency_amount" end
    if args.gift == true then return false, "currency_gift_invalid" end
    if type(args.itemIDs) == "table" and #args.itemIDs > 0 then
        return false, "currency_mixed_transfer_unsupported"
    end
    if args.currencyFullType ~= nil
        and not Currency.IsType(args.currencyFullType)
    then
        return false, "currency_type_invalid"
    end
    if not Currency or type(Currency.RemoveUnits) ~= "function" then
        return false, "currency_service_unavailable"
    end

    local source, sourceReason = nativeContainerFor(
        player, args.playerContainer)
    if not source then return false, sourceReason end
    local removed, removeReason, removedDetails = Currency.RemoveUnits(
        source, amount, {
            recursive = false,
            fullType = args.currencyFullType,
        })
    if not removed then return false, removeReason end

    local specs, bundles, loose = currencySpecs(amount)
    local added, addReason, compactIDs = Inventory.AddItems(
        record,
        specs,
        args.npcContainer or "root",
        "player_currency_to_npc"
    )
    if not added then
        if removedDetails and removedDetails.restore then
            removedDetails.restore()
        end
        return false, addReason
    end

    local projections = {}
    local projected, projectionReason = projectCurrency(
        record, compactIDs, projections)
    if not projected then
        rollbackProjections(projections)
        Inventory.RemoveItems(record, compactIDs,
            "player_currency_to_npc_rollback")
        if removedDetails and removedDetails.restore then
            removedDetails.restore()
        end
        return false, projectionReason
    end

    Internal.refreshLiveEquipment(record)
    Internal.syncResult(player, record, sinceRevision)
    return true, "transferred_currency_to_npc", {
        currencyAmount = amount,
        currencyBundles = bundles,
        currencyLoose = loose,
        itemTypes = { Currency.BUNDLE_TYPE, Currency.MONEY_TYPE },
        itemIDs = compactIDs,
        itemCount = amount,
    }
end

local function compactCurrencyEntries(inv, containerID)
    local container = inv and inv.containers
        and inv.containers[containerID or "root"] or nil
    local output = {}
    for _, itemID in ipairs(container and container.items or {}) do
        local item = inv.items and inv.items[itemID] or nil
        if item and Currency.IsType(item.type) then
            output[#output + 1] = item
        end
    end
    return output
end

local function addCompactConsumeOps(ops, item, quantity)
    local available = math.max(1, math.floor(tonumber(item.stack) or 1))
    if quantity >= available then
        ops[#ops + 1] = { op = "remove", itemID = item.id }
    else
        ops[#ops + 1] = {
            op = "update", itemID = item.id, stack = available - quantity,
        }
    end
end

local function buildCompactRemoval(inv, containerID, amount, exactType)
    local entries = compactCurrencyEntries(inv, containerID)
    local loose = {}
    local bundles = {}
    local total = 0
    for index = 1, #entries do
        local item = entries[index]
        local quantity = math.max(1, math.floor(tonumber(item.stack) or 1))
        total = total + Currency.ValueFor(item.type, quantity)
        if item.type == Currency.MONEY_TYPE then
            loose[#loose + 1] = { item = item, quantity = quantity }
        else
            bundles[#bundles + 1] = { item = item, quantity = quantity }
        end
    end
    if total < amount then return nil, "insufficient_currency" end

    if exactType ~= nil then
        local unitValue = Currency.UnitValue(exactType)
        if unitValue < 1 or amount % unitValue ~= 0 then
            return nil, "currency_quantity_invalid"
        end
        local remaining = math.floor(amount / unitValue)
        local ops = {}
        for index = #entries, 1, -1 do
            if remaining < 1 then break end
            local item = entries[index]
            if item.type == exactType then
                local available = math.max(
                    1, math.floor(tonumber(item.stack) or 1))
                local take = math.min(available, remaining)
                addCompactConsumeOps(ops, item, take)
                remaining = remaining - take
            end
        end
        if remaining > 0 then return nil, "insufficient_currency" end
        return ops
    end

    local ops = {}
    local consumed = {}
    local remaining = amount
    local function consume(list, unitValue, wholeOnly)
        for index = #list, 1, -1 do
            if remaining < 1 then break end
            local entry = list[index]
            local take = math.min(entry.quantity,
                wholeOnly and math.floor(remaining / unitValue) or remaining)
            if take > 0 then
                local itemID = tostring(entry.item.id)
                consumed[itemID] = (consumed[itemID] or 0) + take
                remaining = remaining - take * unitValue
            end
        end
    end
    consume(loose, 1, false)
    consume(bundles, Currency.BUNDLE_VALUE, true)

    if remaining > 0 then
        local entry
        for index = #bundles, 1, -1 do
            local candidate = bundles[index]
            local used = consumed[tostring(candidate.item.id)] or 0
            if candidate.quantity > used then
                entry = candidate
                break
            end
        end
        if not entry then return nil, "insufficient_currency" end
        local itemID = tostring(entry.item.id)
        consumed[itemID] = (consumed[itemID] or 0) + 1
    end

    for index = 1, #entries do
        local item = entries[index]
        local take = consumed[tostring(item.id)] or 0
        if take > 0 then addCompactConsumeOps(ops, item, take) end
    end

    if remaining > 0 then
        ops[#ops + 1] = {
            op = "add",
            item = {
                type = Currency.MONEY_TYPE,
                stack = Currency.BUNDLE_VALUE - remaining,
                container = containerID or "root",
            },
        }
        remaining = 0
    end
    if remaining > 0 then return nil, "insufficient_currency" end
    return ops
end

local function transferNPCToPlayerCurrency(player, record, args, sinceRevision)
    local amount = validAmount(args.currencyAmount)
    if not amount then return false, "invalid_currency_amount" end
    if type(args.itemIDs) == "table" and #args.itemIDs > 0 then
        return false, "currency_mixed_transfer_unsupported"
    end
    if args.currencyFullType ~= nil
        and not Currency.IsType(args.currencyFullType)
    then
        return false, "currency_type_invalid"
    end
    if not Currency then return false, "currency_service_unavailable" end
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local containerID = args.npcContainer or "root"
    local ops, buildReason = buildCompactRemoval(
        inv, containerID, amount, args.currencyFullType)
    if not ops then return false, buildReason end

    local before = PNC.Core and PNC.Core.DeepCopy
        and PNC.Core.DeepCopy(record.inventory) or nil
    local mutated, mutateReason = Inventory.ApplyDelta(
        record, ops, "npc_currency_to_player")
    if not mutated then return false, mutateReason or "remove_failed" end

    local destination = player and player.getInventory
        and player:getInventory() or nil
    local added, addReason = Currency.AddUnits(destination, amount)
    if not added then
        if before then
            record.inventory = before
            Inventory.RebuildCaches(record)
        end
        return false, addReason or "physical_add_failed"
    end
    Internal.refreshLiveEquipment(record)
    Internal.syncResult(player, record, sinceRevision)
    return true, "transferred_currency_to_player", {
        currencyAmount = amount,
        itemCount = amount,
    }
end

Internal.transferPlayerToNPCCurrency = transferPlayerToNPCCurrency
Internal.transferNPCToPlayerCurrency = transferNPCToPlayerCurrency

return Service
