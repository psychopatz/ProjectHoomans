local Internal = PNC.Combat.Internal

local function buildReloadOps(inv, ammoType, weaponItemID, amount, magazineCount)
    local ops = {}
    local ids = Internal.LooseAmmoEntries(inv, ammoType, weaponItemID)
    local remaining = math.max(0, math.floor(tonumber(amount) or 0))
    local i
    local item
    local stack
    local consumed
    for i = 1, #ids do
        if remaining > 0 then
            item = inv.items[ids[i]]
            stack = math.max(1, math.floor(tonumber(item and item.stack) or 1))
            consumed = math.min(stack, remaining)
            if consumed >= stack then
                ops[#ops + 1] = { op = "remove", itemID = ids[i] }
            else
                ops[#ops + 1] = {
                    op = "update",
                    itemID = ids[i],
                    stack = stack - consumed,
                }
            end
            remaining = remaining - consumed
        end
    end
    if remaining > 0 then
        return nil
    end
    ops[#ops + 1] = {
        op = "update",
        itemID = weaponItemID,
        ammoCount = magazineCount,
    }
    return ops
end

Internal.BuildReloadOps = buildReloadOps
