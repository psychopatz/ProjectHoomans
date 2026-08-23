local Inventory = PNC.Inventory
local Internal = Inventory.Internal

function Inventory.SetFavorite(record, itemID, favorite, reason)
    local inv = Inventory.EnsureRecordInventory(record)
    local item
    local applied
    itemID = Internal.normalizeString(itemID)
    item = itemID and inv and inv.items and inv.items[itemID] or nil
    if not item then return false, "item_not_found" end
    favorite = favorite == true
    if item.fav == favorite then return true, "unchanged" end
    applied = Inventory.ApplyDelta(record, {
        {
            op = "update",
            itemID = item.id,
            fav = favorite,
        },
    }, reason or (favorite
        and "inventory_favorite"
        or "inventory_unfavorite"))
    if not applied then return false, "favorite_failed" end
    return true, favorite and "favorited" or "unfavorited"
end

function Inventory.SetInteractionLocked(
    record,
    itemID,
    locked,
    lockReason,
    mutationReason
)
    local inv = Inventory.EnsureRecordInventory(record)
    local item
    local applied
    itemID = Internal.normalizeString(itemID)
    item = itemID and inv and inv.items and inv.items[itemID] or nil
    if not item then return false, "item_not_found" end
    locked = locked == true
    lockReason = locked and Internal.normalizeString(lockReason) or nil
    if item.interactionLocked == locked
        and item.interactionLockReason == lockReason
    then
        return true, "unchanged"
    end
    applied = Inventory.ApplyDelta(record, {
        {
            op = "update",
            itemID = item.id,
            interactionLocked = locked,
            interactionLockReason = lockReason,
        },
    }, mutationReason or (locked
        and "inventory_interaction_lock"
        or "inventory_interaction_unlock"))
    if not applied then return false, "interaction_lock_failed" end
    return true, locked and "interaction_locked" or "interaction_unlocked"
end

return Inventory
