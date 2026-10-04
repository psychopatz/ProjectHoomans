local T = require "tests/support/test"

local equipCalls = {}
PNC = {
    Inventory = {
        EnsureRecordInventory = function(record) return record.inventory end,
        EquipPrimary = function(record, itemID, reason)
            local inventory = record.inventory
            local previous = inventory.equipped.primary
            if previous and inventory.items[previous] then
                inventory.items[previous].equipSlot = nil
            end
            inventory.equipped.primary = itemID
            if itemID and inventory.items[itemID] then
                inventory.items[itemID].equipSlot = "primary"
            end
            record.equipment = record.equipment or {}
            record.equipment.primaryFullType = itemID
                and inventory.items[itemID].type or nil
            equipCalls[#equipCalls + 1] = {
                itemID = itemID, reason = reason,
            }
            return true, "equipped"
        end,
    },
    Equipment = {},
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Equipment/PNC_Equipment/PNC_Equipment_Leases.lua")

local record = {
    weaponMode = "mixed",
    inventory = {
        equipped = { primary = "gun" },
        items = {
            gun = { id = "gun", type = "Base.Pistol", equipSlot = "primary" },
            axe = { id = "axe", type = "Base.Axe" },
            hammer = { id = "hammer", type = "Base.Hammer" },
        },
    },
    equipment = { primaryFullType = "Base.Pistol" },
    runtime = {},
}

local acquired, reason = PNC.Equipment.AcquirePrimaryLease(
    record, "work:LUMBER", "axe", { priority = "WORK", reason = "lumber" })
T.equal(acquired, true, "work lease acquired")
T.equal(reason, "primary_lease_acquired", "work lease reason")
T.equal(record.inventory.equipped.primary, "axe", "work tool equipped")

acquired, reason = PNC.Equipment.AcquirePrimaryLease(
    record, "combat", "hammer", { priority = "COMBAT", reason = "combat" })
T.equal(acquired, true, "combat lease acquired")
T.equal(record.inventory.equipped.primary, "hammer", "combat weapon equipped")
T.equal(PNC.Equipment.GetActivePrimaryLease(record).owner,
    "combat", "combat owns primary slot")

local released
released, reason = PNC.Equipment.ReleaseCombatLease(record, nil, "combat_end")
T.equal(released, true, "combat lease released")
T.equal(record.inventory.equipped.primary, "axe",
    "work tool restored after combat")
T.equal(PNC.Equipment.GetActivePrimaryLease(record).owner,
    "work:LUMBER", "work lease reactivated")

released, reason = PNC.Equipment.ReleasePrimaryLease(
    record, "work:LUMBER", { reason = "work_end" })
T.equal(released, true, "work lease released")
T.equal(record.inventory.equipped.primary, "gun",
    "original primary restored after work")
T.equal(record.weaponMode, "mixed", "original weapon mode restored")
T.equal(#equipCalls, 4, "equipment mutations are bounded")

T.finish("pnc_equipment_lease_smoke")
