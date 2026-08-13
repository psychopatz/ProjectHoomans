if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local Definitions = Internal.Definitions
local Repository = Internal.Repository
local CoreInventory = Internal.CoreInventory
local C = Internal.Constants
local Query = require "PNC/Core/Colony/Storage/PNC_ColonyStorageQuery"

function Service.DebugUpgrade(player, args)
    local function finish(ok, reason, storage)
        Internal.LogTransaction(player, args, "storage_upgrade", ok, reason, storage)
        return ok, reason, storage
    end
    if not Internal.DebugAllowed(player) then return finish(false, "debug_required") end
    local storage, reason = Service.ResolveForPlayer(player, args and args.storageId)
    if not storage then return finish(false, reason) end
    local nextTier = Definitions.GetNextTier(storage.tier)
    if not nextTier then return finish(false, "maximum_tier", storage) end
    storage.tier = nextTier
    Internal.CommitStorage(storage)
    return finish(true, "upgraded", storage)
end

function Service.DebugAction(player, args)
    local action = tostring(args and args.debugAction or "")
    local function finish(ok, reason, storage, details)
        Internal.LogTransaction(player, args, "debug_" .. action, ok, reason, storage)
        return ok, reason, storage, details
    end
    if not Internal.DebugAllowed(player) then return finish(false, "debug_required") end
    local storage, reason = Service.ResolveForPlayer(player, args and args.storageId)
    if not storage then return finish(false, reason) end
    local changed = false
    local details = {}
    if action == "clear" then
        changed, reason = storage.inventory:clear()
    elseif action == "compact" then
        details.recordCount = storage.inventory:compact()
        Service.Metrics.compactions = Service.Metrics.compactions + 1
        changed, reason = true, "compacted"
    elseif action == "recalculate" then
        details.usedWeight = storage.inventory:recalculateWeight()
        changed, reason = true, "recalculated"
    elseif action == "validate" then
        local report
        changed, report = storage.inventory:validate()
        reason, details.validation = changed and "valid" or "invalid", report
        if not changed then
            Service.Metrics.validationFailures =
                Service.Metrics.validationFailures + 1
        end
        return finish(changed, reason, storage, details)
    elseif action == "remove" then
        local record = storage.inventory.records[tonumber(args.recordIndex) or 0]
        if not record then return finish(false, "record_not_found", storage) end
        changed, reason = storage.inventory:remove({ predicate = function(candidate)
            return candidate == record
        end }, math.max(1, math.floor(tonumber(args.quantity)
            or record[C.QUANTITY] or 1)), { includeReserved = true })
        if changed then
            Service.Metrics.withdrawals = Service.Metrics.withdrawals + 1
        end
    elseif action == "add" or action == "fill" then
        local fullType = action == "fill" and "Base.Nails"
            or tostring(args.fullType or "Base.Nails")
        local quantity = action == "fill" and 1000
            or math.max(1, math.floor(tonumber(args.quantity) or 1))
        local item = PNC.Equipment and PNC.Equipment.CreateItem
            and PNC.Equipment.CreateItem(fullType) or nil
        item = type(item) == "table" and not item.getFullType and item[1] or item
        if not item then return finish(false, "item_type_unknown", storage) end
        changed, reason = CoreInventory.deposit(storage.inventory, item, quantity)
    else
        return finish(false, "unknown_debug_action", storage)
    end
    if changed then Internal.CommitStorage(storage) end
    return finish(changed == true, reason or "ok", storage, details)
end

function Service.BuildSnapshot(player, options)
    local storage, reason = Service.ResolveForPlayer(
        player, options and options.storageId
    )
    if not storage then return nil, reason end
    local snapshot = Query.BuildSnapshot(storage, options)
    snapshot.debugAuthorized = Internal.DebugAllowed(player)
    snapshot.metrics = {
        storageDeposits = Service.Metrics.deposits,
        storageWithdrawals = Service.Metrics.withdrawals,
        storageTransferFailures = Service.Metrics.transferFailures,
        storageCapacityRejects = Service.Metrics.capacityRejects,
        storageCompactions = Service.Metrics.compactions,
        storageValidationFailures = Service.Metrics.validationFailures,
    }
    return snapshot
end

return Service
