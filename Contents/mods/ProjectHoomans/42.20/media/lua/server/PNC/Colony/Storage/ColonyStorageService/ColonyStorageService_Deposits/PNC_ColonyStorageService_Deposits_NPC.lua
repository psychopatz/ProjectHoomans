if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal

function Service.RequestNPCDeposit(player, args)
    args = type(args) == "table" and args or {}
    local function finish(ok, reason, details, storage, record)
        Internal.LogTransaction(player, args, "npc_deposit", ok, reason,
            storage, details)
        return ok, reason, details, storage, record
    end
    if not Internal.RememberRequest(player, args.requestId) then
        return finish(false, "duplicate_request")
    end
    local storage, reason = Service.ResolveForPlayer(player, args.storageId)
    if not storage then return finish(false, reason) end
    local record = args.npcId and PNC.Registry.Get(tostring(args.npcId)) or nil
    if not record then return finish(false, "npc_not_found", nil, storage) end
    local ownsNPC = PNC.CompanionCommands
        and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player) == true
    if not ownsNPC and not Internal.DebugAllowed(player) then
        return finish(false, "npc_not_owned", nil, storage, record)
    end
    local inv = PNC.Inventory.EnsureRecordInventory(record)
    if tonumber(args.inventoryRevision) ~= tonumber(inv.revision) then
        return finish(false, "revision_conflict", nil, storage, record)
    end
    local item = inv.items[tostring(args.itemID or "")]
    if not item then return finish(false, "item_not_found", nil, storage, record) end
    if Internal.IsNPCDepositForbiddenItem(item) then
        return finish(false, "item_off_limits", nil, storage, record)
    end
    if item.equipSlot or item.wornSlot or item.attachedSlot then
        return finish(false, "equipped_item", nil, storage, record)
    end
    local quantity = math.max(1, math.min(
        math.floor(tonumber(args.quantity) or 1),
        math.floor(tonumber(item.stack) or 1)
    ))
    local body = PNC.Registry.GetLiveZombie(record.id)
    local source
    if body then
        source, reason = Internal.LiveNPCSource(record, item, quantity, body)
    else
        source = Internal.AbstractNPCSource(record, item, quantity)
    end
    if not source then return finish(false, reason, nil, storage, record) end
    local ok, why, details = Internal.TransferIntoStorage(
        storage, source, quantity
    )
    if not ok then
        Service.Metrics.transferFailures = Service.Metrics.transferFailures + 1
    else
        Internal.RecordActivity(storage, "STORE",
            tostring(record.name or record.id), {{
                fullType = item.type,
                quantity = quantity,
            }}, args.reason)
    end
    return finish(ok, why, details, storage, record)
end

return Service
